# Phase 3 修复方案

## 根因总结
基于 Gemini 3 分析的总结：

Element X Android 发起语音通话时显示"用户不是认证用户"错误的根本原因是：

1. **Widget URL 生成缺少认证 token**：在 `MatrixWidgetSettings.kt` 的 `generateWidgetWebViewUrl()` 方法中，传递给 Rust SDK 的 `ClientProperties` 只包含 `clientId`、`languageTag` 和 `theme`，没有包含用户的 `accessToken`。

2. **Session 状态未验证**：在 `DefaultCallWidgetProvider.getWidget()` 中，虽然调用了 `matrixClientsProvider.getOrRestore(sessionId)` 来获取 Matrix 客户端，但没有验证客户端的认证状态是否有效。即使 session 处于 "soft logout" 状态（token 过期但 session 未完全失效），该方法也可能返回一个客户端对象。

3. **Rust SDK 依赖内部 session 状态**：Rust SDK 的 `generateWebviewUrl()` 函数可能依赖内部的 session 状态来获取认证 token。如果内部的 session 状态无效或过期，生成的 Widget URL 就会缺少必要的认证参数。

## 修复方案
**选定方案：方案 A（Session 前置验证）**

**理由**：
1. **用户体验最好**：在通话发起前就检测认证状态，给用户明确的错误提示，而不是让用户等待10秒后看到失败。
2. **实现相对简单**：只需要在现有代码中添加认证状态检查，不需要修改 Rust SDK 或 Widget URL 生成逻辑。
3. **符合 Element X 的错误处理模式**：现有的错误处理机制已经支持返回明确的错误类型。

## 具体修改

### 文件 1: `features/call/impl/src/main/kotlin/io/element/android/features/call/impl/utils/DefaultCallWidgetProvider.kt`

**修改目标**：在 `getWidget()` 方法中添加 session 认证状态检查。

**修改内容**：
```kotlin
@ContributesBinding(AppScope::class)
class DefaultCallWidgetProvider(
    private val matrixClientsProvider: MatrixClientProvider,
    private val appPreferencesStore: AppPreferencesStore,
    private val callWidgetSettingsProvider: CallWidgetSettingsProvider,
    private val activeRoomsHolder: ActiveRoomsHolder,
    // 添加认证服务依赖
    private val authenticationService: MatrixAuthenticationService,
) : CallWidgetProvider {
    override suspend fun getWidget(
        sessionId: SessionId,
        roomId: RoomId,
        isAudioCall: Boolean,
        clientId: String,
        languageTag: String?,
        theme: String?,
    ): Result<CallWidgetProvider.GetWidgetResult> = runCatchingExceptions {
        // 1. 首先检查 session 认证状态
        val authState = authenticationService.getSessionState(sessionId).getOrThrow()
        if (!authState.isAuthenticated) {
            // 如果 session 未认证，返回明确的错误
            return Result.failure(
                IllegalStateException("User is not authenticated. Please log in again.")
            )
        }
        
        // 2. 获取 Matrix 客户端（原有逻辑）
        val matrixClient = matrixClientsProvider.getOrRestore(sessionId).getOrThrow()
        
        // 3. 检查客户端是否处于 soft logout 状态
        // 注意：需要添加一个方法来检查客户端的认证状态
        val isSoftLogout = matrixClient.isInSoftLogoutState().getOrNull() ?: false
        if (isSoftLogout) {
            return Result.failure(
                IllegalStateException("Session token has expired. Please re-authenticate.")
            )
        }
        
        // 4. 原有逻辑继续执行
        val room = activeRoomsHolder.getActiveRoomMatching(sessionId, roomId)
            ?: matrixClient.getJoinedRoom(roomId)
            ?: error("Room not found")

        val customBaseUrl = appPreferencesStore.getCustomElementCallBaseUrlFlow().firstOrNull()
        val baseUrl = customBaseUrl ?: EMBEDDED_CALL_WIDGET_BASE_URL

        val roomInfo = room.info()
        val isEncrypted = roomInfo.isEncrypted ?: room.getUpdatedIsEncrypted().getOrThrow()
        val widgetSettings = callWidgetSettingsProvider.provide(
            baseUrl = baseUrl,
            encrypted = isEncrypted,
            direct = room.isDm(),
            isAudioCall = isAudioCall,
            hasActiveCall = roomInfo.hasRoomCall,
        )
        val callUrl = room.generateWidgetWebViewUrl(
            widgetSettings = widgetSettings,
            clientId = clientId,
            languageTag = languageTag,
            theme = theme,
        ).getOrThrow()

        val driver = room.getWidgetDriver(widgetSettings).getOrThrow()

        CallWidgetProvider.GetWidgetResult(
            driver = driver,
            url = callUrl,
        )
    }
}
```

