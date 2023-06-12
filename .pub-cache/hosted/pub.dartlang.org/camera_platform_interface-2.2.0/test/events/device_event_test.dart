// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceOrientationChangedEvent tests', () {
    test('Constructor should initialize all properties', () {
      const DeviceOrientationChangedEvent event =
          DeviceOrientationChangedEvent(DeviceOrientation.portraitUp);

      expect(event.orientation, DeviceOrientation.portraitUp);
    });

    test('fromJson should initialize all properties', () {
      final DeviceOrientationChangedEvent event =
          DeviceOrientationChangedEvent.fromJson(const <String, dynamic>{
        'orientation': 'portraitUp',
      });

      expect(event.orientation, DeviceOrientation.portraitUp);
    });

    test('toJson should return a map with all fields', () {
      const DeviceOrientationChangedEvent event =
          DeviceOrientationChangedEvent(DeviceOrientation.portraitUp);

      final Map<String, dynamic> jsonMap = event.toJson();

      expect(jsonMap.length, 1);
      expect(jsonMap['orientation'], 'portraitUp');
    });

    test('equals should return true if objects are the same', () {
      const DeviceOrientationChangedEvent firstEvent =
          DeviceOrientationChangedEvent(DeviceOrientation.portraitUp);
      const DeviceOrientationChangedEvent secondEvent =
          DeviceOrientationChangedEvent(DeviceOrientation.portraitUp);

      expect(firstEvent == secondEvent, true);
    });

    test('equals should return false if orientation is different', () {
      const DeviceOrientationChangedEvent firstEvent =
          DeviceOrientationChangedEvent(DeviceOrientation.portraitUp);
      const DeviceOrientationChangedEvent secondEvent =
          DeviceOrientationChangedEvent(DeviceOrientation.landscapeLeft);

      expect(firstEvent == secondEvent, false);
    });

    test('hashCode should match hashCode of all properties', () {
      const DeviceOrientationChangedEvent event =
          DeviceOrientationChangedEvent(DeviceOrientation.portraitUp);
      final int expectedHashCode = event.orientation.hashCode;

      expect(event.hashCode, expectedHashCode);
    });
  });
}
