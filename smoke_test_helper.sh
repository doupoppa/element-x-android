#!/bin/bash
#
# Copyright (c) 2026 Element Creations Ltd.
#
# SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
# Please see LICENSE files in the repository root for full details.
#

# GTalk 真机冒烟测试自动化辅助脚本
# 用途：执行可自动化的验证项，并生成半自动化测试指引

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APK_PATH="$SCRIPT_DIR/app/build/outputs/apk/fdroid/release/app-fdroid-universal-release.apk"
PACKAGE_NAME="io.element.android.x"
REPORT_FILE="$SCRIPT_DIR/SMOKE_TEST_RESULTS.md"

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                 GTalk 真机冒烟测试执行助手                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

# 初始化报告
cat > "$REPORT_FILE" << 'EOF'
# GTalk 真机冒烟测试执行结果

**测试日期**：$(date +%Y-%m-%d)
**APK版本**：app-fdroid-universal-release.apk
**测试设备**：_____________（请手动填写设备型号）
**Android版本**：_____________（请手动填写）

---

## 自动化验证结果

EOF

# ============== J组：发布产物验证 ==============
echo "▶ 执行 J组：发布产物验证..."

echo "### J1. APK签名校验" >> "$REPORT_FILE"
if apksigner verify --verbose "$APK_PATH" > /tmp/verify_detail.txt 2>&1; then
    echo "- ✅ **通过**：APK签名有效" >> "$REPORT_FILE"
    grep "Verified using" /tmp/verify_detail.txt >> "$REPORT_FILE"
    echo "✅ J1 签名校验通过"
else
    echo "- ❌ **失败**：APK签名无效" >> "$REPORT_FILE"
    cat /tmp/verify_detail.txt >> "$REPORT_FILE"
    echo "❌ J1 签名校验失败"
fi
echo "" >> "$REPORT_FILE"

echo "### J2. 包名与版本信息" >> "$REPORT_FILE"
aapt dump badging "$APK_PATH" 2>&1 | grep -E "package:|application-label:|versionCode|versionName" | head -3 > /tmp/package_info.txt
cat /tmp/package_info.txt >> "$REPORT_FILE"
PACKAGE_LINE=$(grep "^package:" /tmp/package_info.txt)
APP_LABEL=$(grep "^application-label:" /tmp/package_info.txt | head -1)

if [[ "$PACKAGE_LINE" == *"io.element.android.x"* ]]; then
    echo "- ✅ **包名正确**：io.element.android.x" >> "$REPORT_FILE"
    echo "✅ J2 包名正确"
else
    echo "- ❌ **包名异常**：$PACKAGE_LINE" >> "$REPORT_FILE"
    echo "❌ J2 包名异常"
fi

if [[ "$APP_LABEL" == *"GTalk"* ]]; then
    echo "- ✅ **应用名称正确**：GTalk" >> "$REPORT_FILE"
    echo "✅ J2 应用名称正确"
else
    echo "- ⚠️ **应用名称异常**：$APP_LABEL" >> "$REPORT_FILE"
    echo "⚠️ J2 应用名称可能异常"
fi
echo "" >> "$REPORT_FILE"

echo "### J3. APK体积" >> "$REPORT_FILE"
APK_SIZE_MB=$(stat -c %s "$APK_PATH" | awk '{printf "%.1f", $1/1024/1024}')
echo "- **Universal APK大小**：${APK_SIZE_MB} MB" >> "$REPORT_FILE"
if (( $(echo "$APK_SIZE_MB > 400 && $APK_SIZE_MB < 700" | bc -l) )); then
    echo "- ✅ **体积合理**（预期范围 400-700 MB）" >> "$REPORT_FILE"
    echo "✅ J3 APK体积正常 (${APK_SIZE_MB} MB)"
else
    echo "- ⚠️ **体积异常**（超出预期范围）" >> "$REPORT_FILE"
    echo "⚠️ J3 APK体积异常 (${APK_SIZE_MB} MB)"
fi
echo "" >> "$REPORT_FILE"

# ============== 设备检查 ==============
echo ""
echo "▶ 检查 ADB 设备连接..."

if ! command -v adb &> /dev/null; then
    echo "❌ ADB 未安装或未在 PATH 中"
    echo "请先安装 Android SDK Platform Tools"
    exit 1
fi

adb devices -l > /tmp/adb_devices.txt 2>&1
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)

echo "### 设备连接状态" >> "$REPORT_FILE"
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "- ❌ **未检测到设备**" >> "$REPORT_FILE"
    cat /tmp/adb_devices.txt >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "❌ 未检测到连接的Android设备"
    echo ""
    echo "请执行以下操作："
    echo "1. 通过USB连接手机到电脑"
    echo "2. 手机上启用开发者选项和USB调试"
    echo "3. 运行 'adb devices' 确认设备已授权"
    echo "4. 重新运行此脚本"
    exit 1
else
    echo "- ✅ **已连接设备数**：$DEVICE_COUNT" >> "$REPORT_FILE"
    cat /tmp/adb_devices.txt >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "✅ 检测到 $DEVICE_COUNT 个设备"