### 文件 2: `libraries/matrix/api/src/main/kotlin/io/element/android/libraries/matrix/api/MatrixClient.kt`

**修改目标**：在 `MatrixClient` 接口中添加检查 soft logout 状态的方法。

**修改内容**：
```kotlin
/**
 * Represents a logged in Matrix client.
 */
interface MatrixClient {
    // ... 现有方法 ...
    
    val sessionId: SessionId
    val userId: UserId
    val sessionCoroutineScope: CoroutineScope
    val syncService: SyncService
    val roomListService: RoomListService
    val mediaLoader: MediaLoader
    val verificationService: VerificationService
    val pushersService: PushersService
    val userProfileService: UserProfileService
    val userSearchService: UserSearchService
    val notificationService: NotificationService
    val timelineService: TimelineService
    
    // 添加新方法：检查客户端是否处于 soft logout 状态
    /**
     * Checks if the client is in a soft logout state.
     * 
     * Soft logout occurs when the access token has expired but the session
     * is not completely invalidated. The user needs to re-authenticate.
     * 
     * @return `true` if the client is in soft logout state, `false` otherwise.
     */
    suspend fun isInSoftLogoutState(): Result<Boolean>
    
    // ... 其他现有方法 ...
}
```

### 文件 3: `libraries/matrix/impl/src/main/kotlin/io/element/android/libraries/matrix/impl/MatrixClientImpl.kt`

**修改目标**：实现 `isInSoftLogoutState()` 方法。

**修改内容**：
```kotlin
/**
 * Implementation of [MatrixClient] backed by the Rust SDK.
 */
class MatrixClientImpl(
    // ... 现有参数 ...
) : MatrixClient {
    // ... 现有实现 ...
    
    override suspend fun isInSoftLogoutState(): Result<Boolean> = runCatchingExceptions {
        // 尝试执行一个简单的 API 调用来检查认证状态
        // 例如，获取用户信息，如果返回 UnknownToken 错误且 softLogout = true，则说明处于 soft logout 状态
        try {
            // 这是一个简单的检查方法：尝试获取当前用户的信息
            // 如果认证有效，这个调用会成功
            // 如果处于 soft logout 状态，会抛出 UnknownToken 异常
            innerClient.account().getDisplayName()
            false // 调用成功，不在 soft logout 状态
        } catch (e: Exception) {
            // 检查是否是 UnknownToken 错误且 softLogout = true
            when (val errorKind = e.toErrorKind()) {
                is ErrorKind.UnknownToken -> errorKind.softLogout
                else -> false // 其他错误，不是 soft logout
            }
        }
    }
    
    // ... 其他现有实现 ...
}
```

### 文件 4: `features/call/impl/src/main/kotlin/io/element/android/features/call/impl/CallScreenPresenter.kt`

**修改目标**：在通话发起前添加认证检查，并提供用户友好的错误处理。

**修改内容**：
```kotlin
class CallScreenPresenter(
    // ... 现有参数 ...
    private val callWidgetProvider: CallWidgetProvider,
    private val authenticationService: MatrixAuthenticationService,
) : Presenter<CallScreenState> {
    // ... 现有代码 ...
    
    private suspend fun startCall() {
        // 在发起通话前检查认证状态
        val authState = authenticationService.getSessionState(state.sessionId).getOrNull()
        if (authState == null || !authState.isAuthenticated) {
            // 更新状态显示认证错误
            updateState {
                it.copy(
                    isLoading = false,
                    error = "You need to log in to start a call. Please check your login status."
                )
            }
            return
        }
        
        // 原有逻辑继续执行
        val result = callWidgetProvider.getWidget(
            sessionId = state.sessionId,
            roomId = state.roomId,
            isAudioCall = state.isAudioCall,
            clientId = state.clientId,
            languageTag = state.languageTag,
            theme = state.theme,
        )
        
        result.fold(
            onSuccess = { widgetResult ->
                // 处理成功情况
                updateState {
                    it.copy(
                        isLoading = false,
                        widgetResult = widgetResult,
                    )
                }
            },
            onFailure = { error ->
                // 处理失败情况，特别处理认证错误
                val errorMessage = when {
                    error.message?.contains("not authenticated") == true -> 
                        "You are not authenticated. Please log in again."
                    error.message?.contains("token has expired") == true ->
                        "Your session has expired. Please re-authenticate."
                    else -> error.message ?: "Failed to start call"
                }
                
                updateState {
                    it.copy(
                        isLoading = false,
                        error = errorMessage,
                    )
                }
            }
        )
    }
}
```

## 风险评估

