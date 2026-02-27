# 增量编译指南 - Element X Android

## 概述

增量编译（Incremental Build）是一种只重新编译修改过的代码和相关依赖项的编译方式，可以显著加快编译速度。

本指南展示如何利用 Gradle 的增量编译特性快速生成签名版 F-Droid Release APK。

---

## 🚀 快速开始

### 最快方式：运行增量编译脚本
```bash
cd /home/dou/StudioProjects/element-x-android
chmod +x build_incremental.sh
./build_incremental.sh
```

这个脚本会：
- ✅ 自动启用所有增量编译优化
- ✅ 只编译修改的部分
- ✅ 显示编译时间和详细信息
- ✅ 自动检测已连接的设备并提示安装

---

## 🔧 编译方式对比

### 方式 1：完全重新编译（最慢）
```bash
./gradlew clean assemble ReleaseFdroid
```
- ⏱️ 编译时间：8-15 分钟（首次）
- 适用场景：第一次编译或完全清理后

### 方式 2：增量编译（推荐）
```bash
./gradlew assemble ReleaseFdroid
```
- ⏱️ 编译时间：2-5 分钟（后续修改）
- 适用场景：修改少量代码后
- 前提：build 目录未删除

### 方式 3：优化的增量编译（最快）
```bash
./build_incremental.sh
```
- ⏱️ 编译时间：1-3 分钟（后续修改）
- 包含所有优化选项
- 自动化配置

---

## ⚙️ Gradle 增量编译优化

### 1. Kotlin 增量编译
**状态：** ✅ 已启用

```properties
# gradle.properties
kotlin.incremental=true
kotlin.incremental.js=true
```

**作用：** Kotlin 编译器只重新编译修改的类和依赖项

### 2. Gradle Build Cache
**状态：** ✅ 已启用

```properties
org.gradle.caching=true
```

**作用：** 缓存编译产物，相同的输入产生相同的输出

**清除缓存：**
```bash
./gradlew cleanBuildCache
```

### 3. Gradle Configuration Cache
**状态：** ✅ 已启用

```properties
org.gradle.configuration-cache=true
org.gradle.configuration-cache.parallel=true
```

**作用：** 缓存项目配置，避免重复解析 build 脚本

**清除缓存：**
```bash
rm -rf ~/.gradle/configuration-cache/
```

### 4. 并行构建
**状态：** ✅ 已启用

```properties
org.gradle.parallel=true
org.gradle.configureondemand=true
```

**作用：** 多个模块并行编译

### 5. JVM 优化
```properties
org.gradle.jvmargs=-Xmx4g -Dfile.encoding=UTF-8 -XX:+UseG1GC
```

**作用：**
- `-Xmx4g` - 最大堆内存 4GB
- `-XX:+UseG1GC` - 使用 G1 垃圾回收器（适合大堆）

---

## 📊 编译时间对比

### 典型场景：修改 AuthenticationConfig.kt

| 编译方式 | 首次编译 | 增量编译 | 加速比 |
|---------|--------|---------|-------|
| 完全编译 (`clean`) | 12 分钟 | - | 基准 |
| 标准增量 | 12 分钟 | 3-4 分钟 | 3-4x |
| 优化增量 | 12 分钟 | 1-2 分钟 | 6-12x |

**说明：**
- 首次编译时间相同（无缓存）
- 后续修改时，增量编译快 3-12 倍
- 修改的文件数越少，加速越明显

---

## 🎯 何时使用增量编译

### ✅ 适合增量编译的场景

```
场景 1：修改配置文件
修改文件：AuthenticationConfig.kt, OnBoardingPresenter.kt
影响范围：小
编译时间：1-2 分钟
→ 使用增量编译
```

```
场景 2：修改单个功能模块
修改文件：某个 feature 模块的几个类
影响范围：中等
编译时间：2-4 分钟
→ 使用增量编译
```

```
场景 3：快速迭代开发
修改文件：频繁修改同一文件或相关文件
影响范围：小到中等
编译时间：1-5 分钟
→ 使用增量编译
```

