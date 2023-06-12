// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.sensororientation;

import android.app.Activity;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureRequest;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.DartMessenger;
import io.flutter.plugins.camera.features.CameraFeature;
import io.flutter.plugins.camera.features.resolution.ResolutionFeature;

/** Provides access to the sensor orientation of the camera devices. */
public class SensorOrientationFeature extends CameraFeature<Integer> {
  private Integer currentSetting = 0;
  private final DeviceOrientationManager deviceOrientationListener;
  private PlatformChannel.DeviceOrientation lockedCaptureOrientation;

  /**
   * Creates a new instance of the {@link ResolutionFeature}.
   *
   * @param cameraProperties Collection of characteristics for the current camera device.
   * @param activity Current Android {@link android.app.Activity}, used to detect UI orientation
   *     changes.
   * @param dartMessenger Instance of a {@link DartMessenger} used to communicate orientation
   *     updates back to the client.
   */
  public SensorOrientationFeature(
      @NonNull CameraProperties cameraProperties,
      @NonNull Activity activity,
      @NonNull DartMessenger dartMessenger) {
    super(cameraProperties);
    setValue(cameraProperties.getSensorOrientation());

    boolean isFrontFacing = cameraProperties.getLensFacing() == CameraMetadata.LENS_FACING_FRONT;
    deviceOrientationListener =
        DeviceOrientationManager.create(activity, dartMessenger, isFrontFacing, currentSetting);
    deviceOrientationListener.start();
  }

  @Override
  public String getDebugName() {
    return "SensorOrientationFeature";
  }

  @Override
  public Integer getValue() {
    return currentSetting;
  }

  @Override
  public void setValue(Integer value) {
    this.currentSetting = value;
  }

  @Override
  public boolean checkIsSupported() {
    return true;
  }

  @Override
  public void updateBuilder(CaptureRequest.Builder requestBuilder) {
    // Noop: when setting the sensor orientation there is no need to update the request builder.
  }

  /**
   * Gets the instance of the {@link DeviceOrientationManager} used to detect orientation changes.
   *
   * @return The instance of the {@link DeviceOrientationManager}.
   */
  public DeviceOrientationManager getDeviceOrientationManager() {
    return this.deviceOrientationListener;
  }

  /**
   * Lock the capture orientation, indicating that the device orientation should not influence the
   * capture orientation.
   *
   * @param orientation The orientation in which to lock the capture orientation.
   */
  public void lockCaptureOrientation(PlatformChannel.DeviceOrientation orientation) {
    this.lockedCaptureOrientation = orientation;
  }

  /**
   * Unlock the capture orientation, indicating that the device orientation should be used to
   * configure the capture orientation.
   */
  public void unlockCaptureOrientation() {
    this.lockedCaptureOrientation = null;
  }

  /**
   * Gets the configured locked capture orientation.
   *
   * @return The configured locked capture orientation.
   */
  public PlatformChannel.DeviceOrientation getLockedCaptureOrientation() {
    return this.lockedCaptureOrientation;
  }
}
