@file:Suppress("PackageName")

package com.example.android_hardware_smoke_test

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.widget.TextView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** A TextView subclass that supports observing when it is drawn. */
class ObservableTextView(
    context: Context
) : TextView(context) {
    /** Callback invoked when the view is painted. */
    var onDrawn: (() -> Unit)? = null

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        onDrawn?.invoke()
    }
}

/** Factory for creating [NativeTextView] platform views. */
class NativeTextViewFactory(
    private val onDrawCallback: () -> Unit
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        val creationParams = (args as? Map<*, *>)?.mapKeys { it.key as? String ?: "" }
        return NativeTextView(context, viewId, creationParams, onDrawCallback)
    }
}

/** A [PlatformView] that wraps an [ObservableTextView]. */
class NativeTextView(
    context: Context,
    id: Int,
    creationParams: Map<String, Any?>?,
    private val onDrawCallback: () -> Unit
) : PlatformView {
    private val textView: ObservableTextView =
        ObservableTextView(context).apply {
            textSize = 22f
            gravity = Gravity.CENTER
            setBackgroundColor(Color.rgb(100, 200, 255)) // Light blue background
            text = creationParams?.get("text") as? String ?: "Default Native Text"
            setTextColor(Color.BLACK)
        }

    private val drawRunnable =
        Runnable {
            onDrawCallback()
        }

    init {
        textView.onDrawn = {
            textView.post(drawRunnable)
            textView.onDrawn = null
        }
    }

    override fun getView(): View = textView

    override fun dispose() {
        textView.onDrawn = null
        textView.removeCallbacks(drawRunnable)
    }
}
