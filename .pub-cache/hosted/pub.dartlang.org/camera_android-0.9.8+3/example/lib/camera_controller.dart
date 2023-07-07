// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiver/core.dart';

/// The state of a [CameraController].
class CameraValue {
  /// Creates a new camera controller state.
  const CameraValue({
    required this.isInitialized,
    this.previewSize,
    required this.isRecordingVideo,
    required this.isTakingPicture,
    required this.isStreamingImages,
    required this.isRecordingPaused,
    required this.flashMode,
    required this.exposureMode,
    required this.focusMode,
    required this.deviceOrientation,
    this.lockedCaptureOrientation,
    this.recordingOrientation,
    this.isPreviewPaused = false,
    this.previewPauseOrientation,
  });

  /// Creates a new camera controller state for an uninitialized controller.
  const CameraValue.uninitialized()
      : this(
          isInitialized: false,
          isRecordingVideo: false,
          isTakingPicture: false,
          isStreamingImages: false,
          isRecordingPaused: false,
          flashMode: FlashMode.auto,
          exposureMode: ExposureMode.auto,
          focusMode: FocusMode.auto,
          deviceOrientation: DeviceOrientation.portraitUp,
          isPreviewPaused: false,
        );

  /// True after [CameraController.initialize] has completed successfully.
  final bool isInitialized;

  /// True when a picture capture request has been sent but as not yet returned.
  final bool isTakingPicture;

  /// True when the camera is recording (not the same as previewing).
  final bool isRecordingVideo;

  /// True when images from the camera are being streamed.
  final bool isStreamingImages;

  /// True when video recording is paused.
  final bool isRecordingPaused;

  /// True when the preview widget has been paused manually.
  final bool isPreviewPaused;

  /// Set to the orientation the preview was paused in, if it is currently paused.
  final DeviceOrientation? previewPauseOrientation;

  /// The size of the preview in pixels.
  ///
  /// Is `null` until [isInitialized] is `true`.
  final Size? previewSize;

  /// The flash mode the camera is currently set to.
  final FlashMode flashMode;

  /// The exposure mode the camera is currently set to.
  final ExposureMode exposureMode;

  /// The focus mode the camera is currently set to.
  final FocusMode focusMode;

  /// The current device UI orientation.
  final DeviceOrientation deviceOrientation;

  /// The currently locked capture orientation.
  final DeviceOrientation? lockedCaptureOrientation;

  /// Whether the capture orientation is currently locked.
  bool get isCaptureOrientationLocked => lockedCaptureOrientation != null;

  /// The orientation of the currently running video recording.
  final DeviceOrientation? recordingOrientation;

  /// Creates a modified copy of the object.
  ///
  /// Explicitly specified fields get the specified value, all other fields get
  /// the same value of the current object.
  CameraValue copyWith({
    bool? isInitialized,
    bool? isRecordingVideo,
    bool? isTakingPicture,
    bool? isStreamingImages,
    Size? previewSize,
    bool? isRecordingPaused,
    FlashMode? flashMode,
    ExposureMode? exposureMode,
    FocusMode? focusMode,
    bool? exposurePointSupported,
    bool? focusPointSupported,
    DeviceOrientation? deviceOrientation,
    Optional<DeviceOrientation>? lockedCaptureOrientation,
    Optional<DeviceOrientation>? recordingOrientation,
    bool? isPreviewPaused,
    Optional<DeviceOrientation>? previewPauseOrientation,
  }) {
    return CameraValue(
      isInitialized: isInitialized ?? this.isInitialized,
      previewSize: previewSize ?? this.previewSize,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      isTakingPicture: isTakingPicture ?? this.isTakingPicture,
      isStreamingImages: isStreamingImages ?? this.isStreamingImages,
      isRecordingPaused: isRecordingPaused ?? this.isRecordingPaused,
      flashMode: flashMode ?? this.flashMode,
      exposureMode: exposureMode ?? this.exposureMode,
      focusMode: focusMode ?? this.focusMode,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      lockedCaptureOrientation: lockedCaptureOrientation == null
          ? this.lockedCaptureOrientation
          : lockedCaptureOrientation.orNull,
      recordingOrientation: recordingOrientation == null
          ? this.recordingOrientation
          : recordingOrientation.orNull,
      isPreviewPaused: isPreviewPaused ?? this.isPreviewPaused,
      previewPauseOrientation: previewPauseOrientation == null
          ? this.previewPauseOrientation
          : previewPauseOrientation.orNull,
    );
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'CameraValue')}('
        'isRecordingVideo: $isRecordingVideo, '
        'isInitialized: $isInitialized, '
        'previewSize: $previewSize, '
        'isStreamingImages: $isStreamingImages, '
        'flashMode: $flashMode, '
        'exposureMode: $exposureMode, '
        'focusMode: $focusMode, '
        'deviceOrientation: $deviceOrientation, '
        'lockedCaptureOrientation: $lockedCaptureOrientation, '
        'recordingOrientation: $recordingOrientation, '
        'isPreviewPaused: $isPreviewPaused, '
        'previewPausedOrientation: $previewPauseOrientation)';
  }
}

