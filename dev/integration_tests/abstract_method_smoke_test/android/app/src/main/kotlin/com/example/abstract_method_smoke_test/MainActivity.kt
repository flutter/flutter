package com.example.abstract_method_smoke_test

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.view.inputmethod.InputMethodManager
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    class SimplePlatformView(context: Context) : PlatformView {
        private val view: View = View(context)

        init {
            view.setBackgroundColor(Color.CYAN)
        }

        override fun dispose() {}

        override fun getView(): View {
            return view
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)

        registrarFor("com.example.abstract_method_smoke_test")
                .platformViewRegistry()
                .registerViewFactory("simple", object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
                    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
                        return SimplePlatformView(this@MainActivity)
                    }
                })

        // Triggers the Android keyboard, which causes the resize of the Flutter view.
        // We need to wait for the app to complete.
        MethodChannel(flutterView, "com.example.abstract_method_smoke_test")
                .setMethodCallHandler { _, result ->
                    toggleInput()
                    result.success(null)
                }
    }

    override fun onPause() {
        // Hide the input when the app is closed.
        toggleInput()
        super.onPause()
    }

    private fun toggleInput() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        imm.toggleSoftInput(InputMethodManager.SHOW_IMPLICIT, 0)
    }
}
