// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.sensororientation;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.provider.Settings;
import android.view.Display;
import android.view.Surface;
import android.view.WindowManager;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.DeviceOrientation;
import io.flutter.plugins.camera.DartMessenger;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

public class DeviceOrientationManagerTest {
  private Activity mockActivity;
  private DartMessenger mockDartMessenger;
  private WindowManager mockWindowManager;
  private Display mockDisplay;
  private DeviceOrientationManager deviceOrientationManager;

  @Before
  @SuppressWarnings("deprecation")
  public void before() {
    mockActivity = mock(Activity.class);
    mockDartMessenger = mock(DartMessenger.class);
    mockDisplay = mock(Display.class);
    mockWindowManager = mock(WindowManager.class);

    when(mockActivity.getSystemService(Context.WINDOW_SERVICE)).thenReturn(mockWindowManager);
    when(mockWindowManager.getDefaultDisplay()).thenReturn(mockDisplay);

    deviceOrientationManager =
        DeviceOrientationManager.create(mockActivity, mockDartMessenger, false, 0);
  }

  @Test
  public void getVideoOrientation_whenNaturalScreenOrientationEqualsPortraitUp() {
    int degreesPortraitUp =
        deviceOrientationManager.getVideoOrientation(DeviceOrientation.PORTRAIT_UP);
    int degreesPortraitDown =
        deviceOrientationManager.getVideoOrientation(DeviceOrientation.PORTRAIT_DOWN);
    int degreesLandscapeLeft =
        deviceOrientationManager.getVideoOrientation(DeviceOrientation.LANDSCAPE_LEFT);
    int degreesLandscapeRight =
        deviceOrientationManager.getVideoOrientation(DeviceOrientation.LANDSCAPE_RIGHT);

    assertEquals(0, degreesPortraitUp);
    assertEquals(270, degreesLandscapeLeft);
    assertEquals(180, degreesPortraitDown);
    assertEquals(90, degreesLandscapeRight);
  }

  @Test
  public void getVideoOrientation_whenNaturalScreenOrientationEqualsLandscapeLeft() {
    DeviceOrientationManager orientationManager =
        DeviceOrientationManager.create(mockActivity, mockDartMessenger, false, 90);

    int degreesPortraitUp = orientationManager.getVideoOrientation(DeviceOrientation.PORTRAIT_UP);
    int degreesPortraitDown =
        orientationManager.getVideoOrientation(DeviceOrientation.PORTRAIT_DOWN);
    int degreesLandscapeLeft =
        orientationManager.getVideoOrientation(DeviceOrientation.LANDSCAPE_LEFT);
    int degreesLandscapeRight =
        orientationManager.getVideoOrientation(DeviceOrientation.LANDSCAPE_RIGHT);

    assertEquals(90, degreesPortraitUp);
    assertEquals(0, degreesLandscapeLeft);
    assertEquals(270, degreesPortraitDown);
    assertEquals(180, degreesLandscapeRight);
  }

  @Test
  public void getVideoOrientation_fallbackToPortraitSensorOrientationWhenOrientationIsNull() {
    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_0);

    int degrees = deviceOrientationManager.getVideoOrientation(null);