fi

# ============== 检查或安装APK ==============
echo ""
echo "▶ 检查设备上已安装的版本..."
echo "### APK安装/验证" >> "$REPORT_FILE"

# 检查应用是否已安装
if adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
    # 获取已安装版本
    INSTALLED_VERSION=$(adb shell dumpsys package "$PACKAGE_NAME" | grep versionName | head -1 | awk -F= '{print $2}' | tr -d '\r')
    echo "- ℹ️ **检测到已安装版本**：$INSTALLED_VERSION" >> "$REPORT_FILE"
    echo "ℹ️ 检测到已安装版本：$INSTALLED_VERSION"

    # 提示用户选择
    echo ""
    read -p "是否使用已安装版本进行测试？(Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "- ✅ **使用已安装版本**进行测试" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "✅ 使用已安装版本进行测试"
    else
        # 用户选择重新安装
        echo "▶ 尝试重新安装APK..."
        if adb install -r "$APK_PATH" > /tmp/install_result.txt 2>&1; then
            echo "- ✅ **安装成功**" >> "$REPORT_FILE"
            cat /tmp/install_result.txt >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            echo "✅ APK安装成功"
        else
            echo "- ⚠️ **安装失败，使用已安装版本**" >> "$REPORT_FILE"
            cat /tmp/install_result.txt >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            echo "⚠️ APK安装失败，继续使用已安装版本"
            cat /tmp/install_result.txt
        fi
    fi
else
    # 首次安装
    echo "▶ 安装测试APK到设备..."
    if adb install -r "$APK_PATH" > /tmp/install_result.txt 2>&1; then
        echo "- ✅ **安装成功**" >> "$REPORT_FILE"
        cat /tmp/install_result.txt >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "✅ APK安装成功"
    else
        echo "- ❌ **安装失败**" >> "$REPORT_FILE"
        cat /tmp/install_result.txt >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "❌ APK安装失败"
        cat /tmp/install_result.txt
        exit 1
    fi
fi

# ============== 获取设备信息 ==============
echo ""
echo "▶ 获取设备信息..."
adb shell getprop ro.product.model > /tmp/device_model.txt 2>&1
adb shell getprop ro.build.version.release > /tmp/android_version.txt 2>&1

DEVICE_MODEL=$(cat /tmp/device_model.txt | tr -d '\r')
ANDROID_VERSION=$(cat /tmp/android_version.txt | tr -d '\r')

echo "### 测试设备信息" >> "$REPORT_FILE"
echo "- **设备型号**：$DEVICE_MODEL" >> "$REPORT_FILE"
echo "- **Android版本**：$ANDROID_VERSION" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "设备型号：$DEVICE_MODEL"
echo "Android版本：$ANDROID_VERSION"

# ============== 清除应用数据（可选） ==============
echo ""
read -p "是否清除应用数据进行首次启动测试？(y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "▶ 清除应用数据..."
    adb shell pm clear "$PACKAGE_NAME" > /tmp/clear_data.txt 2>&1
    echo "### 数据清除" >> "$REPORT_FILE"
    echo "- ✅ **已清除应用数据**（首次启动测试）" >> "$REPORT_FILE"
    cat /tmp/clear_data.txt >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "✅ 应用数据已清除"
else
    echo "### 数据清除" >> "$REPORT_FILE"
    echo "- ℹ️ **保留应用数据**（升级测试）" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "ℹ️ 保留现有应用数据"
fi

# ============== 启动应用 ==============
echo ""
echo "▶ 启动 GTalk 应用..."
adb shell am start -n "$PACKAGE_NAME/.appnav.root.RootActivity" > /tmp/launch_result.txt 2>&1
echo "### 应用启动" >> "$REPORT_FILE"
if grep -q "Starting: Intent" /tmp/launch_result.txt; then
    echo "- ✅ **启动成功**" >> "$REPORT_FILE"
    cat /tmp/launch_result.txt >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "✅ 应用已启动"
else
    echo "- ❌ **启动失败**" >> "$REPORT_FILE"
    cat /tmp/launch_result.txt >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "❌ 应用启动失败"
fi

