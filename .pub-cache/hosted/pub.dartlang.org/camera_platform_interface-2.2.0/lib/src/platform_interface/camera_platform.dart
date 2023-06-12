// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_platform_interface/src/method_channel/method_channel_camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of camera must implement.
///
/// Platform implementations should extend this class rather than implement it as `camera`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [CameraPlatform] methods.
abstract class CameraPlatform extends PlatformInterface {
  /// Constructs a CameraPlatform.
  CameraPlatform() : super(token: _token);

  static final Object _token = Object();

  static CameraPlatform _instance = MethodChannelCamera();

  /// The default instance of [CameraPlatform] to use.
  ///
  /// Defaults to [MethodChannelCamera].
  static CameraPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [CameraPlatform] when they register themselves.
  static set instance(CameraPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Completes with a list of available cameras.
  ///
  /// This method returns an empty list when no cameras are available.
  Future<List<CameraDescription>> availableCameras() {
    throw UnimplementedError('availableCameras() is not implemented.');
  }

  /// Creates an uninitialized camera instance and returns the cameraId.
  Future<int> createCamera(
    CameraDescription cameraDescription,
    ResolutionPreset? resolutionPreset, {
    bool enableAudio = false,
  }) {
    throw UnimplementedError('createCamera() is not implemented.');
  }

  /// Initializes the camera on the device.
  ///
  /// [imageFormatGroup] is used to specify the image formatting used.
  /// On Android this defaults to ImageFormat.YUV_420_888 and applies only to the imageStream.
  /// On iOS this defaults to kCVPixelFormatType_32BGRA.
  /// On Web this parameter is currently not supported.
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) {
    throw UnimplementedError('initializeCamera() is not implemented.');
  }

