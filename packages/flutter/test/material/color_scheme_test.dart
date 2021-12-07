// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light scheme matches the spec', () {
    // Colors should match the Material Design baseline default theme:
    // https://material.io/design/color/dark-theme.html#ui-application
    const ColorScheme scheme = ColorScheme.light();
    expect(scheme.primary, const Color(0xff6200ee));
    expect(scheme.primaryVariant, const Color(0xff3700b3));
    expect(scheme.secondary, const Color(0xff03dac6));
    expect(scheme.secondaryVariant, const Color(0xff018786));
    expect(scheme.background, const Color(0xffffffff));
    expect(scheme.surface, const Color(0xffffffff));
    expect(scheme.error, const Color(0xffb00020));
    expect(scheme.onPrimary, const Color(0xffffffff));
    expect(scheme.onSecondary, const Color(0xff000000));
    expect(scheme.onBackground, const Color(0xff000000));
    expect(scheme.onSurface, const Color(0xff000000));
    expect(scheme.onError, const Color(0xffffffff));
    expect(scheme.brightness, Brightness.light);
  });

  test('dark scheme matches the spec', () {
    // Colors should match the Material Design baseline dark theme:
    // https://material.io/design/color/dark-theme.html#ui-application
    const ColorScheme scheme = ColorScheme.dark();
    expect(scheme.primary, const Color(0xffbb86fc));
    expect(scheme.primaryVariant, const Color(0xff3700b3));
    expect(scheme.secondary, const Color(0xff03dac6));
    expect(scheme.secondaryVariant, const Color(0xff03dac6));
    expect(scheme.background, const Color(0xff121212));
    expect(scheme.surface, const Color(0xff121212));
    expect(scheme.error, const Color(0xffcf6679));
    expect(scheme.onPrimary, const Color(0xff000000));
    expect(scheme.onSecondary, const Color(0xff000000));
    expect(scheme.onBackground, const Color(0xffffffff));
    expect(scheme.onSurface, const Color(0xffffffff));
    expect(scheme.onError, const Color(0xff000000));
    expect(scheme.brightness, Brightness.dark);
  });

  test('high contrast light scheme matches the spec', () {
    // Colors are based off of the Material Design baseline default theme:
    // https://material.io/design/color/dark-theme.html#ui-application
    const ColorScheme scheme = ColorScheme.highContrastLight();
    expect(scheme.primary, const Color(0xff0000ba));
    expect(scheme.primaryVariant, const Color(0xff000088));
    expect(scheme.secondary, const Color(0xff66fff9));
    expect(scheme.secondaryVariant, const Color(0xff018786));
    expect(scheme.background, const Color(0xffffffff));
    expect(scheme.surface, const Color(0xffffffff));
    expect(scheme.error, const Color(0xff790000));
    expect(scheme.onPrimary, const Color(0xffffffff));
    expect(scheme.onSecondary, const Color(0xff000000));
    expect(scheme.onBackground, const Color(0xff000000));
    expect(scheme.onSurface, const Color(0xff000000));
    expect(scheme.onError, const Color(0xffffffff));
    expect(scheme.brightness, Brightness.light);
  });

  test('high contrast dark scheme matches the spec', () {
    // Colors are based off of the Material Design baseline dark theme:
    // https://material.io/design/color/dark-theme.html#ui-application
    const ColorScheme scheme = ColorScheme.highContrastDark();
    expect(scheme.primary, const Color(0xffefb7ff));
    expect(scheme.primaryVariant, const Color(0xffbe9eff));
    expect(scheme.secondary, const Color(0xff66fff9));
    expect(scheme.secondaryVariant, const Color(0xff66fff9));
    expect(scheme.background, const Color(0xff121212));
    expect(scheme.surface, const Color(0xff121212));
    expect(scheme.error, const Color(0xff9b374d));
    expect(scheme.onPrimary, const Color(0xff000000));
    expect(scheme.onSecondary, const Color(0xff000000));
    expect(scheme.onBackground, const Color(0xffffffff));
    expect(scheme.onSurface, const Color(0xffffffff));
    expect(scheme.onError, const Color(0xff000000));
    expect(scheme.brightness, Brightness.dark);
  });
}
