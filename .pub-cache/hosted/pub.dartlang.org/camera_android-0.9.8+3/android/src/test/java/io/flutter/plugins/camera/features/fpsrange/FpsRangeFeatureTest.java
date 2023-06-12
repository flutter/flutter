// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.fpsrange;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.hardware.camera2.CaptureRequest;
import android.os.Build;
import android.util.Range;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.utils.TestUtils;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

public class FpsRangeFeatureTest {
  @Before
  public void before() {
    TestUtils.setFinalStatic(Build.class, "BRAND", "Test Brand");
    TestUtils.setFinalStatic(Build.class, "MODEL", "Test Model");
  }

  @After
  public void after() {
    TestUtils.setFinalStatic(Build.class, "BRAND", null);
    TestUtils.setFinalStatic(Build.class, "MODEL", null);
  }

  @Test
  public void ctor_shouldInitializeFpsRangeWithHighestUpperValueFromRangeArray() {
    FpsRangeFeature fpsRangeFeature = createTestInstance();
    assertEquals(13, (int) fpsRangeFeature.getValue().getUpper());
  }

  @Test
  public void getDebugName_shouldReturnTheNameOfTheFeature() {
    FpsRangeFeature fpsRangeFeature = createTestInstance();
    assertEquals("FpsRangeFeature", fpsRangeFeature.getDebugName());
  }

  @Test
  public void getValue_shouldReturnHighestUpperRangeIfNotSet() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    FpsRangeFeature fpsRangeFeature = createTestInstance();

    assertEquals(13, (int) fpsRangeFeature.getValue().getUpper());
  }

  @Test
  public void getValue_shouldEchoTheSetValue() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    FpsRangeFeature fpsRangeFeature = new FpsRangeFeature(mockCameraProperties);
    @SuppressWarnings("unchecked")
    Range<Integer> expectedValue = mock(Range.class);

    fpsRangeFeature.setValue(expectedValue);
    Range<Integer> actualValue = fpsRangeFeature.getValue();

    assertEquals(expectedValue, actualValue);
  }

  @Test
  public void checkIsSupported_shouldReturnTrue() {
    FpsRangeFeature fpsRangeFeature = createTestInstance();
    assertTrue(fpsRangeFeature.checkIsSupported());
  }

  @Test
  @SuppressWarnings("unchecked")
  public void updateBuilder_shouldSetAeTargetFpsRange() {
    CaptureRequest.Builder mockBuilder = mock(CaptureRequest.Builder.class);
    FpsRangeFeature fpsRangeFeature = createTestInstance();

    fpsRangeFeature.updateBuilder(mockBuilder);

    verify(mockBuilder).set(eq(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE), any(Range.class));
  }

  private static FpsRangeFeature createTestInstance() {
    @SuppressWarnings("unchecked")
    Range<Integer> rangeOne = mock(Range.class);
    @SuppressWarnings("unchecked")
    Range<Integer> rangeTwo = mock(Range.class);
    @SuppressWarnings("unchecked")
    Range<Integer> rangeThree = mock(Range.class);

    when(rangeOne.getUpper()).thenReturn(11);
    when(rangeTwo.getUpper()).thenReturn(12);
    when(rangeThree.getUpper()).thenReturn(13);

    @SuppressWarnings("unchecked")
    Range<Integer>[] ranges = new Range[] {rangeOne, rangeTwo, rangeThree};

    CameraProperties cameraProperties = mock(CameraProperties.class);

    when(cameraProperties.getControlAutoExposureAvailableTargetFpsRanges()).thenReturn(ranges);

    return new FpsRangeFeature(cameraProperties);
  }
}
