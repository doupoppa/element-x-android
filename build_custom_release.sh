#!/bin/bash

#
# Copyright (c) 2026 Element Creations Ltd.
#
# SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
# Please see LICENSE files in the repository root for full details.
#

# Element X Android - 快速编译脚本
# 用于编译带有自定义 homeserver 的签名版 APK

set -e

PROJECT_ROOT="/home/dou/StudioProjects/element-x-android"
cd "$PROJECT_ROOT"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Element X Android - 自定义 Homeserver 编译脚本        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 编译配置:"
echo "  • Homeserver: https://matrix.cacheskysx.com"
echo "  • 自动跳过 OnBoard 界面: ✓"
echo "  • 签名状态: 已签名"
echo "  • 构建类型: F-Droid Release"
echo ""

echo "⏳ 开始编译..."
echo ""

# 编译
./gradlew clean assembleFdroidRelease -x test --build-cache --configuration-cache --parallel

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    编译完成！                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 检查 APK 文件
APK_DIR="$PROJECT_ROOT/app/build/outputs/apk/fdroid/release"

if [ -d "$APK_DIR" ]; then
    echo "📦 生成的 APK 文件:"
    echo ""
    ls -lh "$APK_DIR"/app-fdroid-*-release.apk 2>/dev/null | awk '{printf "  %-50s %10s\n", $9, $5}' || echo "  未找到 APK 文件"
    echo ""
    echo "📍 完整路径: $APK_DIR"
    echo ""
    echo "✅ 推荐安装版本: app-fdroid-arm64-v8a-release.apk"
    echo "   (适用于大多数现代 Android 手机)"
    echo ""
    echo "💾 安装命令:"
    echo "   adb install -r \"$APK_DIR/app-fdroid-arm64-v8a-release.apk\""
else
    echo "❌ APK 输出目录不存在: $APK_DIR"
    echo "   编译可能失败，请检查编译日志"
fi

echo ""
echo "✨ 编译脚本执行完成"
echo ""

