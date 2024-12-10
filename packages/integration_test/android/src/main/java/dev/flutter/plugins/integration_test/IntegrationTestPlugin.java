// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.plugins.integration_test;

import android.app.Activity;
import android.content.Context;
import com.google.common.util.concurrent.SettableFuture;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.io.IOException;
import java.util.Map;
import java.util.ArrayList;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import androidx.test.uiautomator.UiDevice;
import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.runner.AndroidJUnitRunner;

/** IntegrationTestPlugin */
public class IntegrationTestPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware {
  private static final String CHANNEL = "plugins.flutter.io/integration_test";
  private static final SettableFuture<Map<String, String>> testResultsSettable =
      SettableFuture.create();
  public static final Future<Map<String, String>> testResults = testResultsSettable;
  private final SettableFuture<String[]> testListSettable = SettableFuture.create();
  private final Future<String[]> testListFuture = testListSettable;

  private MethodChannel methodChannel;
  private Activity flutterActivity;
  private FlutterTestJUnitRunner instrumentation;

  public IntegrationTestPlugin() {
    System.out.println("JOHN IntegrationTestPlugin");
    instrumentation = (FlutterTestJUnitRunner)InstrumentationRegistry.getInstrumentation();
    if (instrumentation == null) {
      return;
    }
    System.out.println("JOHN Registering plugin with instrumentation");
    instrumentation.registerPlugin(this);
  }

  String[] getDartTestList() {
    try {
      return this.testListFuture.get();
    }  catch (ExecutionException | InterruptedException e) {
      System.out.println("JOHN failed to get rest getDartTestList execpteion=" + e);
    }
    return new String[0];
  }

  /** Plugin registration. */

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
    UiDevice device = UiDevice.getInstance(instrumentation);

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
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    flutterActivity = binding.getActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    flutterActivity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    flutterActivity = null;
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    flutterActivity = null;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    System.out.println("JOHN IntegrestionTestPlugin onMethodCall " + call.method);
    switch (call.method) {
      case "allTestsFinished":
        final Map<String, String> results = call.argument("results");
        testResultsSettable.set(results);
        result.success(null);
        return;
      case "convertFlutterSurfaceToImage":
        if (flutterActivity == null) {
          result.error("Could not convert to image", "Activity not initialized", null);
          return;
        }
        FlutterDeviceScreenshot.convertFlutterSurfaceToImage(flutterActivity);
        result.success(null);
        return;
      case "revertFlutterImage":
        if (flutterActivity == null) {
          result.error("Could not revert Flutter image", "Activity not initialized", null);
          return;
        }
        FlutterDeviceScreenshot.revertFlutterImage(flutterActivity);
        result.success(null);
        return;
      case "captureScreenshot":
        if (FlutterDeviceScreenshot.hasInstrumentation()) {
          byte[] image;
          try {
            image = FlutterDeviceScreenshot.captureWithUiAutomation();
          } catch (IOException exception) {
            result.error("Could not capture screenshot", "UiAutomation failed", exception);
            return;
          }
          result.success(image);
          return;
        }
        if (flutterActivity == null) {
          result.error("Could not capture screenshot", "Activity not initialized", null);
          return;
        }
        FlutterDeviceScreenshot.captureView(flutterActivity, methodChannel, result);
        return;
      case "populateTestList":
          final ArrayList<String> testList = call.argument("testList");
          final String[] tests = new String[testList.size()];
          for (int i = 0; i < testList.size(); i++) {
            tests[i] = testList.get(i);
          }
          System.out.println("JOHN populateTEstList JAVA SIDE: " + tests);
          testListSettable.set(tests);
          result.success(null);
        return;
      default:
        result.notImplemented();
    }
  }
}
