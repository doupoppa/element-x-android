# 新专家团队深度分析报告

## 日期
2026-04-01

## 分析目标
重新分析 Element X Android 通话 Bug，找到之前修复无效的真正原因。

## 背景
- **Bug 描述**：发起语音通话时显示"用户不是认证用户"错误
- **已实施修复**：修改了 `RustClientSessionDelegate.didReceiveAuthError()` 处理 soft logout
- **修复结果**：编译成功，但 bug 依然存在

---

## 第一部分：代码审查发现

### 1. Widget URL 生成流程

完整流程：
```
用户点击通话按钮
  ↓
DefaultCallWidgetProvider.getWidget()
  ↓
callWidgetSettingsProvider.provide() 
  → 生成 MatrixWidgetSettings (包含 rawUrl)
  ↓
room.generateWidgetWebViewUrl(widgetSettings, clientId, languageTag, theme)
  ↓
调用 Rust SDK: generateWebviewUrl(widgetSettings, room, ClientProperties)
  ↓
返回完整的 Widget URL（应该包含认证参数）
  ↓
WebView 加载 Element Call Web App
```

### 2. 关键代码片段

**文件：`DefaultCallWidgetProvider.kt`**
```kotlin
val callUrl = room.generateWidgetWebViewUrl(
    widgetSettings = widgetSettings,
    clientId = clientId,
    languageTag = languageTag,
    theme = theme,
).getOrThrow()
```

**文件：`MatrixWidgetSettings.kt`**
```kotlin
suspend fun MatrixWidgetSettings.generateWidgetWebViewUrl(
    room: Room,
    clientId: String,
    languageTag: String? = null,
    theme: String? = null
) = generateWebviewUrl(
    widgetSettings = this.toRustWidgetSettings(),
    room = room,
    props = ClientProperties(
        clientId = clientId,
        languageTag = languageTag,
        theme = theme,
    )
)
```

**关键发现**：
- `ClientProperties` 只包含 `clientId`、`languageTag`、`theme`
- **没有显式传递 `accessToken`**
- 认证信息应该由 Rust SDK 从 `room` 对象中自动获取

---

## 第二部分：核心问题分析

### 3. Rust SDK 的 `generateWebviewUrl()` 工作原理

**推测的内部逻辑**：
```
generateWebviewUrl(widgetSettings, room, clientProperties) {
    1. 获取 room 关联的 MatrixClient
    2. 从 MatrixClient 的 session 中获取 accessToken
    3. 将 accessToken 添加到 Widget URL 的查询参数中
    4. 返回完整的认证 URL
}
```

**关键依赖**：
- `room` 对象必须关联到一个**有效的 MatrixClient**
- MatrixClient 的 **session 必须包含有效的 accessToken**

### 4. 真正的 Bug 根因假设

**假设 1：Session 状态不一致**
- `RustClientSessionDelegate.didReceiveAuthError()` 修复后，soft logout 时不再标记 session 为无效
- 但是，**Rust SDK 内部的 session 状态可能仍然是"过期"状态**
- 当 `generateWebviewUrl()` 尝试从 session 获取 accessToken 时，可能获取到空值或过期的 token

**假设 2：Room 对象与 Session 的关联问题**
- `room` 对象可能关联到一个**已经过期的 session**
- 即使 Kotlin 层认为 session 有效，Rust SDK 内部可能认为 session 无效

**假设 3：Token 刷新时机问题**
- Rust SDK 的自动 token 刷新可能**还没有完成**
- `generateWebviewUrl()` 在 token 刷新完成前被调用，导致使用了过期的 token

---

## 第三部分：验证和诊断方案

### 5. 如何验证真正的问题

**方案 A：添加日志验证 URL 内容**

在 `DefaultCallWidgetProvider.getWidget()` 中添加日志：

```kotlin
val callUrl = room.generateWidgetWebViewUrl(
    widgetSettings = widgetSettings,
    clientId = clientId,
    languageTag = languageTag,
    theme = theme,
).getOrThrow()

// 添加日志：检查 URL 是否包含认证参数
Timber.d("Generated call URL: ${callUrl.take(200)}...") // 只打印前200字符避免泄露完整token
Timber.d("URL contains 'access_token': ${callUrl.contains("access_token")}")
Timber.d("URL contains 'userId': ${callUrl.contains("userId")}")
```

**方案 B：检查 Room 的 Session 状态**

在调用 `generateWidgetWebViewUrl()` 前检查 session：

```kotlin
// 在 DefaultCallWidgetProvider.getWidget() 中添加
val matrixClient = matrixClientsProvider.getOrRestore(sessionId).getOrThrow()

// 检查 client 的认证状态
Timber.d("MatrixClient sessionId: ${matrixClient.sessionId}")
Timber.d("MatrixClient userId: ${matrixClient.userId}")

// 尝试获取 session 信息（如果有相关 API）
// val session = matrixClient.getSession() // 假设有这个方法
// Timber.d("Session accessToken exists: ${session.accessToken.isNotEmpty()}")
```

**方案 C：检查 Element Call Web App 的错误来源**

在 WebView 中添加 JavaScript 控制台日志捕获：

```kotlin
// 在 CallScreenView.kt 的 WebView 配置中添加
webView.webChromeClient = object : WebChromeClient() {
    override fun onConsoleMessage(consoleMessage: ConsoleMessage): Boolean {
        Timber.d("WebView Console: ${consoleMessage.message()}")
        return true
    }
}
```

