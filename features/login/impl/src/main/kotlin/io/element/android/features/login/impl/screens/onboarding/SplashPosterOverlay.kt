/*
 * Copyright (c) 2026 Element Creations Ltd.
 *
 * SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
 * Please see LICENSE files in the repository root for full details.
 */

package io.element.android.features.login.impl.screens.onboarding

import androidx.annotation.DrawableRes
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.element.android.libraries.designsystem.preview.ElementPreview
import io.element.android.libraries.designsystem.preview.PreviewsDayNight
import kotlinx.coroutines.delay

// WeChat-green color palette from HTML design
private val DarkGreen1 = Color(0xFF0D1F15)
private val DarkGreen2 = Color(0xFF051208)
private val DarkGreen3 = Color(0xFF020804)
private val WeChatGreen = Color(0xFF07C160)
private val WeChatGreenDark = Color(0xFF05A350)
private val LightGreen = Color(0xFF86EFAC)
private val TextWhite = Color(0xFFF0FDF4)

/**
 * Full-screen splash poster overlay, styled after WeChat's launch screen.
 * Translates the HTML/CSS design to native Compose with matching animations.
 *
 * @param onBoardingLogoResId The drawable resource ID for the app logo (nullable).
 * @param modifier Optional Modifier.
 */
@Composable
fun SplashPosterOverlay(
    @DrawableRes onBoardingLogoResId: Int?,
    modifier: Modifier = Modifier,
) {
    // --- Animations ---

    val infiniteTransition = rememberInfiniteTransition(label = "splash")

    // Float animation for logo (translateY -10dp to 0dp, 3s period)
    val floatOffset by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = -10f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "logoFloat"
    )

    // Shimmer animation for logo gloss effect (0f to 1f, 3s)
    val shimmerProgress by infiniteTransition.animateFloat(
        initialValue = -1f,
        targetValue = 2f,
        animationSpec = infiniteRepeatable(
            animation = tween(3000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart,
        ),
        label = "shimmer"
    )

    // Fade-in animation
    var visible by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { visible = true }
    val alpha by animateFloatAsState(
        targetValue = if (visible) 1f else 0f,
        animationSpec = tween(600),
        label = "fadeIn"
    )

    // Delayed animations for content elements
    var showTitle by remember { mutableStateOf(false) }
    var showDivider by remember { mutableStateOf(false) }
    var showFooter by remember { mutableStateOf(false) }
    var showLoader by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(200)
        showTitle = true
        delay(200)
        showDivider = true
        delay(200)
        showFooter = true
        delay(100)
        showLoader = true
    }
    val titleAlpha by animateFloatAsState(
        targetValue = if (showTitle) 1f else 0f,
        animationSpec = tween(800),
        label = "titleFade"
    )
    val titleOffset by animateFloatAsState(
        targetValue = if (showTitle) 0f else 20f,
        animationSpec = tween(800),
        label = "titleSlide"
    )
    val dividerWidth by animateFloatAsState(
        targetValue = if (showDivider) 40f else 0f,
        animationSpec = tween(1000),
        label = "dividerExpand"
    )
    val footerAlpha by animateFloatAsState(
        targetValue = if (showFooter) 0.9f else 0f,
        animationSpec = tween(800),
        label = "footerFade"
    )
    val loaderAlpha by animateFloatAsState(
        targetValue = if (showLoader) 1f else 0f,
        animationSpec = tween(300),
        label = "loaderFade"
    )

    // --- Layout ---
    Box(
        modifier = modifier
            .fillMaxSize()
            .graphicsLayer { this.alpha = alpha }
            .background(
                Brush.verticalGradient(
                    colors = listOf(DarkGreen1, DarkGreen2, DarkGreen3),
                    startY = 0f,
                    endY = Float.POSITIVE_INFINITY,
                )
            ),
    ) {
        // Background radial glow (WeChat green)
        Canvas(
            modifier = Modifier
                .size(600.dp)
                .align(Alignment.TopCenter)
                .offset(y = (-60).dp)
        ) {
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        WeChatGreen.copy(alpha = 0.06f),
                        Color.Transparent,
                    ),
                    center = Offset(size.width / 2, size.height * 0.6f),
                    radius = size.width / 2,
                ),
                radius = size.width / 2,
                center = Offset(size.width / 2, size.height * 0.6f),
            )
        }

        // Center content: Logo + Title + Divider
        Column(
            modifier = Modifier.align(Alignment.Center),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // Logo container with float animation
            Box(
                modifier = Modifier
                    .offset { IntOffset(0, floatOffset.dp.roundToPx()) }
                    .size(120.dp)
                    .clip(RoundedCornerShape(28.dp))
                    .background(
                        Brush.linearGradient(
                            colors = listOf(WeChatGreen, WeChatGreenDark),
                            start = Offset(0f, 0f),
                            end = Offset(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY),
                        )
                    ),
                contentAlignment = Alignment.Center,
            ) {
                // Shimmer gloss overlay
                Canvas(modifier = Modifier.fillMaxSize()) {
                    val shimmerX = shimmerProgress * size.width * 2 - size.width
                    drawRect(
                        brush = Brush.linearGradient(
                            colors = listOf(
                                Color.Transparent,
                                Color.White.copy(alpha = 0.15f),
                                Color.Transparent,
                            ),
                            start = Offset(shimmerX - size.width * 0.3f, 0f),
                            end = Offset(shimmerX + size.width * 0.3f, size.height),
                        )
                    )
                }

                // Logo image or fallback "G" text
                if (onBoardingLogoResId != null) {
                    Image(
                        painter = painterResource(id = onBoardingLogoResId),
                        contentDescription = "GTalk",
                        modifier = Modifier
                            .size(100.dp)
                            .clip(RoundedCornerShape(20.dp)),
                        contentScale = ContentScale.Fit,
                    )
                } else {
                    Text(
                        text = "G",
                        fontSize = 48.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        textAlign = TextAlign.Center,
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // App name "G T a l k" with slide-up + fade-in
            Text(
                text = "G T a l k",
                fontSize = 42.sp,
                fontWeight = FontWeight.Light,
                color = TextWhite,
                letterSpacing = 8.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .graphicsLayer {
                        this.alpha = titleAlpha
                        translationY = titleOffset
                    }
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Decorative divider line (WeChat green gradient, expanding)
            Box(
                modifier = Modifier
                    .width(dividerWidth.dp)
                    .height(2.dp)
                    .background(
                        Brush.horizontalGradient(
                            colors = listOf(
                                Color.Transparent,
                                WeChatGreen.copy(alpha = 0.6f),
                                Color.Transparent,
                            )
                        )
                    )
            )
        }

        // Loading indicator (above footer)
        CircularProgressIndicator(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 120.dp)
                .size(24.dp)
                .graphicsLayer { this.alpha = loaderAlpha },
            color = WeChatGreen,
            strokeWidth = 2.dp,
        )

        // Footer: "G9集团 · 安全通讯"
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 60.dp)
                .graphicsLayer { this.alpha = footerAlpha },
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
        ) {
            Text(
                text = "G9集团",
                fontSize = 14.sp,
                fontWeight = FontWeight.Normal,
                color = LightGreen,
                letterSpacing = 4.sp,
            )
            Spacer(modifier = Modifier.width(8.dp))
            // Green dot
            Box(
                modifier = Modifier
                    .size(4.dp)
                    .clip(CircleShape)
                    .background(WeChatGreen)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "安全通讯",
                fontSize = 14.sp,
                fontWeight = FontWeight.Normal,
                color = LightGreen,
                letterSpacing = 4.sp,
            )
        }
    }
}

@PreviewsDayNight
@Composable
internal fun SplashPosterOverlayPreview() = ElementPreview {
    SplashPosterOverlay(onBoardingLogoResId = null)
}

