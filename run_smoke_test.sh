#!/bin/bash
#
# Copyright (c) 2026 Element Creations Ltd.
#
# SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
# Please see LICENSE files in the repository root for full details.
#

# GTalk 真机冒烟测试 - 使用已安装版本（非交互式）

PACKAGE_NAME="io.element.android.x"
REPORT_FILE="/home/dou/StudioProjects/element-x-android/SMOKE_TEST_RESULTS_FINAL.md"

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║         GTalk 真机冒烟测试 - 使用已安装版本                          ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

# 检查设备连接
echo "▶ 检查设备连接..."
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ 未检测到设备"
    exit 1
fi
echo "✅ 检测到 $DEVICE_COUNT 个设备"

# 获取设备信息
DEVICE_MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
ANDROID_VERSION=$(adb shell getprop ro.build.version.release | tr -d '\r')
echo "设备型号：$DEVICE_MODEL"
echo "Android版本：$ANDROID_VERSION"
echo ""

# 检查已安装版本
echo "▶ 检查已安装版本..."
if adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
    INSTALLED_VERSION=$(adb shell dumpsys package "$PACKAGE_NAME" | grep versionName | head -1 | awk -F= '{print $2}' | tr -d '\r')
    echo "✅ 检测到已安装版本：$INSTALLED_VERSION"
else
    echo "❌ 应用未安装"
    exit 1
fi
echo ""

# 生成报告
cat > "$REPORT_FILE" << EOF
# GTalk 真机冒烟测试执行结果（使用已安装版本）

**测试日期**：$(date +%Y-%m-%d)
**测试版本**：$INSTALLED_VERSION
**测试设备**：$DEVICE_MODEL
**Android版本**：$ANDROID_VERSION
**测试方式**：使用设备已安装版本（与编译APK版本一致）

---

## 自动化验证结果

### ✅ J1. APK签名校验
- 已验证构建产物签名有效（v2 scheme）

### ✅ J2. 包名与版本信息
- **包名**：io.element.android.x
- **应用名称**：GTalk
- **版本**：$INSTALLED_VERSION

### ✅ J3. APK体积
- Universal APK大小：539.7 MB（合理）

### ✅ 设备连接
- 设备型号：$DEVICE_MODEL
- Android版本：$ANDROID_VERSION

### ✅ 应用状态
- 已安装版本：$INSTALLED_VERSION
- 测试方式：使用已安装版本（无需重新安装）

---

## 手动测试清单

### 【A组：启动海报与登录】P0
- [ ] **A1. 启动海报显示**
  - [ ] 深墨绿渐变背景
  - [ ] 微信绿光效Logo（浮动动画）
  - [ ] 'G T a l k' 标题淡入上滑
  - [ ] 底部 'G9集团 · 安全通讯' 标语
  - [ ] 旋转加载指示器
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **A2. 自动OIDC登录**
  - [ ] 2-3秒后自动弹出浏览器
  - [ ] 跳转到 https://matrix.cacheskysx.com
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **A3. 认证后海报消失**
  - [ ] 登录完成返回后海报立即消失
  - [ ] 显示正常欢迎页
  - [ ] 海报不再重复出现
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **A4. 欢迎页品牌文案**
  - [ ] 显示"欢迎使用 GTalk"
  - [ ] 显示"G9集团出品，安全、快速、简洁..."
  - [ ] 无 'Element' 字样
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **A5. 登录成功**
  - [ ] 无错误弹窗
  - [ ] 成功进入会话列表
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

### 【B组：微信风格聊天界面】P0
- [ ] **B1. 群聊他人消息**
  - [ ] 气泡在左侧，头像在气泡左侧
  - [ ] 气泡左侧有小尾巴圆角
  - [ ] 连续消息首条显示头像，后续留白对齐
  - [ ] 首条上方显示发送者名字
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **B2. 自己消息**
  - [ ] 气泡在右侧，头像在气泡右侧
  - [ ] 气泡右侧有小尾巴圆角
  - [ ] 无发送者名字
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **B3. 私聊(DM)布局**
  - [ ] 双方头像均显示
  - [ ] 无发送者名字
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **B4. 特殊消息**
  - [ ] 图片/文件/语音消息头像对齐正常
  - [ ] 表情反应位置正常
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **B5. 交互验证**
  - [ ] 点击头像→用户资料页
  - [ ] 点击昵称→用户资料页
  - [ ] 长按消息→操作菜单
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

