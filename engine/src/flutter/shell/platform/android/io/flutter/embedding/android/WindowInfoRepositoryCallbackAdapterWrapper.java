// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import androidx.core.util.Consumer;
import androidx.window.java.layout.WindowInfoRepositoryCallbackAdapter;
import androidx.window.layout.WindowLayoutInfo;
import java.util.concurrent.Executor;

/**
 * Wraps {@link WindowInfoRepositoryCallbackAdapter} in order to be able to mock it during testing.
 */
public class WindowInfoRepositoryCallbackAdapterWrapper {

  final WindowInfoRepositoryCallbackAdapter adapter;

  public WindowInfoRepositoryCallbackAdapterWrapper(WindowInfoRepositoryCallbackAdapter adapter) {
    this.adapter = adapter;
  }

  public void addWindowLayoutInfoListener(Executor executor, Consumer<WindowLayoutInfo> consumer) {
    adapter.addWindowLayoutInfoListener(executor, consumer);
  }

  public void removeWindowLayoutInfoListener(Consumer<WindowLayoutInfo> consumer) {
    adapter.removeWindowLayoutInfoListener(consumer);
  }
}