/// Controls a device camera.
///
/// This is a stripped-down version of the app-facing controller to serve as a
/// utility for the example and integration tests. It wraps only the calls that
/// have state associated with them, to consolidate tracking of camera state
/// outside of the overall example code.
class CameraController extends ValueNotifier<CameraValue> {
  /// Creates a new camera controller in an uninitialized state.
  CameraController(
    this.description,
    this.resolutionPreset, {
    this.enableAudio = true,
    this.imageFormatGroup,
  }) : super(const CameraValue.uninitialized());

  /// The properties of the camera device controlled by this controller.
  final CameraDescription description;

  /// The resolution this controller is targeting.
  ///
  /// This resolution preset is not guaranteed to be available on the device,
  /// if unavailable a lower resolution will be used.
  ///
  /// See also: [ResolutionPreset].
  final ResolutionPreset resolutionPreset;

  /// Whether to include audio when recording a video.
  final bool enableAudio;

  /// The [ImageFormatGroup] describes the output of the raw image format.
  ///
  /// When null the imageFormat will fallback to the platforms default.
  final ImageFormatGroup? imageFormatGroup;

  late int _cameraId;

  bool _isDisposed = false;
  StreamSubscription<CameraImageData>? _imageStreamSubscription;
  FutureOr<bool>? _initCalled;
  StreamSubscription<DeviceOrientationChangedEvent>?
      _deviceOrientationSubscription;

  /// The camera identifier with which the controller is associated.
  int get cameraId => _cameraId;

  /// Initializes the camera on the device.
  Future<void> initialize() async {
    final Completer<CameraInitializedEvent> _initializeCompleter =
        Completer<CameraInitializedEvent>();

    _deviceOrientationSubscription = CameraPlatform.instance
        .onDeviceOrientationChanged()
        .listen((DeviceOrientationChangedEvent event) {
      value = value.copyWith(
        deviceOrientation: event.orientation,
      );
    });

    _cameraId = await CameraPlatform.instance.createCamera(
      description,
      resolutionPreset,
      enableAudio: enableAudio,
    );

    CameraPlatform.instance
        .onCameraInitialized(_cameraId)
        .first
        .then((CameraInitializedEvent event) {
      _initializeCompleter.complete(event);
    });

    await CameraPlatform.instance.initializeCamera(
      _cameraId,
      imageFormatGroup: imageFormatGroup ?? ImageFormatGroup.unknown,
    );

    value = value.copyWith(
      isInitialized: true,
      previewSize: await _initializeCompleter.future
          .then((CameraInitializedEvent event) => Size(
                event.previewWidth,
                event.previewHeight,
              )),
      exposureMode: await _initializeCompleter.future
          .then((CameraInitializedEvent event) => event.exposureMode),
      focusMode: await _initializeCompleter.future
          .then((CameraInitializedEvent event) => event.focusMode),
      exposurePointSupported: await _initializeCompleter.future
          .then((CameraInitializedEvent event) => event.exposurePointSupported),
      focusPointSupported: await _initializeCompleter.future
          .then((CameraInitializedEvent event) => event.focusPointSupported),
    );

    _initCalled = true;
  }

  /// Prepare the capture session for video recording.
  Future<void> prepareForVideoRecording() async {
    await CameraPlatform.instance.prepareForVideoRecording();
  }

  /// Pauses the current camera preview
  Future<void> pausePreview() async {
    await CameraPlatform.instance.pausePreview(_cameraId);
    value = value.copyWith(
        isPreviewPaused: true,
        previewPauseOrientation: Optional<DeviceOrientation>.of(
            value.lockedCaptureOrientation ?? value.deviceOrientation));
  }

  /// Resumes the current camera preview
  Future<void> resumePreview() async {
    await CameraPlatform.instance.resumePreview(_cameraId);
    value = value.copyWith(
        isPreviewPaused: false,
        previewPauseOrientation: const Optional<DeviceOrientation>.absent());
  }

  /// Captures an image and returns the file where it was saved.
  ///
  /// Throws a [CameraException] if the capture fails.
  Future<XFile> takePicture() async {
    value = value.copyWith(isTakingPicture: true);
    final XFile file = await CameraPlatform.instance.takePicture(_cameraId);
    value = value.copyWith(isTakingPicture: false);
    return file;
  }

  /// Start streaming images from platform camera.
  Future<void> startImageStream(
      Function(CameraImageData image) onAvailable) async {
    _imageStreamSubscription = CameraPlatform.instance
        .onStreamedFrameAvailable(_cameraId)
        .listen((CameraImageData imageData) {
      onAvailable(imageData);
    });
    value = value.copyWith(isStreamingImages: true);
  }

