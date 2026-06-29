# 02-upstream-sync.md — 上游代码同步与 Element Call 依赖检查报告

**生成时间:** 2026-03-30 20:50 GMT+8  
**项目路径:** ~/projects/element-x-android

---

## 1. 当前版本信息

| 项目 | 值 |
|------|-----|
| **当前分支** | `feature/wechat-style-ui` |
| **最新 commit** | `d134c4dcd8` — `feat: 添加上游同步 GitHub Actions workflow` |
| **本地 commit 总数** | 落后 upstream/develop **36 commits**，领先 origin/develop **13 commits** |

**origin/develop (origin main):** `92920b862b` — `Merge pull request #6342 from element-hq/feature/fga/live_location_sharing_setup`

---

## 2. 上游是否有更新

**答案：严重落后，需要同步。**

- `upstream/develop` 最新: `a2fe637978` — `Fix media cover placeholder floating (#6484)`
- 本地落后 upstream/develop **36 个 commits**
- 本地领先 origin/develop **13 个 commits**（WeChat UI 特性修改）

### 落后 upstream/develop 的关键 Commits（通话/VOIP 相关）

| Commit | Message |
|--------|---------|
| `d3c33c9d5a` | `fix(deps): update dependency io.element.android:element-call-embedded to v0.18.0` |
| `a64bf79bef` | `Merge pull request #5995 from element-hq/valere/rtc/voice_call`（语音通话支持） |
| `360fe65277` | `Merge pull request #6358 from element-hq/renovate/io.element.android-element-call-embedded-0.x` |
| `bba2e6df3f` | `Fix ForegroundServiceDidNotStartInTimeException (#6470)` |
| `c9a1743f51` | `Remove retrofit dependency from :features:call:impl` |
| `2e0832e4ac` | `Remove application error management on loading a call` |

---

## 3. Element Call 依赖版本信息

**当前版本 (libs.versions.toml):**
```toml
element_call_embedded = "io.element.android:element-call-embedded:0.17.0"
```

**最新上游版本:** `0.18.0` (commit `d3c33c9d5a`)

**Element Call 相关文件:**
- 无 `libraries/element-call` 目录（非 submodule）
- 无 element-call git submodule
- Element Call 作为 Gradle 依赖引入: `io.element.android:element-call-embedded`

**相关 WebView 文件:**
- `features/call/impl/src/main/kotlin/io/element/android/features/call/impl/utils/WebViewWidgetMessageInterceptor.kt`
- `features/call/impl/src/main/kotlin/io/element/android/features/call/impl/utils/WebViewPipController.kt`
- `features/call/impl/src/main/kotlin/io/element/android/features/call/impl/utils/WebViewAudioManager.kt`

---

## 4. 通话/VOIP/WebRTC 相关 Recent Commits

### Call 相关 (grep "call")
```
c9a1743f51  Remove `retrofit` dependency from `:features:call:impl`
d3c33c9d5a  fix(deps): update element-call-embedded to v0.18.0
a64bf79bef  Merge pull request #5995 (voice_call feature)
7897101009  Support incoming audio only calls
5491040ac5  WIP: Support using Element Call for voice calls in DMs
d23f81a3a9  Update dependency element-call-embedded to v0.17.0
```

### Video 相关 (grep "video")
```
a64bf79bef  Merge pull request #5995 (voice_call feature)
23f105442e  Remove all video metadata (#6224)
...（多为媒体处理相关，非通话核心）
```

### VOIP / WebRTC
无相关 commits

### WebViewWidgetMessageInterceptor 最近修改
```
eb31505dc7  Copyright: Add Element Creations Ltd. copyright
c156fd58bd  Element Call: Add audio output selector handled by Android (#4663)
ba626fc173  Use embedded version of Element Call (#4470)
```

---

## 5. 特别发现

### 上游存在 fixElementCallLobbyError 分支
`upstream/feature/bma/fixElementCallLobbyError` 分支值得关注，包含了 call 相关的重要修复：
- `2e0832e4ac` — Remove application error management on loading a call
- CallScreenEvents → CallScreenEvent 重构

---

## 6. 本地修改状态

**⚠️ 有 stash 需要保留：**

```
stash@{0}: On feature/wechat-style-ui: 保存当前WeChat UI修改
```

当前分支 `feature/wechat-style-ui` 领先 origin/develop 13 个 commits，主要是 WeChat 风格 UI 的修改。

**Git Status:**
- 有未跟踪文件: `ai-workflow/` 目录

---

## 7. 建议

### ✅ 强烈建议先合并上游再继续 Bug 分析

**理由：**

1. **element-call-embedded 已从 0.17.0 升级到 0.18.0**，上游 `d3c33c9d5a` 包含该升级。0.18.0 可能有 bugfix。
2. **`valere/rtc/voice_call` 分支已合并** (`a64bf79bef`)，引入了语音通话支持，可能影响通话行为。
3. **`:features:call:impl` 的 retrofit 依赖已移除** (`c9a1743f51`)，WebView 通信层有变化。
4. **ForegroundService 相关修复** (`bba2e6df3f`) 可能解决某些 crash。
5. **call error management 机制已简化** (`2e0832e4ac`)，影响 call loading 错误处理。

### 建议操作步骤

```bash
# 1. 保存当前 WeChat UI 修改（已在 stash 中）
git stash list  # 确认 stash@{0} 存在

# 2. 切换到 develop，基于 upstream/develop 创建新分支
git checkout origin/develop -b call-bug-investigation

# 3. 应用 WeChat UI stash（如果需要）
git stash pop

# 4. 或者 cherry-pick 关键 upstream commits（如果不想全部 merge）
# 重点关注：
# - d3c33c9d5a (element-call-embedded 0.18.0)
# - a64bf79bef (voice_call merge)
# - c9a1743f51 (remove retrofit)
# - 2e0832e4ac (remove call error management)
```

### 如果坚持在当前分支继续

至少需要 `git merge upstream/develop`，否则无法获得最新的 Element Call 0.18.0 和相关修复。

---

## 附录：完整 Upstream Develop 最新 Commit (top 20)

```
a2fe637978  Fix media cover placeholder floating (#6484)
cbb220f08d  Merge pull request #6472 from element-hq/feature/bma/inReplyUi
5975454424  fix(deps): update dependency com.google.firebase:firebase-bom to v34.11.0 (#6478)
81cc055c91  fix(deps): update dependency io.element.android:emojibase-bindings to v1.5.1 (#6474)
bba2e6df3f  Fix `ForegroundServiceDidNotStartInTimeException` (#6470)
ef041baeb4  chore: update the build-rust-sdk script (#6476)
8851476bc7  Kotlin 2.3.20
360fe65277  Merge pull request #6358 from element-hq/renovate/io.element.android-element-call-embedded-0.x
dc5889c05c  Merge pull request #6437 from element-hq/renovate/kotlin
cd695d948e  Merge pull request #6442 from element-hq/renovate/nschloe-action-cached-lfs-checkout-1.x
71dd68746b  Merge pull request #6449 from element-hq/renovate/sqldelight
1de3729792  Merge pull request #6446 from bxdxnn/misc/bullet-margin
7d28c52242  Cleanup
747f588fa7  Update UI of replies.
087c159325  Merge pull request #6459 from element-hq/feature/bma/iterateOnBadgeColors
16e9cb64ce  Merge pull request #6468 from element-hq/feature/bma/aiStuff
d3c33c9d5a  fix(deps): update dependency io.element.android:element-call-embedded to v0.18.0
c9a1743f51  Remove `retrofit` dependency from `:features:call:impl`
```
