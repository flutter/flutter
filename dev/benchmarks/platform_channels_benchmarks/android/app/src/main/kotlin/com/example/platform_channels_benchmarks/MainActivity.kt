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

class MainActivity : FlutterActivity() {
    // We allow for the caching of a response in the binary channel case since
    // the reply requires a direct buffer, but the input is not a direct buffer.
    // We can't directly send the input back to the reply currently.
    private var byteBufferCache: ByteBuffer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        val reset = BasicMessageChannel(flutterEngine.dartExecutor, "dev.flutter.echo.reset", StandardMessageCodec.INSTANCE)
        reset.setMessageHandler { message, reply ->
            run {
                byteBufferCache = null
            }
        }
        val basicStandard =
            BasicMessageChannel(flutterEngine.dartExecutor, "dev.flutter.echo.basic.standard", StandardMessageCodec.INSTANCE)
        basicStandard.setMessageHandler { message, reply -> reply.reply(message) }
        val basicBinary = BasicMessageChannel(flutterEngine.dartExecutor, "dev.flutter.echo.basic.binary", BinaryCodec.INSTANCE_DIRECT)
        basicBinary.setMessageHandler { message, reply ->
            run {
                if (byteBufferCache == null) {
                    byteBufferCache = ByteBuffer.allocateDirect(message!!.capacity())
                    byteBufferCache!!.put(message)
                }
                reply.reply(byteBufferCache)
            }
        }
        val taskQueue = flutterEngine.dartExecutor.getBinaryMessenger().makeBackgroundTaskQueue()
        val backgroundStandard =
            BasicMessageChannel(
                flutterEngine.dartExecutor,
                "dev.flutter.echo.background.standard",
                StandardMessageCodec.INSTANCE,
                taskQueue
            )
        backgroundStandard.setMessageHandler { message, reply -> reply.reply(message) }
        super.configureFlutterEngine(flutterEngine)
    }
}
