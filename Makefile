# Build 目标 - Element X Android 快速编译 Makefile
# 使用方法: make build (默认使用优化编译)

.PHONY: build
build: fast-build

.PHONY: fast-build
fast-build:
	@echo "🚀 执行快速优化编译..."
	@./fast_build.sh

.PHONY: ultra-build
ultra-build:
	@echo "⚡ 执行超快速编译..."
	@./super_fast_build.sh

.PHONY: clean-build
clean-build:
	@echo "🔄 执行完整重编译..."
	@./gradlew clean assembleFdroidRelease -x test

.PHONY: clear-cache
clear-cache:
	@echo "🗑️  清除 Gradle 缓存..."
	@rm -rf ~/.gradle/caches/build-cache-*
	@echo "✅ 缓存已清除"

.PHONY: help
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Element X Android - 快速编译 Makefile"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "常用命令:"
	@echo ""
	@echo "  make              - 快速编译 (推荐) 耗时: 2-5 分钟"
	@echo "  make fast-build   - 快速编译"
	@echo "  make ultra-build  - 超快速编译   耗时: 2-4 分钟"
	@echo "  make clean-build  - 完整编译     耗时: 15-20 分钟"
	@echo "  make clear-cache  - 清除缓存"
	@echo "  make help         - 显示此帮助"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

.DEFAULT_GOAL := build

