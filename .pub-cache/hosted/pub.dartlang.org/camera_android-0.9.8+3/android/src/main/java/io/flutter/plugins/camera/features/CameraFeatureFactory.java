// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features;

import android.app.Activity;
import androidx.annotation.NonNull;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.DartMessenger;
import io.flutter.plugins.camera.features.autofocus.AutoFocusFeature;
import io.flutter.plugins.camera.features.exposurelock.ExposureLockFeature;
import io.flutter.plugins.camera.features.exposureoffset.ExposureOffsetFeature;
import io.flutter.plugins.camera.features.exposurepoint.ExposurePointFeature;
import io.flutter.plugins.camera.features.flash.FlashFeature;
import io.flutter.plugins.camera.features.focuspoint.FocusPointFeature;
import io.flutter.plugins.camera.features.fpsrange.FpsRangeFeature;
import io.flutter.plugins.camera.features.noisereduction.NoiseReductionFeature;
import io.flutter.plugins.camera.features.resolution.ResolutionFeature;
import io.flutter.plugins.camera.features.resolution.ResolutionPreset;
import io.flutter.plugins.camera.features.sensororientation.SensorOrientationFeature;
import io.flutter.plugins.camera.features.zoomlevel.ZoomLevelFeature;

/**
 * Factory for creating the supported feature implementation controlling different aspects of the
 * {@link android.hardware.camera2.CaptureRequest}.
 */
public interface CameraFeatureFactory {

  /**
   * Creates a new instance of the auto focus feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @param recordingVideo indicates if the camera is currently recording.
   * @return newly created instance of the AutoFocusFeature class.
   */
  AutoFocusFeature createAutoFocusFeature(
      @NonNull CameraProperties cameraProperties, boolean recordingVideo);

  /**
   * Creates a new instance of the exposure lock feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @return newly created instance of the ExposureLockFeature class.
   */
  ExposureLockFeature createExposureLockFeature(@NonNull CameraProperties cameraProperties);

  /**
   * Creates a new instance of the exposure offset feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @return newly created instance of the ExposureOffsetFeature class.
   */
  ExposureOffsetFeature createExposureOffsetFeature(@NonNull CameraProperties cameraProperties);

  /**
   * Creates a new instance of the flash feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @return newly created instance of the FlashFeature class.
   */
  FlashFeature createFlashFeature(@NonNull CameraProperties cameraProperties);

  /**
   * Creates a new instance of the resolution feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @param initialSetting initial resolution preset.
   * @param cameraName the name of the camera which can be used to identify the camera device.
   * @return newly created instance of the ResolutionFeature class.
   */
  ResolutionFeature createResolutionFeature(
      @NonNull CameraProperties cameraProperties,
      ResolutionPreset initialSetting,
      String cameraName);

  /**
   * Creates a new instance of the focus point feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @param sensorOrientationFeature instance of the SensorOrientationFeature class containing
   *     information about the sensor and device orientation.
   * @return newly created instance of the FocusPointFeature class.
   */
  FocusPointFeature createFocusPointFeature(
      @NonNull CameraProperties cameraProperties,
      @NonNull SensorOrientationFeature sensorOrientationFeature);

  /**
   * Creates a new instance of the FPS range feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @return newly created instance of the FpsRangeFeature class.
   */
  FpsRangeFeature createFpsRangeFeature(@NonNull CameraProperties cameraProperties);

  /**
   * Creates a new instance of the sensor orientation feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @param activity current activity associated with the camera plugin.
   * @param dartMessenger instance of the DartMessenger class, used to send state updates back to
   *     Dart.
   * @return newly created instance of the SensorOrientationFeature class.
   */
  SensorOrientationFeature createSensorOrientationFeature(
      @NonNull CameraProperties cameraProperties,
      @NonNull Activity activity,
      @NonNull DartMessenger dartMessenger);

  /**
   * Creates a new instance of the zoom level feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @return newly created instance of the ZoomLevelFeature class.
   */
  ZoomLevelFeature createZoomLevelFeature(@NonNull CameraProperties cameraProperties);

  /**
   * Creates a new instance of the exposure point feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @param sensorOrientationFeature instance of the SensorOrientationFeature class containing
   *     information about the sensor and device orientation.
   * @return newly created instance of the ExposurePointFeature class.
   */
  ExposurePointFeature createExposurePointFeature(
      @NonNull CameraProperties cameraProperties,
      @NonNull SensorOrientationFeature sensorOrientationFeature);

  /**
   * Creates a new instance of the noise reduction feature.
   *
   * @param cameraProperties instance of the CameraProperties class containing information about the
   *     cameras features.
   * @return newly created instance of the NoiseReductionFeature class.
   */
  NoiseReductionFeature createNoiseReductionFeature(@NonNull CameraProperties cameraProperties);
}
