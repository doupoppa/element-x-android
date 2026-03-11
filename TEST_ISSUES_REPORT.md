# GTalk 发布前自动化测试问题报告

**测试执行时间**：2026-03-10  
**测试分支**：`feature/wechat-style-ui`  
**测试提交**：`a483581473` (chore(branding): update GTalk user-facing branding and store metadata)  
**测试策略**：只测试不修复，输出缺陷报告供审核  

---

## 问题汇总

| ID | 严重级 | 模块 | 问题描述 | 状态 | 阻断发布? |
|----|--------|------|----------|------|-----------|
| BUG-001 | **P1** | features/login/impl | 登录模块单元测试失败 10/151 | 🔴 New | ⚠️ 建议修复 |
| BUG-002 | **P2** | features/call/impl | 通话测试并发执行疑似 flaky | 🟡 Observe | ⬜ 不阻断 |
| BUG-003 | **P0** | 发布链路 | `fdroid release` 构建与签名正常 | ✅ Pass | N/A |
| BUG-004 | **P0** | features/messages/impl | 消息模块单元测试全部通过 | ✅ Pass | N/A |

---

## 🔴 BUG-001 【P1】登录模块单元测试失败 10/151

### 影响范围
- 模块：`features/login/impl`
- 受影响测试套件：
  - `AccountProviderDataSourceTest` (3 个失败)
  - `OnBoardingPresenterTest` (4 个失败)
  - `ChangeAccountProviderPresenterTest` (3 个失败)
- 通过率：141/151 = **93.4%**

### 失败详情

#### 1. AccountProviderDataSourceTest 失败（3/3）

**文件**：`features/login/impl/src/test/kotlin/io/element/android/features/login/impl/accountprovider/AccountProviderDataSourceTest.kt`

| 用例 | 失败行 | 错误类型 |
|------|--------|----------|
| `present - initial state` | 26 | `Platform$ComparisonFailureWithFacts` |
| `present - initial state - matrix org` | 43 | `Platform$ComparisonFailureWithFacts` |
| `present - ensure that default homeserver is not star char` | 64 | `Platform$ComparisonFailureWithFacts` |

**根因分析**（推测）：
- 测试断言的 `AccountProviderDataSource` 初始状态与实际状态不一致
- 可能涉及默认 homeserver URL 期望值（`matrix.org` vs `matrix.cacheskysx.com`）
- 或与品牌替换后的配置默认值不匹配

#### 2. OnBoardingPresenterTest 失败（4/4）

**文件**：`features/login/impl/src/test/kotlin/io/element/android/features/login/impl/screens/onboarding/OnBoardingPresenterTest.kt`

| 用例 | 失败行 | 错误类型 |
|------|--------|----------|
| `present - initial state` | 72 | `AssertionErrorWithFacts` |
| `present - opening the app using link with allowed account provider, and the app does not force account provider` | 160 | `TurbineAssertionError` → `AssertionError` |
| `present - opening the app using link with not allowed account provider, and the app does not force account provider` | 182 | `AssertionErrorWithFacts` |
| `present - default account provider - login and clear error` | 225 | `Platform$ComparisonFailureWithFacts` |

**根因分析**（推测）：
- 新增 `showSplash` 字段后，测试用例未更新断言
- `OnBoardingState` 状态机中 `hasOidcOpened` 逻辑导致状态流预期与实际不符
- Turbine 测试流断言中状态事件序列发生变化

#### 3. ChangeAccountProviderPresenterTest 失败（3/3）

**文件**：`features/login/impl/src/test/kotlin/io/element/android/features/login/impl/screens/changeaccountprovider/ChangeAccountProviderPresenterTest.kt`

| 用例 | 失败行 | 错误类型 |
|------|--------|----------|
| `present - initial state` | 29 | `Platform$ComparisonFailureWithFacts` |
| `present - fixed list of account providers` | 54 | `AssertionErrorWithFacts` |
| `present - opened list of account providers` | 88 | `Platform$ComparisonFailureWithFacts` |

**根因分析**（推测）：
- 账号提供者列表配置被修改或初始状态不一致
- 与 `AuthenticationConfig` 品牌/默认 homeserver 配置变更有关

### 复现步骤
```bash
cd /home/dou/StudioProjects/element-x-android
./gradlew :features:login:impl:testDebugUnitTest
```

### 详细报告位置
```
features/login/impl/build/reports/tests/testDebugUnitTest/index.html
```

### 建议
- **严重级**：P1（不立即阻断发布，但需优先修复）
- **修复方向**：
  1. 检查测试用例断言是否匹配新的 `OnBoardingState` 结构（尤其 `showSplash` 字段）
  2. 检查测试 mock 数据中的 `defaultHomeserverUrl` 是否需更新为 `matrix.cacheskysx.com`
  3. 检查 `AccountProviderDataSource` 和 `OnBoardingPresenter` 的状态提供器（StateProvider）测试夹具
- **风险接受条件**：若真机冒烟测试 A1-A5 全部通过，可以"已知测试债务"形式先发布，计划 hotfix 修复测试

---

## 🟡 BUG-002 【P2】通话测试并发执行疑似 flaky

