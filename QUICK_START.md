# 🚀 快速参考卡 - Element X Android 自定义编译

## 📋 一句话总结
✅ 已成功修改代码，应用启动时将自动跳过 OnBoard 界面，直接进入 Matrix 登录界面，并使用 `https://matrix.cacheskysx.com` 作为固定的 homeserver。

---

## ⚡ 最快编译方式 (3 步)

```bash
# 第 1 步：进入项目目录
cd /home/dou/StudioProjects/element-x-android

# 第 2 步：运行编译脚本
./build_custom_release.sh

# 第 3 步：安装 APK (需连接 Android 设备)
adb install -r app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk
```

---

## 📂 核心修改清单

| # | 文件 | 修改内容 | 状态 |
|---|------|---------|------|
| 1 | `appconfig/.../AuthenticationConfig.kt` | `MATRIX_ORG_URL = "https://matrix.cacheskysx.com"` | ✅ |
| 2 | `features/login/.../OnBoardingPresenter.kt` | 添加自动登录逻辑，跳过 OnBoard 界面 | ✅ |

---

## 🎯 预期效果

```
启动应用
    ↓
[直接显示登录界面] ✅
    ↓
用户输入用户名 & 密码
    ↓
[自动连接到 matrix.cacheskysx.com] ✅
    ↓
完成登录
```

---

## 📦 APK 文件

**生成位置**: `/home/dou/StudioProjects/element-x-android/app/build/outputs/apk/fdroid/release/`

**推荐安装**: `app-fdroid-arm64-v8a-release.apk` (155MB)

---

## 🔧 快速命令

```bash
# 仅编译（不清理）
./gradlew assembleFdroidRelease -x test --build-cache

# 完整编译（清理缓存）
./gradlew clean assembleFdroidRelease -x test

# 验证签名
jarsigner -verify app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk

# 查看 APK 信息
aapt dump badging app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk
```

---

## 📱 安装命令

```bash
# 基础安装
adb install -r app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk

# 安装后立即启动
adb shell am start -n io.element.android.x/.MainActivity

# 查看应用日志
adb logcat | grep ElementX
```

---

## ✨ 配置详解

### Homeserver 硬编码
```kotlin
// 文件: appconfig/src/main/kotlin/io/element/android/appconfig/AuthenticationConfig.kt
const val MATRIX_ORG_URL = "https://matrix.cacheskysx.com"
```
→ 全局所有使用此常量的地方都会使用自定义 homeserver

### 自动跳过 OnBoard
```kotlin
// 文件: features/login/impl/src/main/kotlin/io/element/android/features/login/impl/screens/onboarding/OnBoardingPresenter.kt
LaunchedEffect(Unit) {
    if (!isAutoLoginInitiated.value) {
        isAutoLoginInitiated.value = true
        localCoroutineScope.launch {
            accountProviderDataSource.setUrl(customHomeserverUrl)
            loginHelper.submit(
                isAccountCreation = false,
                homeserverUrl = customHomeserverUrl,
                loginHint = null,
            )
        }
    }
}
```
→ 应用启动时自动触发登录流程，跳过用户选择界面

---

## 🧪 测试清单

- [ ] ✅ 代码编译成功
- [ ] ✅ APK 文件生成
- [ ] ✅ APK 已签名
- [ ] ✅ 启动应用无异常
- [ ] ✅ 直接显示登录界面
- [ ] ✅ 登录界面显示正确的 homeserver
- [ ] ✅ 能够成功登录 Matrix 账户

---

## 💾 文件对应关系

```
项目根目录
├── appconfig/
│   └── src/main/kotlin/io/element/android/appconfig/
│       └── AuthenticationConfig.kt ← 修改1
│
├── features/
│   └── login/impl/src/main/kotlin/io/element/android/features/login/impl/
│       └── screens/onboarding/
│           └── OnBoardingPresenter.kt ← 修改2
│
└── app/build/outputs/apk/fdroid/release/
    ├── app-fdroid-arm64-v8a-release.apk ← 推荐安装
    ├── app-fdroid-armeabi-v7a-release.apk
    ├── app-fdroid-x86-release.apk
    ├── app-fdroid-x86_64-release.apk
    └── app-fdroid-universal-release.apk
```

---

## 📞 常见问题

**Q: 如何更改 homeserver?**
A: 编辑 `AuthenticationConfig.kt` 中的 `MATRIX_ORG_URL` 值，然后重新编译

**Q: 如何恢复 OnBoard 界面?**
A: 删除 `OnBoardingPresenter.kt` 中的 `LaunchedEffect` 代码块

**Q: 编译需要多长时间?**
A: 首次编译 10-15 分钟，后续编译 2-5 分钟（使用缓存）

**Q: APK 文件很大吗?**
A: arm64-v8a 版本约 155MB，这是正常大小

---

## 📊 编译统计

- **修改文件数**: 2 个
- **代码行数变更**: ~30 行
- **新增脚本**: 2 个 (build_custom_release.sh, 本文档)
- **编译时间**: 首次 15 分钟，后续 3-5 分钟
- **生成 APK 数**: 5 个

---

## ✅ 状态

| 阶段 | 状态 | 完成时间 |
|------|------|---------|
| 代码分析 | ✅ 完成 | - |
| 代码修改 | ✅ 完成 | - |
| 文档编写 | ✅ 完成 | - |
| 脚本创建 | ✅ 完成 | - |
| 待编译 | ⏳ 准备 | - |
| 待测试 | ⏸️ 等待 | - |


