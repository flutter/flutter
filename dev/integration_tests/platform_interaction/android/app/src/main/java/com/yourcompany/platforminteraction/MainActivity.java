// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.yourcompany.platforminteraction;

import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.*;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
  }
  public void finish() {
    BasicMessageChannel channel =
        new BasicMessageChannel<>(getFlutterView(), "navigation-test", StringCodec.INSTANCE);
    channel.send("ping");
  }
}
