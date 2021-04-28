package com.example.platform_channels_benchmarks

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.StandardMessageCodec

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        val basicStandard = BasicMessageChannel(flutterEngine.dartExecutor, "dev.flutter.echo.basic.standard", StandardMessageCodec.INSTANCE)
        basicStandard.setMessageHandler { message, reply -> reply.reply(message) }
        super.configureFlutterEngine(flutterEngine)
    }
}
