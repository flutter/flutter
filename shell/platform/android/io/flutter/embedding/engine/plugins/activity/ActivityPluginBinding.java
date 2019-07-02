// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.plugins.activity;

import android.app.Activity;
import android.support.annotation.NonNull;

import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformViewsController;

/**
 * Binding that gives {@link ActivityAware} plugins access to an associated {@link Activity} and
 * the {@link Activity}'s lifecycle methods.
 */
public interface ActivityPluginBinding {

  /**
   * Returns the {@link Activity} that is currently attached to the {@link FlutterEngine} that
   * owns this {@code ActivityPluginBinding}.
   */
  @NonNull
  Activity getActivity();

  /**
   * Adds a listener that is invoked whenever the associated {@link Activity}'s
   * {@code onRequestPermissionsResult(...)} method is invoked.
   */
  void addRequestPermissionsResultListener(@NonNull PluginRegistry.RequestPermissionsResultListener listener);

  /**
   * Removes a listener that was added in {@link #addRequestPermissionsResultListener(PluginRegistry.RequestPermissionsResultListener)}.
   */
  void removeRequestPermissionsResultListener(@NonNull PluginRegistry.RequestPermissionsResultListener listener);

  /**
   * Adds a listener that is invoked whenever the associated {@link Activity}'s
   * {@code onActivityResult(...)} method is invoked.
   */
  void addActivityResultListener(@NonNull PluginRegistry.ActivityResultListener listener);

  /**
   * Removes a listener that was added in {@link #addActivityResultListener(PluginRegistry.ActivityResultListener)}.
   */
  void removeActivityResultListener(@NonNull PluginRegistry.ActivityResultListener listener);

  /**
   * Adds a listener that is invoked whenever the associated {@link Activity}'s
   * {@code onNewIntent(...)} method is invoked.
   */
  void addOnNewIntentListener(@NonNull PluginRegistry.NewIntentListener listener);

  /**
   * Removes a listener that was added in {@link #addOnNewIntentListener(PluginRegistry.NewIntentListener)}.
   */
  void removeOnNewIntentListener(@NonNull PluginRegistry.NewIntentListener listener);

  /**
   * Adds a listener that is invoked whenever the associated {@link Activity}'s
   * {@code onUserLeaveHint()} method is invoked.
   */
  void addOnUserLeaveHintListener(@NonNull PluginRegistry.UserLeaveHintListener listener);

  /**
   * Removes a listener that was added in {@link #addOnUserLeaveHintListener(PluginRegistry.UserLeaveHintListener)}.
   */
  void removeOnUserLeaveHintListener(@NonNull PluginRegistry.UserLeaveHintListener listener);
}
