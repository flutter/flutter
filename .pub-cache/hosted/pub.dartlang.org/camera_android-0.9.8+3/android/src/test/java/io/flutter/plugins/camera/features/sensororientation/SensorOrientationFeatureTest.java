// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.sensororientation;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.hardware.camera2.CameraMetadata;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.DeviceOrientation;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.DartMessenger;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

public class SensorOrientationFeatureTest {
  private MockedStatic<DeviceOrientationManager> mockedStaticDeviceOrientationManager;
  private Activity mockActivity;
  private CameraProperties mockCameraProperties;
  private DartMessenger mockDartMessenger;
  private DeviceOrientationManager mockDeviceOrientationManager;

  @Before
  public void before() {
    mockedStaticDeviceOrientationManager = mockStatic(DeviceOrientationManager.class);
    mockActivity = mock(Activity.class);
    mockCameraProperties = mock(CameraProperties.class);
    mockDartMessenger = mock(DartMessenger.class);
    mockDeviceOrientationManager = mock(DeviceOrientationManager.class);

    when(mockCameraProperties.getSensorOrientation()).thenReturn(0);
    when(mockCameraProperties.getLensFacing()).thenReturn(CameraMetadata.LENS_FACING_BACK);

    mockedStaticDeviceOrientationManager
        .when(() -> DeviceOrientationManager.create(mockActivity, mockDartMessenger, false, 0))
        .thenReturn(mockDeviceOrientationManager);
  }

  @After
  public void after() {
    mockedStaticDeviceOrientationManager.close();
  }

  @Test
  public void ctor_shouldStartDeviceOrientationManager() {
    SensorOrientationFeature sensorOrientationFeature =
        new SensorOrientationFeature(mockCameraProperties, mockActivity, mockDartMessenger);

    verify(mockDeviceOrientationManager, times(1)).start();
  }

  @Test
  public void getDebugName_shouldReturnTheNameOfTheFeature() {
    SensorOrientationFeature sensorOrientationFeature =
        new SensorOrientationFeature(mockCameraProperties, mockActivity, mockDartMessenger);

    assertEquals("SensorOrientationFeature", sensorOrientationFeature.getDebugName());
  }

  @Test
  public void getValue_shouldReturnNullIfNotSet() {
    SensorOrientationFeature sensorOrientationFeature =
        new SensorOrientationFeature(mockCameraProperties, mockActivity, mockDartMessenger);

    assertEquals(0, (int) sensorOrientationFeature.getValue());
  }

  @Test
  public void getValue_shouldEchoSetValue() {
    SensorOrientationFeature sensorOrientationFeature =
        new SensorOrientationFeature(mockCameraProperties, mockActivity, mockDartMessenger);

    sensorOrientationFeature.setValue(90);

    assertEquals(90, (int) sensorOrientationFeature.getValue());
  }

  @Test
  public void checkIsSupport_returnsTrue() {
    SensorOrientationFeature sensorOrientationFeature =
        new SensorOrientationFeature(mockCameraProperties, mockActivity, mockDartMessenger);

    assertTrue(sensorOrientationFeature.checkIsSupported());
  }

  @Test
  public void getDeviceOrientationManager_shouldReturnInitializedDartOrientationManagerInstance() {
    SensorOrientationFeature sensorOrientationFeature =
        new SensorOrientationFeature(mockCameraProperties, mockActivity, mockDartMessenger);

    assertEquals(
        mockDeviceOrientationManager, sensorOrientationFeature.getDeviceOrientationManager());
  }

  @Test
  public void lockCaptureOrientation_shouldLockToSpecifiedOrientation() {
    SensorOrientationFeature sensorOrientationFeature =
        new SensorOrientationFeature(mockCameraProperties, mockActivity, mockDartMessenger);

    sensorOrientationFeature.lockCaptureOrientation(DeviceOrientation.PORTRAIT_DOWN);

    assertEquals(
        DeviceOrientation.PORTRAIT_DOWN, sensorOrientationFeature.getLockedCaptureOrientation());
  }

  @Test
  public void unlockCaptureOrientation_shouldSetLockToNull() {
    SensorOrientationFeature sensorOrientationFeature =
        new SensorOrientationFeature(mockCameraProperties, mockActivity, mockDartMessenger);

    sensorOrientationFeature.unlockCaptureOrientation();

    assertNull(sensorOrientationFeature.getLockedCaptureOrientation());
  }
}
