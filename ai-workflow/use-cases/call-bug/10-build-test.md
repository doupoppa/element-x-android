# Bug 验证环境检查

## 1. 构建环境状态
**JAVA_VERSION**: Java 环境未正确配置。系统报告 "Unable to locate a Java Runtime"。需要安装 Java 17 或更高版本。

**GRADLE_VERSION**: 由于 Java 环境问题，无法运行 Gradle 检查 Gradle 版本。项目使用 Gradle wrapper (gradlew)。

**ANDROID_SDK状态**: 
- Android SDK 存在于 ~/Library/Android/sdk/
- 检测到的平台: android-36.1
- local.properties 中的 sdk.dir 指向 /home/dou/Android/Sdk (Linux 路径)，可能需要更新为 macOS 路径

**环境问题**:
1. Java 未安装或未正确配置
2. ANDROID_HOME 环境变量未设置
3. local.properties 中的 SDK 路径是 Linux 格式，需要调整为 macOS 路径

## 2. 通话相关测试文件
找到的测试文件列表:
1. `./features/roomcall/impl/src/test/kotlin/io/element/android/features/roomcall/impl/RoomCallStatePresenterTest.kt`
2. `./features/call/impl/src/test/kotlin/io/element/android/features/call/ui/CallScreenPresenterTest.kt`
3. `./features/call/impl/src/test/kotlin/io/element/android/features/call/ui/CallTypeTest.kt`
4. `./features/call/impl/src/test/kotlin/io/element/android/features/call/DefaultElementCallEntryPointTest.kt`
5. `./features/call/impl/src/test/kotlin/io/element/android/features/call/utils/DefaultActiveCallManagerTest.kt`
6. `./features/call/impl/src/test/kotlin/io/element/android/features/call/utils/DefaultCallWidgetProviderTest.kt`
7. `./features/call/impl/src/test/kotlin/io/element/android/features/call/utils/CallIntentDataParserTest.kt`
8. `./features/call/impl/src/test/kotlin/io/element/android/features/call/notifications/RingingCallNotificationCreatorTest.kt`
9. `./libraries/push/impl/src/test/kotlin/io/element/android/libraries/push/impl/notifications/DefaultOnMissedCallNotificationHandlerTest.kt`

**关键测试文件**:
- DefaultCallWidgetProviderTest.kt: `./features/call/impl/src/test/kotlin/io/element/android/features/call/utils/DefaultCallWidgetProviderTest.kt`
- RustClientSessionDelegateTest.kt: `./libraries/matrix/impl/src/test/kotlin/io/element/android/libraries/matrix/impl/RustClientSessionDelegateTest.kt`

## 3. 关键代码确认
- **didReceiveAuthError() 在哪里**: `./libraries/matrix/impl/src/main/kotlin/io/element/android/libraries/matrix/impl/RustClientSessionDelegate.kt`
- **第 92 行 TODO 内容**: `// TODO handle isSoftLogout parameter.` (实际在第95行)

**代码片段**:
```kotlin
override fun didReceiveAuthError(isSoftLogout: Boolean) {
    Timber.tag(loggerTag.value).w("didReceiveAuthError(isSoftLogout=$isSoftLogout)")
    if (isLoggingOut.getAndSet(true).not()) {
        Timber.tag(loggerTag.value).v("didReceiveAuthError -> do the cleanup")
        // TODO handle isSoftLogout parameter.
        appCoroutineScope.launch(updateTokensDispatcher) {
            val currentClient = client.get()
            if (currentClient == null) {
                Timber.tag(loggerTag.value).w("didReceiveAuthError -> no client, exiting")
```

## 4. 构建验证步骤
**如何构建 APK 验证 Bug**:
1. 修复 Java 环境: 安装 Java 17+
2. 更新 local.properties: 将 sdk.dir 改为 macOS 路径 (如 /Users/dou/Library/Android/sdk)
3. 设置环境变量: export ANDROID_HOME=~/Library/Android/sdk
4. 运行构建: `./gradlew assembleDebug` 或 `./gradlew assembleRelease`

**如何在本地触发 soft logout 状态**:
根据代码分析，`didReceiveAuthError(isSoftLogout: Boolean)` 方法接收一个 `isSoftLogout` 参数，但目前该参数被忽略（TODO 注释）。要测试此功能，需要:
1. 模拟认证错误场景
2. 确保 `isSoftLogout` 参数被正确处理
3. 可能需要修改 Rust SDK 或测试代码来触发此状态

## 5. 测试方案
**有没有现有测试可以运行**:
- 有 RustClientSessionDelegateTest.kt 测试文件
- 有 DefaultCallWidgetProviderTest.kt 测试文件
- 需要先修复构建环境才能运行测试

**需要新写什么测试**:
1. **didReceiveAuthError 测试**: 测试 `isSoftLogout=true` 和 `isSoftLogout=false` 的不同处理逻辑
2. **Soft Logout 场景测试**: 模拟 soft logout 状态下的通话行为
3. **认证错误恢复测试**: 测试在收到 auth error 后通话功能的恢复能力
4. **Widget Provider 错误处理测试**: 测试 DefaultCallWidgetProvider 在认证错误时的行为

**测试优先级**:
1. 修复构建环境 ✅
2. 运行现有测试验证基础功能
3. 编写 didReceiveAuthError 参数处理测试
4. 集成测试验证通话在认证错误时的行为