这样可以看到 Element Call Web App 内部的错误信息。

---

## 第四部分：修复方案

### 6. 方案一：在 generateWidgetWebViewUrl 前强制刷新 Session

**修改文件**：`DefaultCallWidgetProvider.kt`

```kotlin
override suspend fun getWidget(
    sessionId: SessionId,
    roomId: RoomId,
    isAudioCall: Boolean,
    clientId: String,
    languageTag: String?,
    theme: String?,
): Result<CallWidgetProvider.GetWidgetResult> = runCatchingExceptions {
    val matrixClient = matrixClientsProvider.getOrRestore(sessionId).getOrThrow()
    
    // 新增：确保 session 有效
    ensureSessionValid(matrixClient)
    
    val room = activeRoomsHolder.getActiveRoomMatching(sessionId, roomId)
        ?: matrixClient.getJoinedRoom(roomId)
        ?: error("Room not found")

    // ... 其余代码保持不变
}

private suspend fun ensureSessionValid(client: MatrixClient) {
    // 执行一个简单的 API 调用来验证 session
    // 如果 session 无效，这会触发 Rust SDK 的自动刷新
    try {
        client.getAccountData("m.dummy") // 或其他轻量级 API
    } catch (e: Exception) {
        Timber.w("Session validation failed, but continuing: ${e.message}")
        // 给 Rust SDK 一点时间完成 token 刷新
        delay(500)
    }
}
```


### 7. 方案二：添加重试机制

如果第一次生成 URL 失败，等待后重试：

```kotlin
val callUrl = retryWithDelay(maxAttempts = 2, delayMs = 500) {
    room.generateWidgetWebViewUrl(
        widgetSettings = widgetSettings,
        clientId = clientId,
        languageTag = languageTag,
        theme = theme,
    ).getOrThrow()
}

private suspend fun <T> retryWithDelay(
    maxAttempts: Int,
    delayMs: Long,
    block: suspend () -> T
): T {
    repeat(maxAttempts - 1) { attempt ->
        try {
            return block()
        } catch (e: Exception) {
            Timber.w("Attempt ${attempt + 1} failed: ${e.message}, retrying...")
            delay(delayMs)
        }
    }
    return block()
}
```

### 8. 方案三：检查并等待 Sync 完成

```kotlin
val matrixClient = matrixClientsProvider.getOrRestore(sessionId).getOrThrow()

// 等待 sync 进入 Running 状态
matrixClient.syncService.syncState.first { it == SyncState.Running }
Timber.d("Sync is running, proceeding with call setup")
```

---

## 第五部分：推荐的实施步骤

### 立即行动（诊断阶段）

1. **添加详细日志**
   - 在 `DefaultCallWidgetProvider.getWidget()` 中添加 URL 检查日志
   - 在 WebView 中捕获 JavaScript 控制台日志
   - 让豆爸重现 bug，收集日志

2. **分析日志输出**
   - 检查生成的 URL 是否包含 `access_token` 参数
   - 检查 Element Call Web App 的具体错误信息
   - 确认错误来源（Kotlin 层 vs Web App 层）

### 修复阶段（基于诊断结果）

**如果 URL 缺少 access_token**：
- 实施方案一（强制刷新 session）或方案三（等待 sync）

**如果 URL 包含 access_token 但仍然失败**：
- 问题可能在 Element Call Web App 层
- 需要检查 token 是否真的有效
- 可能需要实施方案二（重试机制）


---

## 第六部分：关键问题回答

### Q1: "用户不是认证用户"错误是从哪里产生的？

**答案**：很可能来自 **Element Call Web App**（React 应用），而不是 Kotlin 层。

**理由**：
- Kotlin 层没有这个错误字符串
- Element Call Web App 在加载时会检查 URL 中的认证参数
- 如果 URL 缺少 `access_token` 或 token 无效，Web App 会显示此错误

### Q2: Widget URL 生成时，认证信息是怎么传递的？

**答案**：认证信息由 **Rust SDK 内部自动添加**。

**流程**：
1. Kotlin 层调用 `generateWebviewUrl(widgetSettings, room, ClientProperties)`
2. Rust SDK 从 `room` 对象获取关联的 MatrixClient
3. Rust SDK 从 MatrixClient 的 session 中提取 `accessToken`
4. Rust SDK 将 `accessToken` 添加到 URL 的查询参数中
5. 返回包含认证信息的完整 URL

### Q3: 如果 session 处于 soft logout 状态，generateWidgetWebViewUrl() 会生成什么样的 URL？

**答案**：可能生成**缺少有效 accessToken 的 URL**。

**原因**：
- 即使 Kotlin 层的 `didReceiveAuthError()` 不再标记 session 为无效
- Rust SDK 内部的 session 状态可能仍然是"token 过期"
- 当 `generateWebviewUrl()` 尝试获取 accessToken 时，可能获取到空值或过期的 token

### Q4: Rust SDK 的 generateWebviewUrl() 内部是怎么工作的？

**答案**：（基于代码推测）

```
generateWebviewUrl(widgetSettings, room, clientProperties) {
    1. 从 room 获取关联的 MatrixClient
    2. 从 MatrixClient.session 获取 accessToken
    3. 构建 URL：baseUrl + widgetId + accessToken + userId + deviceId + ...
    4. 返回完整 URL
}
```

**关键依赖**：
- Room 必须关联到有效的 MatrixClient
- MatrixClient 的 session 必须包含有效的 accessToken

