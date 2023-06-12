// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.noisereduction;

import android.hardware.camera2.CaptureRequest;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.util.Log;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.features.CameraFeature;
import java.util.HashMap;

/**
 * This can either be enabled or disabled. Only full capability devices can set this to off. Legacy
 * and full support the fast mode.
 * https://developer.android.com/reference/android/hardware/camera2/CameraCharacteristics#NOISE_REDUCTION_AVAILABLE_NOISE_REDUCTION_MODES
 */
public class NoiseReductionFeature extends CameraFeature<NoiseReductionMode> {
  private NoiseReductionMode currentSetting = NoiseReductionMode.fast;

  private final HashMap<NoiseReductionMode, Integer> NOISE_REDUCTION_MODES = new HashMap<>();

  /**
   * Creates a new instance of the {@link NoiseReductionFeature}.
   *
   * @param cameraProperties Collection of the characteristics for the current camera device.
   */
  public NoiseReductionFeature(CameraProperties cameraProperties) {
    super(cameraProperties);
    NOISE_REDUCTION_MODES.put(NoiseReductionMode.off, CaptureRequest.NOISE_REDUCTION_MODE_OFF);
    NOISE_REDUCTION_MODES.put(NoiseReductionMode.fast, CaptureRequest.NOISE_REDUCTION_MODE_FAST);
    NOISE_REDUCTION_MODES.put(
        NoiseReductionMode.highQuality, CaptureRequest.NOISE_REDUCTION_MODE_HIGH_QUALITY);
    if (VERSION.SDK_INT >= VERSION_CODES.M) {
      NOISE_REDUCTION_MODES.put(
          NoiseReductionMode.minimal, CaptureRequest.NOISE_REDUCTION_MODE_MINIMAL);
      NOISE_REDUCTION_MODES.put(
          NoiseReductionMode.zeroShutterLag, CaptureRequest.NOISE_REDUCTION_MODE_ZERO_SHUTTER_LAG);
    }
  }

  @Override
  public String getDebugName() {
    return "NoiseReductionFeature";
  }

  @Override
  public NoiseReductionMode getValue() {
    return currentSetting;
  }

  @Override
  public void setValue(NoiseReductionMode value) {
    this.currentSetting = value;
  }

  @Override
  public boolean checkIsSupported() {
    /*
     * Available settings: public static final int NOISE_REDUCTION_MODE_FAST = 1; public static
     * final int NOISE_REDUCTION_MODE_HIGH_QUALITY = 2; public static final int
     * NOISE_REDUCTION_MODE_MINIMAL = 3; public static final int NOISE_REDUCTION_MODE_OFF = 0;
     * public static final int NOISE_REDUCTION_MODE_ZERO_SHUTTER_LAG = 4;
     *
     * <p>Full-capability camera devices will always support OFF and FAST. Camera devices that
     * support YUV_REPROCESSING or PRIVATE_REPROCESSING will support ZERO_SHUTTER_LAG.
     * Legacy-capability camera devices will only support FAST mode.
     */

    // Can be null on some devices.
    int[] modes = cameraProperties.getAvailableNoiseReductionModes();

    /// If there's at least one mode available then we are supported.
    return modes != null && modes.length > 0;
  }

  @Override
  public void updateBuilder(CaptureRequest.Builder requestBuilder) {
    if (!checkIsSupported()) {
      return;
    }

    Log.i("Camera", "updateNoiseReduction | currentSetting: " + currentSetting);

    // Always use fast mode.
    requestBuilder.set(
        CaptureRequest.NOISE_REDUCTION_MODE, NOISE_REDUCTION_MODES.get(currentSetting));
  }
}
