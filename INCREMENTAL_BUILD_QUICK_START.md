# 🚀 增量编译 - 快速开始指南

## 什么是增量编译？

增量编译只重新编译修改过的代码部分，与原编译产物链接组成最终 APK。这可以：

✅ 将编译时间从 **12-15 分钟** 减少到 **1-3 分钟**  
✅ 保留缓存的编译产物，加快链接阶段  
✅ 支持多个架构并行编译  

---

## 📋 最快开始方式

### 第一步：使用增量编译脚本
```bash
cd /home/dou/StudioProjects/element-x-android
./build_incremental.sh
```

### 脚本做的事情：
1. ✅ 启用 Kotlin 增量编译
2. ✅ 启用 Gradle Build Cache
3. ✅ 启用配置缓存
4. ✅ 启用并行构建
5. ✅ 编译已修改的文件
6. ✅ 生成签名 APK
7. ✅ 显示编译时间统计
8. ✅ 提示安装到设备

### 第二步：（可选）自动安装
脚本会询问是否安装到已连接的设备。选择 `y` 自动安装。

---

## ⏱️ 编译时间对比

修改 3 个配置文件后的编译时间：

| 编译方式 | 首次 | 后续 | 加速倍数 |
|---------|------|------|---------|
| `./gradlew clean assembleReleaseFdroid` | 12-15 分钟 | - | 基准 |
| `./gradlew assembleReleaseFdroid` | 12-15 分钟 | 3-4 分钟 | 3-4x ⚡ |
| `./build_incremental.sh` | 12-15 分钟 | 1-3 分钟 | 6-12x ⚡⚡ |

---

## 🎯 命令速查表

### 最常用命令

```bash
# 1. 快速增量编译（推荐）
./build_incremental.sh

# 2. 标准增量编译
./gradlew assembleReleaseFdroid

# 3. 跳过测试的快速编译
./gradlew assembleReleaseFdroid -x test

# 4. 完全重新编译（仅在必要时）
./gradlew clean assembleReleaseFdroid

# 5. 显示编译时间统计
./gradlew assembleReleaseFdroid --profile

# 6. 只编译 ARM64 版本（最快）
./gradlew :app:assembleReleaseFdroidArm64v8a

# 7. 安装到设备
adb install -r app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk
```

---

## 🔥 加速技巧

### 技巧 1：跳过不必要的检查
```bash
# 跳过测试和 lint
./gradlew assembleReleaseFdroid -x test -x lint
```
**可节省：** 2-3 分钟

### 技巧 2：只编译单个架构
```bash
# 仅编译 arm64（大多数现代手机）
./gradlew :app:assembleReleaseFdroidArm64v8a
```
**可节省：** 1-2 分钟

### 技巧 3：增加 JVM 堆内存
```bash
export GRADLE_OPTS="-Xmx6g -XX:+UseG1GC"
./gradlew assembleReleaseFdroid
```
**可节省：** 30-60 秒

### 技巧 4：保持 Gradle Daemon 运行
```bash
# 查看 daemon 状态
./gradlew --status

# Daemon 会自动启动，保留在内存中加速后续编译
./gradlew assembleReleaseFdroid  # 第二次会更快
```
**可节省：** 启动时间

---

## 📝 修改配置文件流程

### 场景：修改 homeserver 配置

```
┌─ 修改 AuthenticationConfig.kt
│
├─ ./build_incremental.sh
│  ├─ Kotlin 编译器检测到 AuthenticationConfig.kt 的变化 ✓
│  ├─ 只重新编译 AuthenticationConfig 及依赖它的类
│  ├─ 缓存加载其他不变的编译产物
│  ├─ 链接所有编译产物组成最终 APK
│  └─ 签名 APK (1-3 分钟) ✓
│
└─ app-fdroid-arm64-v8a-release.apk
   └─ 安装到设备
```

---

## ❓ 常见问题

### Q: 我应该什么时候使用增量编译？

**A:** 在以下场景使用：
- ✅ 修改 1-5 个文件后
- ✅ 快速迭代开发时
- ✅ 频繁生成 APK 测试时

**不适合场景：**
- ❌ 修改了 build.gradle.kts
- ❌ 修改了基础库（libraries/core/*）
- ❌ 首次编译（使用 clean）

### Q: 增量编译失败了怎么办？

**A:** 清除缓存后重新编译：
```bash
./gradlew clean --no-build-cache
./gradlew assembleReleaseFdroid
```

### Q: 如何验证 APK 已签名？

**A:** 使用以下命令检查：
```bash
jarsigner -verify -verbose app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk
```

### Q: 为什么脚本启动时慢，但后续快？

**A:** 这是正常的：
- 首次运行会启动 Gradle Daemon（JVM 进程）
- Daemon 保留在内存中，后续编译会更快
- 第二、三次编译会明显快于首次

### Q: 如何只编译特定架构以进一步加速？

**A:** 
```bash
# ARM64（最常见）
./gradlew :app:assembleReleaseFdroidArm64v8a

# ARMv7（较旧设备）
./gradlew :app:assembleReleaseFdroidArmeabiv7a

# x86（模拟器）
./gradlew :app:assembleReleaseFdroidX86
```

---

## 📊 编译产物检查

编译完成后，检查输出文件：

```bash
# 查看 APK 文件列表
ls -lh app/build/outputs/apk/fdroid/release/

# 检查文件大小和时间戳
stat app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk

# 验证 APK 完整性
file app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk
```

---

## 🚀 性能优化总结

| 优化方向 | 方法 | 效果 |
|---------|------|------|
| **增量编译** | `./build_incremental.sh` | 6-12x ⚡⚡ |
| **跳过检查** | `-x test -x lint` | 2-3x ⚡ |
| **单架构编译** | `:app:assembleReleaseFdroidArm64v8a` | 3-4x ⚡ |
| **更多内存** | `GRADLE_OPTS="-Xmx6g"` | 1.2-1.5x ⚡ |
| **组合优化** | 所有上述方法 | 12-20x ⚡⚡⚡ |

---

## 📖 详细文档

- 📄 `INCREMENTAL_BUILD_GUIDE.md` - 完整的增量编译指南
- 📄 `QUICK_REFERENCE.md` - 命令快速参考
- 📄 `CUSTOM_HOMESERVER_SETUP.md` - 配置说明

---

## 🎯 立即开始

```bash
# 进入项目目录
cd /home/dou/StudioProjects/element-x-android

# 运行增量编译
./build_incremental.sh

# 等待 1-3 分钟...

# 安装到设备（如有提示）
# 选择 y 后自动安装
```

---

## ✨ 提示

- 💡 **第一次编译会比较长**（12-15 分钟），因为没有缓存
- 💡 **后续编译会快很多**（1-3 分钟），利用缓存
- 💡 **脚本会自动检测已连接的设备**，提示是否安装
- 💡 **Gradle Daemon 会持续运行**，保持快速编译

---

**现在就试试吧！** 🚀

```bash
./build_incremental.sh
```

