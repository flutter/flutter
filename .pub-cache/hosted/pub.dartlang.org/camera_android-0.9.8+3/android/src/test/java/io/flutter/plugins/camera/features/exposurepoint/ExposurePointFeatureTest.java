// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.exposurepoint;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.MeteringRectangle;
import android.util.Size;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.CameraRegionUtils;
import io.flutter.plugins.camera.features.Point;
import io.flutter.plugins.camera.features.sensororientation.DeviceOrientationManager;
import io.flutter.plugins.camera.features.sensororientation.SensorOrientationFeature;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;
import org.mockito.Mockito;

public class ExposurePointFeatureTest {

  Size mockCameraBoundaries;
  SensorOrientationFeature mockSensorOrientationFeature;
  DeviceOrientationManager mockDeviceOrientationManager;

  @Before
  public void setUp() {
    this.mockCameraBoundaries = mock(Size.class);
    when(this.mockCameraBoundaries.getWidth()).thenReturn(100);
    when(this.mockCameraBoundaries.getHeight()).thenReturn(100);
    mockSensorOrientationFeature = mock(SensorOrientationFeature.class);
    mockDeviceOrientationManager = mock(DeviceOrientationManager.class);
    when(mockSensorOrientationFeature.getDeviceOrientationManager())
        .thenReturn(mockDeviceOrientationManager);
    when(mockDeviceOrientationManager.getLastUIOrientation())
        .thenReturn(PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT);
  }

