// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.app.Activity;
import android.arch.lifecycle.Lifecycle;
import android.support.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;

/**
 * Configures a {@link FlutterEngine} after it is created, e.g., adds plugins.
 * <p>
 * This interface may be applied to a {@link android.support.v4.app.FragmentActivity} that owns a
 * {@code FlutterFragment}.
 */
public interface FlutterEngineConfigurator {
  /**
   * Configures the given {@link FlutterEngine}.
   * <p>
   * This method is called after the given {@link FlutterEngine} has been attached to the
   * owning {@code FragmentActivity}. See
   * {@link io.flutter.embedding.engine.plugins.activity.ActivityControlSurface#attachToActivity(Activity, Lifecycle)}.
   * <p>
   * It is possible that the owning {@code FragmentActivity} opted not to connect itself as
   * an {@link io.flutter.embedding.engine.plugins.activity.ActivityControlSurface}. In that
   * case, any configuration, e.g., plugins, must not expect or depend upon an available
   * {@code Activity} at the time that this method is invoked.
   */
  void configureFlutterEngine(@NonNull FlutterEngine flutterEngine);
}
