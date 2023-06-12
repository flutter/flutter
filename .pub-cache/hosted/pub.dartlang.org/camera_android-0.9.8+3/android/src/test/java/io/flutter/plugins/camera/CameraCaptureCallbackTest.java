// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import static org.mockito.ArgumentMatchers.anyFloat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.CaptureResult;
import android.hardware.camera2.TotalCaptureResult;
import io.flutter.plugins.camera.types.CameraCaptureProperties;
import io.flutter.plugins.camera.types.CaptureTimeoutsWrapper;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public class CameraCaptureCallbackTest {

  private CameraCaptureCallback cameraCaptureCallback;
  private CameraCaptureProperties mockCaptureProps;

  @Before
  public void setUp() {
    CameraCaptureCallback.CameraCaptureStateListener mockCaptureStateListener =
        mock(CameraCaptureCallback.CameraCaptureStateListener.class);
    CaptureTimeoutsWrapper mockCaptureTimeouts = mock(CaptureTimeoutsWrapper.class);
    mockCaptureProps = mock(CameraCaptureProperties.class);
    cameraCaptureCallback =
        CameraCaptureCallback.create(
            mockCaptureStateListener, mockCaptureTimeouts, mockCaptureProps);
  }

  @Test
  public void onCaptureProgressed_doesNotUpdateCameraCaptureProperties() {
    CameraCaptureSession mockSession = mock(CameraCaptureSession.class);
    CaptureRequest mockRequest = mock(CaptureRequest.class);
    CaptureResult mockResult = mock(CaptureResult.class);

    cameraCaptureCallback.onCaptureProgressed(mockSession, mockRequest, mockResult);

    verify(mockCaptureProps, never()).setLastLensAperture(anyFloat());
    verify(mockCaptureProps, never()).setLastSensorExposureTime(anyLong());
    verify(mockCaptureProps, never()).setLastSensorSensitivity(anyInt());
  }

  @Test
  public void onCaptureCompleted_updatesCameraCaptureProperties() {
    CameraCaptureSession mockSession = mock(CameraCaptureSession.class);
    CaptureRequest mockRequest = mock(CaptureRequest.class);
    TotalCaptureResult mockResult = mock(TotalCaptureResult.class);
    when(mockResult.get(CaptureResult.LENS_APERTURE)).thenReturn(1.0f);
    when(mockResult.get(CaptureResult.SENSOR_EXPOSURE_TIME)).thenReturn(2L);
    when(mockResult.get(CaptureResult.SENSOR_SENSITIVITY)).thenReturn(3);

    cameraCaptureCallback.onCaptureCompleted(mockSession, mockRequest, mockResult);

    verify(mockCaptureProps, times(1)).setLastLensAperture(1.0f);
    verify(mockCaptureProps, times(1)).setLastSensorExposureTime(2L);
    verify(mockCaptureProps, times(1)).setLastSensorSensitivity(3);
  }
}
