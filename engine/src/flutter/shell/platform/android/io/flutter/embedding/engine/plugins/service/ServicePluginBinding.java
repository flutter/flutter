// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.plugins.service;

import android.app.Service;
import android.support.annotation.NonNull;

/**
 * Binding that gives {@link ServiceAware} plugins access to an associated {@link Service}.
 */
public interface ServicePluginBinding {

  /**
   * Returns the {@link Service} that is currently attached to the {@link FlutterEngine} that
   * owns this {@code ServicePluginBinding}.
   */
  @NonNull
  Service getService();

  /**
   * Adds the given {@code listener} to be notified when the associated {@link Service} goes
   * from background to foreground, or foreground to background.
   */
  void addOnModeChangeListener(@NonNull ServiceAware.OnModeChangeListener listener);

  /**
   * Removes the given {@code listener}, which was previously added with
   * {@link #addOnModeChangeListener(OnModeChangeListener)}.
   */
  void removeOnModeChangeListener(@NonNull ServiceAware.OnModeChangeListener listener);
}
