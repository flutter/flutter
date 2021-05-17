// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.platform_channels_benchmarks

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.nio.ByteBuffer

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        val basicStandard = BasicMessageChannel(flutterEngine.dartExecutor, "dev.flutter.echo.basic.standard", StandardMessageCodec.INSTANCE)
        basicStandard.setMessageHandler { message, reply -> reply.reply(message) }
        val basicBinary = BasicMessageChannel(flutterEngine.dartExecutor, "dev.flutter.echo.basic.binary", BinaryCodec.INSTANCE)
        basicBinary.setMessageHandler { message, reply -> run {
            val result = ByteBuffer.allocateDirect(message!!.capacity())
            result.put(message)
            reply.reply(result)
        } }
        super.configureFlutterEngine(flutterEngine)
    }
}
