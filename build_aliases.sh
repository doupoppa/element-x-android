#!/bin/bash

#
# Copyright (c) 2026 Element Creations Ltd.
#
# SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
# Please see LICENSE files in the repository root for full details.
#

# Element X Android - Shell 别名和快捷方式配置
# 将此文件添加到您的 ~/.bashrc 或 ~/.zshrc
# 使用方法: source build_aliases.sh

# 项目目录
PROJECT_DIR="/home/dou/StudioProjects/element-x-android"

# ===== 编译别名 =====

# 快速编译 (默认，推荐)
alias build="cd $PROJECT_DIR && ./fast_build.sh"
alias b="cd $PROJECT_DIR && ./fast_build.sh"

# 超快速编译
alias build-ultra="cd $PROJECT_DIR && ./super_fast_build.sh"
alias bu="cd $PROJECT_DIR && ./super_fast_build.sh"

# 完整编译 (发布前)
alias build-clean="cd $PROJECT_DIR && ./gradlew clean assembleFdroidRelease -x test"
alias bc="cd $PROJECT_DIR && ./gradlew clean assembleFdroidRelease -x test"

# 清除缓存
alias build-cache-clean="rm -rf ~/.gradle/caches/build-cache-* && echo '✅ 缓存已清除'"
alias bcc="rm -rf ~/.gradle/caches/build-cache-* && echo '✅ 缓存已清除'"

# 进入项目目录
alias elem="cd $PROJECT_DIR"
alias ep="cd $PROJECT_DIR"

# ===== 使用说明 =====

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Element X Android - 编译别名已加载                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📝 可用命令:"
echo ""
echo "  编译命令:"
echo "    build          - 快速优化编译 (推荐) [2-5 分钟]"
echo "    b              - 同上 (快捷方式)"
echo "    build-ultra    - 超快速编译 [2-4 分钟]"
echo "    bu             - 同上 (快捷方式)"
echo "    build-clean    - 完整编译 [15-20 分钟]"
echo "    bc             - 同上 (快捷方式)"
echo ""
echo "  缓存管理:"
echo "    build-cache-clean - 清除编译缓存"
echo "    bcc                - 同上 (快捷方式)"
echo ""
echo "  项目导航:"
echo "    elem           - 进入项目目录"
echo "    ep             - 同上 (快捷方式)"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"

