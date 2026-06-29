# Element X Android AI 辅助开发工作流 - 完整操作指南

> **适用对象**：希望借助大模型对 Element X Android 进行二次开发、问题修复、功能添加的开发者
> **项目路径**：`~/projects/element-x-android`
> **适用版本**：Element X Android 最新版

---

## 📌 目录

1. [核心概念与设计哲学](#一核心概念与设计哲学)
2. [三阶段模型使用策略](#二三层模型使用策略)
3. [项目结构速查](#三项目结构速查)
4. [任务一：语音/视频通话 Bug 修复](#四任务一语音视频通话-bug-修复)
5. [任务二：Bug 报告服务器迁移](#五任务二bug-报告服务器迁移)
6. [任务三：阅后即焚功能开发](#六任务三阅后即焚功能开发)
7. [提示词模板库](#七提示词模板库)
8. [状态文件管理](#八状态文件管理)
9. [常见问题与解决方案](#九常见问题与解决方案)

---

## 一、核心概念与设计哲学

### 1.1 上下文管理原则

**核心理念：对话中只保留命令，上下文绝对干净。**

| 内容 | 存放位置 | 对话中 |
|------|---------|--------|
| 您的命令/提问 | 直接发送 | ✅ 在 |
| 模型的思考过程 | 不输出，不保存 | ❌ 不在 |
| 模型的分析报告 | 保存到 `.md` 文件 | ❌ 不在 |
| 关键代码片段 | 保存到文件 | ❌ 不在 |
| 工作流状态 | 保存到 `state.json` | ❌ 不在 |

**为什么要这样做？**

- 对话历史越长，后续模型能有效处理的上下文越少
- 源代码分析报告动不动几千行，放在对话里会把真正的上下文挤出去
- 把所有产出外存，对话永远干净，模型永远专注

### 1.2 分层模型使用策略

不同模型有不同特长，让对的模型做对的事：

```
Kimi/MiniMax  →  快速扫描全局（超长上下文）
Opus 4.6       →  精准实地考察（深度推理）
Sonnet 4.6     →  方案评审（质量把关）
DeepSeek V3    →  具体编码实现（性价比最高）
DeepSeek R1    →  复杂问题分析
```

### 1.3 工作流循环架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Phase 1: 分析                          │
│  Kimi/MiniMax 快速扫描 → 生成结构分析报告                    │
└─────────────────────┬───────────────────────────────────┘
                      ↓ 报告保存到文件
┌─────────────────────▼───────────────────────────────────┐
│                      Phase 2: 设计                         │
│  Opus 直接读关键源码 → 验证 Kimi 分析 → 制定实施方案        │
└─────────────────────┬───────────────────────────────────┘
                      ↓ 方案保存到文件
┌─────────────────────▼───────────────────────────────────┐
│                   Phase 3: 编码                           │
│  DeepSeek V3 读源码和方案 → 编写代码                       │
└─────────────────────┬───────────────────────────────────┘
                      ↓ 代码保存到文件
┌─────────────────────▼───────────────────────────────────┐
│                   Phase 4: 评审                           │
│  Sonnet 4.6 代码审查 → 提出改进建议                       │
└─────────────────────┬───────────────────────────────────┘
                      ↓ 评审意见保存到文件
┌─────────────────────▼───────────────────────────────────┐
│                   Phase 5: 测试                           │
│  DeepSeek 设计测试用例 → 执行验证 → 汇报结果               │
└─────────────────────┬───────────────────────────────────┘
                      ↓ 全部阶段循环，直到所有测试通过
                   👇 （有问题？）
                      ↓
              返回 Phase 2 或 Phase 3
                   👆 （通过？）
                      ↓
                    结束
```

**人工节点：**
- Phase 2 设计方案完成后 → 您审阅方案，确认后再进入编码
- Phase 5 测试结果 → 您判断是否可接受

---

## 二、三层模型使用策略

### 2.1 模型速查表

| 模型 | 用途 | 单次成本 | 适用场景 |
|------|------|---------|---------|
| **MiniMax M2.7** | 日常对话、分析 | 订阅（无额外费用） | 日常任务、轻量分析 |
| **Kimi K2.5** | 超长上下文分析 | 订阅 | 一次性读完整个模块代码 |
| **DeepSeek V3** | 编程实现 | 极低 | 写代码、改 Bug |
| **DeepSeek R1** | 复杂推理 | 低 | 问题根因分析 |
| **Sonnet 4.6** | 代码审查 | 中 | 质量把关、方案评审 |
| **Opus 4.6** | 架构设计 | 高 | 复杂技术方案设计 |

### 2.2 模型切换命令

在对话中直接发送以下命令即可切换：

```
/model m27       # 切换到 MiniMax M2.7
/model Kimi      # 切换到 Kimi K2.5（超长上下文）
/model ds        # 切换到 DeepSeek V3
/model dsr       # 切换到 DeepSeek R1
/model sonnet4   # 切换到 Sonnet 4.6
/model opus4     # 切换到 Opus 4.6
```

### 2.3 分身使用场景

| 场景 | 使用分身？ | 模型选择 |
|------|----------|---------|
| 一次性分析整个项目结构 | ✅ 是 | Kimi/MiniMax |
| 需要等上一步完成才做下一步 | ✅ 是 | 对应模型 |
| 需要并行跑多个分析 | ✅ 是 | 各取所需 |
| 在当前对话里顺序完成任务 | ❌ 否 | 直接切换 |

---

## 三、项目结构速查

### 3.1 目录结构说明

```
element-x-android/
├── app/                          # 主应用模块
├── features/                     # 功能模块（按功能划分）
│   ├── locationsharing/         # 位置共享
│   ├── login/                    # 登录相关
│   ├── message/                  # 消息功能 ← 阅后即焚关键
│   │   ├── api/                 # 消息 API 接口
│   │   └── impl/                # 消息实现
│   ├── rageshake/                # Bug 报告 ← 任务二关键
│   ├── room/                     # 房间相关
│   ├── call/                     # 通话功能 ← 任务一关键
│   └── settings/                 # 设置功能
├── libraries/                    # 公共库
│   ├── matrix/                   # Matrix 协议 SDK ← 核心依赖
│   │   ├── api/                 # Matrix API
│   │   └── rustsdk/             # Rust 实现的 Matrix SDK
│   └── design/                  # UI 设计系统
├── tools/                        # 工具脚本
└── build.gradle.kts             # Gradle 构建配置
```

### 3.2 三个任务对应的关键目录

| 任务 | 关键目录/文件 | 说明 |
|------|-------------|------|
| 语音/视频 Bug | `features/call/`、`libraries/matrix/` | 通话功能核心 |
| Bug 服务器迁移 | `features/rageshake/`、`app/` | Bug 上报逻辑 |
| 阅后即焚 | `features/message/`、`libraries/matrix/api/` | 消息模块 + Matrix 协议 |

---

## 四、任务一：语音/视频通话 Bug 修复

### 背景
Element X Android 无法正常进行语音/视频通话，需要定位问题并修复。

### 推荐工作流

```
Phase 1: Kimi 快速扫描通话模块结构
Phase 2: Opus 直接读关键源码，分析根因
Phase 3: DeepSeek 根据分析结果修复代码
Phase 4: Sonnet 代码审查
Phase 5: 测试验证
```

### Phase 1 - 结构分析（使用 Kimi 或 MiniMax）

**切换模型：**
```
/model Kimi
```
（Kimi 有 256K 上下文，可以一次性读完通话相关的主要文件）

**发送提示词：**
```
请分析 ~/projects/element-x-android/features/call/ 目录，
帮我理解 Element X Android 的语音/视频通话实现：

1. 通话的发起流程（从哪里开始，如何触发 WebRTC）
2. 通话状态的存储和管理（StateFlow？ViewModel？）
3. WebRTC 相关的配置和初始化代码在哪里
4. 通话模块依赖的 Matrix SDK 代码在哪里？（libraries/matrix/）
5. 通话界面的 Compose UI 在哪里

将分析结果保存到：
~/projects/element-x-android/ai-workflow/use-cases/call-bug/01-analysis.md

每个关键文件请附上：
- 文件路径
- 一句话说明作用
- 关键代码片段（如果有的话）
```

---

### Phase 2 - 根因分析（使用 Opus 4.6）

**切换模型：**
```
/model opus4
```

**发送提示词：**
```
请基于 Kimi 的分析报告（~/projects/element-x-android/ai-workflow/use-cases/call-bug/01-analysis.md）
和您自己直接阅读关键源码的方式，分析语音/视频通话无法正常工作的根因。

请按以下步骤操作：
1. 先阅读 01-analysis.md 了解整体结构
2. 直接去读以下关键文件（不要只看报告，自己读源码）：
   - features/call/impl/src/main/java/.../CallScreenViewModel.kt
   - features/call/impl/src/main/java/.../CallHandler.kt
   - libraries/matrix/rustsdk/src/main/java/.../RustCallService.kt
   - libraries/matrix/api/src/main/java/.../MatrixCallClient.kt

3. 分析可能导致通话失败的原因：
   - WebRTC 配置问题？
   - Matrix Signaling 问题？
   - 权限问题？
   - SDK 初始化问题？
   - 网络/ICE candidate 问题？

将分析结果保存到：
~/projects/element-x-android/ai-workflow/use-cases/call-bug/02-root-cause.md

报告需要包含：
- 具体的问题定位（哪个类、哪行代码、什么问题）
- 问题根因分析
- 建议的修复方案（可以给出具体代码修改建议）
```

---

### Phase 3 - 代码修复（使用 DeepSeek V3）

**切换模型：**
```
/model ds
```

**发送提示词：**
```
请根据 Opus 的根因分析（~/projects/element-x-android/ai-workflow/use-cases/call-bug/02-root-cause.md）
修复 Element X Android 的语音/视频通话问题。

请按以下步骤：
1. 阅读 02-root-cause.md 理解问题
2. 直接去读相关源码文件
3. 实施修复代码

修复时请：
- 每修改一个文件，说明修改前后的差异
- 解释为什么这样修改能解决问题
- 注意保持项目的代码风格

具体需要修复的文件和修改内容，请参见 02-root-cause.md 中的建议。

将代码修改记录保存到：
~/projects/element-x-android/ai-workflow/use-cases/call-bug/03-fix-record.md
```

---

### Phase 4 - 代码审查（使用 Sonnet 4.6）

**切换模型：**
```
/model sonnet4
```

**发送提示词：**
```
请审查 Phase 3 的代码修复（~/projects/element-x-android/ai-workflow/use-cases/call-bug/03-fix-record.md）
和实际的代码修改。

检查要点：
1. 修复代码是否真的解决了问题
2. 是否引入了新的 bug 或 regression
3. 是否符合项目的代码规范
4. 是否有可能的边界情况（Edge case）没有处理
5. WebRTC 相关的修改是否与 Matrix 协议规范兼容

将审查结果保存到：
~/projects/element-x-android/ai-workflow/use-cases/call-bug/04-review.md

如果发现问题，请给出具体的改进建议和代码。
```

---

### Phase 5 - 测试验证（使用 DeepSeek V3）

**切换模型：**
```
/model ds
```

**发送提示词：**
```
请根据已完成的修复（~/projects/element-x-android/ai-workflow/use-cases/call-bug/）
设计并执行测试用例，验证语音/视频通话问题是否已修复。

测试要求：
1. 设计测试用例列表（覆盖正常流程 + 边界情况）
2. 说明每个测试用例如何执行
3. 如果发现新的问题，更新到：
~/projects/element-x-android/ai-workflow/use-cases/call-bug/05-test-results.md

测试维度：
- 发起语音通话
- 发起视频通话
- 接听语音通话
- 接听视频通话
- 通话中的网络切换
- 通话结束
- 被拒绝通话
- 无网络环境下的行为
```

---

## 五、任务二：Bug 报告服务器迁移

### 背景
Element X Android 默认将 Bug 报告发送到官方服务器，希望改为发送到自己的服务器，以便自主可控。

### 推荐工作流

```
Phase 1: Kimi 扫描 Bug 上报逻辑
Phase 2: Opus 设计迁移方案
Phase 3: DeepSeek 实施迁移代码
Phase 4: 测试验证
```

### Phase 1 - 结构分析（使用 Kimi）

**切换模型：**
```
/model Kimi
```

**发送提示词：**
```
请分析 ~/projects/element-x-android/features/rageshake/ 目录，
找出 Bug 报告的完整上报链路：

1. Bug 报告的触发点在哪里？（rageshake 功能）
2. Bug 报告的数据格式是什么？
3. Bug 报告发送到哪个服务器？（URL 配置）
4. 发送请求是同步还是异步？
5. App 模块中是否有额外的 Bug 上报逻辑？
6. 项目中是否有 Analytics（分析）相关代码也会发送数据到服务器？

请在 ~/projects/element-x-android/ai-workflow/use-cases/bug-server/01-analysis.md 保存分析结果。
每个关键文件附上：路径、作用、关键代码片段。
```

---

### Phase 2 - 迁移方案设计（使用 Opus 4.6）

**切换模型：**
```
/model opus4
```

**发送提示词：**
```
请基于 Kimi 的分析（~/projects/element-x-android/ai-workflow/use-cases/bug-server/01-analysis.md）
设计将 Bug 报告迁移到自建服务器的方案。

设计要求：
1. 自建服务器需要提供什么接口？（REST？GraphQL？）
2. 数据格式是否需要调整？
3. 如何让用户方便地配置自己的服务器地址？
4. 是否需要鉴权机制？
5. 旧数据如何迁移？

请直接去读以下关键文件：
- features/rageshake/impl/src/main/java/.../RageShakeManager.kt
- features/rageshake/impl/src/main/java/.../BugReporter.kt
- app/src/main/res/values/strings.xml（查找服务器 URL 相关配置）

将方案保存到：
~/projects/element-x-android/ai-workflow/use-cases/bug-server/02-migration-plan.md
```

---

### Phase 3 - 实施迁移（使用 DeepSeek V3）

**切换模型：**
```
/model ds
```

**发送提示词：**
```
请根据迁移方案（~/projects/element-x-android/ai-workflow/use-cases/bug-server/02-migration-plan.md）
修改代码，实现 Bug 报告发送到自建服务器。

实施步骤：
1. 阅读 02-migration-plan.md 理解方案
2. 找到 RageShakeManager 和 BugReporter 的具体实现代码
3. 添加用户配置自己服务器地址的功能（建议在设置页面添加）
4. 修改 Bug 上报的 HTTP 请求目标地址
5. 确保默认地址仍然是官方地址（用户主动切换才用自建）

将修改记录保存到：
~/projects/element-x-android/ai-workflow/use-cases/bug-server/03-implementation.md
```

---

## 六、任务三：阅后即焚功能开发

### 背景
为 Element X Android 添加"阅后即焚"（Burn After Reading）功能。消息被阅读后自动销毁。

### 推荐工作流

```
Phase 1: Kimi 分析消息模块结构
Phase 2: Opus 设计技术方案
Phase 3: DeepSeek 实现核心代码
Phase 4: Sonnet 审查方案
Phase 5: DeepSeek 实现 UI
Phase 6: 测试验证
```

### Phase 1 - 消息模块分析（使用 Kimi）

**切换模型：**
```
/model Kimi
```

**发送提示词：**
```
请深度分析 ~/projects/element-x-android 的消息系统：

重点关注（按重要性排序）：
1. 【最重要】消息的数据模型
   - Message 类在哪里？有哪些字段？
   - 消息的 UUID 或唯一标识如何生成？

2. 消息发送流程
   - 用户点击发送后，代码从哪里开始处理？
   - MessageComposer（消息输入框）在哪里？
   - 消息发送请求是如何构造和发送的？

3. Matrix 协议相关
   - libraries/matrix/api/ 中的接口定义
   - 是否有 Ephemeral Events（临时事件）的现有实现？
   - 加密消息（E2EE）的相关代码在哪里？

4. 消息存储
   - 消息保存在哪里？（Room DB？内存？）
   - 消息的删除逻辑在哪里？

5. UI 层
   - 消息列表如何渲染？
   - 消息气泡的 Compose 代码在哪里？
   - 消息状态（如"已发送""已读"）如何显示？

请在 ~/projects/element-x-android/ai-workflow/use-cases/burn-after-reading/01-message-system.md 保存分析结果。
```

---

### Phase 2 - 技术方案设计（使用 Opus 4.6）

**切换模型：**
```
/model opus4
```

**发送提示词：**
```
请基于 Kimi 的消息系统分析（~/projects/element-x-android/ai-workflow/use-cases/burn-after-reading/01-message-system.md）
为 Element X Android 设计"阅后即焚"功能的技术方案。

背景说明：
- Element X 是 Matrix 协议的客户端
- Matrix 协议本身支持 Ephemeral Events（临时事件，阅后即焚的协议层面支持）
- 项目使用 Kotlin + Jetpack Compose + Matrix Rust SDK

设计要求：
请直接阅读以下关键源码文件（不要只看 Kimi 的报告）：
1. features/message/impl/src/main/java/.../MessageComposerPresenter.kt（消息发送）
2. libraries/matrix/api/src/main/java/.../Message.kt（消息数据模型）
3. libraries/matrix/api/src/main/java/.../Room.kt（Matrix Room 接口）
4. features/message/impl/src/main/java/.../timeline/...（消息时间线）

需要设计的内容：
1. 【消息标记】
   - 如何在 Message 数据模型中标记"阅后即焚"？
   - 需要新增字段还是复用现有字段？

2. 【发送流程】
   - 用户如何选择发送阅后即焚消息？
   - 在 MessageComposer 中如何修改？
   - Matrix 协议的 m.room.poll... 相关？还是新设计？

3. 【销毁逻辑】
   - 消息被"已读"后，多久销毁？（建议可配置，如3秒/10秒/1分钟）
   - 销毁是在本地还是同时通知服务器删除？
   - 销毁后的 UI 如何更新？

4. 【UI 设计】
   - 在消息输入框旁边添加什么 UI 元素来触发？
   - 已阅消息的视觉提示是什么？
   - 倒计时显示在哪里？

5. 【关键文件清单】
   - 列出所有需要修改的文件（新增 + 修改）

将完整方案保存到：
~/projects/element-x-android/ai-workflow/use-cases/burn-after-reading/02-design-plan.md
```

---

### Phase 3 - 核心代码实现（使用 DeepSeek V3）

**切换模型：**
```
/model ds
```

**发送提示词：**
```
请根据技术方案（~/projects/element-x-android/ai-workflow/use-cases/burn-after-reading/02-design-plan.md）
实现阅后即焚功能的核心代码。

实施步骤建议：
1. 先在 Message 数据模型中添加 burnAfterReading 字段
2. 在 MessageComposer 中添加阅后即焚开关（Compose UI）
3. 在消息发送逻辑中添加标记
4. 实现消息阅读检测（参考现有"已读"机制）
5. 实现销毁定时器逻辑
6. 在消息时间线中渲染倒计时 UI

每次修改一个文件，说明：
- 修改了哪个文件
- 修改前后的关键代码
- 为什么这样实现

将代码修改详细记录保存到：
~/projects/element-x-android/ai-workflow/use-cases/burn-after-reading/03-core-implementation.md
```

---

### Phase 4 - 方案审查（使用 Sonnet 4.6）

**切换模型：**
```
/model sonnet4
```

**发送提示词：**
```
请审查阅后即焚功能的实现（~/projects/element-x-android/ai-workflow/use-cases/burn-after-reading/03-core-implementation.md）

审查要点：
1. 与 Matrix 协议的兼容性
2. 加密消息（E2EE）场景下的阅后即焚行为
3. 销毁逻辑是否有安全漏洞（如：是否可能在服务器留存副本）
4. UI 与现有消息气泡的风格一致性
5. 性能影响（倒计时、多消息同时倒计时时的处理）

将审查结果保存到：
~/projects/element-x-android/ai-workflow/use-cases/burn-after-reading/04-review.md
```

---

### Phase 5 - UI 完善（使用 DeepSeek V3）

**切换模型：**
```
/model ds
```

**发送提示词：**
```
请根据审查意见（~/projects/element-x-android/ai-workflow/use-cases/burn-after-reading/04-review.md）
完善阅后即焚功能的 UI 实现。

需要做的 UI 修改：
1. MessageComposer 中的阅后即焚开关 UI
2. 消息气泡中阅后即焚的图标显示
3. 倒计时动画 UI
4. 已销毁消息的占位符（显示"此消息已销毁"）
5. 设置页面中阅后即焚的默认时间选项

参考项目现有的 UI 风格和组件。

将 UI 修改记录保存到：
~/projects/element-x-android/ai-workflow/use-cases/burn-after-reading/05-ui-implementation.md
```

---

## 七、提示词模板库

### 7.1 模型切换模板

```bash
# 切换到 Kimi（超长上下文分析）
/model Kimi

# 切换到 DeepSeek V3（写代码）
/model ds

# 切换到 Opus 4.6（架构设计）
/model opus4

# 切换回 MiniMax M2.7（日常使用）
/model m27
```

### 7.2 分析任务通用模板

```
请分析 [项目路径] 的 [模块/目录]：

1. [具体问题1]
2. [具体问题2]
3. [具体问题3]

将分析结果保存到：[文件路径]

要求：
- 每个关键文件附上：路径 + 一句话作用 + 关键代码片段
- 如果找不到某个内容，说明"未找到，可能在其他依赖库中"
```

### 7.3 设计任务通用模板

```
请基于 [分析报告路径] 的分析结果，
为 [功能名称] 设计实现方案。

背景：
[简要背景说明]

要求：
1. 先阅读分析报告
2. 直接去读关键源码文件（不要只看报告）：
   - [文件1]
   - [文件2]
3. 设计方案需要包含：
   - 具体的技术实现步骤
   - 需要修改/新增的所有文件清单
   - 关键代码的修改建议

将方案保存到：[文件路径]
```

### 7.4 代码修复任务模板

```
请根据 [分析/方案文档路径] 修复 [问题名称]。

已知信息：
[摘要说明]

请按以下步骤：
1. 阅读方案文档
2. 直接去读相关源码
3. 实施代码修改

每修改一个文件后，请说明：
- 修改的文件路径
- 修改内容摘要
- 修改理由

将修改记录保存到：[文件路径]
```

---

## 八、状态文件管理

### 8.1 全局状态文件

```json
// ~/projects/element-x-android/ai-workflow/state.json
{
  "project": "element-x-android",
  "lastUpdated": "2026-03-30T00:00:00Z",
  "useCases": {
    "call-bug": {
      "currentPhase": 3,
      "phases": {
        "1": { "status": "done", "output": "use-cases/call-bug/01-analysis.md" },
        "2": { "status": "done", "output": "use-cases/call-bug/02-root-cause.md" },
        "3": { "status": "in-progress", "output": "use-cases/call-bug/03-fix-record.md" },
        "4": { "status": "pending", "output": "use-cases/call-bug/04-review.md" },
        "5": { "status": "pending", "output": "use-cases/call-bug/05-test-results.md" }
      }
    },
    "bug-server": {
      "currentPhase": 1,
      "phases": {
        "1": { "status": "in-progress", "output": "use-cases/bug-server/01-analysis.md" },
        "2": { "status": "pending", "output": "use-cases/bug-server/02-migration-plan.md" },
        "3": { "status": "pending", "output": "use-cases/bug-server/03-implementation.md" }
      }
    },
    "burn-after-reading": {
      "currentPhase": 2,
      "phases": {
        "1": { "status": "done", "output": "use-cases/burn-after-reading/01-message-system.md" },
        "2": { "status": "in-progress", "output": "use-cases/burn-after-reading/02-design-plan.md" },
        "3": { "status": "pending", "output": "use-cases/burn-after-reading/03-core-implementation.md" },
        "4": { "status": "pending", "output": "use-cases/burn-after-reading/04-review.md" },
        "5": { "status": "pending", "output": "use-cases/burn-after-reading/05-ui-implementation.md" }
      }
    }
  }
}
```

### 8.2 工作流状态命令

```bash
# 查看当前所有任务的状态
cat ~/projects/element-x-android/ai-workflow/state.json | python3 -m json.tool

# 更新某个任务的状态
# （在对应的 phase output 中添加 status: done/in-progress/pending）
```

### 8.3 目录结构规范

```
~/projects/element-x-android/ai-workflow/
├── README.md                    # 本指南
├── state.json                  # 全局状态文件
├── phases/                     # 通用阶段模板
│   ├── 01-analysis.md         # 通用分析模板
│   ├── 02-design.md           # 通用设计模板
│   ├── 03-implementation.md  # 通用实现模板
│   └── 04-review.md           # 通用审查模板
├── prompts/                    # 提示词模板
│   ├── analysis-prompt.md
│   ├── design-prompt.md
│   ├── coding-prompt.md
│   └── review-prompt.md
└── use-cases/                 # 各任务的具体工作
    ├── call-bug/
    │   ├── 01-analysis.md
    │   ├── 02-root-cause.md
    │   ├── 03-fix-record.md
    │   ├── 04-review.md
    │   └── 05-test-results.md
    ├── bug-server/
    │   ├── 01-analysis.md
    │   ├── 02-migration-plan.md
    │   └── 03-implementation.md
    └── burn-after-reading/
        ├── 01-message-system.md
        ├── 02-design-plan.md
        ├── 03-core-implementation.md
        ├── 04-review.md
        ├── 05-ui-implementation.md
        └── 06-test-results.md
```

---

## 九、常见问题与解决方案

### Q1: Opus 4.6 读了很多代码，但设计方案还是不对怎么办？

**A:** Opps 4.6 可能对项目特定技术栈的理解有偏差。不要让 Opus 单独设计 → 改为让 Opus 提出方案后，用 DeepSeek V3 去验证方案的每个细节，发现不对的地方再让 Opus 修正。

### Q2: DeepSeek V3 写的代码有问题，但审查没有发现怎么办？

**A:** 审查的作用有限。对于关键功能，可以：
1. 让 Sonnet 4.6 和 Opus 4.6 分别审查一次
2. 人工抽查关键代码路径
3. 实际编译运行测试

### Q3: Kimi 的分析报告太浅，关键细节没覆盖到怎么办？

**A:** 在给 Opus 或 DeepSeek 的提示词中，明确要求他们"不要只看报告，直接去读 [具体文件路径]"。这样他们会跳过报告，直接读源码。

### Q4: 三个任务同时进行，会不会混乱？

**A:** 建议按优先级顺序一个一个来。如果要并行：
- 每个任务用不同的文件目录（已按 use-cases 子目录分开）
- 每次切换任务前，先读一下 state.json 确认当前状态

### Q5: 分身任务完成后，我怎么知道？

**A:** OpenClaw 会自动通知。当分身完成后，您会收到消息告知结果。如果长时间没有结果，可以问豆花"分身跑完了吗？"

---

## 十、快速启动命令

```bash
# 1. 查看全局状态
cat ~/projects/element-x-android/ai-workflow/state.json

# 2. 查看某个任务的当前阶段
cat ~/projects/element-x-android/ai-workflow/state.json | grep -A5 "call-bug"

# 3. 查看 Kimi 的分析报告
cat ~/projects/element-x-android/ai-workflow/use-cases/burn-after-reading/01-message-system.md

# 4. 更新状态文件（需要手动编辑）
nano ~/projects/element-x-android/ai-workflow/state.json

# 5. 在当前对话中切换模型
# /model opus4
# /model ds
# /model Kimi
```

---

## 附录 A：三任务优先排序建议

| 优先级 | 任务 | 理由 |
|-------|------|------|
| ⭐⭐⭐ | 任务一（通话 Bug） | 功能性问题，影响核心使用 |
| ⭐⭐ | 任务二（Bug 服务器） | 提升自主可控性 |
| ⭐ | 任务三（阅后即焚） | 新功能锦上添花 |

---

*本指南最后更新：2026年3月30日*
*配套文件：~/projects/element-x-android/ai-workflow/state.json*
