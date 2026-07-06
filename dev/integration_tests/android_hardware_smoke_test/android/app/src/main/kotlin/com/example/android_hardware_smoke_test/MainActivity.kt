@file:Suppress("PackageName")

package com.example.android_hardware_smoke_test

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        const val CHANNEL_NAME = "com.example.android_hardware_smoke_test/test_channel"
        private const val METHOD_CHANNEL_NAME = "com.example.android_hardware_smoke_test/native_support"
        private var lastConfiguredEngine: FlutterEngine? = null
    }

    var messageChannel: BasicMessageChannel<Any>? = null
    private var impellerBackend = "vulkan"

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        var backend = "vulkan"
        try {
            val appInfo =
                context.packageManager.getApplicationInfo(
                    context.packageName,
                    PackageManager.GET_META_DATA
                )
            val manifestBackend = appInfo.metaData?.getString("io.flutter.embedding.android.ImpellerBackend")
            if (!manifestBackend.isNullOrEmpty()) {
                backend = manifestBackend
            }
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e(TAG, "Failed to read PackageManager metadata: ${e.message}")
        }

        // Cache the engine.
        // This both speeds up the test execution and avoids teardown crashes
        // which can occur on certain GPU drivers.
        // We only want to do this for Vulkan backend because those teardown
        // crashes are specific to Vulkan, and OpenGLES can crash when
        // creating a surface/window with a cached engine.
        if (backend == "vulkan") {
            var engine = FlutterEngineCache.getInstance().get("smoke_test_engine")
            if (engine == null) {
                engine = FlutterEngine(context)
                FlutterEngineCache.getInstance().put("smoke_test_engine", engine)
            }
            return engine
        }
        return FlutterEngine(context)
    }

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

        if (flutterEngine != lastConfiguredEngine) {
            flutterEngine
                .platformViewsController
                .registry
                .registerViewFactory(
                    "com.example.android_hardware_smoke_test/native_text_view",
                    NativeTextViewFactory()
                )
            lastConfiguredEngine = flutterEngine
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                if (call.method == "impeller_backend") {
                    result.success(impellerBackend)
                } else {
                    result.notImplemented()
                }
            }

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
