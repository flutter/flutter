// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/src/types/focus_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FocusMode should contain 2 options', () {
    const List<FocusMode> values = FocusMode.values;

    expect(values.length, 2);
  });

  test('FocusMode enum should have items in correct index', () {
    const List<FocusMode> values = FocusMode.values;

    expect(values[0], FocusMode.auto);
    expect(values[1], FocusMode.locked);
  });

  test('serializeFocusMode() should serialize correctly', () {
    expect(serializeFocusMode(FocusMode.auto), 'auto');
    expect(serializeFocusMode(FocusMode.locked), 'locked');
  });

  test('deserializeFocusMode() should deserialize correctly', () {
    expect(deserializeFocusMode('auto'), FocusMode.auto);
    expect(deserializeFocusMode('locked'), FocusMode.locked);
  });
}
