@file:Suppress("PackageName")

package com.example.android_hardware_smoke_test

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.widget.TextView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class NativeTextViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        val creationParams = args as? Map<String, Any?>
        return NativeTextView(context, viewId, creationParams)
    }
}

class NativeTextView(
    context: Context,
    id: Int,
    creationParams: Map<String, Any?>?
) : PlatformView {
    private val textView: TextView =
        TextView(context).apply {
            textSize = 22f
            gravity = Gravity.CENTER
            setBackgroundColor(Color.rgb(100, 200, 255)) // Light blue background
            text = creationParams?.get("text") as String? ?: "Default Native Text"
            setTextColor(Color.BLACK)
        }

    override fun getView(): View = textView

    override fun dispose() {}
}
