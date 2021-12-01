// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light scheme matches the spec', () {
    // Colors should match the Material Design baseline default theme:
    // https://material.io/design/color/dark-theme.html#ui-application
    // with the new Material 3 colors defaulting to values from the M2
    // baseline.
    const ColorScheme scheme = ColorScheme.light();
    expect(scheme.brightness, Brightness.light);
    expect(scheme.primary, const Color(0xff6200ee));
    expect(scheme.onPrimary, const Color(0xffffffff));
    expect(scheme.primaryContainer, scheme.primary);
    expect(scheme.onPrimaryContainer, scheme.onPrimary);
    expect(scheme.secondary, const Color(0xff03dac6));
    expect(scheme.onSecondary, const Color(0xff000000));
    expect(scheme.secondaryContainer, scheme.secondary);
    expect(scheme.onSecondaryContainer, scheme.onSecondary);
    expect(scheme.tertiary, scheme.secondary);
    expect(scheme.onTertiary, scheme.onSecondary);
    expect(scheme.tertiaryContainer, scheme.tertiary);
    expect(scheme.onTertiaryContainer, scheme.onTertiary);
    expect(scheme.error, const Color(0xffb00020));
    expect(scheme.onError, const Color(0xffffffff));
    expect(scheme.errorContainer, scheme.error);
    expect(scheme.onErrorContainer, scheme.onError);
    expect(scheme.background, const Color(0xffffffff));
    expect(scheme.onBackground, const Color(0xff000000));
    expect(scheme.surface, const Color(0xffffffff));
    expect(scheme.onSurface, const Color(0xff000000));
    expect(scheme.surfaceVariant, scheme.surface);
    expect(scheme.onSurfaceVariant, scheme.onSurface);
    expect(scheme.outline, scheme.onBackground);
    expect(scheme.shadow, scheme.onBackground);
    expect(scheme.inverseSurface, scheme.onSurface);
    expect(scheme.onInverseSurface, scheme.surface);
    expect(scheme.inversePrimary, scheme.onPrimary);

    expect(scheme.primaryVariant, const Color(0xff3700b3));
    expect(scheme.secondaryVariant, const Color(0xff018786));
  });

  test('dark scheme matches the spec', () {
    // Colors should match the Material Design baseline dark theme:
    // https://material.io/design/color/dark-theme.html#ui-application
    // with the new Material 3 colors defaulting to values from the M2
    // baseline.
    const ColorScheme scheme = ColorScheme.dark();
    expect(scheme.brightness, Brightness.dark);
    expect(scheme.primary, const Color(0xffbb86fc));
    expect(scheme.onPrimary, const Color(0xff000000));
    expect(scheme.primaryContainer, scheme.primary);
    expect(scheme.onPrimaryContainer, scheme.onPrimary);
    expect(scheme.secondary, const Color(0xff03dac6));
    expect(scheme.onSecondary, const Color(0xff000000));
    expect(scheme.secondaryContainer, scheme.secondary);
    expect(scheme.onSecondaryContainer, scheme.onSecondary);
    expect(scheme.tertiary, scheme.secondary);
    expect(scheme.onTertiary, scheme.onSecondary);
    expect(scheme.tertiaryContainer, scheme.tertiary);
    expect(scheme.onTertiaryContainer, scheme.onTertiary);
    expect(scheme.error, const Color(0xffcf6679));
    expect(scheme.onError, const Color(0xff000000));
    expect(scheme.errorContainer, scheme.error);
    expect(scheme.onErrorContainer, scheme.onError);
    expect(scheme.background, const Color(0xff121212));
    expect(scheme.onBackground, const Color(0xffffffff));
    expect(scheme.surface, const Color(0xff121212));
    expect(scheme.onSurface, const Color(0xffffffff));
    expect(scheme.surfaceVariant, scheme.surface);
    expect(scheme.onSurfaceVariant, scheme.onSurface);
    expect(scheme.outline, scheme.onBackground);
    expect(scheme.shadow, scheme.onBackground);
    expect(scheme.inverseSurface, scheme.onSurface);
    expect(scheme.onInverseSurface, scheme.surface);
    expect(scheme.inversePrimary, scheme.onPrimary);

    expect(scheme.primaryVariant, const Color(0xff3700b3));
    expect(scheme.secondaryVariant, const Color(0xff03dac6));
  });

  test('high contrast light scheme matches the spec', () {
    // Colors are based off of the Material Design baseline default theme:
    // https://material.io/design/color/dark-theme.html#ui-application
    // with the new Material 3 colors defaulting to values from the M2
    // baseline.
    const ColorScheme scheme = ColorScheme.highContrastLight();
    expect(scheme.brightness, Brightness.light);
    expect(scheme.primary, const Color(0xff0000ba));
    expect(scheme.onPrimary, const Color(0xffffffff));
    expect(scheme.primaryContainer, scheme.primary);
    expect(scheme.onPrimaryContainer, scheme.onPrimary);
    expect(scheme.secondary, const Color(0xff66fff9));
    expect(scheme.onSecondary, const Color(0xff000000));
    expect(scheme.secondaryContainer, scheme.secondary);
    expect(scheme.onSecondaryContainer, scheme.onSecondary);
    expect(scheme.tertiary, scheme.secondary);
    expect(scheme.onTertiary, scheme.onSecondary);
    expect(scheme.tertiaryContainer, scheme.tertiary);
    expect(scheme.onTertiaryContainer, scheme.onTertiary);
    expect(scheme.error, const Color(0xff790000));
    expect(scheme.onError, const Color(0xffffffff));
    expect(scheme.errorContainer, scheme.error);
    expect(scheme.onErrorContainer, scheme.onError);
    expect(scheme.background, const Color(0xffffffff));
    expect(scheme.onBackground, const Color(0xff000000));
    expect(scheme.surface, const Color(0xffffffff));
    expect(scheme.onSurface, const Color(0xff000000));
    expect(scheme.surfaceVariant, scheme.surface);
    expect(scheme.onSurfaceVariant, scheme.onSurface);
    expect(scheme.outline, scheme.onBackground);
    expect(scheme.shadow, scheme.onBackground);
    expect(scheme.inverseSurface, scheme.onSurface);
    expect(scheme.onInverseSurface, scheme.surface);
    expect(scheme.inversePrimary, scheme.onPrimary);

    expect(scheme.primaryVariant, const Color(0xff000088));
    expect(scheme.secondaryVariant, const Color(0xff018786));
  });

  test('high contrast dark scheme matches the spec', () {
    // Colors are based off of the Material Design baseline dark theme:
    // https://material.io/design/color/dark-theme.html#ui-application
    // with the new Material 3 colors defaulting to values from the M2
    // baseline.
    const ColorScheme scheme = ColorScheme.highContrastDark();
    expect(scheme.brightness, Brightness.dark);
    expect(scheme.primary, const Color(0xffefb7ff));
    expect(scheme.onPrimary, const Color(0xff000000));
    expect(scheme.primaryContainer, scheme.primary);
    expect(scheme.onPrimaryContainer, scheme.onPrimary);
    expect(scheme.secondary, const Color(0xff66fff9));
    expect(scheme.onSecondary, const Color(0xff000000));
    expect(scheme.secondaryContainer, scheme.secondary);
    expect(scheme.onSecondaryContainer, scheme.onSecondary);
    expect(scheme.tertiary, scheme.secondary);
    expect(scheme.onTertiary, scheme.onSecondary);
    expect(scheme.tertiaryContainer, scheme.tertiary);
    expect(scheme.onTertiaryContainer, scheme.onTertiary);
    expect(scheme.error, const Color(0xff9b374d));
    expect(scheme.onError, const Color(0xff000000));
    expect(scheme.errorContainer, scheme.error);
    expect(scheme.onErrorContainer, scheme.onError);
    expect(scheme.background, const Color(0xff121212));
    expect(scheme.onBackground, const Color(0xffffffff));
    expect(scheme.surface, const Color(0xff121212));
    expect(scheme.onSurface, const Color(0xffffffff));
    expect(scheme.surfaceVariant, scheme.surface);
    expect(scheme.onSurfaceVariant, scheme.onSurface);
    expect(scheme.outline, scheme.onBackground);
    expect(scheme.shadow, scheme.onBackground);
    expect(scheme.inverseSurface, scheme.onSurface);
    expect(scheme.onInverseSurface, scheme.surface);
    expect(scheme.inversePrimary, scheme.onPrimary);

    expect(scheme.primaryVariant, const Color(0xffbe9eff));
    expect(scheme.secondaryVariant, const Color(0xff66fff9));
  });
}
