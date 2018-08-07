// Copyright 2016 The Chromium Authors. All rights reserved.
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
    expect(lerped.color, equals(Color.lerp(const Color(0xAAAAAAAA), const Color(0xFF000000), 0.25)));
    expect(lerped.opacity, equals(0.625));
    expect(lerped.size, equals(18.0));
  });
}
