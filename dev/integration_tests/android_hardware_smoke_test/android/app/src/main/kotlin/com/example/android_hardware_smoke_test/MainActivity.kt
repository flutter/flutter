package com.example.android_hardware_smoke_test

import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        const val CHANNEL_NAME = "com.example.android_hardware_smoke_test/test_channel"
        private const val METHOD_CHANNEL_NAME = "com.example.android_hardware_smoke_test/native_support"
    }

    var messageChannel: BasicMessageChannel<Any>? = null
    private var impellerBackend = "vulkan"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            val appInfo = packageManager.getApplicationInfo(
                packageName,
                PackageManager.GET_META_DATA
            )
            val manifestBackend = appInfo.metaData?.getString("io.flutter.embedding.android.ImpellerBackend")
            if (!manifestBackend.isNullOrEmpty()) {
                impellerBackend = manifestBackend
            }
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e(TAG, "Failed to read PackageManager metadata: ${e.message}")
        }

        messageChannel = BasicMessageChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
            JSONMessageCodec.INSTANCE
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                if (call.method == "impeller_backend") {
                    result.success(impellerBackend)
                } else {
                    result.notImplemented()
                }
            }
    }
}
