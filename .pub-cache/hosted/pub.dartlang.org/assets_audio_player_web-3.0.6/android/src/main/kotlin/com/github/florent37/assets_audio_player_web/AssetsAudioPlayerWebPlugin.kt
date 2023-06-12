package com.github.florent37.assets_audio_player_web

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** AssetsAudioPlayerWebPlugin */
public class AssetsAudioPlayerWebPlugin: FlutterPlugin, MethodCallHandler {

  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    //no-op for compatibility
  }

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      //no-op for compatibility
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    //no-op for compatibility
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    //no-op for compatibility
  }
}
