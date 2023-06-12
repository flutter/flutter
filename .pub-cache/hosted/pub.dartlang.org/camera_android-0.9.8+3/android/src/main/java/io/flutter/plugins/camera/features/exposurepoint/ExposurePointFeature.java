// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.exposurepoint;

import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.MeteringRectangle;
import android.util.Size;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.CameraRegionUtils;
import io.flutter.plugins.camera.features.CameraFeature;
import io.flutter.plugins.camera.features.Point;
import io.flutter.plugins.camera.features.sensororientation.SensorOrientationFeature;

/** Exposure point controls where in the frame exposure metering will come from. */
public class ExposurePointFeature extends CameraFeature<Point> {

  private Size cameraBoundaries;
  private Point exposurePoint;
  private MeteringRectangle exposureRectangle;
  private final SensorOrientationFeature sensorOrientationFeature;

  /**
   * Creates a new instance of the {@link ExposurePointFeature}.
   *
   * @param cameraProperties Collection of the characteristics for the current camera device.
   */
  public ExposurePointFeature(
      CameraProperties cameraProperties, SensorOrientationFeature sensorOrientationFeature) {
    super(cameraProperties);
    this.sensorOrientationFeature = sensorOrientationFeature;
  }

  /**
   * Sets the camera boundaries that are required for the exposure point feature to function.
   *
   * @param cameraBoundaries - The camera boundaries to set.
   */
  public void setCameraBoundaries(@NonNull Size cameraBoundaries) {
    this.cameraBoundaries = cameraBoundaries;
    this.buildExposureRectangle();
  }

  @Override
  public String getDebugName() {
    return "ExposurePointFeature";
  }

  @Override
  public Point getValue() {
    return exposurePoint;
  }

  @Override
  public void setValue(Point value) {
    this.exposurePoint = (value == null || value.x == null || value.y == null) ? null : value;
    this.buildExposureRectangle();
  }

  // Whether or not this camera can set the exposure point.
  @Override
  public boolean checkIsSupported() {
    Integer supportedRegions = cameraProperties.getControlMaxRegionsAutoExposure();
    return supportedRegions != null && supportedRegions > 0;
  }

  @Override
  public void updateBuilder(CaptureRequest.Builder requestBuilder) {
    if (!checkIsSupported()) {
      return;
    }
    requestBuilder.set(
        CaptureRequest.CONTROL_AE_REGIONS,
        exposureRectangle == null ? null : new MeteringRectangle[] {exposureRectangle});
  }

  private void buildExposureRectangle() {
    if (this.cameraBoundaries == null) {
      throw new AssertionError(
          "The cameraBoundaries should be set (using `ExposurePointFeature.setCameraBoundaries(Size)`) before updating the exposure point.");
    }
    if (this.exposurePoint == null) {
      this.exposureRectangle = null;
    } else {
      PlatformChannel.DeviceOrientation orientation =
          this.sensorOrientationFeature.getLockedCaptureOrientation();
      if (orientation == null) {
        orientation =
            this.sensorOrientationFeature.getDeviceOrientationManager().getLastUIOrientation();
      }
      this.exposureRectangle =
          CameraRegionUtils.convertPointToMeteringRectangle(
              this.cameraBoundaries, this.exposurePoint.x, this.exposurePoint.y, orientation);
    }
  }
}