# ============== 人工测试提示 ==============
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                    请在设备上进行人工验证                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📱 应用已启动，请按以下清单逐项验证并记录结果："
echo ""
echo "【A组：启动海报与登录】"
echo "  A1. 启动海报显示验证"
echo "      □ 深墨绿渐变背景"
echo "      □ 微信绿光效Logo（浮动动画）"
echo "      □ 'G T a l k' 标题淡入上滑"
echo "      □ 底部 'G9集团 · 安全通讯' 标语"
echo "      □ 旋转加载指示器"
echo ""
echo "  A2. 自动OIDC登录"
echo "      □ 2-3秒后自动弹出浏览器登录"
echo "      □ 跳转到 https://matrix.cacheskysx.com"
echo ""
echo "  A3. 认证后海报消失"
echo "      □ 登录完成返回后海报立即消失"
echo "      □ 显示正常欢迎页"
echo "      □ 海报不再重复出现"
echo ""
echo "  A4. 欢迎页品牌文案"
echo "      □ '欢迎使用 GTalk'"
echo "      □ 'G9集团出品，安全、快速、简洁...'"
echo "      □ 无 'Element' 字样"
echo ""
echo "  A5. 登录成功"
echo "      □ 无错误弹窗"
echo "      □ 进入会话列表"
echo ""
echo "【B组：微信风格聊天界面】"
echo "  B1. 群聊他人消息"
echo "      □ 气泡在左侧，头像在气泡左侧"
echo "      □ 气泡左侧有小尾巴圆角"
echo "      □ 连续消息首条显示头像，后续留白"
echo "      □ 首条上方显示发送者名字"
echo ""
echo "  B2. 自己消息"
echo "      □ 气泡在右侧，头像在气泡右侧"
echo "      □ 气泡右侧有小尾巴圆角"
echo "      □ 无发送者名字"
echo ""
echo "  B3. 私聊(DM)布局"
echo "      □ 双方头像均显示"
echo "      □ 无发送者名字"
echo ""
echo "  B4. 特殊消息"
echo "      □ 图片/文件/语音消息头像对齐正常"
echo "      □ 表情反应位置正常"
echo ""
echo "  B5. 交互"
echo "      □ 点击头像→用户资料"
echo "      □ 点击昵称→用户资料"
echo "      □ 长按消息→操作菜单"
echo ""
echo "【D组：品牌一致性】"
echo "  D1. 应用名称与图标"
echo "      □ 桌面图标显示 'GTalk'"
echo "      □ 任务管理器显示 'GTalk'"
echo "      □ 无 'Element' 字样"
echo ""
echo "  D2. 关键界面文案"
echo "      □ 欢迎页无 'Element'"
echo "      □ 关于页显示 'GTalk'"
echo "      □ 通话界面无 'Element Call'"
echo ""
echo "【E组：核心业务】"
echo "  E1. 收发消息"
echo "      □ 发送20条消息无丢失"
echo "      □ 消息顺序正确"
echo "      □ 发送状态显示正常"
echo ""
echo "  E2. 语音/视频通话（可选）"
echo "      □ 可成功建立通话"
echo "      □ 音视频流正常"
echo ""
echo "【F组：兼容性】"
echo "  F1. 深色/浅色模式"
echo "      □ 切换后界面适配正确"
echo "      □ 启动海报颜色适配"
echo ""
echo "  F2. 横竖屏旋转"
echo "      □ 微信布局自适应横屏"
echo "      □ 无UI错位"
echo ""
echo "【K组：已知问题确认】"
echo "  K1. 恢复密钥生成（预期失败）"
echo "      □ 设置 → Set up recovery → Generate"
echo "      □ 应出现 'We encountered an issue' 错误"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "📝 测试完成后，请编辑报告文件添加结果："
echo "   $REPORT_FILE"
echo ""

# ============== 添加设备日志收集提示 ==============
echo "💡 如需收集崩溃日志，运行："
echo "   adb logcat -d | grep -E 'GTalk|AndroidRuntime|FATAL' > crash_log.txt"
echo ""

# ============== 结束提示 ==============
cat >> "$REPORT_FILE" << 'EOF'

---

## 手动测试结果（请填写）

### A组：启动海报与登录
- [ ] A1. 启动海报显示 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] A2. 自动OIDC登录 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] A3. 认证后海报消失 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] A4. 欢迎页品牌文案 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] A5. 登录成功 - ✅通过 / ❌失败
  - 备注：_________________

### B组：微信风格聊天界面
- [ ] B1. 群聊他人消息 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] B2. 自己消息 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] B3. 私聊布局 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] B4. 特殊消息 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] B5. 交互 - ✅通过 / ❌失败
  - 备注：_________________

### D组：品牌一致性
- [ ] D1. 应用名称与图标 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] D2. 关键界面文案 - ✅通过 / ❌失败
  - 备注：_________________

### E组：核心业务
- [ ] E1. 收发消息 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] E2. 语音/视频通话 - ✅通过 / ❌失败 / ⏭跳过
  - 备注：_________________

### F组：兼容性
- [ ] F1. 深色/浅色模式 - ✅通过 / ❌失败
  - 备注：_________________
- [ ] F2. 横竖屏旋转 - ✅通过 / ❌失败
  - 备注：_________________

### K组：已知问题
- [ ] K1. 恢复密钥生成 - ✅符合预期失败 / ❌行为异常
  - 备注：_________________

---

## 新发现问题（如有）

| ID | 严重级 | 问题描述 | 复现步骤 |
|----|--------|----------|----------|
| #___ | P_ | | |

---

## 测试结论

- [ ] ✅ **通过** - 可发布
- [ ] ⚠️ **有条件通过** - 风险可接受，说明：_______________
- [ ] ❌ **不通过** - 阻断问题：_______________

**测试人签字**：_____________
**日期**：_____________

EOF

echo "✅ 自动化验证完成"
echo "📄 报告已保存到：$REPORT_FILE"
echo ""
echo "请在设备上完成手动验证项，并更新报告文件。"


