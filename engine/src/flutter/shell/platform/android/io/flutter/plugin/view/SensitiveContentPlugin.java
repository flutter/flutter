// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.view;

import static io.flutter.Build.API_LEVELS;

import android.app.Activity;
import android.os.Build;
import android.view.View;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.systemchannels.SensitiveContentChannel;
import io.flutter.plugin.common.MethodChannel;

/**
 * {@link SensitiveContentPlugin} is the implementation of all functionality needed to set the
 * content sensitivity level of a native Flutter Android {@code View}.
 *
 * <p>This plugin handles requests for setting content sensitivity sent by the {@link
 * io.flutter.embedding.engine.systemchannels.SensitiveContentChannel}.
 */
public class SensitiveContentPlugin
    implements SensitiveContentChannel.SensitiveContentMethodHandler {

  private final int mFlutterViewId;
  private final Activity mFlutterActivity;
  private final SensitiveContentChannel mSensitiveContentChannel;

  public SensitiveContentPlugin(
      @NonNull Activity activity,
      @NonNull int flutterViewId,
      @NonNull SensitiveContentChannel sensitiveContentChannel) {
    mFlutterActivity = activity;
    mFlutterViewId = flutterViewId;
    mSensitiveContentChannel = sensitiveContentChannel;

    mSensitiveContentChannel.setSensitiveContentMethodHandler(this);
  }

  /**
   * Sets content sensitivity level of the Android {@code View} associated with this plugin's {@code
   * mFlutterViewId} to the level specified by {@requestedContentSensitivity}.
   */
  @Override
  public void setContentSensitivity(
      @NonNull int requestedContentSensitivity, @NonNull MethodChannel.Result result) {
    if (Build.VERSION.SDK_INT < API_LEVELS.API_35) {
      // This feature is only available on > API 35.
      return;
    }

    final View flutterView = mFlutterActivity.findViewById(mFlutterViewId);
    final int initialContentSensitivity = flutterView.getContentSensitivity();

    // Set requestedContentSensitivity on the requested View.
    flutterView.setContentSensitivity(requestedContentSensitivity);

    // Invalidate the View to force a redraw if we require that the screen
    // become unobscured, which is the case where the View was previously
    // marked sensitive but now is no longer.
    final boolean shouldInvalidateView =
        initialContentSensitivity == View.CONTENT_SENSITIVITY_SENSITIVE
            && requestedContentSensitivity != View.CONTENT_SENSITIVITY_SENSITIVE;
    if (shouldInvalidateView) {
      flutterView.invalidate();
    }

    result.success(null);
  }

  /**
   * Gets content sensitivity level of the Android {@code View} associated with this plugin's {@code
   * mFlutterViewId}.
   */
  @Override
  public void getContentSensitivity(@NonNull MethodChannel.Result result) {
    if (Build.VERSION.SDK_INT < API_LEVELS.API_35) {
      // This feature is only available on > API 35.
      return;
    }

    final View flutterView = mFlutterActivity.findViewById(mFlutterViewId);
    final int currentContentSensitivity = flutterView.getContentSensitivity();
    result.success(currentContentSensitivity);
  }

  /**
   * Releases all resources held by this {@code SensitiveContentPlugin}.
   *
   * <p>Do not invoke any methods on a {@code SensitiveContentPlugin} after invoking this method.
   */
  public void destroy() {
    this.mSensitiveContentChannel.setSensitiveContentMethodHandler(null);
  }
}
