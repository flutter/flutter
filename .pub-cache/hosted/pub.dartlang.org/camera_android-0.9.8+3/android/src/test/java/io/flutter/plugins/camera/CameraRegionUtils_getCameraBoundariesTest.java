// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.camera;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.graphics.Rect;
import android.hardware.camera2.CaptureRequest;
import android.os.Build;
import android.util.Size;
import io.flutter.plugins.camera.utils.TestUtils;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;
import org.mockito.stubbing.Answer;

public class CameraRegionUtils_getCameraBoundariesTest {

  Size mockCameraBoundaries;

  @Before
  public void setUp() {
    this.mockCameraBoundaries = mock(Size.class);
    when(this.mockCameraBoundaries.getWidth()).thenReturn(100);
    when(this.mockCameraBoundaries.getHeight()).thenReturn(100);
  }

  @Test
  public void getCameraBoundaries_shouldReturnSensorInfoPixelArraySizeWhenRunningPreAndroidP() {
    updateSdkVersion(Build.VERSION_CODES.O_MR1);

    try {
      CameraProperties mockCameraProperties = mock(CameraProperties.class);
      CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
      when(mockCameraProperties.getSensorInfoPixelArraySize()).thenReturn(mockCameraBoundaries);

      Size result = CameraRegionUtils.getCameraBoundaries(mockCameraProperties, mockBuilder);

      assertEquals(mockCameraBoundaries, result);
      verify(mockCameraProperties, never()).getSensorInfoPreCorrectionActiveArraySize();
      verify(mockCameraProperties, never()).getSensorInfoActiveArraySize();
    } finally {
      updateSdkVersion(0);
    }
  }