    assertEquals(0, degrees);
  }

  @Test
  public void getVideoOrientation_fallbackToLandscapeSensorOrientationWhenOrientationIsNull() {
    setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_0);

    DeviceOrientationManager orientationManager =
        DeviceOrientationManager.create(mockActivity, mockDartMessenger, false, 90);

    int degrees = orientationManager.getVideoOrientation(null);

    assertEquals(0, degrees);
  }

  @Test
  public void getPhotoOrientation_whenNaturalScreenOrientationEqualsPortraitUp() {
    int degreesPortraitUp =
        deviceOrientationManager.getPhotoOrientation(DeviceOrientation.PORTRAIT_UP);
    int degreesPortraitDown =
        deviceOrientationManager.getPhotoOrientation(DeviceOrientation.PORTRAIT_DOWN);
    int degreesLandscapeLeft =
        deviceOrientationManager.getPhotoOrientation(DeviceOrientation.LANDSCAPE_LEFT);
    int degreesLandscapeRight =
        deviceOrientationManager.getPhotoOrientation(DeviceOrientation.LANDSCAPE_RIGHT);

    assertEquals(0, degreesPortraitUp);
    assertEquals(90, degreesLandscapeRight);
    assertEquals(180, degreesPortraitDown);
    assertEquals(270, degreesLandscapeLeft);
  }

  @Test
  public void getPhotoOrientation_whenNaturalScreenOrientationEqualsLandscapeLeft() {
    DeviceOrientationManager orientationManager =
        DeviceOrientationManager.create(mockActivity, mockDartMessenger, false, 90);

    int degreesPortraitUp = orientationManager.getPhotoOrientation(DeviceOrientation.PORTRAIT_UP);
    int degreesPortraitDown =
        orientationManager.getPhotoOrientation(DeviceOrientation.PORTRAIT_DOWN);
    int degreesLandscapeLeft =
        orientationManager.getPhotoOrientation(DeviceOrientation.LANDSCAPE_LEFT);
    int degreesLandscapeRight =
        orientationManager.getPhotoOrientation(DeviceOrientation.LANDSCAPE_RIGHT);

    assertEquals(90, degreesPortraitUp);
    assertEquals(180, degreesLandscapeRight);
    assertEquals(270, degreesPortraitDown);
    assertEquals(0, degreesLandscapeLeft);
  }

  @Test
  public void getPhotoOrientation_shouldFallbackToCurrentOrientationWhenOrientationIsNull() {
    setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_0);

    int degrees = deviceOrientationManager.getPhotoOrientation(null);

    assertEquals(270, degrees);
  }

  @Test
  public void handleUIOrientationChange_shouldSendMessageWhenSensorAccessIsAllowed() {
    try (MockedStatic<Settings.System> mockedSystem = mockStatic(Settings.System.class)) {
      mockedSystem
          .when(
              () ->
                  Settings.System.getInt(any(), eq(Settings.System.ACCELEROMETER_ROTATION), eq(0)))
          .thenReturn(0);
      setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_0);

      deviceOrientationManager.handleUIOrientationChange();
    }

    verify(mockDartMessenger, times(1))
        .sendDeviceOrientationChangeEvent(DeviceOrientation.LANDSCAPE_LEFT);
  }

  @Test
  public void handleOrientationChange_shouldSendMessageWhenOrientationIsUpdated() {
    DeviceOrientation previousOrientation = DeviceOrientation.PORTRAIT_UP;
    DeviceOrientation newOrientation = DeviceOrientation.LANDSCAPE_LEFT;

    DeviceOrientationManager.handleOrientationChange(
        newOrientation, previousOrientation, mockDartMessenger);

    verify(mockDartMessenger, times(1)).sendDeviceOrientationChangeEvent(newOrientation);
  }

  @Test
  public void handleOrientationChange_shouldNotSendMessageWhenOrientationIsNotUpdated() {
    DeviceOrientation previousOrientation = DeviceOrientation.PORTRAIT_UP;
    DeviceOrientation newOrientation = DeviceOrientation.PORTRAIT_UP;

    DeviceOrientationManager.handleOrientationChange(
        newOrientation, previousOrientation, mockDartMessenger);

    verify(mockDartMessenger, never()).sendDeviceOrientationChangeEvent(any());
  }

  @Test
  public void getUIOrientation() {
    // Orientation portrait and rotation of 0 should translate to "PORTRAIT_UP".
    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_0);
    DeviceOrientation uiOrientation = deviceOrientationManager.getUIOrientation();
    assertEquals(DeviceOrientation.PORTRAIT_UP, uiOrientation);

    // Orientation portrait and rotation of 90 should translate to "PORTRAIT_UP".
    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_90);
    uiOrientation = deviceOrientationManager.getUIOrientation();
    assertEquals(DeviceOrientation.PORTRAIT_UP, uiOrientation);

    // Orientation portrait and rotation of 180 should translate to "PORTRAIT_DOWN".
    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_180);
    uiOrientation = deviceOrientationManager.getUIOrientation();
    assertEquals(DeviceOrientation.PORTRAIT_DOWN, uiOrientation);

    // Orientation portrait and rotation of 270 should translate to "PORTRAIT_DOWN".
    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_270);
    uiOrientation = deviceOrientationManager.getUIOrientation();
    assertEquals(DeviceOrientation.PORTRAIT_DOWN, uiOrientation);

    // Orientation landscape and rotation of 0 should translate to "LANDSCAPE_LEFT".
    setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_0);
    uiOrientation = deviceOrientationManager.getUIOrientation();
    assertEquals(DeviceOrientation.LANDSCAPE_LEFT, uiOrientation);

    // Orientation landscape and rotation of 90 should translate to "LANDSCAPE_LEFT".
    setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_90);
    uiOrientation = deviceOrientationManager.getUIOrientation();
    assertEquals(DeviceOrientation.LANDSCAPE_LEFT, uiOrientation);

    // Orientation landscape and rotation of 180 should translate to "LANDSCAPE_RIGHT".
    setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_180);
    uiOrientation = deviceOrientationManager.getUIOrientation();
    assertEquals(DeviceOrientation.LANDSCAPE_RIGHT, uiOrientation);

    // Orientation landscape and rotation of 270 should translate to "LANDSCAPE_RIGHT".
    setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_270);
    uiOrientation = deviceOrientationManager.getUIOrientation();
    assertEquals(DeviceOrientation.LANDSCAPE_RIGHT, uiOrientation);

    // Orientation undefined should default to "PORTRAIT_UP".
    setUpUIOrientationMocks(Configuration.ORIENTATION_UNDEFINED, Surface.ROTATION_0);
    uiOrientation = deviceOrientationManager.getUIOrientation();
    assertEquals(DeviceOrientation.PORTRAIT_UP, uiOrientation);
  }

  @Test
  public void getDeviceDefaultOrientation() {
    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_0);
    int orientation = deviceOrientationManager.getDeviceDefaultOrientation();
    assertEquals(Configuration.ORIENTATION_PORTRAIT, orientation);

    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_180);
    orientation = deviceOrientationManager.getDeviceDefaultOrientation();
    assertEquals(Configuration.ORIENTATION_PORTRAIT, orientation);

    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_90);
    orientation = deviceOrientationManager.getDeviceDefaultOrientation();
    assertEquals(Configuration.ORIENTATION_LANDSCAPE, orientation);

    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_270);
    orientation = deviceOrientationManager.getDeviceDefaultOrientation();
    assertEquals(Configuration.ORIENTATION_LANDSCAPE, orientation);

    setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_0);
    orientation = deviceOrientationManager.getDeviceDefaultOrientation();
    assertEquals(Configuration.ORIENTATION_LANDSCAPE, orientation);

    setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_180);
    orientation = deviceOrientationManager.getDeviceDefaultOrientation();
    assertEquals(Configuration.ORIENTATION_LANDSCAPE, orientation);

    setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_90);
    orientation = deviceOrientationManager.getDeviceDefaultOrientation();
    assertEquals(Configuration.ORIENTATION_PORTRAIT, orientation);

    setUpUIOrientationMocks(Configuration.ORIENTATION_LANDSCAPE, Surface.ROTATION_270);
    orientation = deviceOrientationManager.getDeviceDefaultOrientation();
    assertEquals(Configuration.ORIENTATION_PORTRAIT, orientation);
  }

  @Test
  public void calculateSensorOrientation() {
    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_0);
    DeviceOrientation orientation = deviceOrientationManager.calculateSensorOrientation(0);
    assertEquals(DeviceOrientation.PORTRAIT_UP, orientation);

    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_0);
    orientation = deviceOrientationManager.calculateSensorOrientation(90);
    assertEquals(DeviceOrientation.LANDSCAPE_LEFT, orientation);

    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_0);
    orientation = deviceOrientationManager.calculateSensorOrientation(180);
    assertEquals(DeviceOrientation.PORTRAIT_DOWN, orientation);

    setUpUIOrientationMocks(Configuration.ORIENTATION_PORTRAIT, Surface.ROTATION_0);
    orientation = deviceOrientationManager.calculateSensorOrientation(270);
    assertEquals(DeviceOrientation.LANDSCAPE_RIGHT, orientation);
  }

  private void setUpUIOrientationMocks(int orientation, int rotation) {
    Resources mockResources = mock(Resources.class);
    Configuration mockConfiguration = mock(Configuration.class);

    when(mockDisplay.getRotation()).thenReturn(rotation);

    mockConfiguration.orientation = orientation;
    when(mockActivity.getResources()).thenReturn(mockResources);
    when(mockResources.getConfiguration()).thenReturn(mockConfiguration);
  }

  @Test
  public void getDisplayTest() {
    Display display = deviceOrientationManager.getDisplay();

    assertEquals(mockDisplay, display);
  }
}
