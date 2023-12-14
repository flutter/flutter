// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  test('Generate a light scheme from a seed color', () {
    final initColor=Colors.blue;
    final ColorsScheme colorsScheme = ColorsScheme.fromSeed(seedColor: initColor);
    expect(colorsScheme.seedColor, initColor);
    expect(colorsScheme.color, const Color(0xff0061a4));
    expect(colorsScheme.onColor, const Color(0xffffffff));
    expect(colorsScheme.container, const Color(0xffd1e4ff));
    expect(colorsScheme.onContainer, const Color(0xff001d36));
    expect(colorsScheme.brightness, Brightness.light);
  });

  test('Generate a dark scheme from a seed color', () {
    final initColor=Colors.blue;
    final ColorsScheme colorsScheme = ColorsScheme.fromSeed(
      seedColor: initColor,
      brightness:Brightness.dark,
    );
    expect(colorsScheme.seedColor, initColor);
    expect(colorsScheme.color, const Color(0xff9ecaff));
    expect(colorsScheme.onColor, const Color(0xff003258));
    expect(colorsScheme.container, const Color(0xff00497d));
    expect(colorsScheme.onContainer, const Color(0xffd1e4ff));
    expect(colorsScheme.brightness, Brightness.dark);
  });

  test('Copy with overrides given colors', () {
    final initColor=Colors.blue;
    final ColorsScheme colorsScheme = ColorsScheme.fromSeed(
      seedColor: initColor,
    ).copyWith(
      seedColor : const Color(0x00000001),
      color : const Color(0x00000002),
      onColor : const Color(0x00000003),
      container : const Color(0x00000004),
      onContainer : const Color(0x00000005),
      brightness : Brightness.dark,
    );
    expect(colorsScheme.seedColor, const Color(0x00000001));
    expect(colorsScheme.color, const Color(0x00000002));
    expect(colorsScheme.onColor, const Color(0x00000003));
    expect(colorsScheme.container, const Color(0x00000004));
    expect(colorsScheme.onContainer, const Color(0x00000005));
    expect(colorsScheme.brightness, Brightness.dark);
  });

}
