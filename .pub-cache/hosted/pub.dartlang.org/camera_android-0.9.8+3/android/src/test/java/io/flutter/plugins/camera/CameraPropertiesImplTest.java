// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.fail;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.graphics.Rect;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.util.Range;
import android.util.Rational;
import android.util.Size;
import org.junit.Before;
import org.junit.Test;

public class CameraPropertiesImplTest {
  private static final String CAMERA_NAME = "test_camera";
  private final CameraCharacteristics mockCharacteristics = mock(CameraCharacteristics.class);
  private final CameraManager mockCameraManager = mock(CameraManager.class);

  private CameraPropertiesImpl cameraProperties;

  @Before
  public void before() {
    try {
      when(mockCameraManager.getCameraCharacteristics(CAMERA_NAME)).thenReturn(mockCharacteristics);
      cameraProperties = new CameraPropertiesImpl(CAMERA_NAME, mockCameraManager);
    } catch (CameraAccessException e) {
      fail();
    }
  }

  @Test
  public void ctor_shouldReturnValidInstance() throws CameraAccessException {
    verify(mockCameraManager, times(1)).getCameraCharacteristics(CAMERA_NAME);
    assertNotNull(cameraProperties);
  }

  @Test
  @SuppressWarnings("unchecked")
  public void getControlAutoExposureAvailableTargetFpsRangesTest() {
    Range<Integer> mockRange = mock(Range.class);
    Range<Integer>[] mockRanges = new Range[] {mockRange};
    when(mockCharacteristics.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES))
        .thenReturn(mockRanges);

    Range<Integer>[] actualRanges =
        cameraProperties.getControlAutoExposureAvailableTargetFpsRanges();

