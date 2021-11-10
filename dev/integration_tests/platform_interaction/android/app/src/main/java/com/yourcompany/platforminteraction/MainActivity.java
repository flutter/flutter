// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.yourcompany.platforminteraction;

import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.*;

public class MainActivity extends FlutterActivity {
  public void finish() {
    BasicMessageChannel channel =
        new BasicMessageChannel<>(getFlutterView(), "navigation-test", StringCodec.INSTANCE);
    channel.send("ping");
  }
}
