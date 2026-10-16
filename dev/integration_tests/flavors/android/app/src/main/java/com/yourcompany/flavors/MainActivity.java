// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.yourcompany.flavors;

import androidx.annotation.NonNull;
import io.flutter.FlutterInjector;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

public class MainActivity extends FlutterActivity {
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "flavor")
        .setMethodCallHandler(
            (call, result) -> {
              if (!call.method.equals("loadBranchConfig")) {
                result.notImplemented();
                return;
              }
              String key =
                  FlutterInjector.instance()
                      .flutterLoader()
                      .getLookupKeyForAsset("assets/branch-config.json");
              try (InputStream input = getAssets().open(key);
                  ByteArrayOutputStream output = new ByteArrayOutputStream()) {
                byte[] buffer = new byte[1024];
                int count;
                while ((count = input.read(buffer)) != -1) {
                  output.write(buffer, 0, count);
                }
                result.success(output.toString("UTF-8"));
              } catch (IOException exception) {
                result.error("asset-read", exception.getMessage(), null);
              }
            });
  }
}
