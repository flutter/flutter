// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Context;
import android.graphics.ImageFormat;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.TotalCaptureResult;
import android.hardware.camera2.params.OutputConfiguration;
import android.hardware.camera2.params.SessionConfiguration;
import android.media.CamcorderProfile;
import android.media.EncoderProfiles;
import android.media.Image;
import android.media.ImageReader;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.util.Log;
import android.util.Size;
import android.view.Display;
import android.view.Surface;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.camera.features.CameraFeature;
import io.flutter.plugins.camera.features.CameraFeatureFactory;
import io.flutter.plugins.camera.features.CameraFeatures;
import io.flutter.plugins.camera.features.Point;
import io.flutter.plugins.camera.features.autofocus.AutoFocusFeature;
import io.flutter.plugins.camera.features.autofocus.FocusMode;
import io.flutter.plugins.camera.features.exposurelock.ExposureLockFeature;
import io.flutter.plugins.camera.features.exposurelock.ExposureMode;
import io.flutter.plugins.camera.features.exposureoffset.ExposureOffsetFeature;
import io.flutter.plugins.camera.features.exposurepoint.ExposurePointFeature;
import io.flutter.plugins.camera.features.flash.FlashFeature;
import io.flutter.plugins.camera.features.flash.FlashMode;
import io.flutter.plugins.camera.features.focuspoint.FocusPointFeature;
import io.flutter.plugins.camera.features.resolution.ResolutionFeature;
import io.flutter.plugins.camera.features.resolution.ResolutionPreset;
import io.flutter.plugins.camera.features.sensororientation.DeviceOrientationManager;
import io.flutter.plugins.camera.features.sensororientation.SensorOrientationFeature;
import io.flutter.plugins.camera.features.zoomlevel.ZoomLevelFeature;
import io.flutter.plugins.camera.media.MediaRecorderBuilder;
import io.flutter.plugins.camera.types.CameraCaptureProperties;
import io.flutter.plugins.camera.types.CaptureTimeoutsWrapper;
import io.flutter.view.TextureRegistry.SurfaceTextureEntry;
import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.Executors;

@FunctionalInterface
interface ErrorCallback {
  void onError(String errorCode, String errorMessage);
}

/** A mockable wrapper for CameraDevice calls. */
interface CameraDeviceWrapper {
  @NonNull
  CaptureRequest.Builder createCaptureRequest(int templateType) throws CameraAccessException;

  @TargetApi(VERSION_CODES.P)
  void createCaptureSession(SessionConfiguration config) throws CameraAccessException;

  @TargetApi(VERSION_CODES.LOLLIPOP)
  void createCaptureSession(
      @NonNull List<Surface> outputs,
      @NonNull CameraCaptureSession.StateCallback callback,
      @Nullable Handler handler)
      throws CameraAccessException;

  void close();
}

