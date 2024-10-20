// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.examples.platform_view;

import android.content.Intent;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "samples.flutter.io/platform_view";
  private static final String METHOD_SWITCH_VIEW = "switchView";
  private static final int COUNT_REQUEST = 1;

  private MethodChannel.Result result;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL).setMethodCallHandler(
      new MethodChannel.MethodCallHandler() {
        @Override
        public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
          MainActivity.this.result = result;
          int count = methodCall.arguments();
          if (methodCall.method.equals(METHOD_SWITCH_VIEW)) {
            onLaunchFullScreen(count);
          } else {
            result.notImplemented();
          }
        }
      }
    );
  }

  private void onLaunchFullScreen(int count) {
    Intent fullScreenIntent = new Intent(this, CountActivity.class);
    fullScreenIntent.putExtra(CountActivity.EXTRA_COUNTER, count);
    startActivityForResult(fullScreenIntent, COUNT_REQUEST);
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode == COUNT_REQUEST) {
      if (resultCode == RESULT_OK) {
        result.success(data.getIntExtra(CountActivity.EXTRA_COUNTER, 0));
      } else {
        result.error("ACTIVITY_FAILURE", "Failed while launching activity", null);
      }
    }
  }
}
