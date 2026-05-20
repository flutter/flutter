package com.example.android_hardware_smoke_test;

import android.os.Bundle;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.JSONMessageCodec;

public class MainActivity extends FlutterActivity {
  private static final String TAG = "MainActivity";
  static final String CHANNEL_NAME = "com.example.android_hardware_smoke_test/test_channel";
  public BasicMessageChannel<Object> messageChannel = null;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
  }
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);

    this.messageChannel = new BasicMessageChannel<Object>(
        flutterEngine.getDartExecutor().getBinaryMessenger(),
        CHANNEL_NAME,
        JSONMessageCodec.INSTANCE);
  }
}