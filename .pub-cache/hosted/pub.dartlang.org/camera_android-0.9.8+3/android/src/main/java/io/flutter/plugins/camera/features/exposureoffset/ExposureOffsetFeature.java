// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.exposureoffset;

import android.hardware.camera2.CaptureRequest;
import android.util.Range;
import androidx.annotation.NonNull;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.features.CameraFeature;

/** Controls the exposure offset making the resulting image brighter or darker. */
public class ExposureOffsetFeature extends CameraFeature<Double> {

  private double currentSetting = 0;

  /**
   * Creates a new instance of the {@link ExposureOffsetFeature}.
   *
   * @param cameraProperties Collection of the characteristics for the current camera device.
   */
  public ExposureOffsetFeature(CameraProperties cameraProperties) {
    super(cameraProperties);
  }

  @Override
  public String getDebugName() {
    return "ExposureOffsetFeature";
  }

  @Override
  public Double getValue() {
    return currentSetting;
  }

  @Override
  public void setValue(@NonNull Double value) {
    double stepSize = getExposureOffsetStepSize();
    this.currentSetting = value / stepSize;
  }

  // Available on all devices.
  @Override
  public boolean checkIsSupported() {
    return true;
  }

  @Override
  public void updateBuilder(CaptureRequest.Builder requestBuilder) {
    if (!checkIsSupported()) {
      return;
    }

    requestBuilder.set(CaptureRequest.CONTROL_AE_EXPOSURE_COMPENSATION, (int) currentSetting);
  }

  /**
   * Returns the minimum exposure offset.
   *
   * @return double Minimum exposure offset.
   */
  public double getMinExposureOffset() {
    Range<Integer> range = cameraProperties.getControlAutoExposureCompensationRange();
    double minStepped = range == null ? 0 : range.getLower();
    double stepSize = getExposureOffsetStepSize();
    return minStepped * stepSize;
  }

  /**
   * Returns the maximum exposure offset.
   *
   * @return double Maximum exposure offset.
   */
  public double getMaxExposureOffset() {
    Range<Integer> range = cameraProperties.getControlAutoExposureCompensationRange();
    double maxStepped = range == null ? 0 : range.getUpper();
    double stepSize = getExposureOffsetStepSize();
    return maxStepped * stepSize;
  }

  /**
   * Returns the smallest step by which the exposure compensation can be changed.
   *
   * <p>Example: if this has a value of 0.5, then an aeExposureCompensation setting of -2 means that
   * the actual AE offset is -1. More details can be found in the official Android documentation:
   * https://developer.android.com/reference/android/hardware/camera2/CameraCharacteristics.html#CONTROL_AE_COMPENSATION_STEP
   *
   * @return double Smallest step by which the exposure compensation can be changed.
   */
  public double getExposureOffsetStepSize() {
    return cameraProperties.getControlAutoExposureCompensationStep();
  }
}