    verify(mockCharacteristics, times(1))
        .get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES);
    assertArrayEquals(actualRanges, mockRanges);
  }

  @Test
  @SuppressWarnings("unchecked")
  public void getControlAutoExposureCompensationRangeTest() {
    Range<Integer> mockRange = mock(Range.class);
    when(mockCharacteristics.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE))
        .thenReturn(mockRange);

    Range<Integer> actualRange = cameraProperties.getControlAutoExposureCompensationRange();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE);
    assertEquals(actualRange, mockRange);
  }

  @Test
  public void getControlAutoExposureCompensationStep_shouldReturnDoubleWhenRationalIsNotNull() {
    double expectedStep = 3.1415926535;
    Rational mockRational = mock(Rational.class);

    when(mockCharacteristics.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_STEP))
        .thenReturn(mockRational);
    when(mockRational.doubleValue()).thenReturn(expectedStep);

    double actualSteps = cameraProperties.getControlAutoExposureCompensationStep();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.CONTROL_AE_COMPENSATION_STEP);
    assertEquals(actualSteps, expectedStep, 0);
  }

  @Test
  public void getControlAutoExposureCompensationStep_shouldReturnZeroWhenRationalIsNull() {
    double expectedStep = 0.0;

    when(mockCharacteristics.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_STEP))
        .thenReturn(null);

    double actualSteps = cameraProperties.getControlAutoExposureCompensationStep();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.CONTROL_AE_COMPENSATION_STEP);
    assertEquals(actualSteps, expectedStep, 0);
  }

  @Test
  public void getControlAutoFocusAvailableModesTest() {
    int[] expectedAutoFocusModes = new int[] {0, 1, 2};
    when(mockCharacteristics.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES))
        .thenReturn(expectedAutoFocusModes);

    int[] actualAutoFocusModes = cameraProperties.getControlAutoFocusAvailableModes();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES);
    assertEquals(actualAutoFocusModes, expectedAutoFocusModes);
  }

  @Test
  public void getControlMaxRegionsAutoExposureTest() {
    int expectedRegions = 42;
    when(mockCharacteristics.get(CameraCharacteristics.CONTROL_MAX_REGIONS_AE))
        .thenReturn(expectedRegions);

    int actualRegions = cameraProperties.getControlMaxRegionsAutoExposure();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.CONTROL_MAX_REGIONS_AE);
    assertEquals(actualRegions, expectedRegions);
  }

  @Test
  public void getControlMaxRegionsAutoFocusTest() {
    int expectedRegions = 42;
    when(mockCharacteristics.get(CameraCharacteristics.CONTROL_MAX_REGIONS_AF))
        .thenReturn(expectedRegions);

    int actualRegions = cameraProperties.getControlMaxRegionsAutoFocus();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.CONTROL_MAX_REGIONS_AF);
    assertEquals(actualRegions, expectedRegions);
  }

  @Test
  public void getDistortionCorrectionAvailableModesTest() {
    int[] expectedCorrectionModes = new int[] {0, 1, 2};
    when(mockCharacteristics.get(CameraCharacteristics.DISTORTION_CORRECTION_AVAILABLE_MODES))
        .thenReturn(expectedCorrectionModes);

    int[] actualCorrectionModes = cameraProperties.getDistortionCorrectionAvailableModes();

    verify(mockCharacteristics, times(1))
        .get(CameraCharacteristics.DISTORTION_CORRECTION_AVAILABLE_MODES);
    assertEquals(actualCorrectionModes, expectedCorrectionModes);
  }

  @Test
  public void getFlashInfoAvailableTest() {
    boolean expectedAvailability = true;
    when(mockCharacteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE))
        .thenReturn(expectedAvailability);

    boolean actualAvailability = cameraProperties.getFlashInfoAvailable();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.FLASH_INFO_AVAILABLE);
    assertEquals(actualAvailability, expectedAvailability);
  }

  @Test
  public void getLensFacingTest() {
    int expectedFacing = 42;
    when(mockCharacteristics.get(CameraCharacteristics.LENS_FACING)).thenReturn(expectedFacing);

    int actualFacing = cameraProperties.getLensFacing();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.LENS_FACING);
    assertEquals(actualFacing, expectedFacing);
  }

  @Test
  public void getLensInfoMinimumFocusDistanceTest() {
    Float expectedFocusDistance = new Float(3.14);
    when(mockCharacteristics.get(CameraCharacteristics.LENS_INFO_MINIMUM_FOCUS_DISTANCE))
        .thenReturn(expectedFocusDistance);

    Float actualFocusDistance = cameraProperties.getLensInfoMinimumFocusDistance();

    verify(mockCharacteristics, times(1))
        .get(CameraCharacteristics.LENS_INFO_MINIMUM_FOCUS_DISTANCE);
    assertEquals(actualFocusDistance, expectedFocusDistance);
  }

  @Test
  public void getScalerAvailableMaxDigitalZoomTest() {
    Float expectedDigitalZoom = new Float(3.14);
    when(mockCharacteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM))
        .thenReturn(expectedDigitalZoom);

    Float actualDigitalZoom = cameraProperties.getScalerAvailableMaxDigitalZoom();

    verify(mockCharacteristics, times(1))
        .get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM);
    assertEquals(actualDigitalZoom, expectedDigitalZoom);
  }

  @Test
  public void getSensorInfoActiveArraySizeTest() {
    Rect expectedArraySize = mock(Rect.class);
    when(mockCharacteristics.get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE))
        .thenReturn(expectedArraySize);

    Rect actualArraySize = cameraProperties.getSensorInfoActiveArraySize();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE);
    assertEquals(actualArraySize, expectedArraySize);
  }

  @Test
  public void getSensorInfoPixelArraySizeTest() {
    Size expectedArraySize = mock(Size.class);
    when(mockCharacteristics.get(CameraCharacteristics.SENSOR_INFO_PIXEL_ARRAY_SIZE))
        .thenReturn(expectedArraySize);

    Size actualArraySize = cameraProperties.getSensorInfoPixelArraySize();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.SENSOR_INFO_PIXEL_ARRAY_SIZE);
    assertEquals(actualArraySize, expectedArraySize);
  }

  @Test
  public void getSensorInfoPreCorrectionActiveArraySize() {
    Rect expectedArraySize = mock(Rect.class);
    when(mockCharacteristics.get(
            CameraCharacteristics.SENSOR_INFO_PRE_CORRECTION_ACTIVE_ARRAY_SIZE))
        .thenReturn(expectedArraySize);

    Rect actualArraySize = cameraProperties.getSensorInfoPreCorrectionActiveArraySize();

    verify(mockCharacteristics, times(1))
        .get(CameraCharacteristics.SENSOR_INFO_PRE_CORRECTION_ACTIVE_ARRAY_SIZE);
    assertEquals(actualArraySize, expectedArraySize);
  }

  @Test
  public void getSensorOrientationTest() {
    int expectedOrientation = 42;
    when(mockCharacteristics.get(CameraCharacteristics.SENSOR_ORIENTATION))
        .thenReturn(expectedOrientation);

    int actualOrientation = cameraProperties.getSensorOrientation();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.SENSOR_ORIENTATION);
    assertEquals(actualOrientation, expectedOrientation);
  }

  @Test
  public void getHardwareLevelTest() {
    int expectedLevel = 42;
    when(mockCharacteristics.get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL))
        .thenReturn(expectedLevel);

    int actualLevel = cameraProperties.getHardwareLevel();

    verify(mockCharacteristics, times(1)).get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL);
    assertEquals(actualLevel, expectedLevel);
  }

  @Test
  public void getAvailableNoiseReductionModesTest() {
    int[] expectedReductionModes = new int[] {0, 1, 2};
    when(mockCharacteristics.get(
            CameraCharacteristics.NOISE_REDUCTION_AVAILABLE_NOISE_REDUCTION_MODES))
        .thenReturn(expectedReductionModes);

    int[] actualReductionModes = cameraProperties.getAvailableNoiseReductionModes();

    verify(mockCharacteristics, times(1))
        .get(CameraCharacteristics.NOISE_REDUCTION_AVAILABLE_NOISE_REDUCTION_MODES);
    assertEquals(actualReductionModes, expectedReductionModes);
  }
}
