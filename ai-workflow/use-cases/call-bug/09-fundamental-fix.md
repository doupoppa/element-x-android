# 根本修复方案（Rust SDK Session 刷新机制）

## 1. Rust SDK Session 机制分析

### Session 管理
- Rust SDK 通过 `Session` 对象管理用户会话，包含 `accessToken` 和可选的 `refreshToken`
- 当 token 过期时，Rust SDK 会通过 `didReceiveAuthError(isSoftLogout: Boolean)` 回调通知客户端
- 目前 `RustClientSessionDelegate.didReceiveAuthError()` 中有一个 TODO 注释：`// TODO handle isSoftLogout parameter.`，说明 soft logout 处理尚未完全实现

### Soft Logout 状态
- **Soft Logout**: 当 access token 过期但 refresh token 仍然有效时，用户处于 "soft logout" 状态
- 在这种状态下，用户会话仍然存在，但需要刷新 access token 才能继续使用
- 目前代码在收到 auth error 时，无论 `isSoftLogout` 参数如何，都会将 session 标记为无效 (`isTokenValid = false`)

### Token 刷新机制
- Rust SDK 应该自动处理 token 刷新，但需要有效的 refresh token
- 当 `generateWebviewUrl()` 被调用时，如果 session 处于 soft logout 状态，生成的 URL 可能没有有效的认证信息

## 2. 根本问题定位

### 问题根源
1. **`RustClientSessionDelegate.didReceiveAuthError()` 未正确处理 soft logout**
   - 当前实现：无论是否 soft logout，都会将 `isTokenValid` 设为 `false`
   - 正确做法：如果是 soft logout，应该尝试刷新 token 而不是直接标记为无效

2. **`generateWebviewUrl()` 依赖有效的 session 状态**
   - 当 session 被标记为无效时，生成的 widget URL 可能缺少必要的认证信息
   - 这导致通话时显示 "用户不是认证用户" 错误

3. **缺少 token 刷新触发机制**
   - 没有明确的 API 在调用 `generateWidgetWebViewUrl()` 之前验证/刷新 session
   - 如果 session 处于 soft logout 状态，没有自动恢复机制

## 3. 根本修复方案

### 方案一：修复 `didReceiveAuthError()` 的 soft logout 处理

**修改文件：** `libraries/matrix/impl/src/main/kotlin/io/element/android/libraries/matrix/impl/RustClientSessionDelegate.kt`

```kotlin
override fun didReceiveAuthError(isSoftLogout: Boolean) {
    Timber.tag(loggerTag.value).w("didReceiveAuthError(isSoftLogout=$isSoftLogout)")
    
    if (isSoftLogout) {
        // 处理 soft logout：尝试刷新 token
        handleSoftLogout()
    } else {
        // 处理 hard logout：标记 session 为无效
        handleHardLogout()
    }
}

private fun handleSoftLogout() {
    if (isLoggingOut.getAndSet(true).not()) {
        appCoroutineScope.launch(updateTokensDispatcher) {
            val currentClient = client.get()
            if (currentClient == null) {
                Timber.tag(loggerTag.value).w("handleSoftLogout -> no client, exiting")
                isLoggingOut.set(false)
                return@launch
            }
            
            // 尝试刷新 token
            val refreshResult = currentClient.tryRefreshToken()
            if (refreshResult.isSuccess) {
                Timber.tag(loggerTag.value).d("Token refresh successful")
                // 更新 session 数据
                val existingData = sessionStore.getSession(currentClient.sessionId.value)
                if (existingData != null) {
                    val newData = existingData.copy(isTokenValid = true)
                    sessionStore.updateData(newData)
                }
            } else {
                Timber.tag(loggerTag.value).w("Token refresh failed, falling back to hard logout")
                handleHardLogout()
            }
            isLoggingOut.set(false)
        }
    }
}

private fun handleHardLogout() {
    if (isLoggingOut.getAndSet(true).not()) {
        // 现有硬登出逻辑...
        // [保持现有代码不变]
    }
}
```

### 方案二：在 `generateWidgetWebViewUrl()` 前添加 session 验证

**修改文件：** `libraries/matrix/impl/src/main/kotlin/io/element/android/libraries/matrix/impl/room/JoinedRustRoom.kt`

```kotlin
override suspend fun generateWidgetWebViewUrl(
    widgetSettings: MatrixWidgetSettings,
    clientId: String,
    languageTag: String?,
    theme: String?,
) = withContext(roomDispatcher) {
    runCatchingExceptions {
        // 在生成 URL 前验证 session 状态
        ensureValidSession()
        
        widgetSettings.generateWidgetWebViewUrl(innerRoom, clientId, languageTag, theme)
    }
}

private suspend fun ensureValidSession() {
    // 检查 session 是否有效，如果无效则尝试恢复
    val session = innerRoom.session()
    if (session == null || session.accessToken.isEmpty()) {
        // 尝试恢复 session
        val client = this@JoinedRustRoom.baseRoom.matrixClient
        client.tryRestoreSession()
    }
}
```

### 方案三：添加 token 刷新 API

**需要添加的接口：**

1. 在 `MatrixClient` 接口中添加：
```kotlin
interface MatrixClient {
    // ... 现有方法 ...
    
    /**
     * 尝试刷新 access token（仅当有 refresh token 且处于 soft logout 状态时）
     */
    suspend fun tryRefreshToken(): Result<Unit>
    
    /**
     * 检查并恢复 session 状态
     */
    suspend fun tryRestoreSession(): Result<Unit>
}
```

