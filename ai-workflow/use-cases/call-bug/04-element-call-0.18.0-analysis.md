# Element Call 0.18.0 升级分析报告

> 分析时间：2026-03-30  
> 项目：element-x-android  
> 升级版本：element-call-embedded `0.17.0` → `0.18.0`  
> 提交：`d3c33c9d5a`（2026-03-16）

---

## 一、Element Call 0.18.0 官方 Release Notes

### 🐛 Bugfixes（直接修复的 Bug）

| PR | 描述 | 与通话 Bug 相关度 |
|----|------|------------------|
| [#3731](https://github.com/element-hq/element-call/pull/3731) | Netlify preview broken | ❌ 无关 |
| [#3733](https://github.com/element-hq/element-call/pull/3733) | **Mobile crash: `TypedError: circular structure` 导致 stringify crash** | ✅ **相关** |
| [#3768](https://github.com/element-hq/element-call/pull/3768) | id-token permission required by tailscale login | ❌ 无关 |

### ✨ Features（新功能）

- **屏幕共享音量控制**（@JakeTripplJ, PR #3747）
- **新版 PiP Layout（画中画，带控制按钮）**（@toger5, PR #3775）
- **根据视频流方向自动适配 tile 布局**（@BillCarsonFr, PR #3756）— 改善移动端→桌面端通话体验

### 📌 关键结论

**v0.18.0 的 Bug 修复非常有限，主要就 3 个**。其中和通话质量直接相关的只有 **#3733（修复 0.17.0-rc.2 在移动端的崩溃问题）**。

---

## 二、v0.17.0 → v0.18.0 期间 element-x-android 通话相关 Commits

### 升级前（v0.17.0 更新后）

| Commit | 日期 | 描述 |
|--------|------|------|
| `2a509d9ea8` | 2026-02-09 | Sort audio device by type before sending to Element Call |
| `001d419afd` | 2026-02-24 | **Catch exceptions** when setting/clearing audio communication device in EC |
| `d23f81a3a9` | 2026-02-26 | Update element-call-embedded to **v0.17.0** |

### 升级后（v0.18.0 合并后）

| Commit | 日期 | 描述 |
|--------|------|------|
| `d3c33c9d5a` | 2026-03-16 | Update element-call-embedded to **v0.18.0** |
| `e3147fa99a` | 2026-03-25 | **fix(call): allow HangUp widget message to close call screen** |

### 🔍 e3147fa99a 详细分析

这是 **v0.18.0 合并之后**才出现的修复，修改的是 `CallScreenPresenter.kt`：

```kotlin
// 修复前：Widget 的 HangUp 消息无法关闭通话界面
// 修复后：Widget 发出的 HangUp 消息能正确触发通话界面关闭
```

**这是目前最新的通话相关 Bug 修复**，但它是 UI 层问题（挂断消息处理），不影响通话连接本身。

---

## 三、逐项检查：是否能解决"语音/视频通话 Bug"？

### ❌ 1. 语音/视频通话无法接通

**Element Call v0.18.0**：❌ 无相关修复  
**element-x-android**：❌ 无相关修复

Element Call 0.18.0 的 changelog 没有任何关于通话接通失败的修复。v0.17.0 有较多修复（#3499, #3502, #3544, #3659, #3675, #3693），但 0.18.0 没有继承这些修复的新变体。

### ❌ 2. WebRTC 连接问题

**Element Call v0.18.0**：❌ 无直接修复  
**element-x-android**：❌ 无直接修复

v0.18.0 的 features 包括 PiP 和视频方向适配，这些是 UI 改进，不涉及 WebRTC 连接层。

### ❌ 3. ICE candidate 问题

**Element Call v0.18.0**：❌ 无相关修复  
**element-x-android**：❌ 无相关修复

搜索整个 git 历史（`--grep="ICE\|candidate"`）无相关提交。

### ✅ 4. 通话大厅（lobby）错误

**Element Call v0.18.0**：间接相关 ✅  
`#3756`（自动适配视频 tile 方向）改善了 mobile → desktop 的通话体验，其中涉及 lobby 阶段的布局问题。

**element-x-android**：`cc38651c44`（2025-09-23）改进了"加入通话时等待 `content_loaded` action"，确保 lobby 不会因 widget 被 dispose 而出现问题。**但这是在 v0.17.0 之前就存在的修复。**

### ✅ 5. 权限问题

**Element Call v0.18.0**：`#3768` 修复了 tailscale login 所需的 id-token permission。  
**element-x-android**：`001d419afd` 修复了设置/清除 audio communication device 时的异常捕获（避免因音频设备权限问题导致崩溃）。

---

## 四、综合判断

### 🎯 结论：**v0.18.0 的修复不太可能直接解决"语音/视频通话 Bug"**

**理由：**

1. **v0.18.0 本身就是个"小版本"**，3 个 bugfix 里只有 1 个（#3733 移动端 crash）和通话相关，但这是 **TypedError stringify crash**（日志导致的崩溃），不是通话连接问题。

2. **主要变更都是 UI/UX 改进**：PiP 布局、屏幕共享音量、视频方向适配，都不是核心通话质量修复。

3. **v0.17.0 才是真正"重量级"版本** — 包含 MatrixRTC spec 实现、`CallViewModel` 重构、众多通话连接修复。

4. **element-x-android 中最新的通话相关修复**（`e3147fa99a`）是 **UI 层挂断消息处理**，不影响通话建立。

### 📋 若要定位"通话 Bug"，建议：

1. **回退到 v0.17.0** 测试，确认是否是 v0.18.0 引入的问题
2. **查看 element-x-android 是否缺少上游 v0.17.0 中的某些修复**（如 #3675 Publisher cleanup, #3693 rejoin crash）— 这些在 element-x-android 中可能没有正确传递
3. **检查 element-x-android 中 SDK 绑定版本**：`org.matrix.rustcomponents:sdk-android` 是否同步更新到支持 MatrixRTC 2.0 的版本

---

## 附录：版本引用

```gradle
# 当前版本（libs.versions.toml 第 236 行）
element_call_embedded = "io.element.android:element-call-embedded:0.18.0"
```

```bash
# 升级 commit
d3c33c9d5a fix(deps): update dependency io.element.android:element-call-embedded to v0.18.0
```

```bash
# v0.17.0 升级 commit
d23f81a3a9 Update dependency io.element.android:element-call-embedded to v0.17.0 (#6244)
```
