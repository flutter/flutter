// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.focuspoint;

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

public class FocusPointFeatureTest {

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
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);

    assertEquals("FocusPointFeature", focusPointFeature.getDebugName());
  }

  @Test
  public void getValue_shouldReturnNullIfNotSet() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    Point actualPoint = focusPointFeature.getValue();
    assertNull(focusPointFeature.getValue());
  }

  @Test
  public void getValue_shouldEchoTheSetValue() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    focusPointFeature.setCameraBoundaries(this.mockCameraBoundaries);
    Point expectedPoint = new Point(0.0, 0.0);

    focusPointFeature.setValue(expectedPoint);
    Point actualPoint = focusPointFeature.getValue();

    assertEquals(expectedPoint, actualPoint);
  }

  @Test
  public void setValue_shouldResetPointWhenXCoordIsNull() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    focusPointFeature.setCameraBoundaries(this.mockCameraBoundaries);

    focusPointFeature.setValue(new Point(null, 0.0));

    assertNull(focusPointFeature.getValue());
  }

  @Test
  public void setValue_shouldResetPointWhenYCoordIsNull() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    focusPointFeature.setCameraBoundaries(this.mockCameraBoundaries);

    focusPointFeature.setValue(new Point(0.0, null));

    assertNull(focusPointFeature.getValue());
  }

  @Test
  public void setValue_shouldSetPointWhenValidCoordsAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    focusPointFeature.setCameraBoundaries(this.mockCameraBoundaries);
    Point point = new Point(0.0, 0.0);

    focusPointFeature.setValue(point);

    assertEquals(point, focusPointFeature.getValue());
  }

  @Test
  public void setValue_shouldDetermineMeteringRectangleWhenValidBoundariesAndCoordsAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(1);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    Size mockedCameraBoundaries = mock(Size.class);
    focusPointFeature.setCameraBoundaries(mockedCameraBoundaries);

    try (MockedStatic<CameraRegionUtils> mockedCameraRegionUtils =
        Mockito.mockStatic(CameraRegionUtils.class)) {

      focusPointFeature.setValue(new Point(0.5, 0.5));

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
    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(1);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);

    try (MockedStatic<CameraRegionUtils> mockedCameraRegionUtils =
        Mockito.mockStatic(CameraRegionUtils.class)) {
      focusPointFeature.setValue(new Point(0.5, 0.5));
    }
  }

  @Test
  public void setValue_shouldNotDetermineMeteringRectangleWhenNullCoordsAreSet() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(1);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    Size mockedCameraBoundaries = mock(Size.class);
    focusPointFeature.setCameraBoundaries(mockedCameraBoundaries);

    try (MockedStatic<CameraRegionUtils> mockedCameraRegionUtils =
        Mockito.mockStatic(CameraRegionUtils.class)) {

      focusPointFeature.setValue(null);
      focusPointFeature.setValue(new Point(null, 0.5));
      focusPointFeature.setValue(new Point(0.5, null));

      mockedCameraRegionUtils.verifyNoInteractions();
    }
  }

  @Test
  public void
      setCameraBoundaries_shouldDetermineMeteringRectangleWhenValidBoundariesAndCoordsAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(1);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    focusPointFeature.setCameraBoundaries(this.mockCameraBoundaries);
    focusPointFeature.setValue(new Point(0.5, 0.5));
    Size mockedCameraBoundaries = mock(Size.class);

    try (MockedStatic<CameraRegionUtils> mockedCameraRegionUtils =
        Mockito.mockStatic(CameraRegionUtils.class)) {

      focusPointFeature.setCameraBoundaries(mockedCameraBoundaries);

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
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    focusPointFeature.setCameraBoundaries(new Size(100, 100));

    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(null);

    assertFalse(focusPointFeature.checkIsSupported());
  }

  @Test
  public void checkIsSupported_shouldReturnFalseWhenMaxRegionsIsZero() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    focusPointFeature.setCameraBoundaries(new Size(100, 100));

    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(0);

    assertFalse(focusPointFeature.checkIsSupported());
  }

  @Test
  public void checkIsSupported_shouldReturnTrueWhenMaxRegionsIsBiggerThenZero() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    focusPointFeature.setCameraBoundaries(new Size(100, 100));

    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(1);

    assertTrue(focusPointFeature.checkIsSupported());
  }

  @Test
  public void updateBuilder_shouldReturnWhenCheckIsSupportedIsFalse() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    CaptureRequest.Builder mockCaptureRequestBuilder = mock(CaptureRequest.Builder.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);

    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(0);

    focusPointFeature.updateBuilder(mockCaptureRequestBuilder);

    verify(mockCaptureRequestBuilder, never()).set(any(), any());
  }

  @Test
  public void updateBuilder_shouldSetMeteringRectangleWhenValidBoundariesAndCoordsAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(1);
    CaptureRequest.Builder mockCaptureRequestBuilder = mock(CaptureRequest.Builder.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
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
      focusPointFeature.setCameraBoundaries(mockedCameraBoundaries);
      focusPointFeature.setValue(new Point(0.5, 0.5));

      focusPointFeature.updateBuilder(mockCaptureRequestBuilder);
    }

    verify(mockCaptureRequestBuilder, times(1))
        .set(CaptureRequest.CONTROL_AE_REGIONS, new MeteringRectangle[] {mockedMeteringRectangle});
  }

  @Test
  public void updateBuilder_shouldNotSetMeteringRectangleWhenNoValidBoundariesAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(1);
    CaptureRequest.Builder mockCaptureRequestBuilder = mock(CaptureRequest.Builder.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    MeteringRectangle mockedMeteringRectangle = mock(MeteringRectangle.class);

    focusPointFeature.updateBuilder(mockCaptureRequestBuilder);

    verify(mockCaptureRequestBuilder, times(1)).set(any(), isNull());
  }

  @Test
  public void updateBuilder_shouldNotSetMeteringRectangleWhenNoValidCoordsAreSupplied() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    when(mockCameraProperties.getControlMaxRegionsAutoFocus()).thenReturn(1);
    CaptureRequest.Builder mockCaptureRequestBuilder = mock(CaptureRequest.Builder.class);
    FocusPointFeature focusPointFeature =
        new FocusPointFeature(mockCameraProperties, mockSensorOrientationFeature);
    focusPointFeature.setCameraBoundaries(this.mockCameraBoundaries);

    focusPointFeature.setValue(null);
    focusPointFeature.updateBuilder(mockCaptureRequestBuilder);
    focusPointFeature.setValue(new Point(0d, null));
    focusPointFeature.updateBuilder(mockCaptureRequestBuilder);
    focusPointFeature.setValue(new Point(null, 0d));
    focusPointFeature.updateBuilder(mockCaptureRequestBuilder);
    verify(mockCaptureRequestBuilder, times(3)).set(any(), isNull());
  }
}
