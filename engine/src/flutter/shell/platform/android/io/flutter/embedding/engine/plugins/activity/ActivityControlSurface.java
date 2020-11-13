// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.plugins.activity;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.Lifecycle;
import io.flutter.embedding.android.ExclusiveAppComponent;

/**
 * Control surface through which an {@link Activity} attaches to a {@link FlutterEngine}.
 *
 * <p>An {@link Activity} that contains a {@link FlutterView} and associated {@link FlutterEngine}
 * should coordinate itself with the {@link FlutterEngine}'s {@code ActivityControlSurface}.
 *
 * <ol>
 *   <li>Once an {@link Activity} is created, and its associated {@link FlutterEngine} is executing
 *       Dart code, the {@link Activity} should invoke {@link #attachToActivity(
 *       ExclusiveAppComponent, Lifecycle)}. At this point the {@link FlutterEngine} is considered
 *       "attached" to the {@link Activity} and all {@link ActivityAware} plugins are given access
 *       to the {@link Activity}.
 *   <li>Just before an attached {@link Activity} is destroyed for configuration change purposes,
 *       that {@link Activity} should invoke {@link #detachFromActivityForConfigChanges()}, giving
 *       each {@link ActivityAware} plugin an opportunity to clean up its references before the
 *       {@link Activity is destroyed}.
 *   <li>When an {@link Activity} is recreated after configuration changes, that {@link Activity}
 *       should invoke {@link #reattachToActivityAfterConfigChange(Activity)} so that all {@link
 *       ActivityAware} plugins can re-establish references to the {@link Activity}.
 *   <li>When an {@link Activity} is destroyed for non-configuration-change purposes, or when the
 *       {@link Activity} is no longer interested in displaying a {@link FlutterEngine}'s content,
 *       the {@link Activity} should invoke {@link #detachFromActivity()}.
 *   <li>When a {@link Activity} is being attached while an existing {@link ExclusiveAppComponent}
 *       is already attached, the existing {@link ExclusiveAppComponent} is given a chance to detach
 *       first via {@link ExclusiveAppComponent#detachFromFlutterEngine()} before the new activity
 *       attaches.
 * </ol>
 *
 * The attached {@link Activity} should also forward all {@link Activity} calls that this {@code
 * ActivityControlSurface} supports, e.g., {@link #onRequestPermissionsResult(int, String[],
 * int[])}. These forwarded calls are made available to all {@link ActivityAware} plugins that are
 * added to the attached {@link FlutterEngine}.
 */
public interface ActivityControlSurface {
  /**
   * Call this method from the {@link Activity} that is displaying the visual content of the {@link
   * FlutterEngine} that is associated with this {@code ActivityControlSurface}.
   *
   * <p>Once an {@link Activity} is created, and its associated {@link FlutterEngine} is executing
   * Dart code, the {@link Activity} should invoke this method. At that point the {@link
   * FlutterEngine} is considered "attached" to the {@link Activity} and all {@link ActivityAware}
   * plugins are given access to the {@link Activity}.
   *
   * @deprecated Prefer using the {@link #attachToActivity(ExclusiveAppComponent, Lifecycle)} API to
   *     avoid situations where multiple activities are driving the FlutterEngine simultaneously.
   *     See https://github.com/flutter/flutter/issues/66192.
   */
  @Deprecated
  void attachToActivity(@NonNull Activity activity, @NonNull Lifecycle lifecycle);

  /**
   * Call this method from the {@link ExclusiveAppComponent} that is displaying the visual content
   * of the {@link FlutterEngine} that is associated with this {@code ActivityControlSurface}.
   *
   * <p>Once an {@link ExclusiveAppComponent} is created, and its associated {@link FlutterEngine}
   * is executing Dart code, the {@link ExclusiveAppComponent} should invoke this method. At that
   * point the {@link FlutterEngine} is considered "attached" to the {@link ExclusiveAppComponent}
   * and all {@link ActivityAware} plugins are given access to the {@link ExclusiveAppComponent}'s
   * {@link Activity}.
   *
   * <p>This method differs from {@link #attachToActivity(Activity, Lifecycle)} in that it calls
   * back the existing {@link ExclusiveAppComponent} to give it a chance to cleanly detach before a
   * new {@link ExclusiveAppComponent} is attached.
   */
  void attachToActivity(
      @NonNull ExclusiveAppComponent<Activity> exclusiveActivity, @NonNull Lifecycle lifecycle);

  /**
   * Call this method from the {@link Activity} that is attached to this {@code
   * ActivityControlSurfaces}'s {@link FlutterEngine} when the {@link Activity} is about to be
   * destroyed due to configuration changes.
   *
   * <p>This method gives each {@link ActivityAware} plugin an opportunity to clean up its
   * references before the {@link Activity is destroyed}.
   */
  void detachFromActivityForConfigChanges();

  /**
   * Call this method from the {@link Activity} that is attached to this {@code
   * ActivityControlSurfaces}'s {@link FlutterEngine} when the {@link Activity} is about to be
   * destroyed for non-configuration-change reasons.
   *
   * <p>This method gives each {@link ActivityAware} plugin an opportunity to clean up its
   * references before the {@link Activity is destroyed}.
   */
  void detachFromActivity();

  /**
   * Call this method from the {@link Activity} that is attached to this {@code
   * ActivityControlSurface}'s {@link FlutterEngine} and the associated method in the {@link
   * Activity} is invoked.
   *
   * <p>Returns true if one or more plugins utilized this permission result.
   */
  boolean onRequestPermissionsResult(
      int requestCode, @NonNull String[] permissions, @NonNull int[] grantResult);

  /**
   * Call this method from the {@link Activity} that is attached to this {@code
   * ActivityControlSurface}'s {@link FlutterEngine} and the associated method in the {@link
   * Activity} is invoked.
   *
   * <p>Returns true if one or more plugins utilized this {@link Activity} result.
   */
  boolean onActivityResult(int requestCode, int resultCode, @Nullable Intent data);

  /**
   * Call this method from the {@link Activity} that is attached to this {@code
   * ActivityControlSurface}'s {@link FlutterEngine} and the associated method in the {@link
   * Activity} is invoked.
   */
  void onNewIntent(@NonNull Intent intent);

  /**
   * Call this method from the {@link Activity} that is attached to this {@code
   * ActivityControlSurface}'s {@link FlutterEngine} and the associated method in the {@link
   * Activity} is invoked.
   */
  void onUserLeaveHint();

  /**
   * Call this method from the {@link Activity} or {@code Fragment} that is attached to this {@code
   * ActivityControlSurface}'s {@link FlutterEngine} when the associated method is invoked in the
   * {@link Activity} or {@code Fragment}.
   */
  void onSaveInstanceState(@NonNull Bundle bundle);

  /**
   * Call this method from the {@link Activity} or {@code Fragment} that is attached to this {@code
   * ActivityControlSurface}'s {@link FlutterEngine} when {@link Activity#onCreate(Bundle)} or
   * {@code Fragment#onCreate(Bundle)} is invoked in the {@link Activity} or {@code Fragment}.
   */
  void onRestoreInstanceState(@Nullable Bundle bundle);
}
