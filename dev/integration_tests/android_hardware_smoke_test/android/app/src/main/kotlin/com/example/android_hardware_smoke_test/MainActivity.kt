@file:Suppress("PackageName")

package com.example.android_hardware_smoke_test

import android.content.pm.PackageManager
import android.os.Build
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
            val appInfo =
                packageManager.getApplicationInfo(
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

        messageChannel =
            BasicMessageChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL_NAME,
                JSONMessageCodec.INSTANCE
            )

        val nativeSupportChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME)
        nativeSupportChannel.setMethodCallHandler { call, result ->
            if (call.method == "impeller_backend") {
                result.success(impellerBackend)
            } else {
                result.notImplemented()
            }
        }

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "com.example.android_hardware_smoke_test/native_text_view",
                NativeTextViewFactory {
                    nativeSupportChannel.invokeMethod("onDraw", null)
                }
            )

        // Register the native_driver channel. This responds to AndroidNativeDriver's connection ping
        // and property checks, enabling the host-side runner to take compositor-level screenshots via ADB.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "native_driver")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sdk_version" -> {
                        result.success(mapOf("version" to Build.VERSION.SDK_INT))
                    }
                    "is_emulator" -> {
                        val isEmulator =
                            Build.MODEL.contains("gphone") ||
                                Build.MODEL.contains("Emulator") ||
                                Build.MODEL.contains("Android SDK built for x86")
                        result.success(mapOf("emulator" to isEmulator))
                    }
                    "ping" -> {
                        result.success(null)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
