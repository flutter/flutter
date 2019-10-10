package com.example.abstract_method_smoke_test

import android.content.Context
import android.os.Bundle
import android.view.inputmethod.InputMethodManager
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    // Triggers the Android keyboard, which causes the resize of the Flutter view.
    // We need to wait for the app to complete.
    MethodChannel(getFlutterView(), "com.example.abstract_method_smoke_test")
        .setMethodCallHandler({ call, result ->
          toggleInput()
          result.success(null)
        })
  }

  override fun onPause() {
    // Hide the input when the app is closed.
    toggleInput()
    super.onPause()
  }

  fun toggleInput() {
    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    imm.toggleSoftInput(InputMethodManager.SHOW_IMPLICIT, 0)
  }
}
