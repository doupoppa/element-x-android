#!/bin/bash

#
# Copyright (c) 2026 Element Creations Ltd.
#
# SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
# Please see LICENSE files in the repository root for full details.
#

# Element X Android - 超快速增量编译脚本 (仅 Fdroid Release)
# 专为快速迭代开发而优化
# 特点: 最小化编译 + 最大化缓存 + 并行度最大

set -e

PROJECT_ROOT="/home/dou/StudioProjects/element-x-android"
cd "$PROJECT_ROOT"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     🚀 超快速增量编译 (Fdroid Release 仅)              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 配置变量
FDROID_RELEASE_DIR="$PROJECT_ROOT/app/build/outputs/apk/fdroid/release"
MAX_WORKERS=$(nproc)
JVM_MEMORY="4g"

# 删除旧 APK
echo "🗑️  清除旧 APK..."
rm -f "$FDROID_RELEASE_DIR"/*.apk 2>/dev/null || true

# 显示编译信息
echo "⚙️  编译配置:"
echo "  • 并行工作线程: $MAX_WORKERS"
echo "  • JVM 内存: $JVM_MEMORY"
echo "  • Gradle 缓存: 启用"
echo "  • 配置缓存: 启用"
echo "  • Kotlin 增量: 启用"
echo ""

echo "📝 编译命令:"
echo "  ./gradlew assembleFdroidRelease -x test \\"
echo "    --build-cache --configuration-cache \\"
echo "    --max-workers=$MAX_WORKERS --no-daemon"
echo ""

echo "⏳ 编译中..."
echo ""

START=$(date +%s)

# 优化的编译命令
./gradlew assembleFdroidRelease \
    -x test \
    --build-cache \
    --configuration-cache \
    --parallel \
    --max-workers=$MAX_WORKERS \
    --no-daemon \
    -Dkotlin.incremental=true \
    -Dkotlin.compiler.execution.strategy=daemon \
    -Dorg.gradle.jvmargs="-Xmx$JVM_MEMORY" 2>&1 | tee /tmp/build.log

BUILD_EXIT=$?

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo "══════════════════════════════════════════════════════════"

if [ $BUILD_EXIT -eq 0 ] && [ -f "$FDROID_RELEASE_DIR/app-fdroid-arm64-v8a-release.apk" ]; then
    MIN=$((DURATION / 60))
    SEC=$((DURATION % 60))

    echo "✅ 编译成功! (耗时: ${MIN}分${SEC}秒)"
    echo ""
    echo "📦 生成的 APK:"
    ls -lh "$FDROID_RELEASE_DIR"/*.apk | awk '{printf "  %s (%s)\n", $(NF), $(NF-4)}'
    echo ""
    echo "📱 安装命令:"
    echo "  adb install -r \"$FDROID_RELEASE_DIR/app-fdroid-arm64-v8a-release.apk\""
else
    MIN=$((DURATION / 60))
    SEC=$((DURATION % 60))
    echo "❌ 编译失败! (耗时: ${MIN}分${SEC}秒)"
    echo ""
    echo "📋 最后 50 行输出:"
    tail -50 /tmp/build.log
fi

echo "══════════════════════════════════════════════════════════"
exit $BUILD_EXIT

