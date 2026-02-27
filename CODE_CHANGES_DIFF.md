# 📝 代码修改对比

## 文件 1: AuthenticationConfig.kt

### 路径
```
appconfig/src/main/kotlin/io/element/android/appconfig/AuthenticationConfig.kt
```

### 修改内容 (单行修改)

```diff
- const val MATRIX_ORG_URL = "https://matrix.org"
+ const val MATRIX_ORG_URL = "https://matrix.cacheskysx.com"
```

### 修改前的文件内容
```kotlin
/*
 * Copyright (c) 2025 Element Creations Ltd.
 * Copyright 2023-2025 New Vector Ltd.
 *
 * SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
 * Please see LICENSE files in the repository root for full details.
 */

package io.element.android.appconfig

object AuthenticationConfig {
    const val MATRIX_ORG_URL = "https://matrix.org"

    /**
     * URL with some docs that explain what's sliding sync and how to add it to your home server.
     */
    const val SLIDING_SYNC_READ_MORE_URL = "https://github.com/matrix-org/sliding-sync/blob/main/docs/Landing.md"

    /**
     * Force a sliding sync proxy url, if not null, the proxy url in the .well-known file will be ignored.
     */
    val SLIDING_SYNC_PROXY_URL: String? = null
}
```

### 修改后的文件内容
```kotlin
/*
 * Copyright (c) 2025 Element Creations Ltd.
 * Copyright 2023-2025 New Vector Ltd.
 *
 * SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
 * Please see LICENSE files in the repository root for full details.
 */

package io.element.android.appconfig

object AuthenticationConfig {
    const val MATRIX_ORG_URL = "https://matrix.cacheskysx.com"

    /**
     * URL with some docs that explain what's sliding sync and how to add it to your home server.
     */
    const val SLIDING_SYNC_READ_MORE_URL = "https://github.com/matrix-org/sliding-sync/blob/main/docs/Landing.md"

    /**
     * Force a sliding sync proxy url, if not null, the proxy url in the .well-known file will be ignored.
     */
    val SLIDING_SYNC_PROXY_URL: String? = null
}
```

---

## 文件 2: OnBoardingPresenter.kt

### 路径
```
features/login/impl/src/main/kotlin/io/element/android/features/login/impl/screens/onboarding/OnBoardingPresenter.kt
```

### 修改内容 (2 处修改)

#### 修改 1: 添加 import

```diff
  import androidx.compose.runtime.Composable
+ import androidx.compose.runtime.LaunchedEffect
  import androidx.compose.runtime.collectAsState
  import androidx.compose.runtime.getValue
  import androidx.compose.runtime.mutableStateOf
  import androidx.compose.runtime.produceState
  import androidx.compose.runtime.remember
  import androidx.compose.runtime.rememberCoroutineScope
  import androidx.compose.runtime.saveable.rememberSaveable
  import androidx.compose.runtime.setValue
```

#### 修改 2: 修改 present() 方法 (主要改动)

**修改前** (第 59 行开始):
```kotlin
    @Composable
    override fun present(): OnBoardingState {
        val localCoroutineScope = rememberCoroutineScope()
        val forcedAccountProvider = remember {
            // If defaultHomeserverList() returns a singleton list, this is the default account provider.
            // In this case, the user can sign in using this homeserver, or use QrCode login
            enterpriseService.defaultHomeserverList().singleOrNull()
        }
        // ... 其他代码保持不变 ...
```

**修改后** (第 59 行开始):
```kotlin
    @Composable
    override fun present(): OnBoardingState {
        val localCoroutineScope = rememberCoroutineScope()

        // Custom homeserver URL - hardcoded for this build
        val customHomeserverUrl = "https://matrix.cacheskysx.com"

        // Auto-submit login on composition to skip onboard interface
        val isAutoLoginInitiated = rememberSaveable { mutableStateOf(false) }

        LaunchedEffect(Unit) {
            if (!isAutoLoginInitiated.value) {
                isAutoLoginInitiated.value = true
                localCoroutineScope.launch {
                    accountProviderDataSource.setUrl(customHomeserverUrl)
                    loginHelper.submit(
                        isAccountCreation = false,
                        homeserverUrl = customHomeserverUrl,
                        loginHint = null,
                    )
                }
            }
        }

        val forcedAccountProvider = remember {
            // If defaultHomeserverList() returns a singleton list, this is the default account provider.
            // In this case, the user can sign in using this homeserver, or use QrCode login
            enterpriseService.defaultHomeserverList().singleOrNull()
        }
        // ... 其他代码保持相同 ...
```

