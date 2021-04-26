package com.example.echo

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.plugin.common.StandardMessageCodec

class EchoPlugin {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = BasicMessageChannel(registrar.messenger(), "dev.flutter.echo.basic.standard", StandardMessageCodec.INSTANCE)
      channel.setMessageHandler { message, reply -> reply.reply(message) }
    }
  }
}
