// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.plugins.lifecycle;

import androidx.annotation.NonNull;
import androidx.lifecycle.Lifecycle;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

/** Provides a static method for extracting lifecycle objects from Flutter plugin bindings. */
public class FlutterLifecycleAdapter {
  private static final String TAG = "FlutterLifecycleAdapter";

  /**
   * Returns the lifecycle object for the activity a plugin is bound to.
   *
   * <p>Returns null if the Flutter engine version does not include the lifecycle extraction code.
   * (this probably means the Flutter engine version is too old).
   */
  @NonNull
  public static Lifecycle getActivityLifecycle(
      @NonNull ActivityPluginBinding activityPluginBinding) {
    HiddenLifecycleReference reference =
        (HiddenLifecycleReference) activityPluginBinding.getLifecycle();
    return reference.getLifecycle();
  }
}
