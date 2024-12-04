// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Theme mode test', () {
    const ThemeMode dark = ThemeMode.dark;
    const ThemeMode light = ThemeMode.light;
    const ThemeMode system = ThemeMode.system;

    expect(dark == ThemeMode.dark, dark.isDark);
    expect(light == ThemeMode.light, light.isLight);
    expect(system == ThemeMode.system, system.isSystem);

    expect(dark != ThemeMode.dark, !dark.isDark);
    expect(light != ThemeMode.light, !light.isLight);
    expect(system != ThemeMode.system, !system.isSystem);

    expect(dark.isDark, true);
    expect(dark.isLight, false);
    expect(dark.isSystem, false);

    expect(light.isDark, false);
    expect(light.isLight, true);
    expect(light.isSystem, false);

    expect(system.isDark, false);
    expect(system.isLight, false);
    expect(system.isSystem, true);
  });
}