  @Test
  public void
      getCameraBoundaries_shouldReturnSensorInfoPixelArraySizeWhenDistortionCorrectionIsNull() {
    updateSdkVersion(Build.VERSION_CODES.P);

    try {
      CameraProperties mockCameraProperties = mock(CameraProperties.class);
      CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);

      when(mockCameraProperties.getDistortionCorrectionAvailableModes()).thenReturn(null);
      when(mockCameraProperties.getSensorInfoPixelArraySize()).thenReturn(mockCameraBoundaries);

      Size result = CameraRegionUtils.getCameraBoundaries(mockCameraProperties, mockBuilder);

      assertEquals(mockCameraBoundaries, result);
      verify(mockCameraProperties, never()).getSensorInfoPreCorrectionActiveArraySize();
      verify(mockCameraProperties, never()).getSensorInfoActiveArraySize();
    } finally {
      updateSdkVersion(0);
    }
  }

  @Test
  public void
      getCameraBoundaries_shouldReturnSensorInfoPixelArraySizeWhenDistortionCorrectionIsOff() {
    updateSdkVersion(Build.VERSION_CODES.P);

    try {
      CameraProperties mockCameraProperties = mock(CameraProperties.class);
      CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);

      when(mockCameraProperties.getDistortionCorrectionAvailableModes())
          .thenReturn(new int[] {CaptureRequest.DISTORTION_CORRECTION_MODE_OFF});
      when(mockCameraProperties.getSensorInfoPixelArraySize()).thenReturn(mockCameraBoundaries);

      Size result = CameraRegionUtils.getCameraBoundaries(mockCameraProperties, mockBuilder);

      assertEquals(mockCameraBoundaries, result);
      verify(mockCameraProperties, never()).getSensorInfoPreCorrectionActiveArraySize();
      verify(mockCameraProperties, never()).getSensorInfoActiveArraySize();
    } finally {
      updateSdkVersion(0);
    }
  }

  @Test
  public void
      getCameraBoundaries_shouldReturnInfoPreCorrectionActiveArraySizeWhenDistortionCorrectionModeIsSetToNull() {
    updateSdkVersion(Build.VERSION_CODES.P);

    try {
      CameraProperties mockCameraProperties = mock(CameraProperties.class);
      CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
      Rect mockSensorInfoPreCorrectionActiveArraySize = mock(Rect.class);
      when(mockSensorInfoPreCorrectionActiveArraySize.width()).thenReturn(100);
      when(mockSensorInfoPreCorrectionActiveArraySize.height()).thenReturn(100);

      when(mockCameraProperties.getDistortionCorrectionAvailableModes())
          .thenReturn(
              new int[] {
                CaptureRequest.DISTORTION_CORRECTION_MODE_OFF,
                CaptureRequest.DISTORTION_CORRECTION_MODE_FAST
              });
      when(mockBuilder.get(CaptureRequest.DISTORTION_CORRECTION_MODE)).thenReturn(null);
      when(mockCameraProperties.getSensorInfoPreCorrectionActiveArraySize())
          .thenReturn(mockSensorInfoPreCorrectionActiveArraySize);

      try (MockedStatic<CameraRegionUtils.SizeFactory> mockedSizeFactory =
          mockStatic(CameraRegionUtils.SizeFactory.class)) {
        mockedSizeFactory
            .when(() -> CameraRegionUtils.SizeFactory.create(anyInt(), anyInt()))
            .thenAnswer(
                (Answer<Size>)
                    invocation -> {
                      Size mockSize = mock(Size.class);
                      when(mockSize.getWidth()).thenReturn(invocation.getArgument(0));
                      when(mockSize.getHeight()).thenReturn(invocation.getArgument(1));
                      return mockSize;
                    });

        Size result = CameraRegionUtils.getCameraBoundaries(mockCameraProperties, mockBuilder);

        assertEquals(100, result.getWidth());
        assertEquals(100, result.getHeight());
        verify(mockCameraProperties, never()).getSensorInfoPixelArraySize();
        verify(mockCameraProperties, never()).getSensorInfoActiveArraySize();
      }
    } finally {
      updateSdkVersion(0);
    }
  }

  @Test
  public void
      getCameraBoundaries_shouldReturnInfoPreCorrectionActiveArraySizeWhenDistortionCorrectionModeIsSetToOff() {
    updateSdkVersion(Build.VERSION_CODES.P);

    try {
      CameraProperties mockCameraProperties = mock(CameraProperties.class);
      CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
      Rect mockSensorInfoPreCorrectionActiveArraySize = mock(Rect.class);
      when(mockSensorInfoPreCorrectionActiveArraySize.width()).thenReturn(100);
      when(mockSensorInfoPreCorrectionActiveArraySize.height()).thenReturn(100);

      when(mockCameraProperties.getDistortionCorrectionAvailableModes())
          .thenReturn(
              new int[] {
                CaptureRequest.DISTORTION_CORRECTION_MODE_OFF,
                CaptureRequest.DISTORTION_CORRECTION_MODE_FAST
              });

      when(mockBuilder.get(CaptureRequest.DISTORTION_CORRECTION_MODE))
          .thenReturn(CaptureRequest.DISTORTION_CORRECTION_MODE_OFF);
      when(mockCameraProperties.getSensorInfoPreCorrectionActiveArraySize())
          .thenReturn(mockSensorInfoPreCorrectionActiveArraySize);

      try (MockedStatic<CameraRegionUtils.SizeFactory> mockedSizeFactory =
          mockStatic(CameraRegionUtils.SizeFactory.class)) {
        mockedSizeFactory
            .when(() -> CameraRegionUtils.SizeFactory.create(anyInt(), anyInt()))
            .thenAnswer(
                (Answer<Size>)
                    invocation -> {
                      Size mockSize = mock(Size.class);
                      when(mockSize.getWidth()).thenReturn(invocation.getArgument(0));
                      when(mockSize.getHeight()).thenReturn(invocation.getArgument(1));
                      return mockSize;
                    });

        Size result = CameraRegionUtils.getCameraBoundaries(mockCameraProperties, mockBuilder);

        assertEquals(100, result.getWidth());
        assertEquals(100, result.getHeight());
        verify(mockCameraProperties, never()).getSensorInfoPixelArraySize();
        verify(mockCameraProperties, never()).getSensorInfoActiveArraySize();
      }
    } finally {
      updateSdkVersion(0);
    }
  }

  @Test
  public void
      getCameraBoundaries_shouldReturnSensorInfoActiveArraySizeWhenDistortionCorrectionModeIsSet() {
    updateSdkVersion(Build.VERSION_CODES.P);

    try {
      CameraProperties mockCameraProperties = mock(CameraProperties.class);
      CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
      Rect mockSensorInfoActiveArraySize = mock(Rect.class);
      when(mockSensorInfoActiveArraySize.width()).thenReturn(100);
      when(mockSensorInfoActiveArraySize.height()).thenReturn(100);

      when(mockCameraProperties.getDistortionCorrectionAvailableModes())
          .thenReturn(
              new int[] {
                CaptureRequest.DISTORTION_CORRECTION_MODE_OFF,
                CaptureRequest.DISTORTION_CORRECTION_MODE_FAST
              });

      when(mockBuilder.get(CaptureRequest.DISTORTION_CORRECTION_MODE))
          .thenReturn(CaptureRequest.DISTORTION_CORRECTION_MODE_FAST);
      when(mockCameraProperties.getSensorInfoActiveArraySize())
          .thenReturn(mockSensorInfoActiveArraySize);

      try (MockedStatic<CameraRegionUtils.SizeFactory> mockedSizeFactory =
          mockStatic(CameraRegionUtils.SizeFactory.class)) {
        mockedSizeFactory
            .when(() -> CameraRegionUtils.SizeFactory.create(anyInt(), anyInt()))
            .thenAnswer(
                (Answer<Size>)
                    invocation -> {
                      Size mockSize = mock(Size.class);
                      when(mockSize.getWidth()).thenReturn(invocation.getArgument(0));
                      when(mockSize.getHeight()).thenReturn(invocation.getArgument(1));
                      return mockSize;
                    });

        Size result = CameraRegionUtils.getCameraBoundaries(mockCameraProperties, mockBuilder);

        assertEquals(100, result.getWidth());
        assertEquals(100, result.getHeight());
        verify(mockCameraProperties, never()).getSensorInfoPixelArraySize();
        verify(mockCameraProperties, never()).getSensorInfoPreCorrectionActiveArraySize();
      }
    } finally {
      updateSdkVersion(0);
    }
  }

  private static void updateSdkVersion(int version) {
    TestUtils.setFinalStatic(Build.VERSION.class, "SDK_INT", version);
  }
}