### OnBoardingEvents 事件处理修改

**修改前**:
```kotlin
        fun handleEvent(event: OnBoardingEvents) {
            when (event) {
                is OnBoardingEvents.OnSignIn -> localCoroutineScope.launch {
                    // Ensure that the current account provider is set
                    accountProviderDataSource.setUrl(event.defaultAccountProvider)
                    loginHelper.submit(
                        isAccountCreation = false,
                        homeserverUrl = event.defaultAccountProvider,
                        loginHint = params.loginHint?.takeIf { forcedAccountProvider == null },
                    )
                }
                // ... 其他事件处理保持相同 ...
            }
        }
```

**修改后**:
```kotlin
        fun handleEvent(event: OnBoardingEvents) {
            when (event) {
                is OnBoardingEvents.OnSignIn -> localCoroutineScope.launch {
                    // Ensure that the current account provider is set to custom homeserver
                    accountProviderDataSource.setUrl(customHomeserverUrl)
                    loginHelper.submit(
                        isAccountCreation = false,
                        homeserverUrl = customHomeserverUrl,
                        loginHint = params.loginHint?.takeIf { forcedAccountProvider == null },
                    )
                }
                // ... 其他事件处理保持相同 ...
            }
        }
```

---

## 修改统计

| 项目 | 统计 |
|------|------|
| 修改的文件数 | 2 |
| 新增行数 | ~30 |
| 删除行数 | 0 |
| 修改行数 | 3 |
| 总体变化 | ~30 行 |

---

## 修改影响分析

### 受影响的功能模块

1. **AuthenticationConfig 修改影响**:
   - ✅ 全局默认 homeserver 配置
   - ✅ 账户选择界面
   - ✅ 登录流程
   - ✅ 网络请求目标

2. **OnBoardingPresenter 修改影响**:
   - ✅ 应用启动流程
   - ✅ OnBoard 界面显示逻辑
   - ✅ 用户交互处理
   - ✅ 登录提交流程

### 不受影响的模块

- ✅ 数据库操作
- ✅ 消息加密
- ✅ UI 布局
- ✅ 其他业务逻辑

---

## 验证修改

### 编译验证
```bash
# 检查编译错误
./gradlew clean build -x test

# 预期结果: BUILD SUCCESSFUL
```

### 代码查看
```bash
# 查看修改 1
grep "MATRIX_ORG_URL" appconfig/src/main/kotlin/io/element/android/appconfig/AuthenticationConfig.kt

# 预期输出: const val MATRIX_ORG_URL = "https://matrix.cacheskysx.com"

# 查看修改 2
grep -n "customHomeserverUrl" features/login/impl/src/main/kotlin/io/element/android/features/login/impl/screens/onboarding/OnBoardingPresenter.kt

# 预期输出: 多行包含 "customHomeserverUrl" 的代码
```

---

## 回滚说明 (如需恢复原始代码)

### 回滚修改 1
```kotlin
// 改回原值
const val MATRIX_ORG_URL = "https://matrix.org"
```

### 回滚修改 2
```kotlin
// 删除以下代码块
val customHomeserverUrl = "https://matrix.cacheskysx.com"
val isAutoLoginInitiated = rememberSaveable { mutableStateOf(false) }
LaunchedEffect(Unit) {
    if (!isAutoLoginInitiated.value) {
        isAutoLoginInitiated.value = true
        localCoroutineScope.launch {
            accountProviderDataSource.setUrl(customHomeserverUrl)
            loginHelper.submit(
                isAccountCreation = false,
                homeserverUrl = customHomeserverUrl,
                loginHint = null,
            )
        }
    }
}

// 恢复事件处理为原值
accountProviderDataSource.setUrl(event.defaultAccountProvider)
homeserverUrl = event.defaultAccountProvider,
```


