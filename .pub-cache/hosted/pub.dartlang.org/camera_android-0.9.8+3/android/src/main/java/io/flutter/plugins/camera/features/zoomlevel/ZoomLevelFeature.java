// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.zoomlevel;

import android.graphics.Rect;
import android.hardware.camera2.CaptureRequest;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.features.CameraFeature;

/** Controls the zoom configuration on the {@link android.hardware.camera2} API. */
public class ZoomLevelFeature extends CameraFeature<Float> {
  private static final float MINIMUM_ZOOM_LEVEL = 1.0f;
  private final boolean hasSupport;
  private final Rect sensorArraySize;
  private Float currentSetting = MINIMUM_ZOOM_LEVEL;
  private Float maximumZoomLevel = MINIMUM_ZOOM_LEVEL;

  /**
   * Creates a new instance of the {@link ZoomLevelFeature}.
   *
   * @param cameraProperties Collection of characteristics for the current camera device.
   */
  public ZoomLevelFeature(CameraProperties cameraProperties) {
    super(cameraProperties);

    sensorArraySize = cameraProperties.getSensorInfoActiveArraySize();

    if (sensorArraySize == null) {
      maximumZoomLevel = MINIMUM_ZOOM_LEVEL;
      hasSupport = false;
      return;
    }

    Float maxDigitalZoom = cameraProperties.getScalerAvailableMaxDigitalZoom();
    maximumZoomLevel =
        ((maxDigitalZoom == null) || (maxDigitalZoom < MINIMUM_ZOOM_LEVEL))
            ? MINIMUM_ZOOM_LEVEL
            : maxDigitalZoom;

    hasSupport = (Float.compare(maximumZoomLevel, MINIMUM_ZOOM_LEVEL) > 0);
  }

  @Override
  public String getDebugName() {
    return "ZoomLevelFeature";
  }

  @Override
  public Float getValue() {
    return currentSetting;
  }

  @Override
  public void setValue(Float value) {
    currentSetting = value;
  }

  @Override
  public boolean checkIsSupported() {
    return hasSupport;
  }

  @Override
  public void updateBuilder(CaptureRequest.Builder requestBuilder) {
    if (!checkIsSupported()) {
      return;
    }

    final Rect computedZoom =
        ZoomUtils.computeZoom(
            currentSetting, sensorArraySize, MINIMUM_ZOOM_LEVEL, maximumZoomLevel);
    requestBuilder.set(CaptureRequest.SCALER_CROP_REGION, computedZoom);
  }

  /**
   * Gets the minimum supported zoom level.
   *
   * @return The minimum zoom level.
   */
  public float getMinimumZoomLevel() {
    return MINIMUM_ZOOM_LEVEL;
  }

  /**
   * Gets the maximum supported zoom level.
   *
   * @return The maximum zoom level.
   */
  public float getMaximumZoomLevel() {
    return maximumZoomLevel;
  }
}
