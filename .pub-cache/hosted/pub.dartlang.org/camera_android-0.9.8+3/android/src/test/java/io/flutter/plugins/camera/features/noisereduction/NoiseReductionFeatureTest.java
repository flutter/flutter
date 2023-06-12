// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.noisereduction;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.hardware.camera2.CaptureRequest;
import android.os.Build.VERSION;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.utils.TestUtils;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

public class NoiseReductionFeatureTest {
  @Before
  public void before() {
    // Make sure the VERSION.SDK_INT field returns 23, to allow using all available
    // noise reduction modes in tests.
    TestUtils.setFinalStatic(VERSION.class, "SDK_INT", 23);
  }

  @After
  public void after() {
    // Make sure we reset the VERSION.SDK_INT field to it's original value.
    TestUtils.setFinalStatic(VERSION.class, "SDK_INT", 0);
  }

  @Test
  public void getDebugName_shouldReturnTheNameOfTheFeature() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    NoiseReductionFeature noiseReductionFeature = new NoiseReductionFeature(mockCameraProperties);

    assertEquals("NoiseReductionFeature", noiseReductionFeature.getDebugName());
  }

  @Test
  public void getValue_shouldReturnFastIfNotSet() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    NoiseReductionFeature noiseReductionFeature = new NoiseReductionFeature(mockCameraProperties);

    assertEquals(NoiseReductionMode.fast, noiseReductionFeature.getValue());
  }

  @Test
  public void getValue_shouldEchoTheSetValue() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    NoiseReductionFeature noiseReductionFeature = new NoiseReductionFeature(mockCameraProperties);
    NoiseReductionMode expectedValue = NoiseReductionMode.fast;

    noiseReductionFeature.setValue(expectedValue);
    NoiseReductionMode actualValue = noiseReductionFeature.getValue();

    assertEquals(expectedValue, actualValue);
  }

  @Test
  public void checkIsSupported_shouldReturnFalseWhenAvailableNoiseReductionModesIsNull() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    NoiseReductionFeature noiseReductionFeature = new NoiseReductionFeature(mockCameraProperties);

    when(mockCameraProperties.getAvailableNoiseReductionModes()).thenReturn(null);

    assertFalse(noiseReductionFeature.checkIsSupported());
  }

  @Test
  public void
      checkIsSupported_shouldReturnFalseWhenAvailableNoiseReductionModesReturnsAnEmptyArray() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    NoiseReductionFeature noiseReductionFeature = new NoiseReductionFeature(mockCameraProperties);

    when(mockCameraProperties.getAvailableNoiseReductionModes()).thenReturn(new int[] {});

    assertFalse(noiseReductionFeature.checkIsSupported());
  }

  @Test
  public void
      checkIsSupported_shouldReturnTrueWhenAvailableNoiseReductionModesReturnsAtLeastOneItem() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    NoiseReductionFeature noiseReductionFeature = new NoiseReductionFeature(mockCameraProperties);

    when(mockCameraProperties.getAvailableNoiseReductionModes()).thenReturn(new int[] {1});

    assertTrue(noiseReductionFeature.checkIsSupported());
  }

  @Test
  public void updateBuilder_shouldReturnWhenCheckIsSupportedIsFalse() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
    NoiseReductionFeature noiseReductionFeature = new NoiseReductionFeature(mockCameraProperties);

    when(mockCameraProperties.getAvailableNoiseReductionModes()).thenReturn(new int[] {});

    noiseReductionFeature.updateBuilder(mockBuilder);

    verify(mockBuilder, never()).set(any(), any());
  }

  @Test
  public void updateBuilder_shouldSetNoiseReductionModeOffWhenOff() {
    testUpdateBuilderWith(NoiseReductionMode.off, CaptureRequest.NOISE_REDUCTION_MODE_OFF);
  }

  @Test
  public void updateBuilder_shouldSetNoiseReductionModeFastWhenFast() {
    testUpdateBuilderWith(NoiseReductionMode.fast, CaptureRequest.NOISE_REDUCTION_MODE_FAST);
  }

  @Test
  public void updateBuilder_shouldSetNoiseReductionModeHighQualityWhenHighQuality() {
    testUpdateBuilderWith(
        NoiseReductionMode.highQuality, CaptureRequest.NOISE_REDUCTION_MODE_HIGH_QUALITY);
  }

  @Test
  public void updateBuilder_shouldSetNoiseReductionModeMinimalWhenMinimal() {
    testUpdateBuilderWith(NoiseReductionMode.minimal, CaptureRequest.NOISE_REDUCTION_MODE_MINIMAL);
  }

  @Test
  public void updateBuilder_shouldSetNoiseReductionModeZeroShutterLagWhenZeroShutterLag() {
    testUpdateBuilderWith(
        NoiseReductionMode.zeroShutterLag, CaptureRequest.NOISE_REDUCTION_MODE_ZERO_SHUTTER_LAG);
  }

  private static void testUpdateBuilderWith(NoiseReductionMode mode, int expectedResult) {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
    NoiseReductionFeature noiseReductionFeature = new NoiseReductionFeature(mockCameraProperties);

    when(mockCameraProperties.getAvailableNoiseReductionModes()).thenReturn(new int[] {1});

    noiseReductionFeature.setValue(mode);
    noiseReductionFeature.updateBuilder(mockBuilder);
    verify(mockBuilder, times(1)).set(CaptureRequest.NOISE_REDUCTION_MODE, expectedResult);
  }
}
