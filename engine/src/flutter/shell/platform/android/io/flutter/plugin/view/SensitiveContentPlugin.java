// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.view;

import static io.flutter.Build.API_LEVELS;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Build;
import android.view.View;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.systemchannels.SensitiveContentChannel;

/**
 * {@link SensitiveContentPlugin} is the implementation of all functionality needed to set and
 * retrieve the content sensitivity level of a native Flutter Android {@code View}.
 *
 * <p>This plugin handles requests for getting and setting content sensitivity sent by the {@link
 * io.flutter.embedding.engine.systemchannels.SensitiveContentChannel}.
 */
public class SensitiveContentPlugin
    implements SensitiveContentChannel.SensitiveContentMethodHandler {

  private Activity mFlutterActivity;
  private final int mFlutterViewId;
  private final SensitiveContentChannel mSensitiveContentChannel;

  public SensitiveContentPlugin(
      @NonNull int flutterViewId,
      @NonNull Activity activity,
      @NonNull SensitiveContentChannel sensitiveContentChannel) {
    mFlutterActivity = activity;
    mFlutterViewId = flutterViewId;
    mSensitiveContentChannel = sensitiveContentChannel;

    mSensitiveContentChannel.setSensitiveContentMethodHandler(this);
  }

  private String getNotSupportedErrorReason() {
    return "isSupported() should be called before attempting to set content sensitivity as it is not supported on this device.";
  }

  private String getFlutterViewNotFoundErrorReason() {
    return "FlutterView with ID " + mFlutterViewId + "not found";
  }

  /**
   * Sets content sensitivity level of the Android {@code View} associated with this plugin's {@code
   * mFlutterViewId} to the level specified by {@requestedContentSensitivity}.
   */
  // Suppress lint to calls getContentSensitivity, setContentSensitivity since these are guarded by
  // the call to isSupported.
  @SuppressLint("NewApi")
  @Override
  public void setContentSensitivity(@NonNull int requestedContentSensitivity) {
    if (!isSupported()) {
      // This feature is only available on >= API 35.
      throw new IllegalStateException(getNotSupportedErrorReason());
    }

    final View flutterView = mFlutterActivity.findViewById(mFlutterViewId);
    if (flutterView == null) {
      throw new IllegalArgumentException(getFlutterViewNotFoundErrorReason());
    }

    final int currentContentSensitivity = flutterView.getContentSensitivity();

    if (currentContentSensitivity == requestedContentSensitivity) {
      // Content sensitivity for the requested View already set to requestedContentSensitivity.
      return;
    }

    // Set requestedContentSensitivity on the View.
    flutterView.setContentSensitivity(requestedContentSensitivity);

    // Invalidate the View to force a redraw in order to ensure that it updates to be
    // obscured/unobscured as expected.
    flutterView.invalidate();
  }

  /**
   * Gets content sensitivity level of the Android {@code View} associated with this plugin's {@code
   * mFlutterViewId}.
   */
  // Suppress lint to call getContentSensitivity since this is guarded by the
  // call to isSupported.
  @SuppressLint("NewApi")
  @Override
  public int getContentSensitivity() {
    if (!isSupported()) {
      // This feature is only available on >= API 35. Return not sensitive content
      // sensitivity mode since every other mode is unavailable.
      return View.CONTENT_SENSITIVITY_NOT_SENSITIVE;
    }

    final View flutterView = mFlutterActivity.findViewById(mFlutterViewId);
    if (flutterView == null) {
      throw new IllegalArgumentException(getFlutterViewNotFoundErrorReason());
    }

    final int currentContentSensitivity = flutterView.getContentSensitivity();
    return currentContentSensitivity;
  }

  /**
   * Returns whether or not marking content sensitivity is supported on the device.
   *
   * <p>It is supported on devices running Android API >= 35.
   */
  @Override
  public boolean isSupported() {
    boolean isSupported = Build.VERSION.SDK_INT >= API_LEVELS.API_35;
    return isSupported;
  }

  /**
   * Releases all resources held by this {@code SensitiveContentPlugin}.
   *
   * <p>Do not invoke any methods on a {@code SensitiveContentPlugin} after invoking this method.
   */
  public void destroy() {
    this.mSensitiveContentChannel.setSensitiveContentMethodHandler(null);
    this.mFlutterActivity = null;
  }
}