  /// The camera has been initialized.
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) {
    throw UnimplementedError('onCameraInitialized() is not implemented.');
  }

  /// The camera's resolution has changed.
  /// On Web this returns an empty stream.
  Stream<CameraResolutionChangedEvent> onCameraResolutionChanged(int cameraId) {
    throw UnimplementedError('onResolutionChanged() is not implemented.');
  }

  /// The camera started to close.
  Stream<CameraClosingEvent> onCameraClosing(int cameraId) {
    throw UnimplementedError('onCameraClosing() is not implemented.');
  }

  /// The camera experienced an error.
  Stream<CameraErrorEvent> onCameraError(int cameraId) {
    throw UnimplementedError('onCameraError() is not implemented.');
  }

  /// The camera finished recording a video.
  Stream<VideoRecordedEvent> onVideoRecordedEvent(int cameraId) {
    throw UnimplementedError('onCameraTimeLimitReached() is not implemented.');
  }

  /// The ui orientation changed.
  ///
  /// Implementations for this:
  /// - Should support all 4 orientations.
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() {
    throw UnimplementedError(
        'onDeviceOrientationChanged() is not implemented.');
  }

  /// Locks the capture orientation.
  Future<void> lockCaptureOrientation(
      int cameraId, DeviceOrientation orientation) {
    throw UnimplementedError('lockCaptureOrientation() is not implemented.');
  }

  /// Unlocks the capture orientation.
  Future<void> unlockCaptureOrientation(int cameraId) {
    throw UnimplementedError('unlockCaptureOrientation() is not implemented.');
  }

  /// Captures an image and returns the file where it was saved.
  Future<XFile> takePicture(int cameraId) {
    throw UnimplementedError('takePicture() is not implemented.');
  }

  /// Prepare the capture session for video recording.
  Future<void> prepareForVideoRecording() {
    throw UnimplementedError('prepareForVideoRecording() is not implemented.');
  }

  /// Starts a video recording.
  ///
  /// The length of the recording can be limited by specifying the [maxVideoDuration].
  /// By default no maximum duration is specified,
  /// meaning the recording will continue until manually stopped.
  /// With [maxVideoDuration] set the video is returned in a [VideoRecordedEvent]
  /// through the [onVideoRecordedEvent] stream when the set duration is reached.
  Future<void> startVideoRecording(int cameraId, {Duration? maxVideoDuration}) {
    throw UnimplementedError('startVideoRecording() is not implemented.');
  }

  /// Stops the video recording and returns the file where it was saved.
  Future<XFile> stopVideoRecording(int cameraId) {
    throw UnimplementedError('stopVideoRecording() is not implemented.');
  }

  /// Pause video recording.
  Future<void> pauseVideoRecording(int cameraId) {
    throw UnimplementedError('pauseVideoRecording() is not implemented.');
  }

  /// Resume video recording after pausing.
  Future<void> resumeVideoRecording(int cameraId) {
    throw UnimplementedError('resumeVideoRecording() is not implemented.');
  }

  /// A new streamed frame is available.
  ///
  /// Listening to this stream will start streaming, and canceling will stop.
  /// Pausing will throw a [CameraException], as pausing the stream would cause
  /// very high memory usage; to temporarily stop receiving frames, cancel, then
  /// listen again later.
  ///
  ///
  // TODO(bmparr): Add options to control streaming settings (e.g.,
  // resolution and FPS).
  Stream<CameraImageData> onStreamedFrameAvailable(int cameraId,
      {CameraImageStreamOptions? options}) {
    throw UnimplementedError('onStreamedFrameAvailable() is not implemented.');
  }

  /// Sets the flash mode for the selected camera.
  /// On Web [FlashMode.auto] corresponds to [FlashMode.always].
  Future<void> setFlashMode(int cameraId, FlashMode mode) {
    throw UnimplementedError('setFlashMode() is not implemented.');
  }

  /// Sets the exposure mode for taking pictures.
  Future<void> setExposureMode(int cameraId, ExposureMode mode) {
    throw UnimplementedError('setExposureMode() is not implemented.');
  }

  /// Sets the exposure point for automatically determining the exposure values.
  ///
  /// Supplying `null` for the [point] argument will result in resetting to the
  /// original exposure point value.
  Future<void> setExposurePoint(int cameraId, Point<double>? point) {
    throw UnimplementedError('setExposurePoint() is not implemented.');
  }

  /// Gets the minimum supported exposure offset for the selected camera in EV units.
  Future<double> getMinExposureOffset(int cameraId) {
    throw UnimplementedError('getMinExposureOffset() is not implemented.');
  }

  /// Gets the maximum supported exposure offset for the selected camera in EV units.
  Future<double> getMaxExposureOffset(int cameraId) {
    throw UnimplementedError('getMaxExposureOffset() is not implemented.');
  }

  /// Gets the supported step size for exposure offset for the selected camera in EV units.
  ///
  /// Returns 0 when the camera supports using a free value without stepping.
  Future<double> getExposureOffsetStepSize(int cameraId) {
    throw UnimplementedError('getMinExposureOffset() is not implemented.');
  }

  /// Sets the exposure offset for the selected camera.
  ///
  /// The supplied [offset] value should be in EV units. 1 EV unit represents a
  /// doubling in brightness. It should be between the minimum and maximum offsets
  /// obtained through `getMinExposureOffset` and `getMaxExposureOffset` respectively.
  /// Throws a `CameraException` when an illegal offset is supplied.
  ///
  /// When the supplied [offset] value does not align with the step size obtained
  /// through `getExposureStepSize`, it will automatically be rounded to the nearest step.
  ///
  /// Returns the (rounded) offset value that was set.
  Future<double> setExposureOffset(int cameraId, double offset) {
    throw UnimplementedError('setExposureOffset() is not implemented.');
  }

  /// Sets the focus mode for taking pictures.
  Future<void> setFocusMode(int cameraId, FocusMode mode) {
    throw UnimplementedError('setFocusMode() is not implemented.');
  }

  /// Sets the focus point for automatically determining the focus values.
  ///
  /// Supplying `null` for the [point] argument will result in resetting to the
  /// original focus point value.
  Future<void> setFocusPoint(int cameraId, Point<double>? point) {
    throw UnimplementedError('setFocusPoint() is not implemented.');
  }

  /// Gets the maximum supported zoom level for the selected camera.
  Future<double> getMaxZoomLevel(int cameraId) {
    throw UnimplementedError('getMaxZoomLevel() is not implemented.');
  }

  /// Gets the minimum supported zoom level for the selected camera.
  Future<double> getMinZoomLevel(int cameraId) {
    throw UnimplementedError('getMinZoomLevel() is not implemented.');
  }

  /// Set the zoom level for the selected camera.
  ///
  /// The supplied [zoom] value should be between the minimum and the maximum supported
  /// zoom level returned by `getMinZoomLevel` and `getMaxZoomLevel`. Throws a `CameraException`
  /// when an illegal zoom level is supplied.
  Future<void> setZoomLevel(int cameraId, double zoom) {
    throw UnimplementedError('setZoomLevel() is not implemented.');
  }

  /// Pause the active preview on the current frame for the selected camera.
  Future<void> pausePreview(int cameraId) {
    throw UnimplementedError('pausePreview() is not implemented.');
  }

  /// Resume the paused preview for the selected camera.
  Future<void> resumePreview(int cameraId) {
    throw UnimplementedError('pausePreview() is not implemented.');
  }

  /// Returns a widget showing a live camera preview.
  Widget buildPreview(int cameraId) {
    throw UnimplementedError('buildView() has not been implemented.');
  }

  /// Releases the resources of this camera.
  Future<void> dispose(int cameraId) {
    throw UnimplementedError('dispose() is not implemented.');
  }
}
