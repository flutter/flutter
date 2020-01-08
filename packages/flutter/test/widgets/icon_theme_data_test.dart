// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IconThemeData control test', () {
    const IconThemeData data = IconThemeData(color: Color(0xAAAAAAAA), opacity: 0.5, size: 16.0);

    expect(data, hasOneLineDescription);
    expect(data, equals(data.copyWith()));
    expect(data.hashCode, equals(data.copyWith().hashCode));

    final IconThemeData lerped = IconThemeData.lerp(data, const IconThemeData.fallback(), 0.25);
    expect(lerped.color, const Color(0xBF7F7F7F));
    expect(lerped.opacity, 0.625);
    expect(lerped.size, 18.0);
  });

  test('IconThemeData lerp with first null', () {
    const IconThemeData data = IconThemeData(color: Color(0xFFFFFFFF), opacity: 1.0, size: 16.0);

    final IconThemeData lerped = IconThemeData.lerp(null, data, 0.25);
    expect(lerped.color, const Color(0x40FFFFFF));
    expect(lerped.opacity, 0.25);
    expect(lerped.size, 4.0);
  });

  test('IconThemeData lerp with second null', () {
    const IconThemeData data = IconThemeData(color: Color(0xFFFFFFFF), opacity: 1.0, size: 16.0);

    final IconThemeData lerped = IconThemeData.lerp(data, null, 0.25);
    expect(lerped.color, const Color(0xBFFFFFFF));
    expect(lerped.opacity, 0.75);
    expect(lerped.size, 12.0);
  });

  test('IconThemeData lerp with both null', () {
    final IconThemeData lerped = IconThemeData.lerp(null, null, 0.25);
    expect(lerped.color, null);
    expect(lerped.opacity, null);
    expect(lerped.size, null);
  });
}
