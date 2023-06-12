// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraLensDirection tests', () {
    test('CameraLensDirection should contain 3 options', () {
      const List<CameraLensDirection> values = CameraLensDirection.values;

      expect(values.length, 3);
    });

    test('CameraLensDirection enum should have items in correct index', () {
      const List<CameraLensDirection> values = CameraLensDirection.values;

      expect(values[0], CameraLensDirection.front);
      expect(values[1], CameraLensDirection.back);
      expect(values[2], CameraLensDirection.external);
    });
  });

  group('CameraDescription tests', () {
    test('Constructor should initialize all properties', () {
      const CameraDescription description = CameraDescription(
        name: 'Test',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 90,
      );

      expect(description.name, 'Test');
      expect(description.lensDirection, CameraLensDirection.front);
      expect(description.sensorOrientation, 90);
    });

    test('equals should return true if objects are the same', () {
      const CameraDescription firstDescription = CameraDescription(
        name: 'Test',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 90,
      );
      const CameraDescription secondDescription = CameraDescription(
        name: 'Test',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 90,
      );

      expect(firstDescription == secondDescription, true);
    });

    test('equals should return false if name is different', () {
      const CameraDescription firstDescription = CameraDescription(
        name: 'Test',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 90,
      );
      const CameraDescription secondDescription = CameraDescription(
        name: 'Testing',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 90,
      );

      expect(firstDescription == secondDescription, false);
    });

    test('equals should return false if lens direction is different', () {
      const CameraDescription firstDescription = CameraDescription(
        name: 'Test',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 90,
      );
      const CameraDescription secondDescription = CameraDescription(
        name: 'Test',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      );

      expect(firstDescription == secondDescription, false);
    });

    test('equals should return true if sensor orientation is different', () {
      const CameraDescription firstDescription = CameraDescription(
        name: 'Test',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 0,
      );
      const CameraDescription secondDescription = CameraDescription(
        name: 'Test',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 90,
      );

      expect(firstDescription == secondDescription, true);
    });

    test('hashCode should match hashCode of all equality-tested properties',
        () {
      const CameraDescription description = CameraDescription(
        name: 'Test',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 0,
      );
      final int expectedHashCode =
          Object.hash(description.name, description.lensDirection);

      expect(description.hashCode, expectedHashCode);
    });
  });
}
