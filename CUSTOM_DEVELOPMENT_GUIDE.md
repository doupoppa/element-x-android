# Element X Android 二次开发 - 完整操作指南

## ✅ 已完成的修改

### 1. Homeserver 硬编码修改
✅ **文件**: `appconfig/src/main/kotlin/io/element/android/appconfig/AuthenticationConfig.kt`
- 将 `MATRIX_ORG_URL` 从 `https://matrix.org` 改为 `https://matrix.cacheskysx.com`
- 此修改影响全局，所有使用该常量的地方都会自动使用新的 homeserver

### 2. OnBoard 界面自动跳转修改
✅ **文件**: `features/login/impl/src/main/kotlin/io/element/android/features/login/impl/screens/onboarding/OnBoardingPresenter.kt`
- 添加了 `LaunchedEffect` 用于自动化流程控制
- 在组件装载时自动调用 `loginHelper.submit()` 跳过 OnBoard 界面
- 强制使用自定义 homeserver `https://matrix.cacheskysx.com`
- 使用 `rememberSaveable` 防止重复自动提交

---

## 🚀 快速编译方式

### 方式 1: 使用自动化脚本（推荐）
```bash
cd /home/dou/StudioProjects/element-x-android
chmod +x build_custom_release.sh
./build_custom_release.sh
```

### 方式 2: 手动编译
```bash
cd /home/dou/StudioProjects/element-x-android

# 清理并编译（完整编译）
./gradlew clean assembleFdroidRelease -x test

# 或快速编译（使用缓存）
./gradlew assembleFdroidRelease -x test --build-cache --configuration-cache --parallel
```

---

## 📦 编译输出

### APK 文件位置
```
/home/dou/StudioProjects/element-x-android/app/build/outputs/apk/fdroid/release/
```

### 生成的 APK 文件
| 文件名 | 用途 | 推荐 |
|--------|------|------|
| `app-fdroid-arm64-v8a-release.apk` | 64位 Android 设备 | ⭐⭐⭐ |
| `app-fdroid-armeabi-v7a-release.apk` | 32位 Android 设备 | ⭐ |
| `app-fdroid-x86-release.apk` | x86 模拟器 | ⭐⭐ |
| `app-fdroid-x86_64-release.apk` | x86_64 模拟器 | ⭐⭐ |
| `app-fdroid-universal-release.apk` | 包含所有架构 | ⭐ (文件最大) |

---

## 📱 安装 APK

### 方式 1: 使用 ADB（推荐）
```bash
# 查看连接的设备
adb devices

# 安装 APK
adb install -r /home/dou/StudioProjects/element-x-android/app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk

# 安装并启动应用
adb shell monkey -p io.element.android.x 1
```

### 方式 2: 直接拖拽
将 APK 文件直接拖拽到 Android 设备的文件管理器中，然后点击安装。

---

## 🧪 验证步骤

### 1. 验证自动跳转
- [ ] 启动应用
- [ ] 观察是否**直接显示登录界面**，而不是 OnBoard 界面
- [ ] 确认没有出现选择 Homeserver 的界面

### 2. 验证 Homeserver 配置
- [ ] 在登录界面查看输入框上方或下方的 homeserver 信息
- [ ] 确认显示 `https://matrix.cacheskysx.com`
- [ ] 尝试修改 URL，确认是否强制使用自定义 homeserver

### 3. 验证登录功能
- [ ] 输入有效的 Matrix 账户用户名和密码
- [ ] 确认能够成功登录
- [ ] 检查登录后是否能正常同步消息

### 4. 验证签名
```bash
# 验证 APK 签名
jarsigner -verify -verbose /home/dou/StudioProjects/element-x-android/app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk

# 或使用 apksigner
apksigner verify /home/dou/StudioProjects/element-x-android/app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk
```

---

## 📝 注意事项

### 重要提示
1. **不可逆更改**: 这些修改直接硬编码到代码中，发布后用户无法更改 homeserver
2. **签名密钥**: APK 使用预设签名密钥签名，更换设备可能需要重新签名
3. **版本兼容性**: 此修改基于最新代码，可能不兼容早期版本

### 后续修改建议
如果需要更改 homeserver 地址，只需修改以下两个文件中的 URL：
- `AuthenticationConfig.kt` 中的 `MATRIX_ORG_URL`
- `OnBoardingPresenter.kt` 中的 `customHomeserverUrl`

---

## 🔧 故障排查

### 问题 1: 编译失败
**症状**: 编译时出现错误
**解决方案**:
```bash
# 清除所有缓存
./gradlew clean

# 重新编译
./gradlew assembleFdroidRelease -x test
```

### 问题 2: APK 文件未生成
**症状**: 编译完成但找不到 APK 文件
**解决方案**:
```bash
# 检查编译输出目录
find . -name "*.apk" -type f | grep fdroid

# 查看编译日志
./gradlew assembleFdroidRelease -x test --info 2>&1 | tail -100
```

### 问题 3: 应用仍然显示 OnBoard 界面
**症状**: 修改后应用仍然显示选择 Homeserver 的界面
**解决方案**:
1. 确保已重新编译 APK
2. 完全卸载旧版本应用
3. 清空应用数据和缓存
4. 重新安装新编译的 APK

---

## 📞 支持信息

### 相关文件
- **主配置文件**: `appconfig/src/main/kotlin/io/element/android/appconfig/AuthenticationConfig.kt`
- **登录流程**: `features/login/impl/src/main/kotlin/io/element/android/features/login/impl/screens/onboarding/OnBoardingPresenter.kt`
- **构建文档**: 本目录下的 `CUSTOM_MODIFICATION_SUMMARY.md`

### 自动化脚本
- **编译脚本**: `build_custom_release.sh`
- **用法**: `./build_custom_release.sh`

---

## 🎯 下一步

1. ✅ 代码修改已完成
2. ⏭️ 运行编译脚本生成 APK
3. ⏭️ 安装到测试设备验证
4. ⏭️ 根据需要进行二次调整


