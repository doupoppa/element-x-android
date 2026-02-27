#!/bin/bash

#
# Copyright (c) 2026 Element Creations Ltd.
#
# SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
# Please see LICENSE files in the repository root for full details.
#

# Element X Android - 快速增量编译脚本
# 优化点: 删除旧APK + 增量编译 + 并行构建 + 缓存利用
# 只生成签名版 Fdroid Release APK

set -e

PROJECT_ROOT="/home/dou/StudioProjects/element-x-android"
cd "$PROJECT_ROOT"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Element X Android - 快速增量编译脚本              ║"
echo "║  (仅 Fdroid Release + 增量编译 + 自动清理旧APK)          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 步骤 1: 删除旧的 APK 文件
echo "📦 第 1 步: 删除旧的 APK 文件..."
FDROID_RELEASE_DIR="$PROJECT_ROOT/app/build/outputs/apk/fdroid/release"
if [ -d "$FDROID_RELEASE_DIR" ]; then
    OLD_APK_COUNT=$(ls "$FDROID_RELEASE_DIR"/*.apk 2>/dev/null | wc -l)
    if [ $OLD_APK_COUNT -gt 0 ]; then
        echo "  删除 $OLD_APK_COUNT 个旧 APK 文件..."
        rm -f "$FDROID_RELEASE_DIR"/*.apk
        echo "  ✅ 旧 APK 已清除"
    else
        echo "  ℹ️  没有找到旧 APK 文件"
    fi
fi
echo ""

# 步骤 2: 显示编译配置
echo "⚙️  第 2 步: 编译配置"
echo "  Homeserver: https://matrix.cacheskysx.com"
echo "  自动跳过 OnBoard: ✅"
echo "  构建类型: Fdroid Release (签名版)"
echo "  增量编译: ✅ 启用"
echo "  Gradle 缓存: ✅ 启用"
echo "  配置缓存: ✅ 启用"
echo "  并行构建: ✅ 启用"
echo "  JVM 内存: 4GB"
echo ""

# 步骤 3: 执行增量编译
echo "🚀 第 3 步: 启动增量编译..."
echo "  命令: ./gradlew assembleFdroidRelease -x test"
echo "        --build-cache --configuration-cache --parallel"
echo "        --no-daemon -Dkotlin.incremental=true"
echo ""

START_TIME=$(date +%s)

# 执行编译
./gradlew assembleFdroidRelease \
    -x test \
    --build-cache \
    --configuration-cache \
    --parallel \
    --no-daemon \
    -Dkotlin.incremental=true \
    -Dkotlin.compiler.execution.strategy=daemon

BUILD_RESULT=$?

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_MIN=$((DURATION / 60))
DURATION_SEC=$((DURATION % 60))

echo ""
echo "═══════════════════════════════════════════════════════════"

if [ $BUILD_RESULT -eq 0 ]; then
    echo "✅ 编译成功！"
    echo "⏱️  编译耗时: ${DURATION_MIN}分 ${DURATION_SEC}秒"
    echo ""

    # 检查 APK 文件
    echo "📦 生成的 APK 文件:"
    echo ""
    if [ -d "$FDROID_RELEASE_DIR" ]; then
        ls -lh "$FDROID_RELEASE_DIR"/*.apk 2>/dev/null | awk '{
            name = $9
            size = $5
            gsub(/.*\//, "", name)
            printf "  %-50s %10s\n", name, size
        }' || echo "  ⚠️ 未找到 APK 文件"

        APK_COUNT=$(ls "$FDROID_RELEASE_DIR"/*.apk 2>/dev/null | wc -l)
        echo ""
        echo "✨ 总计: $APK_COUNT 个 APK 文件"
        echo ""

        # 推荐安装信息
        if [ -f "$FDROID_RELEASE_DIR/app-fdroid-arm64-v8a-release.apk" ]; then
            RECOMMENDED_APK="$FDROID_RELEASE_DIR/app-fdroid-arm64-v8a-release.apk"
            APK_SIZE=$(ls -lh "$RECOMMENDED_APK" | awk '{print $5}')
            echo "📱 推荐安装版本:"
            echo "  app-fdroid-arm64-v8a-release.apk ($APK_SIZE)"
            echo ""
            echo "💾 安装命令:"
            echo "  adb install -r \"$RECOMMENDED_APK\""
        fi
    fi
else
    echo "❌ 编译失败！"
    echo "⏱️  编译耗时: ${DURATION_MIN}分 ${DURATION_SEC}秒"
    echo ""
    echo "🔍 故障排查步骤:"
    echo "  1. 查看编译错误信息 (通常在上面的输出中)"
    echo "  2. 检查修改的源代码是否有语法错误"
    echo "  3. 尝试运行完整编译: ./gradlew clean assembleFdroidRelease -x test"
    echo "  4. 检查网络连接和 Gradle 缓存"
fi

echo "═══════════════════════════════════════════════════════════"
echo ""

exit $BUILD_RESULT

