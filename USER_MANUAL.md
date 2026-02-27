# 📖 Element X Android 自定义版 - 使用手册

## 🎉 欢迎使用

您正在使用 Element X Android 的自定义版本，该版本进行了以下修改：

1. **Homeserver 硬编码** → `https://matrix.cacheskysx.com`
2. **自动跳过 OnBoard 界面** → 直接进入登录界面
3. **禁止用户修改 Homeserver** → 强制使用自定义服务器

---

## 🚀 快速开始

### 安装应用

```bash
# 连接 Android 设备到电脑
adb devices

# 安装 APK (推荐使用 arm64-v8a 版本)
adb install -r /path/to/app-fdroid-arm64-v8a-release.apk

# 或者直接拖拽 APK 到设备
```

### 启动应用

1. 在 Android 设备上找到应用图标 "Element"
2. 点击启动
3. **自动进入登录界面** (OnBoard 界面被跳过)

### 登录

1. 输入 Matrix 用户名或邮箱
2. 输入密码
3. 点击 "Sign In" 按钮
4. **自动连接到 `https://matrix.cacheskysx.com`**
5. 完成登录

---

## 📋 功能说明

### 登录界面的改动

**修改前的流程**:
```
启动应用 → OnBoard 界面 → 选择 Homeserver → 登录界面 → 输入账户 → 登录
```

**修改后的流程** (您的版本):
```
启动应用 → [自动跳过] → [直接进入] → 登录界面 → 输入账户 → 自动连接 matrix.cacheskysx.com → 登录
```

### Homeserver 信息

- **当前 Homeserver**: `https://matrix.cacheskysx.com`
- **是否可修改**: ❌ 不可修改 (硬编码)
- **用户选择**: ❌ 不允许 (自动使用自定义)

### 应用功能

除了上述改��外，其他所有 Element X 功能保持不变：

- ✅ 消息聊天
- ✅ 群组管理
- ✅ 加密通讯
- ✅ 文件分享
- ✅ 用户搜索
- ✅ 主题设置
- ✅ 等等...

---

## 🔧 配置和设置

### 修改 Homeserver (需要重新编译)

如果需要更改 Homeserver 地址，需要修改源代码并重新编译：

**方法 1: 修改配置文件**
```kotlin
// 文件: appconfig/src/main/kotlin/io/element/android/appconfig/AuthenticationConfig.kt
const val MATRIX_ORG_URL = "https://your-matrix-server.com"
```

**方法 2: 修改登录逻辑**
```kotlin
// 文件: features/login/impl/src/main/kotlin/io/element/android/features/login/impl/screens/onboarding/OnBoardingPresenter.kt
val customHomeserverUrl = "https://your-matrix-server.com"
```

然后重新编译：
```bash
./gradlew clean assembleFdroidRelease -x test
```

### 其他应用设置

在应用内设置中可以修改：
- 主题 (亮色/暗色)
- 字体大小
- 通知设置
- 隐私设置
- 等等...

---

## 🆘 故障排查

### 问题 1: 无法登录

**症状**: 输入账户信息后无法登录

**检查清单**:
1. 确认 Homeserver 是否在线: `https://matrix.cacheskysx.com`
2. 确认账户名称和密码是否正确
3. 检查网络连接
4. 等待 30 秒后重试

**解决方案**:
```bash
# 重启应用
adb shell am force-stop io.element.android.x
adb shell am start -n io.element.android.x/.MainActivity

# 或重启设备
adb reboot
```

### 问题 2: 应用卡在登录界面

**症状**: 登录界面加载不出来或无响应

**解决方案**:
1. 清空应用缓存: 设置 → 应用 → Element → 存储空间 → 清除缓存
2. 重启应用
3. 检查网络连接

### 问题 3: 无法连接到 Homeserver

**症状**: 显示网络错误或无法连接

**检查清单**:
1. 确认网络已连接
2. 确认 `https://matrix.cacheskysx.com` 可访问
3. 尝试连接到其他网络
4. 检查防火墙设置

