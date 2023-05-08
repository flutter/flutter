// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NavigationDrawerThemeData copyWith, ==, hashCode, basics', () {
    expect(const NavigationDrawerThemeData(), const NavigationDrawerThemeData().copyWith());
    expect(const NavigationDrawerThemeData().hashCode, const NavigationDrawerThemeData().copyWith().hashCode);
  });

  test('NavigationDrawerThemeData lerp special cases', () {
    expect(NavigationDrawerThemeData.lerp(null, null, 0), null);
    const NavigationDrawerThemeData data = NavigationDrawerThemeData();
    expect(identical(NavigationDrawerThemeData.lerp(data, data, 0.5), data), true);
  });
}
