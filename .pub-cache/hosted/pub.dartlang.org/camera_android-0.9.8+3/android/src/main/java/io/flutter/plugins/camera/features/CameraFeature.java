// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features;

import android.hardware.camera2.CaptureRequest;
import androidx.annotation.NonNull;
import io.flutter.plugins.camera.CameraProperties;

/**
 * An interface describing a feature in the camera. This holds a setting value of type T and must
 * implement a means to check if this setting is supported by the current camera properties. It also
 * must implement a builder update method which will update a given capture request builder for this
 * feature's current setting value.
 *
 * @param <T>
 */
public abstract class CameraFeature<T> {

  protected final CameraProperties cameraProperties;

  protected CameraFeature(@NonNull CameraProperties cameraProperties) {
    this.cameraProperties = cameraProperties;
  }

  /** Debug name for this feature. */
  public abstract String getDebugName();

  /**
   * Gets the current value of this feature's setting.
   *
   * @return <T> Current value of this feature's setting.
   */
  public abstract T getValue();

  /**
   * Sets a new value for this feature's setting.
   *
   * @param value New value for this feature's setting.
   */
  public abstract void setValue(T value);

  /**
   * Returns whether or not this feature is supported.
   *
   * <p>When the feature is not supported any {@see #value} is simply ignored by the camera plugin.
   *
   * @return boolean Whether or not this feature is supported.
   */
  public abstract boolean checkIsSupported();

  /**
   * Updates the setting in a provided {@see android.hardware.camera2.CaptureRequest.Builder}.
   *
   * @param requestBuilder A {@see android.hardware.camera2.CaptureRequest.Builder} instance used to
   *     configure the settings and outputs needed to capture a single image from the camera device.
   */
  public abstract void updateBuilder(CaptureRequest.Builder requestBuilder);
}
