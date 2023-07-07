// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ResolutionPreset should contain 6 options', () {
    const List<ResolutionPreset> values = ResolutionPreset.values;

    expect(values.length, 6);
  });

  test('ResolutionPreset enum should have items in correct index', () {
    const List<ResolutionPreset> values = ResolutionPreset.values;

    expect(values[0], ResolutionPreset.low);
    expect(values[1], ResolutionPreset.medium);
    expect(values[2], ResolutionPreset.high);
    expect(values[3], ResolutionPreset.veryHigh);
    expect(values[4], ResolutionPreset.ultraHigh);
    expect(values[5], ResolutionPreset.max);
  });
}
