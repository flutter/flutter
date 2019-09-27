package com.example.abstract_method_smoke_test

import android.content.Context
import android.os.Bundle
import android.view.inputmethod.InputMethodManager
import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    // Triggers the Android keyboard, which causes the resize of the Flutter view.
    // https://github.com/flutter/flutter/issues/40126
    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0)
  }
}
