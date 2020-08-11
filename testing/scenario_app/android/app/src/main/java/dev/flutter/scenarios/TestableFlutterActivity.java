// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import java.util.concurrent.atomic.AtomicBoolean;

public class TestableFlutterActivity extends FlutterActivity {
  private Object flutterUiRenderedLock = new Object();
  private AtomicBoolean isScenarioReady = new AtomicBoolean(false);

  @Override
  public void configureFlutterEngine(FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    flutterEngine
        .getDartExecutor()
        .setMessageHandler("take_screenshot", (byteBuffer, binaryReply) -> notifyFlutterRendered());
  }

  protected void notifyFlutterRendered() {
    synchronized (flutterUiRenderedLock) {
      isScenarioReady.set(true);
      flutterUiRenderedLock.notifyAll();
    }
  }

  public void waitUntilFlutterRendered() {
    try {
      if (isScenarioReady.get()) {
        return;
      }
      synchronized (flutterUiRenderedLock) {
        flutterUiRenderedLock.wait();
      }
      // Reset the lock.
      flutterUiRenderedLock = new Object();
    } catch (InterruptedException e) {
      throw new RuntimeException(e);
    }
  }
}