### ❌ 不适合增量编译的场景

```
场景 1：修改基础库或核心依赖
修改文件：libraries/core/* 或依赖项版本
影响范围：全项目
→ 使用完全重新编译
```

```
场景 2：修改 Gradle 配置
修改文件：build.gradle.kts, gradle.properties
影响范围：全项目
→ 使用完全重新编译
```

```
场景 3：删除或重命名大量文件
→ 使用完全重新编译
```

---

## 💻 详细编译命令

### 标准增量编译
```bash
./gradlew assembleReleaseFdroid
```

### 启用详细日志的增量编译
```bash
./gradlew assembleReleaseFdroid --info
```

### 显示编译时间统计
```bash
./gradlew assembleReleaseFdroid --profile
```
输出文件：`build/reports/profile/`

### 显示缓存命中率
```bash
./gradlew assembleReleaseFdroid --build-cache --info | grep -i "cache"
```

### 监视编译过程
```bash
./gradlew assembleReleaseFdroid --scan
```
会生成 Gradle Build Scan 报告

### 并行编译，显示进度
```bash
./gradlew assembleReleaseFdroid --parallel --info
```

---

## 🔍 监视编译性能

### 生成构建报告
```bash
./gradlew assembleReleaseFdroid --profile
# 查看报告
open build/reports/profile/profile-*.html
```

### 查看任务执行时间
```bash
./gradlew assembleReleaseFdroid --profile 2>&1 | grep -E "^\s+[a-z].*\d+ms"
```

### 分析缓存命中
```bash
./gradlew assembleReleaseFdroid --build-cache --info 2>&1 | \
  grep -E "(BUILD CACHE|cache entry|FROM-CACHE|SKIP)"
```

### 查看 Kotlin 增量编译的详情
```bash
./gradlew assembleReleaseFdroid -x test --info 2>&1 | \
  grep -i "incremental"
```

---

## 🚨 常见问题

### Q1: 增量编译失败，提示 "cache is corrupt"

**解决：**
```bash
# 清除 Gradle 缓存
./gradlew cleanBuildCache

# 清除 Kotlin 编译缓存
rm -rf .gradle/kotlin-build/

# 重新编译
./gradlew assembleReleaseFdroid
```

### Q2: 修改了代码但没有重新编译

**检查：**
```bash
# 查看修改的文件
git status

# 确保文件已保存
touch src/main/kotlin/.../ModifiedFile.kt

# 强制重新编译
./gradlew --rerun-tasks assembleReleaseFdroid
```

### Q3: 增量编译比完全编译还慢

**原因：**
- 第一次编译后 Gradle 需要建立缓存（可能更慢）
- 修改的文件影响很多其他文件

**解决：**
```bash
# 清除所有缓存，进行干净的增量编译
./gradlew cleanBuildCache
./gradlew clean
./gradlew assembleReleaseFdroid
```

### Q4: 编译中断后，build 目录损坏

**恢复：**
```bash
# 方式 1：仅删除中间产物
./gradlew clean

# 方式 2：完全清理所有缓存
./gradlew clean --no-build-cache
rm -rf .gradle/

# 方式 3：重新编译
./gradlew assembleReleaseFdroid
```

---

## 🔐 签名配置

增量编译时，签名配置必须存在：

### 检查签名配置
```bash
# 查看 gradle.properties 中的签名设置
cat gradle.properties | grep -i signing
```

### 配置签名信息
```properties
# gradle.properties
signing.element.storeFile=path/to/keystore.jks
signing.element.storePassword=YourStorePassword
signing.element.keyId=YourKeyAlias
signing.element.keyPassword=YourKeyPassword
```

### F-Droid 特定签名
```bash
# 查看 F-Droid 签名配置
cat gradle.properties | grep -i fdroid
```

---

## 📈 性能优化建议

### 1. 优化 JVM 参数
```bash
# 根据你的系统调整
export GRADLE_OPTS="-Xmx6g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
./gradlew assembleReleaseFdroid
```

