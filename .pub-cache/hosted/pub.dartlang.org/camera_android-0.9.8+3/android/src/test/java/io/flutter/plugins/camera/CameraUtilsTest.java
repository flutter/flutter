// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.Context;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import java.util.List;
import java.util.Map;
import org.junit.Test;

public class CameraUtilsTest {

  @Test
  public void serializeDeviceOrientation_serializesCorrectly() {
    assertEquals(
        "portraitUp",
        CameraUtils.serializeDeviceOrientation(PlatformChannel.DeviceOrientation.PORTRAIT_UP));
    assertEquals(
        "portraitDown",
        CameraUtils.serializeDeviceOrientation(PlatformChannel.DeviceOrientation.PORTRAIT_DOWN));
    assertEquals(
        "landscapeLeft",
        CameraUtils.serializeDeviceOrientation(PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT));
    assertEquals(
        "landscapeRight",
        CameraUtils.serializeDeviceOrientation(PlatformChannel.DeviceOrientation.LANDSCAPE_RIGHT));
  }

  @Test(expected = UnsupportedOperationException.class)
  public void serializeDeviceOrientation_throws_for_null() {
    CameraUtils.serializeDeviceOrientation(null);
  }

  @Test
  public void deserializeDeviceOrientation_deserializesCorrectly() {
    assertEquals(
        PlatformChannel.DeviceOrientation.PORTRAIT_UP,
        CameraUtils.deserializeDeviceOrientation("portraitUp"));
    assertEquals(
        PlatformChannel.DeviceOrientation.PORTRAIT_DOWN,
        CameraUtils.deserializeDeviceOrientation("portraitDown"));
    assertEquals(
        PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT,
        CameraUtils.deserializeDeviceOrientation("landscapeLeft"));
    assertEquals(
        PlatformChannel.DeviceOrientation.LANDSCAPE_RIGHT,
        CameraUtils.deserializeDeviceOrientation("landscapeRight"));
  }

  @Test(expected = UnsupportedOperationException.class)
  public void deserializeDeviceOrientation_throwsForNull() {
    CameraUtils.deserializeDeviceOrientation(null);
  }

  @Test
  public void getAvailableCameras_retrievesValidCameras()
      throws CameraAccessException, NumberFormatException {
    final Activity mockActivity = mock(Activity.class);
    final CameraManager mockCameraManager = mock(CameraManager.class);
    final CameraCharacteristics mockCameraCharacteristics = mock(CameraCharacteristics.class);
    final String[] mockCameraIds = {"1394902", "-192930", "0283835", "foobar"};
    final int mockSensorOrientation0 = 90;
    final int mockSensorOrientation2 = 270;
    final int mockLensFacing0 = CameraMetadata.LENS_FACING_FRONT;
    final int mockLensFacing2 = CameraMetadata.LENS_FACING_EXTERNAL;

    when(mockActivity.getSystemService(Context.CAMERA_SERVICE)).thenReturn(mockCameraManager);
    when(mockCameraManager.getCameraIdList()).thenReturn(mockCameraIds);
    when(mockCameraManager.getCameraCharacteristics(anyString()))
        .thenReturn(mockCameraCharacteristics);
    when(mockCameraCharacteristics.get(any()))
        .thenReturn(mockSensorOrientation0)
        .thenReturn(mockLensFacing0)
        .thenReturn(mockSensorOrientation2)
        .thenReturn(mockLensFacing2);

    List<Map<String, Object>> availableCameras = CameraUtils.getAvailableCameras(mockActivity);

    assertEquals(availableCameras.size(), 2);
    assertEquals(availableCameras.get(0).get("name"), "1394902");
    assertEquals(availableCameras.get(0).get("sensorOrientation"), mockSensorOrientation0);
    assertEquals(availableCameras.get(0).get("lensFacing"), "front");
    assertEquals(availableCameras.get(1).get("name"), "0283835");
    assertEquals(availableCameras.get(1).get("sensorOrientation"), mockSensorOrientation2);
    assertEquals(availableCameras.get(1).get("lensFacing"), "external");
  }
}