### 风险 1：误判认证状态
- **风险**：可能错误地判断用户为未认证状态，即使他们的 session 实际上是有效的。
- **缓解措施**：使用保守的检查策略，只在明确检测到认证错误时才阻止通话。

### 风险 2：性能影响
- **风险**：添加额外的认证检查可能增加通话发起的延迟。
- **缓解措施**：认证检查应该是轻量级的 API 调用，对性能影响最小。

### 风险 3：向后兼容性
- **风险**：新增的 `isInSoftLogoutState()` 方法需要所有 `MatrixClient` 实现都支持。
- **缓解措施**：提供默认实现，返回 `false` 表示不在 soft logout 状态。

### 风险 4：错误处理复杂性
- **风险**：新增的错误处理逻辑可能增加代码复杂性。
- **缓解措施**：保持错误处理简单明了，使用现有的错误处理模式。

## 测试验证方法

### 1. 单元测试
```kotlin
// 测试 DefaultCallWidgetProvider 的认证检查
@Test
fun `getWidget should fail when session is not authenticated`() = runTest {
    // 模拟未认证的 session
    val mockAuthService = mockk<MatrixAuthenticationService>()
    coEvery { mockAuthService.getSessionState(any()) } returns Result.success(
        SessionState(isAuthenticated = false)
    )
    
    val provider = DefaultCallWidgetProvider(
        // ... 其他依赖 ...
        authenticationService = mockAuthService,
    )
    
    val result = provider.getWidget(
        sessionId = SessionId("test"),
        roomId = RoomId("!test:example.com"),
        isAudioCall = true,
        clientId = "test-client",
    )
    
    assertTrue(result.isFailure)
    assertTrue(result.exceptionOrNull()?.message?.contains("not authenticated") == true)
}

@Test
fun `getWidget should fail when client is in soft logout`() = runTest {
    // 模拟认证的 session 但处于 soft logout 状态
    val mockAuthService = mockk<MatrixAuthenticationService>()
    coEvery { mockAuthService.getSessionState(any()) } returns Result.success(
        SessionState(isAuthenticated = true)
    )
    
    val mockClient = mockk<MatrixClient>()
    coEvery { mockClient.isInSoftLogoutState() } returns Result.success(true)
    
    val mockClientProvider = mockk<MatrixClientProvider>()
    coEvery { mockClientProvider.getOrRestore(any()) } returns Result.success(mockClient)
    
    val provider = DefaultCallWidgetProvider(
        matrixClientsProvider = mockClientProvider,
        // ... 其他依赖 ...
        authenticationService = mockAuthService,
    )
    
    val result = provider.getWidget(
        sessionId = SessionId("test"),
        roomId = RoomId("!test:example.com"),
        isAudioCall = true,
        clientId = "test-client",
    )
    
    assertTrue(result.isFailure)
    assertTrue(result.exceptionOrNull()?.message?.contains("token has expired") == true)
}
```

### 2. 集成测试
```kotlin
// 测试完整的通话流程
@Test
fun `call flow should show authentication error when session is invalid`() = runTest {
    // 模拟用户处于 soft logout 状态
    // 启动通话界面
    // 验证显示正确的错误消息
    // 验证通话没有实际发起
}
```

### 3. 手动测试步骤
1. **正常情况测试**：
   - 登录有效的账户
   - 发起语音通话
   - 验证通话正常建立

2. **Soft logout 测试**：
   - 登录账户
   - 模拟 token 过期（可以通过修改服务器配置或等待 token 自然过期）
   - 尝试发起语音通话
   - 验证显示"Session token has expired"错误
   - 验证通话没有实际发起

3. **未认证测试**：
   - 登出账户
   - 尝试发起语音通话
   - 验证显示"You need to log in"错误
   - 验证通话没有实际发起

4. **错误恢复测试**：
   - 在显示认证错误后
   - 重新登录账户
   - 再次尝试发起语音通话
   - 验证通话正常建立

### 4. 监控和日志
- 在 `DefaultCallWidgetProvider` 中添加详细的日志记录
- 记录认证检查的结果
- 记录通话发起的成功/失败情况
- 监控认证错误的发生频率

## 备选方案说明

如果上述方案实现起来太复杂，可以考虑以下简化方案：

### 简化方案：仅在前端捕获并处理认证错误
在 `CallScreenPresenter` 中捕获通话失败的错误，检查错误消息是否包含认证相关的关键词（如"not authenticated"、"unauthorized"等），然后显示用户友好的错误提示。

**优点**：
- 实现简单，不需要修改底层认证检查逻辑
- 仍然能改善用户体验

**缺点**：
- 用户仍然会等待通话尝试失败（约10秒）
- 不如前置检查方案体验好

**推荐**：优先实现完整的前置检查方案，如果时间或资源有限，再考虑简化方案。