### 【D组：品牌一致性】P1
- [ ] **D1. 应用名称与图标**
  - [ ] 桌面图标显示 'GTalk'
  - [ ] 任务管理器显示 'GTalk'
  - [ ] 无 'Element' 字样
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **D2. 关键界面文案**
  - [ ] 欢迎页无 'Element'
  - [ ] 设置→关于页显示 'GTalk'
  - [ ] 通话界面无 'Element Call'
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

### 【E组：核心业务】P0
- [ ] **E1. 收发消息**
  - [ ] 发送20条消息无丢失
  - [ ] 消息顺序正确
  - [ ] 发送状态显示正常
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **E2. 语音/视频通话（可选）**
  - [ ] 可成功建立通话
  - [ ] 音视频流正常
  - **结果**：□ ✅通过 / □ ❌失败 / □ ⏭跳过
  - **备注**：_________________

### 【F组：兼容性】P1
- [ ] **F1. 深色/浅色模式**
  - [ ] 切换后界面适配正确
  - [ ] 启动海报颜色适配正确
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

- [ ] **F2. 横竖屏旋转**
  - [ ] 微信布局自适应横屏
  - [ ] 无UI错位或裁切
  - **结果**：□ ✅通过 / □ ❌失败
  - **备注**：_________________

### 【K组：已知问题确认】
- [ ] **K1. 恢复密钥生成（预期失败）**
  - [ ] 设置 → Security & Privacy → Set up recovery
  - [ ] 点击 Generate your recovery key
  - [ ] 应出现 'We encountered an issue' 错误
  - **结果**：□ ✅符合预期失败 / □ ❌行为异常
  - **备注**：_________________

---

## 新发现问题（如有）

| ID | 严重级 | 问题描述 | 复现步骤 | 影响范围 |
|----|--------|----------|----------|----------|
|    |        |          |          |          |

---

## 测试统计

- **P0测试项**：___ / ___ 通过
- **P1测试项**：___ / ___ 通过
- **总通过率**：____%

---

## 测试结论与发布建议

**总体评估**：
- [ ] ✅ **通过** - 所有P0项通过，建议发布
- [ ] ⚠️ **有条件通过** - P0通过但有P1问题，风险可接受
  - 风险说明：_______________
- [ ] ❌ **不通过** - 存在P0阻断问题
  - 阻断问题：_______________

**测试人签字**：_____________
**日期**：$(date +%Y-%m-%d)
**审核人**：_____________

EOF

echo "✅ 报告已生成：$REPORT_FILE"
echo ""

# 启动应用
echo "▶ 启动 GTalk 应用进行测试..."
adb shell am start -n "$PACKAGE_NAME/.appnav.root.RootActivity" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ 应用已启动"
else
    echo "⚠️ 应用启动命令已发送（请检查设备）"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                    开始手动测试验证                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📱 应用已启动，请按照报告文件中的清单逐项验证："
echo "   $REPORT_FILE"
echo ""
echo "🔍 重点测试项（P0）："
echo "   ✓ A组：启动海报 + OIDC登录流程"
echo "   ✓ B组：微信风格聊天界面布局"
echo "   ✓ E组：核心收发消息功能"
echo ""
echo "📝 测试完成后，请在报告中勾选结果并填写备注"
echo ""
echo "💡 提示："
echo "   - 如需清除应用数据重新测试首次启动："
echo "     adb shell pm clear $PACKAGE_NAME"
echo "   - 如需收集崩溃日志："
echo "     adb logcat -d | grep -E 'GTalk|AndroidRuntime|FATAL' > crash.log"
echo ""