### 影响范围
- 模块：`features/call/impl`
- 受影响测试：`DefaultActiveCallManagerTest > Decline event - Should ignore decline for other notification events`
- 复现概率：**不稳定**（并发执行失败，单独执行通过）

### 失败详情

**文件**：`features/call/impl/src/test/kotlin/io/element/android/features/call/utils/DefaultActiveCallManagerTest.kt`

**错误类型**：`kotlinx.coroutines.test.UncompletedCoroutinesError`

**并发执行失败命令**：
```bash
cd /home/dou/StudioProjects/element-x-android
./gradlew :features:messages:impl:testDebugUnitTest :features:call:impl:testDebugUnitTest --parallel
```

**单独执行通过命令**：
```bash
cd /home/dou/StudioProjects/element-x-android
./gradlew :features:call:impl:testDebugUnitTest
```

### 根因分析（推测）
- 协程测试作用域泄漏或未正确清理
- 测试中有未等待完成的 `launch`/`async` 协程
- 可能与 `TestDispatcher` 配置或并发资源竞争有关

### 建议
- **严重级**：P2（非核心阻断，但影响 CI 稳定性）
- **修复方向**：
  1. 检查 `DefaultActiveCallManagerTest` 中是否有未 `join()`/`cancel()` 的协程
  2. 确认测试用 `TestScope` 是否正确使用 `runTest { advanceUntilIdle() }`
  3. 增加测试隔离（确保每个用例后清理协程上下文）
- **风险接受条件**：单独执行稳定通过 + 真机通话功能验证通过，可先发布，CI 脚本临时改为串行执行或重试机制

---

## ✅ PASS-001 【P0】F-Droid Release 构建与签名正常

### 验证内容
- 构建命令：
  ```bash
  cd /home/dou/StudioProjects/element-x-android
  ./gradlew :app:assembleFdroidRelease
  ```
- 构建结果：`BUILD SUCCESSFUL in 24s`
- 产物路径：`app/build/outputs/apk/fdroid/release/`

### 产物清单
```
app-fdroid-arm64-v8a-release.apk      (179 MB)
app-fdroid-armeabi-v7a-release.apk    (141 MB)
app-fdroid-universal-release.apk      (540 MB)
app-fdroid-x86_64-release.apk         (184 MB)
app-fdroid-x86-release.apk            (186 MB)
```

### 签名验证
- 命令：`apksigner verify app-fdroid-universal-release.apk`
- 结果：**通过**（返回码 0）

### 结论
发布链路与签名配置正常，可支持发布。

---

## ✅ PASS-002 【P0】消息模块单元测试全部通过

### 验证内容
- 构建命令：
  ```bash
  cd /home/dou/StudioProjects/element-x-android
  ./gradlew :features:messages:impl:testDebugUnitTest
  ```
- 测试结果：`BUILD SUCCESSFUL`，无失败用例
- 覆盖范围：
  - 微信风格时间线布局逻辑
  - 消息分组与头像显示逻辑
  - MessagesViewTest 多节点匹配修复（`onAllNodesWithTag().onFirst()`）

### 结论
微信风格 UI 改造核心逻辑测试稳定，无明显回归。

---

## 测试执行证据（日志路径）

- 登录模块测试日志：`/tmp/test_login_only.log`
- 消息+通话并发测试日志：`/tmp/test_messages_call.log`
- 消息模块单独测试日志：`/tmp/test_messages_only.log`
- 通话模块单独测试日志：`/tmp/test_call_only.log`
- Release 构建日志：`/tmp/test_app_release_full.log`

---

## 建议修复优先级（供审核）

### 立即修复（阻断发布）
- 无

### 高优先级修复（建议发布前完成）
- **BUG-001**：登录模块单元测试失败
  - 修复方式：更新测试用例断言以匹配新的 `OnBoardingState`（含 `showSplash`）和品牌配置
  - 工作量：中等（需逐个用例分析预期与实际差异）

### 中优先级修复（可发布后修复）
- **BUG-002**：通话测试 flaky
  - 修复方式：协程测试清理与隔离
  - 工作量：小（单个测试用例修复）

### 接受风险发布条件
如果真机冒烟测试清单（见 `RELEASE_SMOKE_TEST_CHECKLIST.md`）中：
- A 组（登录）：100% 通过
- B 组（微信 UI）：100% 通过
- E 组（核心业务）：100% 通过
- J 组（发布产物）：100% 通过

则可接受当前单元测试失败，作为"测试债务"在下个补丁版本修复。

---

## 下一步行动（待审核后执行）

1. **请你执行真机冒烟测试清单**（`RELEASE_SMOKE_TEST_CHECKLIST.md`），回传结果
2. **基于真机测试结果召开 Go/No-Go 评审**
3. **若 Go**：
   - 将 BUG-001 和 BUG-002 登记到缺陷跟踪系统
   - 准备 Release Notes 和回滚预案
   - 执行发布
4. **若 No-Go**：
   - 我立即修复 BUG-001 并重新提交测试
   - 重新执行完整测试轮次

---

**报告产出人**：GitHub Copilot  
**待审核人**：项目负责人

