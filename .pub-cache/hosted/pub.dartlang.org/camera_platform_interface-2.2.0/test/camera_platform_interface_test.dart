// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_platform_interface/src/method_channel/method_channel_camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$CameraPlatform', () {
    test('$MethodChannelCamera is the default instance', () {
      expect(CameraPlatform.instance, isA<MethodChannelCamera>());
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        CameraPlatform.instance = ImplementsCameraPlatform();
      }, throwsNoSuchMethodError);
    });

    test('Can be extended', () {
      CameraPlatform.instance = ExtendsCameraPlatform();
    });

    test(
        'Default implementation of availableCameras() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.availableCameras(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of onCameraInitialized() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.onCameraInitialized(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of onResolutionChanged() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.onCameraResolutionChanged(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of onCameraClosing() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.onCameraClosing(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of onCameraError() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.onCameraError(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of onDeviceOrientationChanged() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.onDeviceOrientationChanged(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of lockCaptureOrientation() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.lockCaptureOrientation(
            1, DeviceOrientation.portraitUp),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of unlockCaptureOrientation() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.unlockCaptureOrientation(1),
        throwsUnimplementedError,
      );
    });

    test('Default implementation of dispose() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.dispose(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of createCamera() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.createCamera(
          const CameraDescription(
            name: 'back',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 0,
          ),
          ResolutionPreset.high,
        ),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of initializeCamera() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.initializeCamera(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of pauseVideoRecording() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.pauseVideoRecording(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of prepareForVideoRecording() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.prepareForVideoRecording(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of resumeVideoRecording() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.resumeVideoRecording(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of setFlashMode() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.setFlashMode(1, FlashMode.auto),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of setExposureMode() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.setExposureMode(1, ExposureMode.auto),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of setExposurePoint() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.setExposurePoint(1, null),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of getMinExposureOffset() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.getMinExposureOffset(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of getMaxExposureOffset() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.getMaxExposureOffset(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of getExposureOffsetStepSize() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.getExposureOffsetStepSize(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of setExposureOffset() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.setExposureOffset(1, 2.0),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of setFocusMode() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.setFocusMode(1, FocusMode.auto),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of setFocusPoint() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.setFocusPoint(1, null),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of startVideoRecording() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.startVideoRecording(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of stopVideoRecording() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.stopVideoRecording(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of takePicture() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.takePicture(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of getMaxZoomLevel() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.getMaxZoomLevel(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of getMinZoomLevel() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.getMinZoomLevel(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of setZoomLevel() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.setZoomLevel(1, 1.0),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of pausePreview() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.pausePreview(1),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of resumePreview() should throw unimplemented error',
        () {
      // Arrange
      final ExtendsCameraPlatform cameraPlatform = ExtendsCameraPlatform();

      // Act & Assert
      expect(
        () => cameraPlatform.resumePreview(1),
        throwsUnimplementedError,
      );
    });
  });
}

class ImplementsCameraPlatform implements CameraPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ExtendsCameraPlatform extends CameraPlatform {}
