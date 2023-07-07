// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.autofocus;

import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CaptureRequest;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.features.CameraFeature;

/** Controls the auto focus configuration on the {@see anddroid.hardware.camera2} API. */
public class AutoFocusFeature extends CameraFeature<FocusMode> {
  private FocusMode currentSetting = FocusMode.auto;

  // When switching recording modes this feature is re-created with the appropriate setting here.
  private final boolean recordingVideo;

  /**
   * Creates a new instance of the {@see AutoFocusFeature}.
   *
   * @param cameraProperties Collection of the characteristics for the current camera device.
   * @param recordingVideo Indicates whether the camera is currently recording video.
   */
  public AutoFocusFeature(CameraProperties cameraProperties, boolean recordingVideo) {
    super(cameraProperties);
    this.recordingVideo = recordingVideo;
  }

  @Override
  public String getDebugName() {
    return "AutoFocusFeature";
  }

  @Override
  public FocusMode getValue() {
    return currentSetting;
  }

  @Override
  public void setValue(FocusMode value) {
    this.currentSetting = value;
  }

  @Override
  public boolean checkIsSupported() {
    int[] modes = cameraProperties.getControlAutoFocusAvailableModes();

    final Float minFocus = cameraProperties.getLensInfoMinimumFocusDistance();

    // Check if the focal length of the lens is fixed. If the minimum focus distance == 0, then the
    // focal length  is fixed. The minimum focus distance can be null on some devices: https://developer.android.com/reference/android/hardware/camera2/CameraCharacteristics#LENS_INFO_MINIMUM_FOCUS_DISTANCE
    boolean isFixedLength = minFocus == null || minFocus == 0;

    return !isFixedLength
        && !(modes.length == 0
            || (modes.length == 1 && modes[0] == CameraCharacteristics.CONTROL_AF_MODE_OFF));
  }

  @Override
  public void updateBuilder(CaptureRequest.Builder requestBuilder) {
    if (!checkIsSupported()) {
      return;
    }

    switch (currentSetting) {
      case locked:
        // When locking the auto-focus the camera device should do a one-time focus and afterwards
        // set the auto-focus to idle. This is accomplished by setting the CONTROL_AF_MODE to
        // CONTROL_AF_MODE_AUTO.
        requestBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_AUTO);
        break;
      case auto:
        requestBuilder.set(
            CaptureRequest.CONTROL_AF_MODE,
            recordingVideo
                ? CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_VIDEO
                : CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
      default:
        break;
    }
  }
}
