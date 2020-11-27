// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.plugins.integration_test;

import android.content.Context;
import com.google.common.util.concurrent.SettableFuture;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.util.Map;
import java.util.concurrent.Future;

/** IntegrationTestPlugin */
public class IntegrationTestPlugin implements MethodCallHandler, FlutterPlugin {
  private MethodChannel methodChannel;

  private static final SettableFuture<Map<String, String>> testResultsSettable =
      SettableFuture.create();
  public static final Future<Map<String, String>> testResults = testResultsSettable;

  private static final String CHANNEL = "plugins.flutter.io/integration_test";

  /** Plugin registration. */
  @SuppressWarnings("deprecation")
  public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    final IntegrationTestPlugin instance = new IntegrationTestPlugin();
    instance.onAttachedToEngine(registrar.context(), registrar.messenger());
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
  }

  private void onAttachedToEngine(Context unusedApplicationContext, BinaryMessenger messenger) {
    methodChannel = new MethodChannel(messenger, CHANNEL);
    methodChannel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    methodChannel.setMethodCallHandler(null);
    methodChannel = null;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("allTestsFinished")) {
      Map<String, String> results = call.argument("results");
      testResultsSettable.set(results);
      result.success(null);
    } else {
      result.notImplemented();
    }
  }
}
