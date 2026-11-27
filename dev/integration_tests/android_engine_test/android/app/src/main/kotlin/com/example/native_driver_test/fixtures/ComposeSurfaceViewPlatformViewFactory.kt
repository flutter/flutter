// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@file:Suppress("PackageName")

package com.example.android_engine_test.fixtures

import android.content.Context
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.compose.ui.platform.ComposeView
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class ComposeSurfaceViewPlatformViewFactory : PlatformViewFactory(null) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView = ComposeSurfaceViewPlatformView(context)
}

private class ComposeSurfaceViewPlatformView(
    context: Context
) : FrameLayout(context),
    PlatformView {
    init {
        layoutParams =
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        // A SurfaceView child forces PlatformViewsController.createForTextureLayer to fall back
        // to Virtual Display mode. Keep it GONE so only the ComposeView renders into the display.
        addView(
            SurfaceView(context).apply {
                visibility = View.GONE
            },
            LayoutParams(0, 0)
        )
        addView(
            ComposeView(context).apply {
                contentDescription = "Change color"
                setContent {
                    ComposePlatformViewContent()
                }
            },
            LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )
    }

    override fun getView(): View = this

    override fun dispose() {}
}
