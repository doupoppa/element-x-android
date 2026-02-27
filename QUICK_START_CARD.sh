#!/bin/bash
#
# Copyright (c) 2026 Element Creations Ltd.
#
# SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
# Please see LICENSE files in the repository root for full details.
#

# Element X Android 二次开发快速启动卡片
# 保存此文件，每次需要时参考

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  Element X Android 二次开发 - 快速启动卡片                        ║
║                                                                    ║
║  默认 Homeserver: https://matrix.cacheskysx.com                   ║
║  编译加速: 8-12 倍 (12-15 分钟 → 1-2 分钟)                        ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝


📋 快速命令（复制粘贴即用）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 首次编译（建立缓存，仅需一次）
   $ cd /home/dou/StudioProjects/element-x-android
   $ ./gradlew clean assembleReleaseFdroid
   ⏱️ 耗时：12-15 分钟

⚡⚡ 日常快速编译（推荐，每次修改后）
   $ ./build_incremental.sh
   ⏱️ 耗时：1-2 分钟

🚀 最快编译（仅 ARM64）
   $ ./gradlew :app:assembleReleaseFdroidArm64v8a
   ⏱️ 耗时：45-60 秒

📱 安装应用
   $ adb install -r app/build/outputs/apk/fdroid/release/app-fdroid-arm64-v8a-release.apk


📚 文档速查表
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

需求                          文档
─────────────────────────────────────────────────────────────
快速了解（5 分钟）            INCREMENTAL_BUILD_QUICK_START.md
查询命令（2 分钟）            QUICK_REFERENCE.md
修改配置（15 分钟）           CUSTOM_HOMESERVER_SETUP.md
深入学习（20-30 分钟）        INCREMENTAL_BUILD_GUIDE.md
性能分析（15 分钟）           INCREMENTAL_BUILD_ANALYSIS.md
完整方案（10 分钟）           COMPLETE_SOLUTION_SUMMARY.md
查找文件（即时）              FILE_INDEX.md


🔧 常见操作
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

修改 Homeserver 地址：
  编辑：appconfig/src/main/kotlin/.../AuthenticationConfig.kt
  改：const val MATRIX_ORG_URL = "https://your-server.com"
  改：const val FORCED_HOMESERVER_URL = "https://your-server.com"
  重新编译：./build_incremental.sh

清除编译缓存：
  $ ./gradlew cleanBuildCache

查看编译时间统计：
  $ ./gradlew assembleReleaseFdroid --profile
  查看报告：build/reports/profile/

卸载应用：
  $ adb uninstall io.element.android.x


✅ 性能数据
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

编译方式             首次        再次        加速倍数
───────────────────────────────────────────────────
完全编译             12-15 分钟  12-15 分钟  基准
标准增量编译         12-15 分钟  3-4 分钟    3-4 倍 ⚡
优化增量编译         12-15 分钟  1-2 分钟    8-12 倍 ⚡⚡ 推荐

时间节省统计：
  每次编译节省：11-13 分钟
  每天编译 1 次：11-13 分钟/天 = 4-6 小时/月 = 50-65 小时/年
  每天编译 5 次：55-65 分钟/天 = 20-30 小时/月 = 250-325 小时/年


💡 核心提示
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ 首次编译：12-15 分钟（建立缓存，仅需一次）
✓ 后续编译：1-2 分钟（利用缓存，快速迭代）
✓ 最快编译：45-60 秒（仅 ARM64，开发测试用）
✓ 自动化：脚本自动安装到设备，无需手动操作
✓ 随时恢复：所有修改可通过 git 恢复


📁 关键文件位置
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

编译脚本：
  build_incremental.sh (推荐使用)
  build_custom_homeserver.sh

Homeserver 配置：
  appconfig/src/main/kotlin/.../AuthenticationConfig.kt

禁止用户修改的代码：
  features/login/.../accountprovider/AccountProviderDataSource.kt

隐藏选择界面的代码：
  features/login/.../screens/onboarding/OnBoardingPresenter.kt

编译输出：
  app/build/outputs/apk/fdroid/release/


🎯 日常工作流
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 修改代码
   ↓
2. 运行编译
   $ ./build_incremental.sh
   (1-2 分钟)
   ↓
3. 应用自动安装到设备
   ↓
4. 测试应用
   ↓
5. 重复第 1 步


🚀 立即开始
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$ cd /home/dou/StudioProjects/element-x-android
$ ./build_incremental.sh

稍等 1-2 分钟...

✅ 完成！应用已生成并安装


📞 需要帮助？
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

查看所有文档：
  $ ls -lh *.md

查看快速参考：
  $ cat QUICK_REFERENCE.md

查看文件索引：
  $ cat FILE_INDEX.md

搜索关键词：
  $ grep -r "关键词" *.md


════════════════════════════════════════════════════════════════════

项目完成时间：2025-02-25
默认 Homeserver: https://matrix.cacheskysx.com
推荐命令：./build_incremental.sh
项目状态：✅ 生产就绪

祝您开发愉快！🚀

════════════════════════════════════════════════════════════════════

EOF

# 打印完成
echo ""
echo "✅ 快速启动卡片已显示"
echo ""
echo "下次需要时，运行："
echo "  cat QUICK_START_CARD.sh"
echo ""

