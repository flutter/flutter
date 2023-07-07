// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCaptureSession.CaptureCallback;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.CaptureResult;
import android.hardware.camera2.TotalCaptureResult;
import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.plugins.camera.types.CameraCaptureProperties;
import io.flutter.plugins.camera.types.CaptureTimeoutsWrapper;

/**
 * A callback object for tracking the progress of a {@link android.hardware.camera2.CaptureRequest}
 * submitted to the camera device.
 */
class CameraCaptureCallback extends CaptureCallback {
  private static final String TAG = "CameraCaptureCallback";
  private final CameraCaptureStateListener cameraStateListener;
  private CameraState cameraState;
  private final CaptureTimeoutsWrapper captureTimeouts;
  private final CameraCaptureProperties captureProps;

  private CameraCaptureCallback(
      @NonNull CameraCaptureStateListener cameraStateListener,
      @NonNull CaptureTimeoutsWrapper captureTimeouts,
      @NonNull CameraCaptureProperties captureProps) {
    cameraState = CameraState.STATE_PREVIEW;
    this.cameraStateListener = cameraStateListener;
    this.captureTimeouts = captureTimeouts;
    this.captureProps = captureProps;
  }

  /**
   * Creates a new instance of the {@link CameraCaptureCallback} class.
   *
   * @param cameraStateListener instance which will be called when the camera state changes.
   * @param captureTimeouts specifying the different timeout counters that should be taken into
   *     account.
   * @return a configured instance of the {@link CameraCaptureCallback} class.
   */
  public static CameraCaptureCallback create(
      @NonNull CameraCaptureStateListener cameraStateListener,
      @NonNull CaptureTimeoutsWrapper captureTimeouts,
      @NonNull CameraCaptureProperties captureProps) {
    return new CameraCaptureCallback(cameraStateListener, captureTimeouts, captureProps);
  }

  /**
   * Gets the current {@link CameraState}.
   *
   * @return the current {@link CameraState}.
   */
  public CameraState getCameraState() {
    return cameraState;
  }

  /**
   * Sets the {@link CameraState}.
   *
   * @param state the camera is currently in.
   */
  public void setCameraState(@NonNull CameraState state) {
    cameraState = state;
  }

  private void process(CaptureResult result) {
    Integer aeState = result.get(CaptureResult.CONTROL_AE_STATE);
    Integer afState = result.get(CaptureResult.CONTROL_AF_STATE);

    // Update capture properties
    if (result instanceof TotalCaptureResult) {
      Float lensAperture = result.get(CaptureResult.LENS_APERTURE);
      Long sensorExposureTime = result.get(CaptureResult.SENSOR_EXPOSURE_TIME);
      Integer sensorSensitivity = result.get(CaptureResult.SENSOR_SENSITIVITY);
      this.captureProps.setLastLensAperture(lensAperture);
      this.captureProps.setLastSensorExposureTime(sensorExposureTime);
      this.captureProps.setLastSensorSensitivity(sensorSensitivity);
    }

    if (cameraState != CameraState.STATE_PREVIEW) {
      Log.d(
          TAG,
          "CameraCaptureCallback | state: "
              + cameraState
              + " | afState: "
              + afState
              + " | aeState: "
              + aeState);
    }

    switch (cameraState) {
      case STATE_PREVIEW:
        {
          // We have nothing to do when the camera preview is working normally.
          break;
        }
      case STATE_WAITING_FOCUS:
        {
          if (afState == null) {
            return;
          } else if (afState == CaptureResult.CONTROL_AF_STATE_FOCUSED_LOCKED
              || afState == CaptureResult.CONTROL_AF_STATE_NOT_FOCUSED_LOCKED) {
            handleWaitingFocusState(aeState);
          } else if (captureTimeouts.getPreCaptureFocusing().getIsExpired()) {
            Log.w(TAG, "Focus timeout, moving on with capture");
            handleWaitingFocusState(aeState);
          }

          break;
        }
      case STATE_WAITING_PRECAPTURE_START:
        {
          // CONTROL_AE_STATE can be null on some devices
          if (aeState == null
              || aeState == CaptureResult.CONTROL_AE_STATE_CONVERGED
              || aeState == CaptureResult.CONTROL_AE_STATE_PRECAPTURE
              || aeState == CaptureResult.CONTROL_AE_STATE_FLASH_REQUIRED) {
            setCameraState(CameraState.STATE_WAITING_PRECAPTURE_DONE);
          } else if (captureTimeouts.getPreCaptureMetering().getIsExpired()) {
            Log.w(TAG, "Metering timeout waiting for pre-capture to start, moving on with capture");

            setCameraState(CameraState.STATE_WAITING_PRECAPTURE_DONE);
          }
          break;
        }
      case STATE_WAITING_PRECAPTURE_DONE:
        {
          // CONTROL_AE_STATE can be null on some devices
          if (aeState == null || aeState != CaptureResult.CONTROL_AE_STATE_PRECAPTURE) {
            cameraStateListener.onConverged();
          } else if (captureTimeouts.getPreCaptureMetering().getIsExpired()) {
            Log.w(
                TAG, "Metering timeout waiting for pre-capture to finish, moving on with capture");
            cameraStateListener.onConverged();
          }

          break;
        }
    }
  }

  private void handleWaitingFocusState(Integer aeState) {
    // CONTROL_AE_STATE can be null on some devices
    if (aeState == null || aeState == CaptureRequest.CONTROL_AE_STATE_CONVERGED) {
      cameraStateListener.onConverged();
    } else {
      cameraStateListener.onPrecapture();
    }
  }

  @Override
  public void onCaptureProgressed(
      @NonNull CameraCaptureSession session,
      @NonNull CaptureRequest request,
      @NonNull CaptureResult partialResult) {
    process(partialResult);
  }

  @Override
  public void onCaptureCompleted(
      @NonNull CameraCaptureSession session,
      @NonNull CaptureRequest request,
      @NonNull TotalCaptureResult result) {
    process(result);
  }

  /** An interface that describes the different state changes implementers can be informed about. */
  interface CameraCaptureStateListener {

    /** Called when the {@link android.hardware.camera2.CaptureRequest} has been converged. */
    void onConverged();

    /**
     * Called when the {@link android.hardware.camera2.CaptureRequest} enters the pre-capture state.
     */
    void onPrecapture();
  }
}
