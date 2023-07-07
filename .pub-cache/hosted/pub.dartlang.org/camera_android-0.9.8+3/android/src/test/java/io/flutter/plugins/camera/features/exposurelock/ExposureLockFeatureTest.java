// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.exposurelock;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import android.hardware.camera2.CaptureRequest;
import io.flutter.plugins.camera.CameraProperties;
import org.junit.Test;

public class ExposureLockFeatureTest {
  @Test
  public void getDebugName_shouldReturnTheNameOfTheFeature() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposureLockFeature exposureLockFeature = new ExposureLockFeature(mockCameraProperties);

    assertEquals("ExposureLockFeature", exposureLockFeature.getDebugName());
  }

  @Test
  public void getValue_shouldReturnAutoIfNotSet() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposureLockFeature exposureLockFeature = new ExposureLockFeature(mockCameraProperties);

    assertEquals(ExposureMode.auto, exposureLockFeature.getValue());
  }

  @Test
  public void getValue_shouldEchoTheSetValue() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposureLockFeature exposureLockFeature = new ExposureLockFeature(mockCameraProperties);
    ExposureMode expectedValue = ExposureMode.locked;

    exposureLockFeature.setValue(expectedValue);
    ExposureMode actualValue = exposureLockFeature.getValue();

    assertEquals(expectedValue, actualValue);
  }

  @Test
  public void checkIsSupported_shouldReturnTrue() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ExposureLockFeature exposureLockFeature = new ExposureLockFeature(mockCameraProperties);

    assertTrue(exposureLockFeature.checkIsSupported());
  }

  @Test
  public void updateBuilder_shouldSetControlAeLockToFalseWhenAutoExposureIsSetToAuto() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
    ExposureLockFeature exposureLockFeature = new ExposureLockFeature(mockCameraProperties);

    exposureLockFeature.setValue(ExposureMode.auto);
    exposureLockFeature.updateBuilder(mockBuilder);

    verify(mockBuilder, times(1)).set(CaptureRequest.CONTROL_AE_LOCK, false);
  }

  @Test
  public void updateBuilder_shouldSetControlAeLockToFalseWhenAutoExposureIsSetToLocked() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
    ExposureLockFeature exposureLockFeature = new ExposureLockFeature(mockCameraProperties);

    exposureLockFeature.setValue(ExposureMode.locked);
    exposureLockFeature.updateBuilder(mockBuilder);

    verify(mockBuilder, times(1)).set(CaptureRequest.CONTROL_AE_LOCK, true);
  }
}
