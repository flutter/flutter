package com.example.unmigrated_sample_plugin

import android.content.Context
import android.graphics.Color
import android.view.View
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class BlueBoxView(context: Context) : PlatformView {
    private val view: View = View(context).apply {
        setBackgroundColor(Color.BLUE)
    }

    override fun getView(): View {
        return view
    }

    override fun dispose() {}
}

class BlueBoxViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return BlueBoxView(context)
    }
}