  @Test
  public void getDebugName_shouldReturnTheNameOfTheFeature() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);

    assertEquals("ExposurePointFeature", exposurePointFeature.getDebugName());
  }

  @Test
  public void getValue_shouldReturnNullIfNotSet() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    assertNull(exposurePointFeature.getValue());
  }

  @Test
  public void getValue_shouldEchoTheSetValue() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    exposurePointFeature.setCameraBoundaries(this.mockCameraBoundaries);
    Point expectedPoint = new Point(0.0, 0.0);

    exposurePointFeature.setValue(expectedPoint);
    Point actualPoint = exposurePointFeature.getValue();

    assertEquals(expectedPoint, actualPoint);
  }

  @Test
  public void setValue_shouldResetPointWhenXCoordIsNull() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    exposurePointFeature.setCameraBoundaries(this.mockCameraBoundaries);

    exposurePointFeature.setValue(new Point(null, 0.0));

    assertNull(exposurePointFeature.getValue());
  }

  @Test
  public void setValue_shouldResetPointWhenYCoordIsNull() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    exposurePointFeature.setCameraBoundaries(this.mockCameraBoundaries);

    exposurePointFeature.setValue(new Point(0.0, null));

    assertNull(exposurePointFeature.getValue());
  }

  @Test
  public void setValue_shouldSetPointWhenValidCoordsAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    exposurePointFeature.setCameraBoundaries(this.mockCameraBoundaries);
    Point point = new Point(0.0, 0.0);

    exposurePointFeature.setValue(point);

    assertEquals(point, exposurePointFeature.getValue());
  }

  @Test
  public void setValue_shouldDetermineMeteringRectangleWhenValidBoundariesAndCoordsAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(1);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    Size mockedCameraBoundaries = mock(Size.class);
    exposurePointFeature.setCameraBoundaries(mockedCameraBoundaries);

    try (MockedStatic<CameraRegionUtils> mockedCameraRegionUtils =
        Mockito.mockStatic(CameraRegionUtils.class)) {

      exposurePointFeature.setValue(new Point(0.5, 0.5));

      mockedCameraRegionUtils.verify(
          () ->
              CameraRegionUtils.convertPointToMeteringRectangle(
                  mockedCameraBoundaries,
                  0.5,
                  0.5,
                  PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT),
          times(1));
    }
  }

  @Test(expected = AssertionError.class)
  public void setValue_shouldThrowAssertionErrorWhenNoValidBoundariesAreSet() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(1);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);

    try (MockedStatic<CameraRegionUtils> mockedCameraRegionUtils =
        Mockito.mockStatic(CameraRegionUtils.class)) {
      exposurePointFeature.setValue(new Point(0.5, 0.5));
    }
  }

  @Test
  public void setValue_shouldNotDetermineMeteringRectangleWhenNullCoordsAreSet() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(1);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    Size mockedCameraBoundaries = mock(Size.class);
    exposurePointFeature.setCameraBoundaries(mockedCameraBoundaries);

    try (MockedStatic<CameraRegionUtils> mockedCameraRegionUtils =
        Mockito.mockStatic(CameraRegionUtils.class)) {

      exposurePointFeature.setValue(null);
      exposurePointFeature.setValue(new Point(null, 0.5));
      exposurePointFeature.setValue(new Point(0.5, null));

      mockedCameraRegionUtils.verifyNoInteractions();
    }
  }

  @Test
  public void
      setCameraBoundaries_shouldDetermineMeteringRectangleWhenValidBoundariesAndCoordsAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(1);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    exposurePointFeature.setCameraBoundaries(this.mockCameraBoundaries);
    exposurePointFeature.setValue(new Point(0.5, 0.5));
    Size mockedCameraBoundaries = mock(Size.class);

    try (MockedStatic<CameraRegionUtils> mockedCameraRegionUtils =
        Mockito.mockStatic(CameraRegionUtils.class)) {

      exposurePointFeature.setCameraBoundaries(mockedCameraBoundaries);

      mockedCameraRegionUtils.verify(
          () ->
              CameraRegionUtils.convertPointToMeteringRectangle(
                  mockedCameraBoundaries,
                  0.5,
                  0.5,
                  PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT),
          times(1));
    }
  }

  @Test
  public void checkIsSupported_shouldReturnFalseWhenMaxRegionsIsNull() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    exposurePointFeature.setCameraBoundaries(new Size(100, 100));

    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(null);

    assertFalse(exposurePointFeature.checkIsSupported());
  }

  @Test
  public void checkIsSupported_shouldReturnFalseWhenMaxRegionsIsZero() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    exposurePointFeature.setCameraBoundaries(new Size(100, 100));

    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(0);

    assertFalse(exposurePointFeature.checkIsSupported());
  }

  @Test
  public void checkIsSupported_shouldReturnTrueWhenMaxRegionsIsBiggerThenZero() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    exposurePointFeature.setCameraBoundaries(new Size(100, 100));

    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(1);

    assertTrue(exposurePointFeature.checkIsSupported());
  }

  @Test
  public void updateBuilder_shouldReturnWhenCheckIsSupportedIsFalse() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    CaptureRequest.Builder mockCaptureRequestBuilder = mock(CaptureRequest.Builder.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);

    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(0);

    exposurePointFeature.updateBuilder(mockCaptureRequestBuilder);

    verify(mockCaptureRequestBuilder, never()).set(any(), any());
  }

  @Test
  public void updateBuilder_shouldSetMeteringRectangleWhenValidBoundariesAndCoordsAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(1);
    CaptureRequest.Builder mockCaptureRequestBuilder = mock(CaptureRequest.Builder.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    Size mockedCameraBoundaries = mock(Size.class);
    MeteringRectangle mockedMeteringRectangle = mock(MeteringRectangle.class);

    try (MockedStatic<CameraRegionUtils> mockedCameraRegionUtils =
        Mockito.mockStatic(CameraRegionUtils.class)) {
      mockedCameraRegionUtils
          .when(
              () ->
                  CameraRegionUtils.convertPointToMeteringRectangle(
                      mockedCameraBoundaries,
                      0.5,
                      0.5,
                      PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT))
          .thenReturn(mockedMeteringRectangle);
      exposurePointFeature.setCameraBoundaries(mockedCameraBoundaries);
      exposurePointFeature.setValue(new Point(0.5, 0.5));

      exposurePointFeature.updateBuilder(mockCaptureRequestBuilder);
    }

    verify(mockCaptureRequestBuilder, times(1))
        .set(CaptureRequest.CONTROL_AE_REGIONS, new MeteringRectangle[] {mockedMeteringRectangle});
  }

  @Test
  public void updateBuilder_shouldNotSetMeteringRectangleWhenNoValidBoundariesAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(1);
    CaptureRequest.Builder mockCaptureRequestBuilder = mock(CaptureRequest.Builder.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);

    exposurePointFeature.updateBuilder(mockCaptureRequestBuilder);

    verify(mockCaptureRequestBuilder, times(1)).set(any(), isNull());
  }

  @Test
  public void updateBuilder_shouldNotSetMeteringRectangleWhenNoValidCoordsAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoExposure()).thenReturn(1);
    CaptureRequest.Builder mockCaptureRequestBuilder = mock(CaptureRequest.Builder.class);
    ExposurePointFeature exposurePointFeature =
        new ExposurePointFeature(mockCameraProperties, mockSensorOrientationFeature);
    exposurePointFeature.setCameraBoundaries(this.mockCameraBoundaries);

    exposurePointFeature.setValue(null);
    exposurePointFeature.updateBuilder(mockCaptureRequestBuilder);
    exposurePointFeature.setValue(new Point(0d, null));
    exposurePointFeature.updateBuilder(mockCaptureRequestBuilder);
    exposurePointFeature.setValue(new Point(null, 0d));
    exposurePointFeature.updateBuilder(mockCaptureRequestBuilder);
    verify(mockCaptureRequestBuilder, times(3)).set(any(), isNull());
  }
}
