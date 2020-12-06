// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' show Brightness;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('MediaQuery does not have a default', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          tested = true;
          MediaQuery.of(context); // should throw
          return Container();
        },
      ),
    );
    expect(tested, isTrue);
    final dynamic exception = tester.takeException();
    expect(exception, isNotNull);
    expect(exception ,isFlutterError);
    final FlutterError error = exception as FlutterError;
    expect(error.diagnostics.length, 3);
    expect(error.diagnostics.last, isA<DiagnosticsProperty<Element>>());
    expect(
      error.toStringDeep(),
      equalsIgnoringHashCodes(
        'FlutterError\n'
        '   MediaQuery.of() called with a context that does not contain a\n'
        '   MediaQuery.\n'
        '   No MediaQuery ancestor could be found starting from the context\n'
        '   that was passed to MediaQuery.of(). This can happen because you\n'
        '   do not have a WidgetsApp or MaterialApp widget (those widgets\n'
        '   introduce a MediaQuery), or it can happen if the context you use\n'
        '   comes from a widget above those widgets.\n'
        '   The context used was:\n'
        '     Builder\n',
      ),
    );
  });

  testWidgets('MediaQuery defaults to null', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          final MediaQueryData data = MediaQuery.of(context, nullOk: true);
          expect(data, isNull);
          tested = true;
          return Container();
        },
      ),
    );
    expect(tested, isTrue);
  });

  testWidgets('MediaQueryData is sane', (WidgetTester tester) async {
    final MediaQueryData data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    expect(data, hasOneLineDescription);
    expect(data.hashCode, equals(data.copyWith().hashCode));
    expect(data.size, equals(WidgetsBinding.instance.window.physicalSize / WidgetsBinding.instance.window.devicePixelRatio));
    expect(data.accessibleNavigation, false);
    expect(data.invertColors, false);
    expect(data.disableAnimations, false);
    expect(data.boldText, false);
    expect(data.highContrast, false);
    expect(data.platformBrightness, Brightness.light);
  });

  testWidgets('MediaQueryData.copyWith defaults to source', (WidgetTester tester) async {
    final MediaQueryData data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    final MediaQueryData copied = data.copyWith();
    expect(copied.size, data.size);
    expect(copied.devicePixelRatio, data.devicePixelRatio);
    expect(copied.textScaleFactor, data.textScaleFactor);
    expect(copied.padding, data.padding);
    expect(copied.viewPadding, data.viewPadding);
    expect(copied.viewInsets, data.viewInsets);
    expect(copied.systemGestureInsets, data.systemGestureInsets);
    expect(copied.alwaysUse24HourFormat, data.alwaysUse24HourFormat);
    expect(copied.accessibleNavigation, data.accessibleNavigation);
    expect(copied.invertColors, data.invertColors);
    expect(copied.disableAnimations, data.disableAnimations);
    expect(copied.boldText, data.boldText);
    expect(copied.highContrast, data.highContrast);
    expect(copied.platformBrightness, data.platformBrightness);
  });

  testWidgets('MediaQuery.copyWith copies specified values', (WidgetTester tester) async {
    // Random and unique double values are used to ensure that the correct
    // values are copied over exactly
    const Size customSize = Size(3.14, 2.72);
    const double customDevicePixelRatio = 1.41;
    const double customTextScaleFactor = 1.62;
    const EdgeInsets customPadding = EdgeInsets.all(9.10938);
    const EdgeInsets customViewPadding = EdgeInsets.all(11.24031);
    const EdgeInsets customViewInsets = EdgeInsets.all(1.67262);
    const EdgeInsets customSystemGestureInsets = EdgeInsets.all(1.5556);

    final MediaQueryData data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    final MediaQueryData copied = data.copyWith(
      size: customSize,
      devicePixelRatio: customDevicePixelRatio,
      textScaleFactor: customTextScaleFactor,
      padding: customPadding,
      viewPadding: customViewPadding,
      viewInsets: customViewInsets,
      systemGestureInsets: customSystemGestureInsets,
      alwaysUse24HourFormat: true,
      accessibleNavigation: true,
      invertColors: true,
      disableAnimations: true,
      boldText: true,
      highContrast: true,
      platformBrightness: Brightness.dark,
    );
    expect(copied.size, customSize);
    expect(copied.devicePixelRatio, customDevicePixelRatio);
    expect(copied.textScaleFactor, customTextScaleFactor);
    expect(copied.padding, customPadding);
    expect(copied.viewPadding, customViewPadding);
    expect(copied.viewInsets, customViewInsets);
    expect(copied.systemGestureInsets, customSystemGestureInsets);
    expect(copied.alwaysUse24HourFormat, true);
    expect(copied.accessibleNavigation, true);
    expect(copied.invertColors, true);
    expect(copied.disableAnimations, true);
    expect(copied.boldText, true);
    expect(copied.highContrast, true);
    expect(copied.platformBrightness, Brightness.dark);
  });

  testWidgets('MediaQuery.removePadding removes specified padding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);

    MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              removeTop: true,
              removeRight: true,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, EdgeInsets.zero);
    expect(unpadded.viewPadding, viewInsets);
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
  });

  testWidgets('MediaQuery.removePadding only removes specified padding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);

    MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, padding.copyWith(top: 0));
    expect(unpadded.viewPadding, viewPadding.copyWith(top: viewInsets.top));
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
  });

  testWidgets('MediaQuery.removeViewInsets removes specified viewInsets', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);

    MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removeViewInsets(
              context: context,
              removeLeft: true,
              removeTop: true,
              removeRight: true,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, padding);
    expect(unpadded.viewPadding, padding);
    expect(unpadded.viewInsets, EdgeInsets.zero);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
  });

  testWidgets('MediaQuery.removeViewInsets removes only specified viewInsets', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);

    MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, padding);
    expect(unpadded.viewPadding, viewPadding.copyWith(bottom: 8));
    expect(unpadded.viewInsets, viewInsets.copyWith(bottom: 0));
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
  });

  testWidgets('MediaQuery.removeViewPadding removes specified viewPadding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);

    MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removeViewPadding(
              context: context,
              removeLeft: true,
              removeTop: true,
              removeRight: true,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, EdgeInsets.zero);
    expect(unpadded.viewPadding, EdgeInsets.zero);
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
  });

  testWidgets('MediaQuery.removeViewPadding removes only specified viewPadding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);

    MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removeViewPadding(
              context: context,
              removeLeft: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, padding.copyWith(left: 0));
    expect(unpadded.viewPadding, viewPadding.copyWith(left: 0));
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
  });

  testWidgets('MediaQuery.textScaleFactorOf', (WidgetTester tester) async {
    double outsideTextScaleFactor;
    double insideTextScaleFactor;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideTextScaleFactor = MediaQuery.textScaleFactorOf(context);
          return MediaQuery(
            data: const MediaQueryData(
              textScaleFactor: 4.0,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideTextScaleFactor = MediaQuery.textScaleFactorOf(context);
                return Container();
              },
            ),
          );
        },
      ),
    );

    expect(outsideTextScaleFactor, 1.0);
    expect(insideTextScaleFactor, 4.0);
  });

  testWidgets('MediaQuery.platformBrightnessOf', (WidgetTester tester) async {
    Brightness outsideBrightness;
    Brightness insideBrightness;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideBrightness = MediaQuery.platformBrightnessOf(context);
          return MediaQuery(
            data: const MediaQueryData(
              platformBrightness: Brightness.dark,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideBrightness = MediaQuery.platformBrightnessOf(context);
                return Container();
              },
            ),
          );
        },
      ),
    );

    expect(outsideBrightness, Brightness.light);
    expect(insideBrightness, Brightness.dark);
  });

  testWidgets('MediaQuery.highContrastOf', (WidgetTester tester) async {
    bool outsideHighContrast;
    bool insideHighContrast;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideHighContrast = MediaQuery.highContrastOf(context);
          return MediaQuery(
            data: const MediaQueryData(
              highContrast: true,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideHighContrast = MediaQuery.highContrastOf(context);
                return Container();
              },
            ),
          );
        },
      ),
    );

    expect(outsideHighContrast, false);
    expect(insideHighContrast, true);
  });

  testWidgets('MediaQuery.boldTextOverride', (WidgetTester tester) async {
    bool outsideBoldTextOverride;
    bool insideBoldTextOverride;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideBoldTextOverride = MediaQuery.boldTextOverride(context);
          return MediaQuery(
            data: const MediaQueryData(
              boldText: true,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideBoldTextOverride = MediaQuery.boldTextOverride(context);
                return Container();
              },
            ),
          );
        },
      ),
    );

    expect(outsideBoldTextOverride, false);
    expect(insideBoldTextOverride, true);
  });

  test('size parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(size: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('size != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('devicePixelRatio parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(devicePixelRatio: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('devicePixelRatio != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('textScaleFactor parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(textScaleFactor: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('textScaleFactor != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('platformBrightness parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(platformBrightness: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('platformBrightness != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('padding parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(padding: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('padding != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('viewInsets parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(viewInsets: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('viewInsets != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('systemGestureInsets parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(systemGestureInsets: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('systemGestureInsets != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('viewPadding parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(viewPadding: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('viewPadding != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('alwaysUse24HourFormat parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(alwaysUse24HourFormat: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('alwaysUse24HourFormat != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('accessibleNavigation parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(accessibleNavigation: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('accessibleNavigation != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('invertColors parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(invertColors: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('invertColors != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('highContrast parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(highContrast: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('highContrast != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('disableAnimations parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(disableAnimations: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('disableAnimations != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

  test('boldText parameter in MediaQueryData cannot be null', () {
    try {
      MediaQueryData(boldText: null);
    } on AssertionError catch (error) {
      expect(error.toString(), contains('boldText != null'));
      expect(error.toString(), contains('is not true'));
      return;
    }
    fail('The assert was never called when it should have been');
  });

}
