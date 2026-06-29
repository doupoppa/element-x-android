# 实施记录 - 方案一：修复 `didReceiveAuthError()` 的 soft logout 处理

## 日期
2026-04-01

## 修改文件
- `libraries/matrix/impl/src/main/kotlin/io/element/android/libraries/matrix/impl/RustClientSessionDelegate.kt`

## 修改内容

### 问题分析

**当前 `didReceiveAuthError()` 的行为（第 92-125 行）：**
```kotlin
override fun didReceiveAuthError(isSoftLogout: Boolean) {
    Timber.tag(loggerTag.value).w("didReceiveAuthError(isSoftLogout=$isSoftLogout)")
    if (isLoggingOut.getAndSet(true).not()) {
        // TODO handle isSoftLogout parameter.  ← 忽略 isSoftLogout 参数！
        appCoroutineScope.launch(updateTokensDispatcher) {
            // ... 总是标记 session 为无效
            val newData = existingData.copy(isTokenValid = false)
            sessionStore.updateData(newData)
            // ... 总是调用 logout
            currentClient.logout(userInitiated = false, ignoreSdkError = true)
        }
    }
}
```

**问题：** 无论 `isSoftLogout` 是 `true` 还是 `false`，代码都会：
1. 将 session 标记为无效 (`isTokenValid = false`)
2. 调用 `currentClient.logout()`

这导致 soft logout 时，session 被错误地标记为无效，通话功能无法使用。

### Rust SDK Token 刷新 API 分析

通过分析 Rust SDK（AAR 二进制库）：
- Rust SDK **不提供** 公开的 `refreshAccessToken()` API
- Token 刷新由 Rust SDK **内部自动处理**
- `didReceiveAuthError(isSoftLogout: Boolean)` 是 SDK 在自动刷新失败后调用的回调
- `isSoftLogout = true` 表示 session 仍然有效，只是 access token 过期
- `isSoftLogout = false` 表示 session 本身已失效

### 修复方案

**修改后的逻辑：**

```kotlin
override fun didReceiveAuthError(isSoftLogout: Boolean) {
    Timber.tag(loggerTag.value).w("didReceiveAuthError(isSoftLogout=$isSoftLogout)")
    if (isSoftLogout) {
        // Soft logout: access token expired but session is still valid.
        // The Rust SDK will automatically retry with refreshed credentials.
        // We just log and let the SDK handle token refresh internally.
        Timber.tag(loggerTag.value).d(
            "Soft logout detected. The SDK will automatically retry with refreshed credentials. " +
                "Session data left unchanged."
        )
    } else if (isLoggingOut.getAndSet(true).not()) {
        // Hard logout: session is invalidated, proceed with full cleanup
        // ... 保持现有逻辑不变
    }
}
```

**关键变更：**
1. `isSoftLogout = true` 时：**不标记 session 为无效**，仅记录日志，让 Rust SDK 自动处理 token 刷新重试
2. `isSoftLogout = false` 时：保持现有行为（标记无效 + logout）
3. 移除了 `// TODO handle isSoftLogout parameter.` 注释

### 为什么这个修复有效

1. **Soft logout 场景：**
   - 用户 access token 过期，但 session 本身仍然有效（有有效的 refresh token）
   - Rust SDK 会自动尝试用 refresh token 获取新的 access token
   - 如果自动刷新成功，SDK 会自动重试原操作
   - 如果自动刷新失败，SDK 会再次调用 `didReceiveAuthError`，这次 `isSoftLogout` 可能变为 `false`

2. **Hard logout 场景：**
   - Session 本身已失效，必须重新登录
   - 保持现有逻辑不变

### 编译验证

```
$ JAVA_HOME=/opt/homebrew/opt/openjdk@21 ./gradlew :libraries:matrix:impl:compileDebugKotlin --no-daemon
BUILD SUCCESSFUL in 15s
```

✅ 编译成功，无错误

## 遇到的问题和解决方案

### 问题 1：Rust SDK 没有公开的 token 刷新 API

**问题描述：** 原本计划在 soft logout 时主动调用 token 刷新 API，但 Rust SDK 不提供公开的 `refreshAccessToken()` 方法。

**解决方案：** Rust SDK 会**自动处理** token 刷新，不需要应用层主动调用。修复策略改为：soft logout 时保持 session 有效，让 SDK 的自动重试机制正常工作。

### 问题 2：Java 运行时未找到

**问题描述：** 执行 gradle 编译时提示 "Unable to locate a Java Runtime"。

**解决方案：** 使用 Homebrew 安装的 OpenJDK 21，显式设置 `JAVA_HOME`：
```bash
JAVA_HOME=/opt/homebrew/opt/openjdk@21 ./gradlew :libraries:matrix:impl:compileDebugKotlin
```

## 后续步骤（方案二、三）

### 方案二（待实施）：
在 `JoinedRustRoom.generateWidgetWebViewUrl()` 前添加 session 验证，防止在 session 处于边缘状态时生成无效 URL。

### 方案三（待评估）：
在 `MatrixClient` 接口中添加 `ensureSessionValid()` 等方法，在关键操作前验证 session 状态。

## 参考资料

- 原始分析文档：`09-fundamental-fix.md`
- Rust SDK 版本：`26.03.24` (org.matrix.rustcomponents:sdk-android)
- Matrix SDK 的 token 刷新机制由 SDK 内部自动处理，应用层通过 `ClientSessionDelegate` 回调获取通知
