// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@file:Suppress("PackageName")

package com.example.android_engine_test.fixtures

import android.content.Context
import android.graphics.Color
import android.graphics.Paint
import android.view.SurfaceHolder
import android.view.SurfaceView // Changed from View
import android.view.View
import android.view.ViewGroup
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MyTestFactory : PlatformViewFactory(null) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView = MyTest(context)
}

private class MyTest(
    context: Context
) : SurfaceView(context), // Extend SurfaceView
    PlatformView,
    SurfaceHolder.Callback { // Implement Callback to listen for surface availability

    private val paintRed =
        Paint().apply {
            color = Color.RED
            style = Paint.Style.FILL
        }
    private val paintBlue =
        Paint().apply {
            color = Color.BLUE
            style = Paint.Style.FILL
        }

    private var isBlue = false

    init {
        layoutParams =
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )

        contentDescription = "Change color"

        // Register the callback to know when the surface is created
        holder.addCallback(this)

        setOnClickListener {
            isBlue = !isBlue
            drawSurface() // Manually trigger the draw routine
        }
    }

    // Helper function to handle SurfaceView drawing mechanics
    private fun drawSurface() {
        // Ensure the surface is valid before trying to draw
        if (holder.surface.isValid) {
            // 1. Lock the canvas
            val canvas = holder.lockCanvas()
            
            // 2. Perform drawing
            if (canvas != null) {
                canvas.drawColor(Color.WHITE) // Clear previous drawing (optional but recommended)
                canvas.drawRect(
                    0f, 
                    0f, 
                    width.toFloat(), 
                    height.toFloat(), 
                    if (isBlue) paintBlue else paintRed
                )
                
                // 3. Unlock and post the canvas to display it
                holder.unlockCanvasAndPost(canvas)
            }
        }
    }

    override fun getView(): View = this

    override fun dispose() {
        // Clean up callbacks to prevent memory leaks
        holder.removeCallback(this)
    }

    // --- SurfaceHolder.Callback Implementation ---

    override fun surfaceCreated(holder: SurfaceHolder) {
        // The surface is ready, perform the initial draw
        drawSurface()
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        // If dimensions change, redraw to fit new bounds
        drawSurface()
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        // Surface is gone, stop any active rendering threads here if you had them
    }
}