2. 在 `RustMatrixClient` 中实现：
```kotlin
override suspend fun tryRefreshToken(): Result<Unit> = withContext(coroutineDispatchers.io) {
    runCatchingExceptions {
        // 调用 Rust SDK 的 token 刷新机制
        // 注意：需要检查 Rust SDK 是否提供此 API
        innerClient.refreshAccessToken()
    }
}

override suspend fun tryRestoreSession(): Result<Unit> = withContext(coroutineDispatchers.io) {
    runCatchingExceptions {
        // 从存储中恢复 session
        val sessionData = sessionStore.getSession(sessionId.value)
        if (sessionData != null && !sessionData.isTokenValid) {
            // 如果 token 无效，尝试重新认证
            authenticationService.restoreSession(sessionId)
        }
    }
}
```

## 4. 需要修改的文件

### 主要修改：
1. **`RustClientSessionDelegate.kt`** - 修复 `didReceiveAuthError()` 方法，区分 soft/hard logout
2. **`JoinedRustRoom.kt`** - 在 `generateWidgetWebViewUrl()` 前添加 session 验证
3. **`RustMatrixClient.kt`** - 实现 token 刷新和 session 恢复方法

### 接口扩展：
1. **`MatrixClient.kt`** (API) - 添加 `tryRefreshToken()` 和 `tryRestoreSession()` 方法
2. **`MatrixClientProvider.kt`** - 确保提供恢复后的 client

### 辅助修改：
1. **`DefaultCallWidgetProvider.kt`** - 考虑在获取 widget 前验证 session
2. **`MatrixSessionCache.kt`** - 增强 session 恢复逻辑

## 5. 风险评估

### 技术风险：
1. **Rust SDK API 可用性**：需要确认 Rust SDK 是否提供 `refreshAccessToken()` 或类似 API
2. **并发问题**：多个地方同时尝试刷新 token 可能导致竞争条件
3. **向后兼容性**：修改接口可能影响现有代码

### 缓解措施：
1. **渐进式实现**：先实现最基本的修复（方案一），再逐步完善
2. **错误处理**：确保所有失败情况都有适当的回退机制
3. **测试覆盖**：添加单元测试和集成测试验证修复效果

### 备选方案：
如果 Rust SDK 不提供 token 刷新 API，可以考虑：
1. **重新登录流程**：当检测到 soft logout 时，引导用户重新登录
2. **预验证机制**：在关键操作（如通话）前主动验证 session 状态
3. **定期检查**：后台定期检查 token 有效性并提前刷新

## 6. 关键问题答案

### 问题 1：Rust SDK 的 session 会在什么时机自动刷新 token？
**答案**：目前 **没有自动刷新机制**。当 Rust SDK 检测到认证错误时，会通过 `didReceiveAuthError(isSoftLogout: Boolean)` 回调通知客户端。当前实现无论 `isSoftLogout` 参数如何，都会将 session 标记为无效。`generateWebviewUrl` 被调用时 **不会自动触发** token 刷新。

### 问题 2：如果 session 处于 soft logout 状态，有没有 API 可以触发重新认证？
**答案**：目前 **没有直接的 API** 来触发 token 刷新。`RustClientSessionDelegate.didReceiveAuthError()` 方法有一个 TODO 注释（第 92 行），表明 soft logout 处理尚未实现。需要检查 Rust SDK 是否提供 `refreshAccessToken()` 或类似方法。

### 问题 3：能否在 `generateWidgetWebViewUrl()` 之前主动触发 session 验证/刷新？
**答案**：**可以，但需要实现**。目前没有现成的机制。建议在 `JoinedRustRoom.generateWidgetWebViewUrl()` 方法开始时添加 session 验证，调用 `ensureValidSession()` 方法检查 session 状态并在需要时尝试恢复。

## 7. 结论

### 根本修复是否可行？
**是可行的**，但需要分阶段实施：

### 建议的实施步骤：
1. **第一阶段（紧急修复）**：实现方案一，修复 `didReceiveAuthError()` 对 soft logout 的处理
2. **第二阶段（增强）**：实现方案三，添加 token 刷新 API
3. **第三阶段（预防）**：实现方案二，在关键操作前验证 session

### 优先级建议：
1. **高优先级**：修复 `didReceiveAuthError()` 方法（方案一）
   - 这是最直接的修复，能立即解决大部分 soft logout 问题
   - 修改范围小，风险可控

2. **中优先级**：添加 session 验证（方案二）
   - 预防性措施，减少未来出现类似问题的可能性
   - 需要修改通话相关代码

3. **低优先级**：完整 token 刷新机制（方案三）
   - 需要 Rust SDK 支持，可能涉及更多改动
   - 可以作为长期改进目标

### 立即行动项：
1. 检查 Rust SDK 文档/源码，确认 token 刷新 API 的可用性
2. 实现 `didReceiveAuthError()` 的 soft logout 处理
3. 添加测试用例验证修复效果

### 备选方案（如果 Rust SDK 不支持 token 刷新）：
如果 Rust SDK 不提供 token 刷新 API，可以考虑以下备选方案：
1. **重新登录流程**：当检测到 soft logout 时，引导用户重新登录
2. **预验证机制**：在关键操作（如通话）前主动验证 session 状态，如果无效则提示用户
3. **定期检查**：后台定期检查 token 有效性，提前发现并处理过期问题