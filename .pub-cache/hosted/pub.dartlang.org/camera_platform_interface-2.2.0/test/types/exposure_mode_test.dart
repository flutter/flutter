// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_platform_interface/src/types/exposure_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ExposureMode should contain 2 options', () {
    const List<ExposureMode> values = ExposureMode.values;

    expect(values.length, 2);
  });

  test('ExposureMode enum should have items in correct index', () {
    const List<ExposureMode> values = ExposureMode.values;

    expect(values[0], ExposureMode.auto);
    expect(values[1], ExposureMode.locked);
  });

  test('serializeExposureMode() should serialize correctly', () {
    expect(serializeExposureMode(ExposureMode.auto), 'auto');
    expect(serializeExposureMode(ExposureMode.locked), 'locked');
  });

  test('deserializeExposureMode() should deserialize correctly', () {
    expect(deserializeExposureMode('auto'), ExposureMode.auto);
    expect(deserializeExposureMode('locked'), ExposureMode.locked);
  });
}
