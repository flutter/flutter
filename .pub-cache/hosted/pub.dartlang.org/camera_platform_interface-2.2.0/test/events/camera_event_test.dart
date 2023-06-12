// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraInitializedEvent tests', () {
    test('Constructor should initialize all properties', () {
      const CameraInitializedEvent event = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);

      expect(event.cameraId, 1);
      expect(event.previewWidth, 1024);
      expect(event.previewHeight, 640);
      expect(event.exposureMode, ExposureMode.auto);
      expect(event.focusMode, FocusMode.auto);
      expect(event.exposurePointSupported, true);
      expect(event.focusPointSupported, true);
    });

    test('fromJson should initialize all properties', () {
      final CameraInitializedEvent event =
          CameraInitializedEvent.fromJson(const <String, dynamic>{
        'cameraId': 1,
        'previewWidth': 1024.0,
        'previewHeight': 640.0,
        'exposureMode': 'auto',
        'exposurePointSupported': true,
        'focusMode': 'auto',
        'focusPointSupported': true
      });

      expect(event.cameraId, 1);
      expect(event.previewWidth, 1024);
      expect(event.previewHeight, 640);
      expect(event.exposureMode, ExposureMode.auto);
      expect(event.exposurePointSupported, true);
      expect(event.focusMode, FocusMode.auto);
      expect(event.focusPointSupported, true);
    });

    test('toJson should return a map with all fields', () {
      const CameraInitializedEvent event = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);

      final Map<String, dynamic> jsonMap = event.toJson();

      expect(jsonMap.length, 7);
      expect(jsonMap['cameraId'], 1);
      expect(jsonMap['previewWidth'], 1024);
      expect(jsonMap['previewHeight'], 640);
      expect(jsonMap['exposureMode'], 'auto');
      expect(jsonMap['exposurePointSupported'], true);
      expect(jsonMap['focusMode'], 'auto');
      expect(jsonMap['focusPointSupported'], true);
    });

    test('equals should return true if objects are the same', () {
      const CameraInitializedEvent firstEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);
      const CameraInitializedEvent secondEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);

      expect(firstEvent == secondEvent, true);
    });

    test('equals should return false if cameraId is different', () {
      const CameraInitializedEvent firstEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);
      const CameraInitializedEvent secondEvent = CameraInitializedEvent(
          2, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);

      expect(firstEvent == secondEvent, false);
    });

    test('equals should return false if previewWidth is different', () {
      const CameraInitializedEvent firstEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);
      const CameraInitializedEvent secondEvent = CameraInitializedEvent(
          1, 2048, 640, ExposureMode.auto, true, FocusMode.auto, true);

      expect(firstEvent == secondEvent, false);
    });

    test('equals should return false if previewHeight is different', () {
      const CameraInitializedEvent firstEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);
      const CameraInitializedEvent secondEvent = CameraInitializedEvent(
          1, 1024, 980, ExposureMode.auto, true, FocusMode.auto, true);

      expect(firstEvent == secondEvent, false);
    });

    test('equals should return false if exposureMode is different', () {
      const CameraInitializedEvent firstEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);
      const CameraInitializedEvent secondEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.locked, true, FocusMode.auto, true);

      expect(firstEvent == secondEvent, false);
    });

    test('equals should return false if exposurePointSupported is different',
        () {
      const CameraInitializedEvent firstEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);
      const CameraInitializedEvent secondEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, false, FocusMode.auto, true);

      expect(firstEvent == secondEvent, false);
    });

    test('equals should return false if focusMode is different', () {
      const CameraInitializedEvent firstEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);
      const CameraInitializedEvent secondEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.locked, true);

      expect(firstEvent == secondEvent, false);
    });

    test('equals should return false if focusPointSupported is different', () {
      const CameraInitializedEvent firstEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);
      const CameraInitializedEvent secondEvent = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, false);

      expect(firstEvent == secondEvent, false);
    });

    test('hashCode should match hashCode of all properties', () {
      const CameraInitializedEvent event = CameraInitializedEvent(
          1, 1024, 640, ExposureMode.auto, true, FocusMode.auto, true);
      final int expectedHashCode = Object.hash(
          event.cameraId,
          event.previewWidth,
          event.previewHeight,
          event.exposureMode,
          event.exposurePointSupported,
          event.focusMode,
          event.focusPointSupported);

      expect(event.hashCode, expectedHashCode);
    });
  });

  group('CameraResolutionChangesEvent tests', () {
    test('Constructor should initialize all properties', () {
      const CameraResolutionChangedEvent event =
          CameraResolutionChangedEvent(1, 1024, 640);

      expect(event.cameraId, 1);
      expect(event.captureWidth, 1024);
      expect(event.captureHeight, 640);
    });

    test('fromJson should initialize all properties', () {
      final CameraResolutionChangedEvent event =
          CameraResolutionChangedEvent.fromJson(const <String, dynamic>{
        'cameraId': 1,
        'captureWidth': 1024.0,
        'captureHeight': 640.0,
      });

      expect(event.cameraId, 1);
      expect(event.captureWidth, 1024);
      expect(event.captureHeight, 640);
    });

    test('toJson should return a map with all fields', () {
      const CameraResolutionChangedEvent event =
          CameraResolutionChangedEvent(1, 1024, 640);

      final Map<String, dynamic> jsonMap = event.toJson();

      expect(jsonMap.length, 3);
      expect(jsonMap['cameraId'], 1);
      expect(jsonMap['captureWidth'], 1024);
      expect(jsonMap['captureHeight'], 640);
    });

    test('equals should return true if objects are the same', () {
      const CameraResolutionChangedEvent firstEvent =
          CameraResolutionChangedEvent(1, 1024, 640);
      const CameraResolutionChangedEvent secondEvent =
          CameraResolutionChangedEvent(1, 1024, 640);

      expect(firstEvent == secondEvent, true);
    });

    test('equals should return false if cameraId is different', () {
      const CameraResolutionChangedEvent firstEvent =
          CameraResolutionChangedEvent(1, 1024, 640);
      const CameraResolutionChangedEvent secondEvent =
          CameraResolutionChangedEvent(2, 1024, 640);

      expect(firstEvent == secondEvent, false);
    });

    test('equals should return false if captureWidth is different', () {
      const CameraResolutionChangedEvent firstEvent =
          CameraResolutionChangedEvent(1, 1024, 640);
      const CameraResolutionChangedEvent secondEvent =
          CameraResolutionChangedEvent(1, 2048, 640);

      expect(firstEvent == secondEvent, false);
    });

    test('equals should return false if captureHeight is different', () {
      const CameraResolutionChangedEvent firstEvent =
          CameraResolutionChangedEvent(1, 1024, 640);
      const CameraResolutionChangedEvent secondEvent =
          CameraResolutionChangedEvent(1, 1024, 980);

      expect(firstEvent == secondEvent, false);
    });

    test('hashCode should match hashCode of all properties', () {
      const CameraResolutionChangedEvent event =
          CameraResolutionChangedEvent(1, 1024, 640);
      final int expectedHashCode =
          Object.hash(event.cameraId, event.captureWidth, event.captureHeight);

      expect(event.hashCode, expectedHashCode);
    });
  });

  group('CameraClosingEvent tests', () {
    test('Constructor should initialize all properties', () {
      const CameraClosingEvent event = CameraClosingEvent(1);

      expect(event.cameraId, 1);
    });

    test('fromJson should initialize all properties', () {
      final CameraClosingEvent event =
          CameraClosingEvent.fromJson(const <String, dynamic>{
        'cameraId': 1,
      });

      expect(event.cameraId, 1);
    });

    test('toJson should return a map with all fields', () {
      const CameraClosingEvent event = CameraClosingEvent(1);

      final Map<String, dynamic> jsonMap = event.toJson();

      expect(jsonMap.length, 1);
      expect(jsonMap['cameraId'], 1);
    });

    test('equals should return true if objects are the same', () {
      const CameraClosingEvent firstEvent = CameraClosingEvent(1);
      const CameraClosingEvent secondEvent = CameraClosingEvent(1);

      expect(firstEvent == secondEvent, true);
    });

    test('equals should return false if cameraId is different', () {
      const CameraClosingEvent firstEvent = CameraClosingEvent(1);
      const CameraClosingEvent secondEvent = CameraClosingEvent(2);

      expect(firstEvent == secondEvent, false);
    });

    test('hashCode should match hashCode of all properties', () {
      const CameraClosingEvent event = CameraClosingEvent(1);
      final int expectedHashCode = event.cameraId.hashCode;

      expect(event.hashCode, expectedHashCode);
    });
  });

  group('CameraErrorEvent tests', () {
    test('Constructor should initialize all properties', () {
      const CameraErrorEvent event = CameraErrorEvent(1, 'Error');

      expect(event.cameraId, 1);
      expect(event.description, 'Error');
    });

    test('fromJson should initialize all properties', () {
      final CameraErrorEvent event = CameraErrorEvent.fromJson(
          const <String, dynamic>{'cameraId': 1, 'description': 'Error'});

      expect(event.cameraId, 1);
      expect(event.description, 'Error');
    });

    test('toJson should return a map with all fields', () {
      const CameraErrorEvent event = CameraErrorEvent(1, 'Error');

      final Map<String, dynamic> jsonMap = event.toJson();

      expect(jsonMap.length, 2);
      expect(jsonMap['cameraId'], 1);
      expect(jsonMap['description'], 'Error');
    });

    test('equals should return true if objects are the same', () {
      const CameraErrorEvent firstEvent = CameraErrorEvent(1, 'Error');
      const CameraErrorEvent secondEvent = CameraErrorEvent(1, 'Error');

      expect(firstEvent == secondEvent, true);
    });

    test('equals should return false if cameraId is different', () {
      const CameraErrorEvent firstEvent = CameraErrorEvent(1, 'Error');
      const CameraErrorEvent secondEvent = CameraErrorEvent(2, 'Error');

      expect(firstEvent == secondEvent, false);
    });

    test('equals should return false if description is different', () {
      const CameraErrorEvent firstEvent = CameraErrorEvent(1, 'Error');
      const CameraErrorEvent secondEvent = CameraErrorEvent(1, 'Ooops');

      expect(firstEvent == secondEvent, false);
    });

    test('hashCode should match hashCode of all properties', () {
      const CameraErrorEvent event = CameraErrorEvent(1, 'Error');
      final int expectedHashCode =
          Object.hash(event.cameraId, event.description);

      expect(event.hashCode, expectedHashCode);
    });
  });
}