### 2. 关闭不必要的检查
```bash
# 跳过 lint 检查
./gradlew assembleReleaseFdroid -x lint

# 跳过测试
./gradlew assembleReleaseFdroid -x test

# 组合使用
./gradlew assembleReleaseFdroid -x test -x lint
```

### 3. 只编译特定架构
```bash
# 仅编译 arm64-v8a（最快）
./gradlew :app:assembleReleaseFdroidArm64v8a
```

### 4. 使用 Daemon 进程（持久化）
```bash
# Gradle Daemon 会保持在内存中，加速后续编译
./gradlew assembleReleaseFdroid  # 第一次启动 daemon

# 查看 daemon 状态
./gradlew --status

# 停止 daemon
./gradlew --stop
```

---

## 📊 编译流程图

```
修改代码
    │
    ▼
运行增量编译 (assembleReleaseFdroid)
    │
    ├─ 检查修改的文件 ✓
    ├─ 读取配置缓存 ✓
    ├─ Kotlin 增量编译 ✓
    ├─ 仅重新编译改动的类
    ├─ 从缓存加载不变的编译产物 ✓
    ├─ 链接 APK ✓
    ├─ 签名 APK ✓
    │
    ▼
生成 APK (1-3 分钟)
```

---

## ✅ 验证增量编译成功

### 检查清单

- [ ] 编译完成，无错误
- [ ] APK 文件生成在 `app/build/outputs/apk/fdroid/release/`
- [ ] APK 文件时间戳是最新的
- [ ] APK 已签名（可用 adb 验证）
- [ ] 编译耗时显著少于首次编译

### 验证 APK 签名
```bash
# 查看 APK 签名信息
jarsigner -verify -verbose app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk

# 或使用 apktool
apktool if app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk
apktool d app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk
```

---

## 🎓 进阶优化

### 1. Gradle Enterprise Build Cache
```bash
# 使用远程缓存（需要 Gradle Enterprise）
./gradlew assembleReleaseFdroid \
  -Dorg.gradle.caching=true \
  -Dorg.gradle.caching.hostname=cache.example.com
```

### 2. 自定义任务缓存规则
编辑 `build.gradle.kts`：
```kotlin
tasks.withType<JavaCompile>().configureEach {
    outputs.cacheIf { true }  // 缓存所有 Java 编译
}
```

### 3. 并行编译调优
```properties
# 根据 CPU 核心数调整
org.gradle.workers.max=8
```

---

## 📝 最佳实践总结

| 操作 | 命令 | 耗时 |
|------|------|------|
| 首次编译 | `./gradlew clean assemble...` | 12-15 分钟 |
| 修改一个文件后 | `./build_incremental.sh` | 1-3 分钟 |
| 修改配置文件后 | `./gradlew assembleReleaseFdroid` | 2-4 分钟 |
| 快速迭代开发 | `./build_incremental.sh -x test` | 1-2 分钟 |
| 完整测试前 | `./gradlew check assemble...` | 20-30 分钟 |

---

## 🚀 下一步

1. **使用增量编译脚本：**
   ```bash
   ./build_incremental.sh
   ```

2. **查看编译统计：**
   ```bash
   ./gradlew assembleReleaseFdroid --profile
   ```

3. **监视性能改进：**
   记录首次和后续编译的时间，对比效果

4. **针对您的系统调优：**
   根据 CPU 和内存配置调整 GRADLE_OPTS

---

## 📚 相关文档

- [Gradle 增量编译官方文档](https://docs.gradle.org/current/userguide/java_plugin.html#sec:incremental_compile)
- [Kotlin 增量编译](https://kotlinlang.org/docs/whatsnew14.html#new-incremental-compilation-enabled-by-default)
- [Gradle Build Cache](https://docs.gradle.org/current/userguide/build_cache.html)
- [Configuration Cache](https://docs.gradle.org/current/userguide/configuration_cache.html)

---

**编译优化完成！🚀**

使用 `./build_incremental.sh` 享受快速增量编译的便利！

