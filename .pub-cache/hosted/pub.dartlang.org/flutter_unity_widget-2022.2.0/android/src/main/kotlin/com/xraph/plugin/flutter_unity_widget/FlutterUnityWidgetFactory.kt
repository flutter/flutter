package com.xraph.plugin.flutter_unity_widget

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FlutterUnityWidgetFactory(
        private val binaryMessenger: BinaryMessenger,
        private var lifecycleProvider: LifecycleProvider
        ) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context?, id: Int, args: Any?): PlatformView {
        val builder = FlutterUnityWidgetBuilder()
        val params = args as Map<*, *>

        if (params.containsKey("fullscreen")) {
            builder.setFullscreenEnabled(params["fullscreen"] as Boolean)
        }

        if (params.containsKey("hideStatus")) {
            builder.setHideStatusBar(params["hideStatus"] as Boolean)
        }

        if (params.containsKey("earlyInitUnity")) {
            builder.setRunImmediately(params["earlyInitUnity"] as Boolean)
        }

        if (params.containsKey("unloadOnDispose")) {
            builder.setUnloadOnDispose(params["unloadOnDispose"] as Boolean)
        }

        return builder.build(
                id,
                context,
                binaryMessenger,
                lifecycleProvider
        )
    }

    fun creates(p0: Context?, p1: Int, p2: Any?): PlatformView {
        TODO("Not yet implemented")
    }
}