#!/bin/bash

#
# Copyright (c) 2026 Element Creations Ltd.
#
# SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
# Please see LICENSE files in the repository root for full details.
#

# GTalk - 增量编译脚本（仅编译改动部分）
# 用途：快速编译签名的 F-Droid Release APK，节省编译时间

set -e  # 任何错误都会退出脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_OUTPUT="$PROJECT_DIR/app/build/outputs/apk/fdroid/release"

echo -e "${BLUE}╔═════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  GTalk - 增量编译脚本                                       ║${NC}"
echo -e "${BLUE}║  仅编译改动部分，与原编译产物链接                         ║${NC}"
echo -e "${BLUE}╠═════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Homeserver: https://matrix.cacheskysx.com                 ║${NC}"
echo -e "${BLUE}║  Build Type: F-Droid Release (Incremental)                 ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 配置项
ENABLE_INCREMENTAL=true
ENABLE_CACHE=true
ENABLE_PARALLEL=true
ENABLE_CONFIG_CACHE=true
GRADLE_OPTS="-Xmx4g -XX:+UseG1GC"
BUILD_VARIANT="FdroidRelease"

# 记录编译时间
START_TIME=$(date +%s)

echo -e "${CYAN}📋 编译配置：${NC}"
echo "  增量编译: $ENABLE_INCREMENTAL"
echo "  Gradle 缓存: $ENABLE_CACHE"
echo "  并行构建: $ENABLE_PARALLEL"
echo "  配置缓存: $ENABLE_CONFIG_CACHE"
echo "  JVM 内存: 4GB (G1GC)"
echo ""

# 检查 Java
if ! command -v java &> /dev/null; then
    echo -e "${RED}✗ 错误：Java 未安装${NC}"
    exit 1
fi

# 检查 gradlew
if [ ! -f "$PROJECT_DIR/gradlew" ]; then
    echo -e "${RED}✗ 错误：gradlew 不存在${NC}"
    exit 1
fi

# 显示修改的文件
echo -e "${CYAN}📝 检测修改的文件：${NC}"
modified_files=$(git diff --name-only 2>/dev/null || echo "无版本控制")
if [ "$modified_files" != "无版本控制" ]; then
    # 只显示源代码的修改
    echo "$modified_files" | grep -E '\.(kt|java|xml)$' | head -10
    file_count=$(echo "$modified_files" | grep -E '\.(kt|java|xml)$' | wc -l)
    echo "  ... 共 $file_count 个文件修改"
else
    echo "  (使用 git status 获取详细信息)"
fi
echo ""

# Step 1: 验证编译环境
echo -e "${YELLOW}[1/4] 验证编译环境...${NC}"
java_version=$(java -version 2>&1 | head -1)
echo "  Java: $java_version"

gradle_version=$(./gradlew --version 2>&1 | head -1)
echo "  Gradle: $gradle_version"
echo ""

# Step 2: 增量编译（不清理缓存）
echo -e "${YELLOW}[2/4] 执行增量编译...${NC}"
echo "  启用选项:"
echo "    • 增量编译 (kotlin.incremental=true)"
echo "    • Gradle 缓存 (org.gradle.caching=true)"
echo "    • 配置缓存 (org.gradle.configuration-cache=true)"
echo "    • 并行构建 (org.gradle.parallel=true)"
echo ""

export GRADLE_OPTS="$GRADLE_OPTS"

# 构建命令
BUILD_CMD="./gradlew"
BUILD_CMD="$BUILD_CMD --build-cache"
BUILD_CMD="$BUILD_CMD --configuration-cache"
BUILD_CMD="$BUILD_CMD --parallel"
BUILD_CMD="$BUILD_CMD assemble${BUILD_VARIANT}"

echo -e "${CYAN}执行命令：${NC}"
echo "  $BUILD_CMD"
echo ""

# 执行编译
if $BUILD_CMD; then
    echo -e "${GREEN}✓ 编译成功${NC}"
else
    echo -e "${RED}✗ 编译失败${NC}"
    echo ""
    echo -e "${YELLOW}💡 如果增量编译失败，尝试完全重新编译：${NC}"
    echo "  ./gradlew clean assemble${BUILD_VARIANT}"
    exit 1
fi
echo ""

# Step 3: 验证输出
echo -e "${YELLOW}[3/4] 验证编译产物...${NC}"
if [ ! -d "$BUILD_OUTPUT" ]; then
    echo -e "${RED}✗ 错误：输出目录不存在${NC}"
    exit 1
fi

apk_count=$(find "$BUILD_OUTPUT" -name "*.apk" 2>/dev/null | wc -l)
if [ "$apk_count" -eq 0 ]; then
    echo -e "${RED}✗ 错误：未找到 APK 文件${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 找到 $apk_count 个 APK 文件${NC}"
echo ""

# Step 4: 显示编译结果
echo -e "${YELLOW}[4/4] 编译结果${NC}"
echo -e "${BLUE}各架构 APK 文件：${NC}"

declare -a archs=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
for arch in "${archs[@]}"; do
    apk_file="$BUILD_OUTPUT/app-fdroid-${arch}-release.apk"
    if [ -f "$apk_file" ]; then
        size=$(du -h "$apk_file" | cut -f1)
        timestamp=$(date -r "$apk_file" '+%H:%M:%S')
        echo -e "  ${GREEN}✓${NC} $arch: $size (编译于 $timestamp)"
    fi
done
echo ""

# 计算编译时间
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo -e "${GREEN}╔═════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ 增量编译完成！                                         ║${NC}"
echo -e "${GREEN}╠═════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  编译耗时: ${MINUTES}分${SECONDS}秒                                      ║${NC}"
echo -e "${GREEN}║  输出目录: app/build/outputs/apk/fdroid/release/           ║${NC}"
echo -e "${GREEN}╚═════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 显示安装命令
echo -e "${CYAN}📱 安装到设备：${NC}"
echo "  adb install -r $BUILD_OUTPUT/app-fdroid-arm64-v8a-release.apk"
echo ""

# 自动安装选项
if command -v adb &> /dev/null; then
    devices=$(adb devices -l 2>/dev/null | grep -c "device$" || echo 0)
    if [ "$devices" -gt 0 ]; then
        echo -e "${YELLOW}检测到已连接的设备，是否立即安装？(y/n)${NC}"
        read -r -t 10 -n 1 response || response="n"
        echo ""

        if [[ "$response" =~ ^[Yy]$ ]]; then
            if [ -f "$BUILD_OUTPUT/app-fdroid-arm64-v8a-release.apk" ]; then
                echo -e "${YELLOW}正在安装 arm64-v8a 版本...${NC}"
                if adb install -r "$BUILD_OUTPUT/app-fdroid-arm64-v8a-release.apk"; then
                    echo -e "${GREEN}✓ 安装成功！${NC}"
                else
                    echo -e "${RED}✗ 安装失败${NC}"
                fi
            fi
        fi
    fi
fi

echo ""
echo -e "${CYAN}💡 增量编译优化技巧：${NC}"
echo "  1. 首次编译会稍长，但之后会快很多"
echo "  2. 修改同一个文件多次时，增量编译效果最佳"
echo "  3. 如果遇到问题，运行：./gradlew clean assemble${BUILD_VARIANT}"
echo "  4. 查看缓存统计：./gradlew --build-cache --info 2>&1 | grep -i cache"
echo ""

exit 0

