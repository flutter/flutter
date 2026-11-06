// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@file:Suppress("PackageName")

package com.example.android_engine_test.fixtures

import android.content.Context
import android.view.View
import android.view.ViewGroup
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalView
import androidx.lifecycle.findViewTreeViewModelStoreOwner
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class ComposePlatformViewFactory : PlatformViewFactory(null) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView = ComposePlatformView(context)
}

private class ComposePlatformView(
    context: Context
) : PlatformView {
    private val composeView =
        ComposeView(context).apply {
            layoutParams =
                ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            contentDescription = "Change color"
            setContent {
                ComposePlatformViewContent()
            }
        }

    override fun getView(): View = composeView

    override fun dispose() {}
}

@Composable
internal fun ComposePlatformViewContent() {
    checkNotNull(LocalView.current.findViewTreeViewModelStoreOwner()) {
        "ViewTreeViewModelStoreOwner not found from LocalView"
    }
    var isToggled by rememberSaveable { mutableStateOf(false) }
    val interactionSource = remember { MutableInteractionSource() }

    Column(
        modifier =
            Modifier
                .fillMaxSize()
                .clickable(
                    interactionSource = interactionSource,
                    indication = null
                ) {
                    isToggled = !isToggled
                }
    ) {
        Box(
            modifier =
                Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .background(if (isToggled) Color.Blue else Color.Red)
        )
        Box(
            modifier =
                Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .background(if (isToggled) Color.Red else Color.Blue)
        )
    }
}
