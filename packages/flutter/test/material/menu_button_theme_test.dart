// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MenuButtonThemeData lerp special cases', () {
    expect(MenuButtonThemeData.lerp(null, null, 0), null);
    const data = MenuButtonThemeData();
    expect(identical(MenuButtonThemeData.lerp(data, data, 0.5), data), true);
  });
}
