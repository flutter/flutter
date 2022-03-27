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
    expect(scheme.shadow, const Color(0xff000000));
    expect(scheme.inverseSurface, scheme.onSurface);
    expect(scheme.onInverseSurface, scheme.surface);
    expect(scheme.inversePrimary, scheme.onPrimary);
    expect(scheme.surfaceTint, scheme.primary);

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
    expect(scheme.shadow, const Color(0xff000000));
    expect(scheme.inverseSurface, scheme.onSurface);
    expect(scheme.onInverseSurface, scheme.surface);
    expect(scheme.inversePrimary, scheme.onPrimary);
    expect(scheme.surfaceTint, scheme.primary);

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
    expect(scheme.shadow, const Color(0xff000000));
    expect(scheme.inverseSurface, scheme.onSurface);
    expect(scheme.onInverseSurface, scheme.surface);
    expect(scheme.inversePrimary, scheme.onPrimary);
    expect(scheme.surfaceTint, scheme.primary);

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
    expect(scheme.shadow, const Color(0xff000000));
    expect(scheme.inverseSurface, scheme.onSurface);
    expect(scheme.onInverseSurface, scheme.surface);
    expect(scheme.inversePrimary, scheme.onPrimary);
    expect(scheme.surfaceTint, scheme.primary);

    expect(scheme.primaryVariant, const Color(0xffbe9eff));
    expect(scheme.secondaryVariant, const Color(0xff66fff9));
  });

  test('can generate a light scheme from a seed color', () {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    expect(scheme.primary, const Color(0xff0061a6));
    expect(scheme.onPrimary, const Color(0xffffffff));
    expect(scheme.primaryContainer, const Color(0xffd0e4ff));
    expect(scheme.onPrimaryContainer, const Color(0xff001d36));
    expect(scheme.secondary, const Color(0xff535f70));
    expect(scheme.onSecondary, const Color(0xffffffff));
    expect(scheme.secondaryContainer, const Color(0xffd6e3f7));
    expect(scheme.onSecondaryContainer, const Color(0xff101c2b));
    expect(scheme.tertiary, const Color(0xff6b5778));
    expect(scheme.onTertiary, const Color(0xffffffff));
    expect(scheme.tertiaryContainer, const Color(0xfff3daff));
    expect(scheme.onTertiaryContainer, const Color(0xff251432));
    expect(scheme.error, const Color(0xffba1b1b));
    expect(scheme.onError, const Color(0xffffffff));
    expect(scheme.errorContainer, const Color(0xffffdad4));
    expect(scheme.onErrorContainer, const Color(0xff410001));
    expect(scheme.outline, const Color(0xff73777f));
    expect(scheme.background, const Color(0xfffdfcff));
    expect(scheme.onBackground, const Color(0xff1b1b1b));
    expect(scheme.surface, const Color(0xfffdfcff));
    expect(scheme.onSurface, const Color(0xff1b1b1b));
    expect(scheme.surfaceVariant, const Color(0xffdfe2eb));
    expect(scheme.onSurfaceVariant, const Color(0xff42474e));
    expect(scheme.inverseSurface, const Color(0xff2f3033));
    expect(scheme.onInverseSurface, const Color(0xfff1f0f4));
    expect(scheme.inversePrimary, const Color(0xff9ccaff));
    expect(scheme.shadow, const Color(0xff000000));
    expect(scheme.surfaceTint, const Color(0xff0061a6));
    expect(scheme.brightness, Brightness.light);
  });

  test('can generate a dark scheme from a seed color', () {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);
    expect(scheme.primary, const Color(0xff9ccaff));
    expect(scheme.onPrimary, const Color(0xff00325a));
    expect(scheme.primaryContainer, const Color(0xff00497f));
    expect(scheme.onPrimaryContainer, const Color(0xffd0e4ff));
    expect(scheme.secondary, const Color(0xffbbc8db));
    expect(scheme.onSecondary, const Color(0xff253140));
    expect(scheme.secondaryContainer, const Color(0xff3c4858));
    expect(scheme.onSecondaryContainer, const Color(0xffd6e3f7));
    expect(scheme.tertiary, const Color(0xffd6bee4));
    expect(scheme.onTertiary, const Color(0xff3b2948));
    expect(scheme.tertiaryContainer, const Color(0xff523f5f));
    expect(scheme.onTertiaryContainer, const Color(0xfff3daff));
    expect(scheme.error, const Color(0xffffb4a9));
    expect(scheme.onError, const Color(0xff680003));
    expect(scheme.errorContainer, const Color(0xff930006));
    expect(scheme.onErrorContainer, const Color(0xffffb4a9));
    expect(scheme.outline, const Color(0xff8d9199));
    expect(scheme.background, const Color(0xff1b1b1b));
    expect(scheme.onBackground, const Color(0xffe2e2e6));
    expect(scheme.surface, const Color(0xff1b1b1b));
    expect(scheme.onSurface, const Color(0xffe2e2e6));
    expect(scheme.surfaceVariant, const Color(0xff42474e));
    expect(scheme.onSurfaceVariant, const Color(0xffc3c7d0));
    expect(scheme.inverseSurface, const Color(0xffe2e2e6));
    expect(scheme.onInverseSurface, const Color(0xff2f3033));
    expect(scheme.inversePrimary, const Color(0xff0061a6));
    expect(scheme.shadow, const Color(0xff000000));
    expect(scheme.surfaceTint, const Color(0xff9ccaff));
    expect(scheme.brightness, Brightness.dark);
  });

  test('can override specific colors in a generated scheme', () {
    final ColorScheme baseScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    const Color primaryOverride = Color(0xffabcdef);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      primary: primaryOverride,
    );
    expect(scheme.primary, primaryOverride);
    // The rest should be the same.
    expect(scheme.onPrimary, baseScheme.onPrimary);
    expect(scheme.primaryContainer, baseScheme.primaryContainer);
    expect(scheme.onPrimaryContainer, baseScheme.onPrimaryContainer);
    expect(scheme.secondary, baseScheme.secondary);
    expect(scheme.onSecondary, baseScheme.onSecondary);
    expect(scheme.secondaryContainer, baseScheme.secondaryContainer);
    expect(scheme.onSecondaryContainer, baseScheme.onSecondaryContainer);
    expect(scheme.tertiary, baseScheme.tertiary);
    expect(scheme.onTertiary, baseScheme.onTertiary);
    expect(scheme.tertiaryContainer, baseScheme.tertiaryContainer);
    expect(scheme.onTertiaryContainer, baseScheme.onTertiaryContainer);
    expect(scheme.error, baseScheme.error);
    expect(scheme.onError, baseScheme.onError);
    expect(scheme.errorContainer, baseScheme.errorContainer);
    expect(scheme.onErrorContainer, baseScheme.onErrorContainer);
    expect(scheme.outline, baseScheme.outline);
    expect(scheme.background, baseScheme.background);
    expect(scheme.onBackground, baseScheme.onBackground);
    expect(scheme.surface, baseScheme.surface);
    expect(scheme.onSurface, baseScheme.onSurface);
    expect(scheme.surfaceVariant, baseScheme.surfaceVariant);
    expect(scheme.onSurfaceVariant, baseScheme.onSurfaceVariant);
    expect(scheme.inverseSurface, baseScheme.inverseSurface);
    expect(scheme.onInverseSurface, baseScheme.onInverseSurface);
    expect(scheme.inversePrimary, baseScheme.inversePrimary);
    expect(scheme.shadow, baseScheme.shadow);
    expect(scheme.surfaceTint, baseScheme.surfaceTint);
    expect(scheme.brightness, baseScheme.brightness);
  });

  testWidgets('generated scheme "on" colors meet a11y contrast guidelines', (WidgetTester tester) async {
    final ColorScheme colors = ColorScheme.fromSeed(seedColor: Colors.teal);

    Widget label(String text, Color textColor, Color background) {
      return Container(
        color: background,
        padding: const EdgeInsets.all(8),
        child: Text(text, style: TextStyle(color: textColor)),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colors),
        home: Scaffold(
          body: Column(
            children: <Widget>[
              label('primary', colors.onPrimary, colors.primary),
              label('secondary', colors.onSecondary, colors.secondary),
              label('tertiary', colors.onTertiary, colors.tertiary),
              label('error', colors.onError, colors.error),
              label('background', colors.onBackground, colors.background),
              label('surface', colors.onSurface, colors.surface),
            ],
          ),
        ),
      ),
    );
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  },
    skip: isBrowser, // https://github.com/flutter/flutter/issues/44115
  );
}
