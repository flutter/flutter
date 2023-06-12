// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FlashMode should contain 4 options', () {
    const List<FlashMode> values = FlashMode.values;

    expect(values.length, 4);
  });

  test('FlashMode enum should have items in correct index', () {
    const List<FlashMode> values = FlashMode.values;

    expect(values[0], FlashMode.off);
    expect(values[1], FlashMode.auto);
    expect(values[2], FlashMode.always);
    expect(values[3], FlashMode.torch);
  });
}
