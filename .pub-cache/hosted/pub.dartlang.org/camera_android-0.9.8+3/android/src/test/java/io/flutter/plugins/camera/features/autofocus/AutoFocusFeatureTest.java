// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.autofocus;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CaptureRequest;
import io.flutter.plugins.camera.CameraProperties;
import org.junit.Test;

public class AutoFocusFeatureTest {
  private static final int[] FOCUS_MODES_ONLY_OFF =
      new int[] {CameraCharacteristics.CONTROL_AF_MODE_OFF};
  private static final int[] FOCUS_MODES =
      new int[] {
        CameraCharacteristics.CONTROL_AF_MODE_OFF, CameraCharacteristics.CONTROL_AF_MODE_AUTO
      };

  @Test
  public void getDebugName_shouldReturnTheNameOfTheFeature() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);

    assertEquals("AutoFocusFeature", autoFocusFeature.getDebugName());
  }

  @Test
  public void getValue_shouldReturnAutoIfNotSet() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);

    assertEquals(FocusMode.auto, autoFocusFeature.getValue());
  }

  @Test
  public void getValue_shouldEchoTheSetValue() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);
    FocusMode expectedValue = FocusMode.locked;

    autoFocusFeature.setValue(expectedValue);
    FocusMode actualValue = autoFocusFeature.getValue();

    assertEquals(expectedValue, actualValue);
  }

  @Test
  public void checkIsSupported_shouldReturnFalseWhenMinimumFocusDistanceIsZero() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);

    when(mockCameraProperties.getControlAutoFocusAvailableModes()).thenReturn(FOCUS_MODES);
    when(mockCameraProperties.getLensInfoMinimumFocusDistance()).thenReturn(0.0F);

    assertFalse(autoFocusFeature.checkIsSupported());
  }

  @Test
  public void checkIsSupported_shouldReturnFalseWhenMinimumFocusDistanceIsNull() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);

    when(mockCameraProperties.getControlAutoFocusAvailableModes()).thenReturn(FOCUS_MODES);
    when(mockCameraProperties.getLensInfoMinimumFocusDistance()).thenReturn(null);

    assertFalse(autoFocusFeature.checkIsSupported());
  }

  @Test
  public void checkIsSupport_shouldReturnFalseWhenNoFocusModesAreAvailable() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);

    when(mockCameraProperties.getControlAutoFocusAvailableModes()).thenReturn(new int[] {});
    when(mockCameraProperties.getLensInfoMinimumFocusDistance()).thenReturn(1.0F);

    assertFalse(autoFocusFeature.checkIsSupported());
  }

  @Test
  public void checkIsSupport_shouldReturnFalseWhenOnlyFocusOffIsAvailable() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);

    when(mockCameraProperties.getControlAutoFocusAvailableModes()).thenReturn(FOCUS_MODES_ONLY_OFF);
    when(mockCameraProperties.getLensInfoMinimumFocusDistance()).thenReturn(1.0F);

    assertFalse(autoFocusFeature.checkIsSupported());
  }

  @Test
  public void checkIsSupport_shouldReturnTrueWhenOnlyMultipleFocusModesAreAvailable() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);

    when(mockCameraProperties.getControlAutoFocusAvailableModes()).thenReturn(FOCUS_MODES);
    when(mockCameraProperties.getLensInfoMinimumFocusDistance()).thenReturn(1.0F);

    assertTrue(autoFocusFeature.checkIsSupported());
  }

  @Test
  public void updateBuilderShouldReturnWhenCheckIsSupportedIsFalse() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);

    when(mockCameraProperties.getControlAutoFocusAvailableModes()).thenReturn(FOCUS_MODES);
    when(mockCameraProperties.getLensInfoMinimumFocusDistance()).thenReturn(0.0F);

    autoFocusFeature.updateBuilder(mockBuilder);

    verify(mockBuilder, never()).set(any(), any());
  }

  @Test
  public void updateBuilder_shouldSetControlModeToAutoWhenFocusIsLocked() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);

    when(mockCameraProperties.getControlAutoFocusAvailableModes()).thenReturn(FOCUS_MODES);
    when(mockCameraProperties.getLensInfoMinimumFocusDistance()).thenReturn(1.0F);

    autoFocusFeature.setValue(FocusMode.locked);
    autoFocusFeature.updateBuilder(mockBuilder);

    verify(mockBuilder, times(1))
        .set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_AUTO);
  }

  @Test
  public void
      updateBuilder_shouldSetControlModeToContinuousVideoWhenFocusIsAutoAndRecordingVideo() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, true);

    when(mockCameraProperties.getControlAutoFocusAvailableModes()).thenReturn(FOCUS_MODES);
    when(mockCameraProperties.getLensInfoMinimumFocusDistance()).thenReturn(1.0F);

    autoFocusFeature.setValue(FocusMode.auto);
    autoFocusFeature.updateBuilder(mockBuilder);

    verify(mockBuilder, times(1))
        .set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_VIDEO);
  }

  @Test
  public void
      updateBuilder_shouldSetControlModeToContinuousVideoWhenFocusIsAutoAndNotRecordingVideo() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
    AutoFocusFeature autoFocusFeature = new AutoFocusFeature(mockCameraProperties, false);

    when(mockCameraProperties.getControlAutoFocusAvailableModes()).thenReturn(FOCUS_MODES);
    when(mockCameraProperties.getLensInfoMinimumFocusDistance()).thenReturn(1.0F);

    autoFocusFeature.setValue(FocusMode.auto);
    autoFocusFeature.updateBuilder(mockBuilder);

    verify(mockBuilder, times(1))
        .set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
  }
}
