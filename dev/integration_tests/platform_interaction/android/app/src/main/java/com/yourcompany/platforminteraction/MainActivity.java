// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.yourcompany.platforminteraction;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StringCodec;

public class MainActivity extends FlutterActivity {
  BasicMessageChannel<String> channel;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    channel =
        new BasicMessageChannel<>(flutterEngine.getDartExecutor().getBinaryMessenger(), "navigation-test", StringCodec.INSTANCE);
  }

  public void finish() {
    channel.send("ping");
  }
}
