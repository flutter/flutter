@file:Suppress("PackageName")

package com.example.android_hardware_smoke_test

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity :
    FlutterActivity(),
    NativeSupportApi {
    companion object {
        private const val TAG = "MainActivity"
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    var engine: FlutterEngine? = null
        private set

    private var impellerBackend = "vulkan"

    // Overridden to return a cached, application-wide FlutterEngine instance.
    // In JUnit integration tests, the activity is destroyed and recreated for each test case.
    // Tearing down and recreating a new FlutterEngine (and its native Impeller Vulkan resources)
    // per test method triggers native driver race conditions and Vulkan memory/mutex crashes on Android.
    // Reusing the cached engine keeps the Vulkan context stable across all test runs.
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        val cache = FlutterEngineCache.getInstance()
        var cachedEngine = cache.get("smoke_test_engine")
        if (cachedEngine == null) {
            cachedEngine = FlutterEngine(context.applicationContext)
            cachedEngine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            cache.put("smoke_test_engine", cachedEngine)
        }
        return cachedEngine
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engine = flutterEngine

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

        NativeSupportApi.setUp(flutterEngine.dartExecutor.binaryMessenger, this)

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "com.example.android_hardware_smoke_test/native_text_view",
                NativeTextViewFactory()
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

    override fun getImpellerBackend(): String? = impellerBackend
}
