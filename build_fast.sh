#!/bin/bash
# ============================================================
# 快速编译脚本 - 开发阶段使用
#
# 优化策略：
#   1. 使用 Gradle Daemon（增量编译 + JVM 热缓存）
#   2. 跳过 R8 混淆（通过 gradle.properties dev.fast.build=true）
#   3. 跳过 lint 检查（通过 gradle 配置自动禁用）
#   4. 跳过测试
#   5. 利用 build-cache + configuration-cache 加速
#
# 用法：
#   ./build_fast.sh          # 快速增量编译
#   ./build_fast.sh clean    # 清理后重新编译
#   ./build_fast.sh install  # 编译并安装到设备
#   ./build_fast.sh release  # 正式发布版（启用R8+lint）
# ============================================================

set -e

cd "$(dirname "$0")"

# 清理旧 APK
rm -f app/build/outputs/apk/fdroid/release/*.apk 2>/dev/null

echo "============================================"
echo "  Element X - 快速编译"
echo "  $(date)"
echo "============================================"

START_TIME=$(date +%s)

# 通用快速编译参数（R8和lint已在gradle配置中通过dev.fast.build控制）
FAST_ARGS="-x test -x lint --stacktrace"

if [ "$1" = "clean" ]; then
    echo "[1/2] 清理..."
    rm -rf .gradle/configuration-cache
    ./gradlew clean 2>&1 | tail -5
    echo "[2/2] 编译中..."
    ./gradlew assembleFdroidRelease $FAST_ARGS \
        2>&1 | tee /tmp/fdroid_build.log | grep -E "^(> Task :app:|BUILD|FAILED)" || true

elif [ "$1" = "install" ]; then
    echo "[1/2] 编译中..."
    ./gradlew assembleFdroidRelease $FAST_ARGS \
        2>&1 | tee /tmp/fdroid_build.log | grep -E "^(> Task :app:|BUILD|FAILED)" || true

    echo "[2/2] 安装到设备..."
    APK=$(find app/build/outputs/apk/fdroid/release -name "*arm64*release*.apk" 2>/dev/null | head -1)
    if [ -n "$APK" ]; then
        adb install -r "$APK"
        echo "已安装: $APK"
    else
        echo "未找到 APK 文件"
        exit 1
    fi

elif [ "$1" = "release" ]; then
    echo "正式发布版编译（启用 R8 + lint）"
    echo "这将花费较长时间..."
    rm -rf .gradle/configuration-cache
    ./gradlew assembleFdroidRelease \
        -x test --stacktrace \
        -Pdev.fast.build=false \
        2>&1 | tee /tmp/fdroid_build.log | grep -E "^(> Task :app:|BUILD|FAILED)" || true

else
    echo "编译中（增量模式）..."
    ./gradlew assembleFdroidRelease $FAST_ARGS \
        2>&1 | tee /tmp/fdroid_build.log | grep -E "^(> Task :app:|BUILD|FAILED)" || true
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo ""
echo "============================================"

# 检查结果
if grep -q "BUILD SUCCESSFUL" /tmp/fdroid_build.log; then
    echo "  编译成功! 耗时: ${MINUTES}分${SECONDS}秒"
    echo ""
    echo "  生成的 APK:"
    find app/build/outputs/apk/fdroid/release -name "*.apk" -exec ls -lh {} \; 2>/dev/null
else
    echo "  编译失败! 耗时: ${MINUTES}分${SECONDS}秒"
    echo ""
    echo "  错误信息:"
    grep -A5 "What went wrong" /tmp/fdroid_build.log | head -20
fi

echo "============================================"
echo "  完整日志: /tmp/fdroid_build.log"
echo "============================================"



