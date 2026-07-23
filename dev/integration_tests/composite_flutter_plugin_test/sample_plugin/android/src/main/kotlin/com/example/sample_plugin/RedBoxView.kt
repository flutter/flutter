package com.example.sample_plugin

import android.content.Context
import android.graphics.Color
import android.view.View
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class RedBoxView(context: Context) : PlatformView {
    private val view: View = View(context).apply {
        setBackgroundColor(Color.RED)
    }

    override fun getView(): View {
        return view
    }

    override fun dispose() {}
}

class RedBoxViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return RedBoxView(context)
    }
}