  /// Stop streaming images from platform camera.
  Future<void> stopImageStream() async {
    value = value.copyWith(isStreamingImages: false);
    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = null;
  }

  /// Start a video recording.
  ///
  /// The video is returned as a [XFile] after calling [stopVideoRecording].
  /// Throws a [CameraException] if the capture fails.
  Future<void> startVideoRecording() async {
    await CameraPlatform.instance.startVideoRecording(_cameraId);
    value = value.copyWith(
        isRecordingVideo: true,
        isRecordingPaused: false,
        recordingOrientation: Optional<DeviceOrientation>.of(
            value.lockedCaptureOrientation ?? value.deviceOrientation));
  }

  /// Stops the video recording and returns the file where it was saved.
  ///
  /// Throws a [CameraException] if the capture failed.
  Future<XFile> stopVideoRecording() async {
    final XFile file =
        await CameraPlatform.instance.stopVideoRecording(_cameraId);
    value = value.copyWith(
      isRecordingVideo: false,
      recordingOrientation: const Optional<DeviceOrientation>.absent(),
    );
    return file;
  }

  /// Pause video recording.
  ///
  /// This feature is only available on iOS and Android sdk 24+.
  Future<void> pauseVideoRecording() async {
    await CameraPlatform.instance.pauseVideoRecording(_cameraId);
    value = value.copyWith(isRecordingPaused: true);
  }

  /// Resume video recording after pausing.
  ///
  /// This feature is only available on iOS and Android sdk 24+.
  Future<void> resumeVideoRecording() async {
    await CameraPlatform.instance.resumeVideoRecording(_cameraId);
    value = value.copyWith(isRecordingPaused: false);
  }

  /// Returns a widget showing a live camera preview.
  Widget buildPreview() {
    return CameraPlatform.instance.buildPreview(_cameraId);
  }

  /// Sets the flash mode for taking pictures.
  Future<void> setFlashMode(FlashMode mode) async {
    await CameraPlatform.instance.setFlashMode(_cameraId, mode);
    value = value.copyWith(flashMode: mode);
  }

  /// Sets the exposure mode for taking pictures.
  Future<void> setExposureMode(ExposureMode mode) async {
    await CameraPlatform.instance.setExposureMode(_cameraId, mode);
    value = value.copyWith(exposureMode: mode);
  }

  /// Sets the exposure offset for the selected camera.
  Future<double> setExposureOffset(double offset) async {
    // Check if offset is in range
    final List<double> range = await Future.wait(<Future<double>>[
      CameraPlatform.instance.getMinExposureOffset(_cameraId),
      CameraPlatform.instance.getMaxExposureOffset(_cameraId)
    ]);

    // Round to the closest step if needed
    final double stepSize =
        await CameraPlatform.instance.getExposureOffsetStepSize(_cameraId);
    if (stepSize > 0) {
      final double inv = 1.0 / stepSize;
      double roundedOffset = (offset * inv).roundToDouble() / inv;
      if (roundedOffset > range[1]) {
        roundedOffset = (offset * inv).floorToDouble() / inv;
      } else if (roundedOffset < range[0]) {
        roundedOffset = (offset * inv).ceilToDouble() / inv;
      }
      offset = roundedOffset;
    }

    return CameraPlatform.instance.setExposureOffset(_cameraId, offset);
  }

  /// Locks the capture orientation.
  ///
  /// If [orientation] is omitted, the current device orientation is used.
  Future<void> lockCaptureOrientation() async {
    await CameraPlatform.instance
        .lockCaptureOrientation(_cameraId, value.deviceOrientation);
    value = value.copyWith(
        lockedCaptureOrientation:
            Optional<DeviceOrientation>.of(value.deviceOrientation));
  }

  /// Unlocks the capture orientation.
  Future<void> unlockCaptureOrientation() async {
    await CameraPlatform.instance.unlockCaptureOrientation(_cameraId);
    value = value.copyWith(
        lockedCaptureOrientation: const Optional<DeviceOrientation>.absent());
  }

  /// Sets the focus mode for taking pictures.
  Future<void> setFocusMode(FocusMode mode) async {
    await CameraPlatform.instance.setFocusMode(_cameraId, mode);
    value = value.copyWith(focusMode: mode);
  }

  /// Releases the resources of this camera.
  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _deviceOrientationSubscription?.cancel();
    _isDisposed = true;
    super.dispose();
    if (_initCalled != null) {
      await _initCalled;
      await CameraPlatform.instance.dispose(_cameraId);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    // Prevent ValueListenableBuilder in CameraPreview widget from causing an
    // exception to be thrown by attempting to remove its own listener after
    // the controller has already been disposed.
    if (!_isDisposed) {
      super.removeListener(listener);
    }
  }
}