### 问题 4: 应用崩溃

**症状**: 应用突然退出或显示错误信息

**解决方案**:
1. 卸载并重新安装应用
2. 检查 Android 系统版本 (需要 Android 8.0 及以上)
3. 清除设备存储空间

### 获取帮助

如果问题未解决，请：

1. 查看应用日志:
```bash
adb logcat | grep ElementX
```

2. 查看编译文档:
   - `DEVELOPMENT_COMPLETE.md` - 开发完成说明
   - `CODE_CHANGES_DIFF.md` - 代码改动详解
   - `TECHNICAL_IMPLEMENTATION.md` - 技术细节

---

## 📱 系统要求

- **Android 版本**: 8.0 (API 26) 及以上
- **RAM**: 至少 2GB (推荐 4GB+)
- **存储空间**: 至少 150MB
- **网络**: 需要 Wi-Fi 或移动数据连接

---

## 🔒 安全和隐私

### 数据加密

- ✅ 所有消息通过 E2E 端到端加密传输
- ✅ 密钥存储在本地设备上
- ✅ Homeserver 无法读取加密消息

### 数据收集

- ✅ 不收集个人信息 (除非您主动分享)
- ✅ 不向第三方共享数据
- ✅ 所有数据只存储在您的 Homeserver 上

### 权限说明

应用申请的权限及用途：
- **网络**: 连接到 Matrix Homeserver
- **存储**: 保存消息、图片等
- **摄像头**: 用于拍照和视频通话
- **麦克风**: 用于语音和视频通话
- **联系人**: 用于搜索联系人

---

## 💡 使用技巧

### 快速操作

| 操作 | 方法 |
|------|------|
| 搜索消息 | 点击顶部搜索图标 |
| 创建新聊天 | 点击右上角 + 按钮 |
| 查看聊天详情 | 点击聊天标题 |
| 发送图片 | 点击输入框旁的 + 按钮 |
| 回复消息 | 长按消息并选择回复 |

### 键盘快捷键

| 快捷键 | 功能 |
|--------|------|
| Enter | 发送消息 |
| Shift+Enter | 换行 |
| Ctrl+A | 全选 |
| Ctrl+C | 复制 |

---

## 📊 应用统计

| 项目 | 数据 |
|------|------|
| 应用大小 | ~155MB (arm64-v8a) |
| 支持的 Matrix 版本 | v1.0+ |
| 集成库 | 100+ |
| 代码修改 | 2 个文件 |

---

## 🔄 更新说明

### 检查更新

设置 → 关于应用 → 检查更新

### 更新注意事项

- ⚠️ 更新前建议备份聊天记录
- ⚠️ 更新可能会重置您的自定义设置
- ✅ 所有消息和密钥将保留

---

## 📞 联系支持

### 反馈问题

如果遇到问题或有建议：

1. 查看本手册的故障排查部分
2. 查看项目文档 (DEVELOPMENT_COMPLETE.md 等)
3. 检查应用日志: `adb logcat`

### 技术信息

- **应用包名**: `io.element.android.x`
- **版本**: 基于最新代码
- **构建类型**: F-Droid Release
- **签名**: 自签名证书

---

## 📚 相关文档

1. **DEVELOPMENT_COMPLETE.md** - 开发完成说明
2. **CODE_CHANGES_DIFF.md** - 代码改动详解
3. **QUICK_START.md** - 快速参考
4. **CUSTOM_DEVELOPMENT_GUIDE.md** - 完整操作指南
5. **TECHNICAL_IMPLEMENTATION.md** - 技术细节 (高级用户)

---

## ✨ 特别感谢

感谢您使用 Element X Android！

如果您对这个自定义版本有任何问题或建议，欢迎反馈。

---

**版本**: 1.0
**最后更新**: 2026-02-26
**Homeserver**: https://matrix.cacheskysx.com

**祝您使用愉快！** 🎉


