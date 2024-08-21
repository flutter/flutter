package com.example.android_driver_test

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.view.View
import io.flutter.plugin.platform.PlatformView

class BlueRectanglePlatformView(context: Context) : PlatformView {
    private val blueRectangleView = BlueRectangleView(context)

    override fun getView(): View {
        return blueRectangleView
    }

    override fun dispose() {}

    private class BlueRectangleView(context: Context) : View(context) {
        private val paint = Paint().apply() {
            color = Color.BLUE
            style = Paint.Style.FILL
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        }
    }
}