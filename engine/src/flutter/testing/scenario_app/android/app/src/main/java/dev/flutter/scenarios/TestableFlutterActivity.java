// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;

public class TestableFlutterActivity extends FlutterActivity {
  private Object flutterUiRenderedLock;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    // Reset the lock.
    flutterUiRenderedLock = new Object();
  }

  protected void notifyFlutterRendered() {
    synchronized (flutterUiRenderedLock) {
      flutterUiRenderedLock.notifyAll();
    }
  }

  public void waitUntilFlutterRendered() {
    try {
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