class Camera
    implements CameraCaptureCallback.CameraCaptureStateListener,
        ImageReader.OnImageAvailableListener {
  private static final String TAG = "Camera";

  private static final HashMap<String, Integer> supportedImageFormats;

  // Current supported outputs.
  static {
    supportedImageFormats = new HashMap<>();
    supportedImageFormats.put("yuv420", ImageFormat.YUV_420_888);
    supportedImageFormats.put("jpeg", ImageFormat.JPEG);
  }

  /**
   * Holds all of the camera features/settings and will be used to update the request builder when
   * one changes.
   */
  private final CameraFeatures cameraFeatures;

  private final SurfaceTextureEntry flutterTexture;
  private final boolean enableAudio;
  private final Context applicationContext;
  private final DartMessenger dartMessenger;
  private final CameraProperties cameraProperties;
  private final CameraFeatureFactory cameraFeatureFactory;
  private final Activity activity;
  /** A {@link CameraCaptureSession.CaptureCallback} that handles events related to JPEG capture. */
  private final CameraCaptureCallback cameraCaptureCallback;
  /** A {@link Handler} for running tasks in the background. */
  private Handler backgroundHandler;

  /** An additional thread for running tasks that shouldn't block the UI. */
  private HandlerThread backgroundHandlerThread;
  /** True when backgroundHandlerThread is in the process of being stopped. */
  private boolean stoppingBackgroundHandlerThread = false;

  private CameraDeviceWrapper cameraDevice;
  private CameraCaptureSession captureSession;
  private ImageReader pictureImageReader;
  private ImageReader imageStreamReader;
  /** {@link CaptureRequest.Builder} for the camera preview */
  private CaptureRequest.Builder previewRequestBuilder;

  private MediaRecorder mediaRecorder;
  /** True when recording video. */
  private boolean recordingVideo;
  /** True when the preview is paused. */
  private boolean pausedPreview;

  private File captureFile;

  /** Holds the current capture timeouts */
  private CaptureTimeoutsWrapper captureTimeouts;
  /** Holds the last known capture properties */
  private CameraCaptureProperties captureProps;

  private MethodChannel.Result flutterResult;

  /** A CameraDeviceWrapper implementation that forwards calls to a CameraDevice. */
  private class DefaultCameraDeviceWrapper implements CameraDeviceWrapper {
    private final CameraDevice cameraDevice;

    private DefaultCameraDeviceWrapper(CameraDevice cameraDevice) {
      this.cameraDevice = cameraDevice;
    }

    @NonNull
    @Override
    public CaptureRequest.Builder createCaptureRequest(int templateType)
        throws CameraAccessException {
      return cameraDevice.createCaptureRequest(templateType);
    }

    @TargetApi(VERSION_CODES.P)
    @Override
    public void createCaptureSession(SessionConfiguration config) throws CameraAccessException {
      cameraDevice.createCaptureSession(config);
    }

    @TargetApi(VERSION_CODES.LOLLIPOP)
    @SuppressWarnings("deprecation")
    @Override
    public void createCaptureSession(
        @NonNull List<Surface> outputs,
        @NonNull CameraCaptureSession.StateCallback callback,
        @Nullable Handler handler)
        throws CameraAccessException {
      cameraDevice.createCaptureSession(outputs, callback, backgroundHandler);
    }

    @Override
    public void close() {
      cameraDevice.close();
    }
  }

  public Camera(
      final Activity activity,
      final SurfaceTextureEntry flutterTexture,
      final CameraFeatureFactory cameraFeatureFactory,
      final DartMessenger dartMessenger,
      final CameraProperties cameraProperties,
      final ResolutionPreset resolutionPreset,
      final boolean enableAudio) {

    if (activity == null) {
      throw new IllegalStateException("No activity available!");
    }
    this.activity = activity;
    this.enableAudio = enableAudio;
    this.flutterTexture = flutterTexture;
    this.dartMessenger = dartMessenger;
    this.applicationContext = activity.getApplicationContext();
    this.cameraProperties = cameraProperties;
    this.cameraFeatureFactory = cameraFeatureFactory;
    this.cameraFeatures =
        CameraFeatures.init(
            cameraFeatureFactory, cameraProperties, activity, dartMessenger, resolutionPreset);

    // Create capture callback.
    captureTimeouts = new CaptureTimeoutsWrapper(3000, 3000);
    captureProps = new CameraCaptureProperties();
    cameraCaptureCallback = CameraCaptureCallback.create(this, captureTimeouts, captureProps);

    startBackgroundThread();
  }

  @Override
  public void onConverged() {
    takePictureAfterPrecapture();
  }

  @Override
  public void onPrecapture() {
    runPrecaptureSequence();
  }

  /**
   * Updates the builder settings with all of the available features.
   *
   * @param requestBuilder request builder to update.
   */
  private void updateBuilderSettings(CaptureRequest.Builder requestBuilder) {
    for (CameraFeature feature : cameraFeatures.getAllFeatures()) {
      Log.d(TAG, "Updating builder with feature: " + feature.getDebugName());
      feature.updateBuilder(requestBuilder);
    }
  }

  private void prepareMediaRecorder(String outputFilePath) throws IOException {
    Log.i(TAG, "prepareMediaRecorder");

    if (mediaRecorder != null) {
      mediaRecorder.release();
    }

    final PlatformChannel.DeviceOrientation lockedOrientation =
        ((SensorOrientationFeature) cameraFeatures.getSensorOrientation())
            .getLockedCaptureOrientation();

    MediaRecorderBuilder mediaRecorderBuilder;

    if (Build.VERSION.SDK_INT >= 31) {
      mediaRecorderBuilder = new MediaRecorderBuilder(getRecordingProfile(), outputFilePath);
    } else {
      mediaRecorderBuilder = new MediaRecorderBuilder(getRecordingProfileLegacy(), outputFilePath);
    }

    mediaRecorder =
        mediaRecorderBuilder
            .setEnableAudio(enableAudio)
            .setMediaOrientation(
                lockedOrientation == null
                    ? getDeviceOrientationManager().getVideoOrientation()
                    : getDeviceOrientationManager().getVideoOrientation(lockedOrientation))
            .build();
  }

  @SuppressLint("MissingPermission")
  public void open(String imageFormatGroup) throws CameraAccessException {
    final ResolutionFeature resolutionFeature = cameraFeatures.getResolution();

    if (!resolutionFeature.checkIsSupported()) {
      // Tell the user that the camera they are trying to open is not supported,
      // as its {@link android.media.CamcorderProfile} cannot be fetched due to the name
      // not being a valid parsable integer.
      dartMessenger.sendCameraErrorEvent(
          "Camera with name \""
              + cameraProperties.getCameraName()
              + "\" is not supported by this plugin.");
      return;
    }

    // Always capture using JPEG format.
    pictureImageReader =
        ImageReader.newInstance(
            resolutionFeature.getCaptureSize().getWidth(),
            resolutionFeature.getCaptureSize().getHeight(),
            ImageFormat.JPEG,
            1);

    // For image streaming, use the provided image format or fall back to YUV420.
    Integer imageFormat = supportedImageFormats.get(imageFormatGroup);
    if (imageFormat == null) {
      Log.w(TAG, "The selected imageFormatGroup is not supported by Android. Defaulting to yuv420");
      imageFormat = ImageFormat.YUV_420_888;
    }
    imageStreamReader =
        ImageReader.newInstance(
            resolutionFeature.getPreviewSize().getWidth(),
            resolutionFeature.getPreviewSize().getHeight(),
            imageFormat,
            1);

    // Open the camera.
    CameraManager cameraManager = CameraUtils.getCameraManager(activity);
    cameraManager.openCamera(
        cameraProperties.getCameraName(),
        new CameraDevice.StateCallback() {
          @Override
          public void onOpened(@NonNull CameraDevice device) {
            cameraDevice = new DefaultCameraDeviceWrapper(device);
            try {
              startPreview();
              dartMessenger.sendCameraInitializedEvent(
                  resolutionFeature.getPreviewSize().getWidth(),
                  resolutionFeature.getPreviewSize().getHeight(),
                  cameraFeatures.getExposureLock().getValue(),
                  cameraFeatures.getAutoFocus().getValue(),
                  cameraFeatures.getExposurePoint().checkIsSupported(),
                  cameraFeatures.getFocusPoint().checkIsSupported());
            } catch (CameraAccessException e) {
              dartMessenger.sendCameraErrorEvent(e.getMessage());
              close();
            }
          }

          @Override
          public void onClosed(@NonNull CameraDevice camera) {
            Log.i(TAG, "open | onClosed");

            // Prevents calls to methods that would otherwise result in IllegalStateException exceptions.
            cameraDevice = null;
            closeCaptureSession();
            dartMessenger.sendCameraClosingEvent();
          }

          @Override
          public void onDisconnected(@NonNull CameraDevice cameraDevice) {
            Log.i(TAG, "open | onDisconnected");

            close();
            dartMessenger.sendCameraErrorEvent("The camera was disconnected.");
          }

          @Override
          public void onError(@NonNull CameraDevice cameraDevice, int errorCode) {
            Log.i(TAG, "open | onError");

            close();
            String errorDescription;
            switch (errorCode) {
              case ERROR_CAMERA_IN_USE:
                errorDescription = "The camera device is in use already.";
                break;
              case ERROR_MAX_CAMERAS_IN_USE:
                errorDescription = "Max cameras in use";
                break;
              case ERROR_CAMERA_DISABLED:
                errorDescription = "The camera device could not be opened due to a device policy.";
                break;
              case ERROR_CAMERA_DEVICE:
                errorDescription = "The camera device has encountered a fatal error";
                break;
              case ERROR_CAMERA_SERVICE:
                errorDescription = "The camera service has encountered a fatal error.";
                break;
              default:
                errorDescription = "Unknown camera error";
            }
            dartMessenger.sendCameraErrorEvent(errorDescription);
          }
        },
        backgroundHandler);
  }

  @VisibleForTesting
  void createCaptureSession(int templateType, Surface... surfaces) throws CameraAccessException {
    createCaptureSession(templateType, null, surfaces);
  }

  private void createCaptureSession(
      int templateType, Runnable onSuccessCallback, Surface... surfaces)
      throws CameraAccessException {
    // Close any existing capture session.
    captureSession = null;

    // Create a new capture builder.
    previewRequestBuilder = cameraDevice.createCaptureRequest(templateType);

    // Build Flutter surface to render to.
    ResolutionFeature resolutionFeature = cameraFeatures.getResolution();
    SurfaceTexture surfaceTexture = flutterTexture.surfaceTexture();
    surfaceTexture.setDefaultBufferSize(
        resolutionFeature.getPreviewSize().getWidth(),
        resolutionFeature.getPreviewSize().getHeight());
    Surface flutterSurface = new Surface(surfaceTexture);
    previewRequestBuilder.addTarget(flutterSurface);

    List<Surface> remainingSurfaces = Arrays.asList(surfaces);
    if (templateType != CameraDevice.TEMPLATE_PREVIEW) {
      // If it is not preview mode, add all surfaces as targets.
      for (Surface surface : remainingSurfaces) {
        previewRequestBuilder.addTarget(surface);
      }
    }

    // Update camera regions.
    Size cameraBoundaries =
        CameraRegionUtils.getCameraBoundaries(cameraProperties, previewRequestBuilder);
    cameraFeatures.getExposurePoint().setCameraBoundaries(cameraBoundaries);
    cameraFeatures.getFocusPoint().setCameraBoundaries(cameraBoundaries);

    // Prepare the callback.
    CameraCaptureSession.StateCallback callback =
        new CameraCaptureSession.StateCallback() {
          boolean captureSessionClosed = false;

          @Override
          public void onConfigured(@NonNull CameraCaptureSession session) {
            Log.i(TAG, "CameraCaptureSession onConfigured");
            // Camera was already closed.
            if (cameraDevice == null || captureSessionClosed) {
              dartMessenger.sendCameraErrorEvent("The camera was closed during configuration.");
              return;
            }
            captureSession = session;

            Log.i(TAG, "Updating builder settings");
            updateBuilderSettings(previewRequestBuilder);

            refreshPreviewCaptureSession(
                onSuccessCallback, (code, message) -> dartMessenger.sendCameraErrorEvent(message));
          }

          @Override
          public void onConfigureFailed(@NonNull CameraCaptureSession cameraCaptureSession) {
            Log.i(TAG, "CameraCaptureSession onConfigureFailed");
            dartMessenger.sendCameraErrorEvent("Failed to configure camera session.");
          }

          @Override
          public void onClosed(@NonNull CameraCaptureSession session) {
            Log.i(TAG, "CameraCaptureSession onClosed");
            captureSessionClosed = true;
          }
        };

    // Start the session.
    if (VERSION.SDK_INT >= VERSION_CODES.P) {
      // Collect all surfaces to render to.
      List<OutputConfiguration> configs = new ArrayList<>();
      configs.add(new OutputConfiguration(flutterSurface));
      for (Surface surface : remainingSurfaces) {
        configs.add(new OutputConfiguration(surface));
      }
      createCaptureSessionWithSessionConfig(configs, callback);
    } else {
      // Collect all surfaces to render to.
      List<Surface> surfaceList = new ArrayList<>();
      surfaceList.add(flutterSurface);
      surfaceList.addAll(remainingSurfaces);
      createCaptureSession(surfaceList, callback);
    }
  }

  @TargetApi(VERSION_CODES.P)
  private void createCaptureSessionWithSessionConfig(
      List<OutputConfiguration> outputConfigs, CameraCaptureSession.StateCallback callback)
      throws CameraAccessException {
    cameraDevice.createCaptureSession(
        new SessionConfiguration(
            SessionConfiguration.SESSION_REGULAR,
            outputConfigs,
            Executors.newSingleThreadExecutor(),
            callback));
  }

  @TargetApi(VERSION_CODES.LOLLIPOP)
  @SuppressWarnings("deprecation")
  private void createCaptureSession(
      List<Surface> surfaces, CameraCaptureSession.StateCallback callback)
      throws CameraAccessException {
    cameraDevice.createCaptureSession(surfaces, callback, backgroundHandler);
  }

  // Send a repeating request to refresh  capture session.
  private void refreshPreviewCaptureSession(
      @Nullable Runnable onSuccessCallback, @NonNull ErrorCallback onErrorCallback) {
    Log.i(TAG, "refreshPreviewCaptureSession");

    if (captureSession == null) {
      Log.i(
          TAG,
          "refreshPreviewCaptureSession: captureSession not yet initialized, "
              + "skipping preview capture session refresh.");
      return;
    }

    try {
      if (!pausedPreview) {
        captureSession.setRepeatingRequest(
            previewRequestBuilder.build(), cameraCaptureCallback, backgroundHandler);
      }

      if (onSuccessCallback != null) {
        onSuccessCallback.run();
      }

    } catch (IllegalStateException e) {
      onErrorCallback.onError("cameraAccess", "Camera is closed: " + e.getMessage());
    } catch (CameraAccessException e) {
      onErrorCallback.onError("cameraAccess", e.getMessage());
    }
  }

  public void takePicture(@NonNull final Result result) {
    // Only take one picture at a time.
    if (cameraCaptureCallback.getCameraState() != CameraState.STATE_PREVIEW) {
      result.error("captureAlreadyActive", "Picture is currently already being captured", null);
      return;
    }

    flutterResult = result;

    // Create temporary file.
    final File outputDir = applicationContext.getCacheDir();
    try {
      captureFile = File.createTempFile("CAP", ".jpg", outputDir);
      captureTimeouts.reset();
    } catch (IOException | SecurityException e) {
      dartMessenger.error(flutterResult, "cannotCreateFile", e.getMessage(), null);
      return;
    }

    // Listen for picture being taken.
    pictureImageReader.setOnImageAvailableListener(this, backgroundHandler);

    final AutoFocusFeature autoFocusFeature = cameraFeatures.getAutoFocus();
    final boolean isAutoFocusSupported = autoFocusFeature.checkIsSupported();
    if (isAutoFocusSupported && autoFocusFeature.getValue() == FocusMode.auto) {
      runPictureAutoFocus();
    } else {
      runPrecaptureSequence();
    }
  }

  /**
   * Run the precapture sequence for capturing a still image. This method should be called when a
   * response is received in {@link #cameraCaptureCallback} from lockFocus().
   */
  private void runPrecaptureSequence() {
    Log.i(TAG, "runPrecaptureSequence");
    try {
      // First set precapture state to idle or else it can hang in STATE_WAITING_PRECAPTURE_START.
      previewRequestBuilder.set(
          CaptureRequest.CONTROL_AE_PRECAPTURE_TRIGGER,
          CaptureRequest.CONTROL_AE_PRECAPTURE_TRIGGER_IDLE);
      captureSession.capture(
          previewRequestBuilder.build(), cameraCaptureCallback, backgroundHandler);

      // Repeating request to refresh preview session.
      refreshPreviewCaptureSession(
          null,
          (code, message) -> dartMessenger.error(flutterResult, "cameraAccess", message, null));

      // Start precapture.
      cameraCaptureCallback.setCameraState(CameraState.STATE_WAITING_PRECAPTURE_START);

      previewRequestBuilder.set(
          CaptureRequest.CONTROL_AE_PRECAPTURE_TRIGGER,
          CaptureRequest.CONTROL_AE_PRECAPTURE_TRIGGER_START);

      // Trigger one capture to start AE sequence.
      captureSession.capture(
          previewRequestBuilder.build(), cameraCaptureCallback, backgroundHandler);

    } catch (CameraAccessException e) {
      e.printStackTrace();
    }
  }

  /**
   * Capture a still picture. This method should be called when a response is received {@link
   * #cameraCaptureCallback} from both lockFocus().
   */
  private void takePictureAfterPrecapture() {
    Log.i(TAG, "captureStillPicture");
    cameraCaptureCallback.setCameraState(CameraState.STATE_CAPTURING);

    if (cameraDevice == null) {
      return;
    }
    // This is the CaptureRequest.Builder that is used to take a picture.
    CaptureRequest.Builder stillBuilder;
    try {
      stillBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE);
    } catch (CameraAccessException e) {
      dartMessenger.error(flutterResult, "cameraAccess", e.getMessage(), null);
      return;
    }
    stillBuilder.addTarget(pictureImageReader.getSurface());

    // Zoom.
    stillBuilder.set(
        CaptureRequest.SCALER_CROP_REGION,
        previewRequestBuilder.get(CaptureRequest.SCALER_CROP_REGION));

    // Have all features update the builder.
    updateBuilderSettings(stillBuilder);

    // Orientation.
    final PlatformChannel.DeviceOrientation lockedOrientation =
        ((SensorOrientationFeature) cameraFeatures.getSensorOrientation())
            .getLockedCaptureOrientation();
    stillBuilder.set(
        CaptureRequest.JPEG_ORIENTATION,
        lockedOrientation == null
            ? getDeviceOrientationManager().getPhotoOrientation()
            : getDeviceOrientationManager().getPhotoOrientation(lockedOrientation));

    CameraCaptureSession.CaptureCallback captureCallback =
        new CameraCaptureSession.CaptureCallback() {
          @Override
          public void onCaptureCompleted(
              @NonNull CameraCaptureSession session,
              @NonNull CaptureRequest request,
              @NonNull TotalCaptureResult result) {
            unlockAutoFocus();
          }
        };

    try {
      captureSession.stopRepeating();
      Log.i(TAG, "sending capture request");
      captureSession.capture(stillBuilder.build(), captureCallback, backgroundHandler);
    } catch (CameraAccessException e) {
      dartMessenger.error(flutterResult, "cameraAccess", e.getMessage(), null);
    }
  }

  @SuppressWarnings("deprecation")
  private Display getDefaultDisplay() {
    return activity.getWindowManager().getDefaultDisplay();
  }

  /** Starts a background thread and its {@link Handler}. */
  public void startBackgroundThread() {
    if (backgroundHandlerThread != null) {
      return;
    }

    backgroundHandlerThread = HandlerThreadFactory.create("CameraBackground");
    try {
      backgroundHandlerThread.start();
    } catch (IllegalThreadStateException e) {
      // Ignore exception in case the thread has already started.
    }
    backgroundHandler = HandlerFactory.create(backgroundHandlerThread.getLooper());
  }

  /** Stops the background thread and its {@link Handler}. */
  public void stopBackgroundThread() {
    if (stoppingBackgroundHandlerThread) {
      return;
    }
    if (backgroundHandlerThread != null) {
      stoppingBackgroundHandlerThread = true;
      backgroundHandlerThread.quitSafely();
      try {
        backgroundHandlerThread.join();
      } catch (InterruptedException e) {
        dartMessenger.error(flutterResult, "cameraAccess", e.getMessage(), null);
      }
    }
    backgroundHandlerThread = null;
    backgroundHandler = null;
    stoppingBackgroundHandlerThread = false;
  }

  /** Start capturing a picture, doing autofocus first. */
  private void runPictureAutoFocus() {
    Log.i(TAG, "runPictureAutoFocus");

    cameraCaptureCallback.setCameraState(CameraState.STATE_WAITING_FOCUS);
    lockAutoFocus();
  }

  private void lockAutoFocus() {
    Log.i(TAG, "lockAutoFocus");
    if (captureSession == null) {
      Log.i(TAG, "[unlockAutoFocus] captureSession null, returning");
      return;
    }

    // Trigger AF to start.
    previewRequestBuilder.set(
        CaptureRequest.CONTROL_AF_TRIGGER, CaptureRequest.CONTROL_AF_TRIGGER_START);

    try {
      captureSession.capture(previewRequestBuilder.build(), null, backgroundHandler);
    } catch (CameraAccessException e) {
      dartMessenger.sendCameraErrorEvent(e.getMessage());
    }
  }

  /** Cancel and reset auto focus state and refresh the preview session. */
  private void unlockAutoFocus() {
    Log.i(TAG, "unlockAutoFocus");
    if (captureSession == null) {
      Log.i(TAG, "[unlockAutoFocus] captureSession null, returning");
      return;
    }
    try {
      // Cancel existing AF state.
      previewRequestBuilder.set(
          CaptureRequest.CONTROL_AF_TRIGGER, CameraMetadata.CONTROL_AF_TRIGGER_CANCEL);
      captureSession.capture(previewRequestBuilder.build(), null, backgroundHandler);

      // Set AF state to idle again.
      previewRequestBuilder.set(
          CaptureRequest.CONTROL_AF_TRIGGER, CameraMetadata.CONTROL_AF_TRIGGER_IDLE);

      captureSession.capture(previewRequestBuilder.build(), null, backgroundHandler);
    } catch (CameraAccessException e) {
      dartMessenger.sendCameraErrorEvent(e.getMessage());
      return;
    }

    refreshPreviewCaptureSession(
        null,
        (errorCode, errorMessage) ->
            dartMessenger.error(flutterResult, errorCode, errorMessage, null));
  }

  public void startVideoRecording(@NonNull Result result) {
    final File outputDir = applicationContext.getCacheDir();
    try {
      captureFile = File.createTempFile("REC", ".mp4", outputDir);
    } catch (IOException | SecurityException e) {
      result.error("cannotCreateFile", e.getMessage(), null);
      return;
    }
    try {
      prepareMediaRecorder(captureFile.getAbsolutePath());
    } catch (IOException e) {
      recordingVideo = false;
      captureFile = null;
      result.error("videoRecordingFailed", e.getMessage(), null);
      return;
    }
    // Re-create autofocus feature so it's using video focus mode now.
    cameraFeatures.setAutoFocus(
        cameraFeatureFactory.createAutoFocusFeature(cameraProperties, true));
    recordingVideo = true;
    try {
      createCaptureSession(
          CameraDevice.TEMPLATE_RECORD, () -> mediaRecorder.start(), mediaRecorder.getSurface());
      result.success(null);
    } catch (CameraAccessException e) {
      recordingVideo = false;
      captureFile = null;
      result.error("videoRecordingFailed", e.getMessage(), null);
    }
  }

  public void stopVideoRecording(@NonNull final Result result) {
    if (!recordingVideo) {
      result.success(null);
      return;
    }
    // Re-create autofocus feature so it's using continuous capture focus mode now.
    cameraFeatures.setAutoFocus(
        cameraFeatureFactory.createAutoFocusFeature(cameraProperties, false));
    recordingVideo = false;
    try {
      captureSession.abortCaptures();
      mediaRecorder.stop();
    } catch (CameraAccessException | IllegalStateException e) {
      // Ignore exceptions and try to continue (changes are camera session already aborted capture).
    }
    mediaRecorder.reset();
    try {
      startPreview();
    } catch (CameraAccessException | IllegalStateException e) {
      result.error("videoRecordingFailed", e.getMessage(), null);
      return;
    }
    result.success(captureFile.getAbsolutePath());
    captureFile = null;
  }

  public void pauseVideoRecording(@NonNull final Result result) {
    if (!recordingVideo) {
      result.success(null);
      return;
    }

    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        mediaRecorder.pause();
      } else {
        result.error("videoRecordingFailed", "pauseVideoRecording requires Android API +24.", null);
        return;
      }
    } catch (IllegalStateException e) {
      result.error("videoRecordingFailed", e.getMessage(), null);
      return;
    }

    result.success(null);
  }

  public void resumeVideoRecording(@NonNull final Result result) {
    if (!recordingVideo) {
      result.success(null);
      return;
    }

    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        mediaRecorder.resume();
      } else {
        result.error(
            "videoRecordingFailed", "resumeVideoRecording requires Android API +24.", null);
        return;
      }
    } catch (IllegalStateException e) {
      result.error("videoRecordingFailed", e.getMessage(), null);
      return;
    }

    result.success(null);
  }

  /**
   * Method handler for setting new flash modes.
   *
   * @param result Flutter result.
   * @param newMode new mode.
   */
  public void setFlashMode(@NonNull final Result result, @NonNull FlashMode newMode) {
    // Save the new flash mode setting.
    final FlashFeature flashFeature = cameraFeatures.getFlash();
    flashFeature.setValue(newMode);
    flashFeature.updateBuilder(previewRequestBuilder);

    refreshPreviewCaptureSession(
        () -> result.success(null),
        (code, message) -> result.error("setFlashModeFailed", "Could not set flash mode.", null));
  }

  /**
   * Method handler for setting new exposure modes.
   *
   * @param result Flutter result.
   * @param newMode new mode.
   */
  public void setExposureMode(@NonNull final Result result, @NonNull ExposureMode newMode) {
    final ExposureLockFeature exposureLockFeature = cameraFeatures.getExposureLock();
    exposureLockFeature.setValue(newMode);
    exposureLockFeature.updateBuilder(previewRequestBuilder);

    refreshPreviewCaptureSession(
        () -> result.success(null),
        (code, message) ->
            result.error("setExposureModeFailed", "Could not set exposure mode.", null));
  }

  /**
   * Sets new exposure point from dart.
   *
   * @param result Flutter result.
   * @param point The exposure point.
   */
  public void setExposurePoint(@NonNull final Result result, @Nullable Point point) {
    final ExposurePointFeature exposurePointFeature = cameraFeatures.getExposurePoint();
    exposurePointFeature.setValue(point);
    exposurePointFeature.updateBuilder(previewRequestBuilder);

    refreshPreviewCaptureSession(
        () -> result.success(null),
        (code, message) ->
            result.error("setExposurePointFailed", "Could not set exposure point.", null));
  }

  /** Return the max exposure offset value supported by the camera to dart. */
  public double getMaxExposureOffset() {
    return cameraFeatures.getExposureOffset().getMaxExposureOffset();
  }

  /** Return the min exposure offset value supported by the camera to dart. */
  public double getMinExposureOffset() {
    return cameraFeatures.getExposureOffset().getMinExposureOffset();
  }

  /** Return the exposure offset step size to dart. */
  public double getExposureOffsetStepSize() {
    return cameraFeatures.getExposureOffset().getExposureOffsetStepSize();
  }

  /**
   * Sets new focus mode from dart.
   *
   * @param result Flutter result.
   * @param newMode New mode.
   */
  public void setFocusMode(final Result result, @NonNull FocusMode newMode) {
    final AutoFocusFeature autoFocusFeature = cameraFeatures.getAutoFocus();
    autoFocusFeature.setValue(newMode);
    autoFocusFeature.updateBuilder(previewRequestBuilder);

    /*
     * For focus mode an extra step of actually locking/unlocking the
     * focus has to be done, in order to ensure it goes into the correct state.
     */
    if (!pausedPreview) {
      switch (newMode) {
        case locked:
          // Perform a single focus trigger.
          if (captureSession == null) {
            Log.i(TAG, "[unlockAutoFocus] captureSession null, returning");
            return;
          }
          lockAutoFocus();

          // Set AF state to idle again.
          previewRequestBuilder.set(
              CaptureRequest.CONTROL_AF_TRIGGER, CameraMetadata.CONTROL_AF_TRIGGER_IDLE);

          try {
            captureSession.setRepeatingRequest(
                previewRequestBuilder.build(), null, backgroundHandler);
          } catch (CameraAccessException e) {
            if (result != null) {
              result.error(
                  "setFocusModeFailed", "Error setting focus mode: " + e.getMessage(), null);
            }
            return;
          }
          break;
        case auto:
          // Cancel current AF trigger and set AF to idle again.
          unlockAutoFocus();
          break;
      }
    }

    if (result != null) {
      result.success(null);
    }
  }

  /**
   * Sets new focus point from dart.
   *
   * @param result Flutter result.
   * @param point the new coordinates.
   */
  public void setFocusPoint(@NonNull final Result result, @Nullable Point point) {
    final FocusPointFeature focusPointFeature = cameraFeatures.getFocusPoint();
    focusPointFeature.setValue(point);
    focusPointFeature.updateBuilder(previewRequestBuilder);

    refreshPreviewCaptureSession(
        () -> result.success(null),
        (code, message) -> result.error("setFocusPointFailed", "Could not set focus point.", null));

    this.setFocusMode(null, cameraFeatures.getAutoFocus().getValue());
  }

  /**
   * Sets a new exposure offset from dart. From dart the offset comes as a double, like +1.3 or
   * -1.3.
   *
   * @param result flutter result.
   * @param offset new value.
   */
  public void setExposureOffset(@NonNull final Result result, double offset) {
    final ExposureOffsetFeature exposureOffsetFeature = cameraFeatures.getExposureOffset();
    exposureOffsetFeature.setValue(offset);
    exposureOffsetFeature.updateBuilder(previewRequestBuilder);

    refreshPreviewCaptureSession(
        () -> result.success(exposureOffsetFeature.getValue()),
        (code, message) ->
            result.error("setExposureOffsetFailed", "Could not set exposure offset.", null));
  }

  public float getMaxZoomLevel() {
    return cameraFeatures.getZoomLevel().getMaximumZoomLevel();
  }

  public float getMinZoomLevel() {
    return cameraFeatures.getZoomLevel().getMinimumZoomLevel();
  }

  /** Shortcut to get current recording profile. Legacy method provides support for SDK < 31. */
  CamcorderProfile getRecordingProfileLegacy() {
    return cameraFeatures.getResolution().getRecordingProfileLegacy();
  }

  EncoderProfiles getRecordingProfile() {
    return cameraFeatures.getResolution().getRecordingProfile();
  }

  /** Shortut to get deviceOrientationListener. */
  DeviceOrientationManager getDeviceOrientationManager() {
    return cameraFeatures.getSensorOrientation().getDeviceOrientationManager();
  }

  /**
   * Sets zoom level from dart.
   *
   * @param result Flutter result.
   * @param zoom new value.
   */
  public void setZoomLevel(@NonNull final Result result, float zoom) throws CameraAccessException {
    final ZoomLevelFeature zoomLevel = cameraFeatures.getZoomLevel();
    float maxZoom = zoomLevel.getMaximumZoomLevel();
    float minZoom = zoomLevel.getMinimumZoomLevel();

    if (zoom > maxZoom || zoom < minZoom) {
      String errorMessage =
          String.format(
              Locale.ENGLISH,
              "Zoom level out of bounds (zoom level should be between %f and %f).",
              minZoom,
              maxZoom);
      result.error("ZOOM_ERROR", errorMessage, null);
      return;
    }

    zoomLevel.setValue(zoom);
    zoomLevel.updateBuilder(previewRequestBuilder);

    refreshPreviewCaptureSession(
        () -> result.success(null),
        (code, message) -> result.error("setZoomLevelFailed", "Could not set zoom level.", null));
  }

  /**
   * Lock capture orientation from dart.
   *
   * @param orientation new orientation.
   */
  public void lockCaptureOrientation(PlatformChannel.DeviceOrientation orientation) {
    cameraFeatures.getSensorOrientation().lockCaptureOrientation(orientation);
  }

  /** Unlock capture orientation from dart. */
  public void unlockCaptureOrientation() {
    cameraFeatures.getSensorOrientation().unlockCaptureOrientation();
  }

  /** Pause the preview from dart. */
  public void pausePreview() throws CameraAccessException {
    this.pausedPreview = true;
    this.captureSession.stopRepeating();
  }

  /** Resume the preview from dart. */
  public void resumePreview() {
    this.pausedPreview = false;
    this.refreshPreviewCaptureSession(
        null, (code, message) -> dartMessenger.sendCameraErrorEvent(message));
  }

  public void startPreview() throws CameraAccessException {
    if (pictureImageReader == null || pictureImageReader.getSurface() == null) return;
    Log.i(TAG, "startPreview");

    createCaptureSession(CameraDevice.TEMPLATE_PREVIEW, pictureImageReader.getSurface());
  }

  public void startPreviewWithImageStream(EventChannel imageStreamChannel)
      throws CameraAccessException {
    createCaptureSession(CameraDevice.TEMPLATE_RECORD, imageStreamReader.getSurface());
    Log.i(TAG, "startPreviewWithImageStream");

    imageStreamChannel.setStreamHandler(
        new EventChannel.StreamHandler() {
          @Override
          public void onListen(Object o, EventChannel.EventSink imageStreamSink) {
            setImageStreamImageAvailableListener(imageStreamSink);
          }

          @Override
          public void onCancel(Object o) {
            imageStreamReader.setOnImageAvailableListener(null, backgroundHandler);
          }
        });
  }

  /**
   * This a callback object for the {@link ImageReader}. "onImageAvailable" will be called when a
   * still image is ready to be saved.
   */
  @Override
  public void onImageAvailable(ImageReader reader) {
    Log.i(TAG, "onImageAvailable");

    backgroundHandler.post(
        new ImageSaver(
            // Use acquireNextImage since image reader is only for one image.
            reader.acquireNextImage(),
            captureFile,
            new ImageSaver.Callback() {
              @Override
              public void onComplete(String absolutePath) {
                dartMessenger.finish(flutterResult, absolutePath);
              }

              @Override
              public void onError(String errorCode, String errorMessage) {
                dartMessenger.error(flutterResult, errorCode, errorMessage, null);
              }
            }));
    cameraCaptureCallback.setCameraState(CameraState.STATE_PREVIEW);
  }

  private void setImageStreamImageAvailableListener(final EventChannel.EventSink imageStreamSink) {
    imageStreamReader.setOnImageAvailableListener(
        reader -> {
          Image img = reader.acquireNextImage();
          // Use acquireNextImage since image reader is only for one image.
          if (img == null) return;

          List<Map<String, Object>> planes = new ArrayList<>();
          for (Image.Plane plane : img.getPlanes()) {
            ByteBuffer buffer = plane.getBuffer();

            byte[] bytes = new byte[buffer.remaining()];
            buffer.get(bytes, 0, bytes.length);

            Map<String, Object> planeBuffer = new HashMap<>();
            planeBuffer.put("bytesPerRow", plane.getRowStride());
            planeBuffer.put("bytesPerPixel", plane.getPixelStride());
            planeBuffer.put("bytes", bytes);

            planes.add(planeBuffer);
          }

          Map<String, Object> imageBuffer = new HashMap<>();
          imageBuffer.put("width", img.getWidth());
          imageBuffer.put("height", img.getHeight());
          imageBuffer.put("format", img.getFormat());
          imageBuffer.put("planes", planes);
          imageBuffer.put("lensAperture", this.captureProps.getLastLensAperture());
          imageBuffer.put("sensorExposureTime", this.captureProps.getLastSensorExposureTime());
          Integer sensorSensitivity = this.captureProps.getLastSensorSensitivity();
          imageBuffer.put(
              "sensorSensitivity", sensorSensitivity == null ? null : (double) sensorSensitivity);

          final Handler handler = new Handler(Looper.getMainLooper());
          handler.post(() -> imageStreamSink.success(imageBuffer));
          img.close();
        },
        backgroundHandler);
  }

  private void closeCaptureSession() {
    if (captureSession != null) {
      Log.i(TAG, "closeCaptureSession");

      captureSession.close();
      captureSession = null;
    }
  }

  public void close() {
    Log.i(TAG, "close");

    if (cameraDevice != null) {
      cameraDevice.close();
      cameraDevice = null;

      // Closing the CameraDevice without closing the CameraCaptureSession is recommended
      // for quickly closing the camera:
      // https://developer.android.com/reference/android/hardware/camera2/CameraCaptureSession#close()
      captureSession = null;
    } else {
      closeCaptureSession();
    }

    if (pictureImageReader != null) {
      pictureImageReader.close();
      pictureImageReader = null;
    }
    if (imageStreamReader != null) {
      imageStreamReader.close();
      imageStreamReader = null;
    }
    if (mediaRecorder != null) {
      mediaRecorder.reset();
      mediaRecorder.release();
      mediaRecorder = null;
    }

    stopBackgroundThread();
  }

  public void dispose() {
    Log.i(TAG, "dispose");

    close();
    flutterTexture.release();
    getDeviceOrientationManager().stop();
  }

  /** Factory class that assists in creating a {@link HandlerThread} instance. */
  static class HandlerThreadFactory {
    /**
     * Creates a new instance of the {@link HandlerThread} class.
     *
     * <p>This method is visible for testing purposes only and should never be used outside this *
     * class.
     *
     * @param name to give to the HandlerThread.
     * @return new instance of the {@link HandlerThread} class.
     */
    @VisibleForTesting
    public static HandlerThread create(String name) {
      return new HandlerThread(name);
    }
  }

  /** Factory class that assists in creating a {@link Handler} instance. */
  static class HandlerFactory {
    /**
     * Creates a new instance of the {@link Handler} class.
     *
     * <p>This method is visible for testing purposes only and should never be used outside this *
     * class.
     *
     * @param looper to give to the Handler.
     * @return new instance of the {@link Handler} class.
     */
    @VisibleForTesting
    public static Handler create(Looper looper) {
      return new Handler(looper);
    }
  }
}
