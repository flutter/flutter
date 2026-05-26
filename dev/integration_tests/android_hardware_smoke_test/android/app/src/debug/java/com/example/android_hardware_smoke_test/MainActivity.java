package com.example.android_hardware_smoke_test;

import android.os.Bundle;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.util.Log;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
  private static final String TAG = "MainActivity";
  static final String TEST_CHANNEL_NAME = "com.example.android_hardware_smoke_test/test_channel";
  private static final String METHOD_CHANNEL_NAME = "com.example.android_hardware_smoke_test/native_support";

  public BasicMessageChannel<Object> messageChannel = null;
  private String impellerBackend = "vulkan";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
  }
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);

    // Read the manifest metadata to determine which Impeller backend the test is configured to use.
    try {
      ApplicationInfo appInfo = getPackageManager().getApplicationInfo(
          getPackageName(),
          PackageManager.GET_META_DATA
      );
      if (appInfo.metaData != null) {
        String manifestBackend = appInfo.metaData.getString("io.flutter.embedding.android.ImpellerBackend");
        if (manifestBackend != null && !manifestBackend.isEmpty()) {
          this.impellerBackend = manifestBackend;
        }
      }
    } catch (PackageManager.NameNotFoundException e) {
      Log.e(TAG, "Failed to read PackageManager metadata: " + e.getMessage());
    }

    // Set up a method channel to expose the Impeller backend to the Flutter app.
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL_NAME)
        .setMethodCallHandler((call, result) -> {
          if (call.method.equals("impeller_backend")) {
            result.success(this.impellerBackend);
          } else {
            result.notImplemented();
          }
        });

    // Set up the message channel for test instructions.
    this.messageChannel = new BasicMessageChannel<Object>(
        flutterEngine.getDartExecutor().getBinaryMessenger(),
        TEST_CHANNEL_NAME,
        JSONMessageCodec.INSTANCE);
  }
}