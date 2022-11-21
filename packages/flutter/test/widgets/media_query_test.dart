// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Brightness, DisplayFeature, DisplayFeatureState, DisplayFeatureType, GestureSettings, ViewConfiguration;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(error.diagnostics.length, 5);
    expect(error.diagnostics.last, isA<ErrorHint>());
    expect(
      error.toStringDeep(),
      equalsIgnoringHashCodes(
        'FlutterError\n'
        '   No ViewQuery/PlatformQuery widget ancestors found.\n'
        '   Builder widgets require a ViewQuery widget ancestor and a\n'
        '   PlatformQuery widget ancestor.\n'
        '   The specific widget that could not find ViewQuery/PlatformQuery\n'
        '   widget ancestors was:\n'
        '     Builder\n'
        '   The ownership chain for the affected widget is: "Builder ←\n'
        '     [root]"\n'
        '   No ViewQuery/PlatformQuery widget ancestors could be found\n'
        '   starting from the context that was passed to MediaQuery.of().\n'
        '   This can happen because you have not added a WidgetsApp,\n'
        '   CupertinoApp, or MaterialApp widget (those widgets introduce\n'
        '   ViewQuery/PlatformQuery widget ancestors), or it can happen if\n'
        '   the context you use comes from a widget above those widgets.\n'
      ),
    );
  });

  testWidgets('MediaQuery.of finds a MediaQueryData when there is one', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (BuildContext context) {
            final MediaQueryData data = MediaQuery.of(context);
            expect(data, isNotNull);
            tested = true;
            return Container();
          },
        ),
      ),
    );
    final dynamic exception = tester.takeException();
    expect(exception, isNull);
    expect(tested, isTrue);
  });

  testWidgets('MediaQuery.maybeOf defaults to null', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          final MediaQueryData? data = MediaQuery.maybeOf(context);
          expect(data, isNull);
          tested = true;
          return Container();
        },
      ),
    );
    expect(tested, isTrue);
  });

  testWidgets('MediaQuery.maybeOf finds a MediaQueryData when there is one', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (BuildContext context) {
            final MediaQueryData? data = MediaQuery.maybeOf(context);
            expect(data, isNotNull);
            tested = true;
            return Container();
          },
        ),
      ),
    );
    expect(tested, isTrue);
  });

  testWidgets('MediaQueryData.fromWindow is sane', (WidgetTester tester) async {
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
    expect(data.gestureSettings.touchSlop, null);
    expect(data.displayFeatures, isEmpty);
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
    expect(copied.gestureSettings, data.gestureSettings);
    expect(copied.displayFeatures, data.displayFeatures);
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
    const DeviceGestureSettings gestureSettings = DeviceGestureSettings(touchSlop: 8.0);
    const List<DisplayFeature> customDisplayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

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
      navigationMode: NavigationMode.directional,
      gestureSettings: gestureSettings,
      displayFeatures: customDisplayFeatures,
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
    expect(copied.navigationMode, NavigationMode.directional);
    expect(copied.gestureSettings, gestureSettings);
    expect(copied.displayFeatures, customDisplayFeatures);
  });

  testWidgets('MediaQuery.removePadding removes specified padding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
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
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
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
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.removePadding only removes specified padding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
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
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
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
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.removeViewInsets removes specified viewInsets', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
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
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
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
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.removeViewInsets removes only specified viewInsets', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
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
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
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
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.removeViewPadding removes specified viewPadding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
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
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
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
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.removeViewPadding removes only specified viewPadding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
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
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
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
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.textScaleFactorOf', (WidgetTester tester) async {
    late double outsideTextScaleFactor;
    late double insideTextScaleFactor;

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
    late Brightness outsideBrightness;
    late Brightness insideBrightness;

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
    late bool outsideHighContrast;
    late bool insideHighContrast;

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
    late bool outsideBoldTextOverride;
    late bool insideBoldTextOverride;

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

  testWidgets('MediaQuery.fromWindow creates a MediaQuery', (WidgetTester tester) async {
    MediaQueryData? mediaQueryAsParentOutside;
    MediaQueryData? mediaQueryAsParentInside;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          mediaQueryAsParentOutside = MediaQuery.maybeOf(context);
          return MediaQuery.fromWindow(
            child: Builder(
              builder: (BuildContext context) {
                mediaQueryAsParentInside = MediaQuery.maybeOf(context);
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );

    expect(mediaQueryAsParentOutside, isNull);
    expect(mediaQueryAsParentInside, isNotNull);
  });

  testWidgets('MediaQueryData.fromWindow is created using window values', (WidgetTester tester) async {
    final MediaQueryData windowData = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    late MediaQueryData fromWindowData;

    await tester.pumpWidget(
      MediaQuery.fromWindow(
        child: Builder(
          builder: (BuildContext context) {
            fromWindowData = MediaQuery.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(windowData, equals(fromWindowData));
  });

  testWidgets('MediaQuery.removeDisplayFeatures removes specified display features and padding', (WidgetTester tester) async {
    const Size size = Size(82.0, 40.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.fromLTRB(40, 0, 42, 40),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      ),
      DisplayFeature(
        bounds: Rect.fromLTRB(70, 10, 74, 14),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    // A section of the screen that intersects no display feature or padding area
    const Rect subScreen = Rect.fromLTRB(20, 10, 40, 20);

    late MediaQueryData subScreenMediaQuery;
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
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(context).removeDisplayFeatures(subScreen),
              child: Builder(
                builder: (BuildContext context) {
                  subScreenMediaQuery = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(subScreenMediaQuery.size, size);
    expect(subScreenMediaQuery.devicePixelRatio, devicePixelRatio);
    expect(subScreenMediaQuery.textScaleFactor, textScaleFactor);
    expect(subScreenMediaQuery.padding, EdgeInsets.zero);
    expect(subScreenMediaQuery.viewPadding, EdgeInsets.zero);
    expect(subScreenMediaQuery.viewInsets, EdgeInsets.zero);
    expect(subScreenMediaQuery.alwaysUse24HourFormat, true);
    expect(subScreenMediaQuery.accessibleNavigation, true);
    expect(subScreenMediaQuery.invertColors, true);
    expect(subScreenMediaQuery.disableAnimations, true);
    expect(subScreenMediaQuery.boldText, true);
    expect(subScreenMediaQuery.highContrast, true);
    expect(subScreenMediaQuery.displayFeatures, isEmpty);
  });

  testWidgets('MediaQuery.removePadding only removes specified display features and padding', (WidgetTester tester) async {
    const Size size = Size(82.0, 40.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 46.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const DisplayFeature cutoutDisplayFeature = DisplayFeature(
      bounds: Rect.fromLTRB(70, 10, 74, 14),
      type: DisplayFeatureType.cutout,
      state: DisplayFeatureState.unknown,
    );
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.fromLTRB(40, 0, 42, 40),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      ),
      cutoutDisplayFeature,
    ];

    // A section of the screen that does contain display features and padding
    const Rect subScreen = Rect.fromLTRB(42, 0, 82, 40);

    late MediaQueryData subScreenMediaQuery;
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
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(context).removeDisplayFeatures(subScreen),
              child: Builder(
                builder: (BuildContext context) {
                  subScreenMediaQuery = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(subScreenMediaQuery.size, size);
    expect(subScreenMediaQuery.devicePixelRatio, devicePixelRatio);
    expect(subScreenMediaQuery.textScaleFactor, textScaleFactor);
    expect(
      subScreenMediaQuery.padding,
      const EdgeInsets.only(top: 1.0, right: 2.0, bottom: 4.0),
    );
    expect(
      subScreenMediaQuery.viewPadding,
      const EdgeInsets.only(top: 6.0, left: 4.0, right: 8.0, bottom: 12.0),
    );
    expect(
      subScreenMediaQuery.viewInsets,
      const EdgeInsets.only(top: 5.0, right: 6.0, bottom: 8.0),
    );
    expect(subScreenMediaQuery.alwaysUse24HourFormat, true);
    expect(subScreenMediaQuery.accessibleNavigation, true);
    expect(subScreenMediaQuery.invertColors, true);
    expect(subScreenMediaQuery.disableAnimations, true);
    expect(subScreenMediaQuery.boldText, true);
    expect(subScreenMediaQuery.highContrast, true);
    expect(subScreenMediaQuery.displayFeatures, <DisplayFeature>[cutoutDisplayFeature]);
  });

  testWidgets('MediaQueryData.gestureSettings is set from window.viewConfiguration', (WidgetTester tester) async {
    tester.binding.window.viewConfigurationTestValue = const ViewConfiguration(
      gestureSettings: GestureSettings(physicalDoubleTapSlop: 100, physicalTouchSlop: 100),
    );

    expect(MediaQueryData.fromWindow(tester.binding.window).gestureSettings.touchSlop, closeTo(33.33, 0.1)); // Repeating, of course
    tester.binding.window.viewConfigurationTestValue = null;
  });

  testWidgets('MediaQuery backwards compatibility test', (WidgetTester tester) async {
    late MediaQueryData mediaQuery;
    late PlatformQueryData platformQuery;
    late ViewQueryData viewQuery;

    const MediaQueryData originalMediaQueryData = MediaQueryData(
      size: Size(3.14, 2.72),
      devicePixelRatio: 1.41,
      textScaleFactor: 1.62,
      platformBrightness: Brightness.dark,
      padding: EdgeInsets.all(9.10938),
      viewInsets: EdgeInsets.all(1.67262),
      systemGestureInsets: EdgeInsets.all(1.5556),
      viewPadding: EdgeInsets.all(11.24031),
      alwaysUse24HourFormat: true,
      accessibleNavigation: true,
      invertColors: true,
      highContrast: true,
      disableAnimations: true,
      boldText: true,
      navigationMode: NavigationMode.directional,
      gestureSettings: DeviceGestureSettings(touchSlop: 8.0),
      displayFeatures: <DisplayFeature>[
        DisplayFeature(
          bounds: Rect.zero,
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
      ],
    );

    await tester.pumpWidget(
      MediaQuery(
        data: originalMediaQueryData,
        child: Builder(
          builder: (BuildContext context) {
            mediaQuery = MediaQuery.of(context);
            platformQuery = PlatformQuery.of(context);
            viewQuery = ViewQuery.of(context);
            return Container();
          },
        )
      ),
    );

    expect(mediaQuery, equals(originalMediaQueryData));
    expect(viewQuery.size, equals(originalMediaQueryData.size));
    expect(viewQuery.devicePixelRatio, equals(originalMediaQueryData.devicePixelRatio));
    expect(platformQuery.textScaleFactor, equals(originalMediaQueryData.textScaleFactor));
    expect(platformQuery.platformBrightness, equals(originalMediaQueryData.platformBrightness));
    expect(viewQuery.padding, equals(originalMediaQueryData.padding));
    expect(viewQuery.viewInsets, equals(originalMediaQueryData.viewInsets));
    expect(viewQuery.systemGestureInsets, equals(originalMediaQueryData.systemGestureInsets));
    expect(viewQuery.viewPadding, equals(originalMediaQueryData.viewPadding));
    expect(platformQuery.alwaysUse24HourFormat, equals(originalMediaQueryData.alwaysUse24HourFormat));
    expect(platformQuery.accessibleNavigation, equals(originalMediaQueryData.accessibleNavigation));
    expect(platformQuery.invertColors, equals(originalMediaQueryData.invertColors));
    expect(platformQuery.highContrast, equals(originalMediaQueryData.highContrast));
    expect(platformQuery.disableAnimations, equals(originalMediaQueryData.disableAnimations));
    expect(platformQuery.boldText, equals(originalMediaQueryData.boldText));
    expect(platformQuery.navigationMode, equals(originalMediaQueryData.navigationMode));
    expect(viewQuery.gestureSettings, equals(originalMediaQueryData.gestureSettings));
    expect(viewQuery.displayFeatures, equals(originalMediaQueryData.displayFeatures));
  });

  testWidgets('PlatformQuery/ViewQuery backwards compatibility test', (WidgetTester tester) async {
    late MediaQueryData mediaQuery;
    late PlatformQueryData platformQuery;
    late ViewQueryData viewQuery;

    const PlatformQueryData originalPlatformQueryData = PlatformQueryData(
      textScaleFactor: 1.62,
      platformBrightness: Brightness.dark,
      alwaysUse24HourFormat: true,
      accessibleNavigation: true,
      invertColors: true,
      highContrast: true,
      disableAnimations: true,
      boldText: true,
      navigationMode: NavigationMode.directional,
    );

    const ViewQueryData originalViewQueryData = ViewQueryData(
      size: Size(3.14, 2.72),
      devicePixelRatio: 1.41,
      padding: EdgeInsets.all(9.10938),
      viewInsets: EdgeInsets.all(1.67262),
      systemGestureInsets: EdgeInsets.all(1.5556),
      viewPadding: EdgeInsets.all(11.24031),
      gestureSettings: DeviceGestureSettings(touchSlop: 8.0),
      displayFeatures: <DisplayFeature>[
        DisplayFeature(
          bounds: Rect.zero,
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
      ],
    );

    await tester.pumpWidget(
      PlatformQuery(
          data: originalPlatformQueryData,
          child: ViewQuery(
            data: originalViewQueryData,
            child: Builder(
              builder: (BuildContext context) {
                mediaQuery = MediaQuery.of(context);
                platformQuery = PlatformQuery.of(context);
                viewQuery = ViewQuery.of(context);
                return Container();
              },
            ),
          )
      ),
    );

    expect(platformQuery, equals(originalPlatformQueryData));
    expect(viewQuery, equals(originalViewQueryData));
    expect(mediaQuery.size, equals(viewQuery.size));
    expect(mediaQuery.devicePixelRatio, equals(viewQuery.devicePixelRatio));
    expect(mediaQuery.textScaleFactor, equals(platformQuery.textScaleFactor));
    expect(mediaQuery.platformBrightness, equals(platformQuery.platformBrightness));
    expect(mediaQuery.padding, equals(viewQuery.padding));
    expect(mediaQuery.viewInsets, equals(viewQuery.viewInsets));
    expect(mediaQuery.systemGestureInsets, equals(viewQuery.systemGestureInsets));
    expect(mediaQuery.viewPadding, equals(viewQuery.viewPadding));
    expect(mediaQuery.alwaysUse24HourFormat, equals(platformQuery.alwaysUse24HourFormat));
    expect(mediaQuery.accessibleNavigation, equals(platformQuery.accessibleNavigation));
    expect(mediaQuery.invertColors, equals(platformQuery.invertColors));
    expect(mediaQuery.highContrast, equals(platformQuery.highContrast));
    expect(mediaQuery.disableAnimations, equals(platformQuery.disableAnimations));
    expect(mediaQuery.boldText, equals(platformQuery.boldText));
    expect(mediaQuery.navigationMode, equals(platformQuery.navigationMode));
    expect(mediaQuery.gestureSettings, equals(viewQuery.gestureSettings));
    expect(mediaQuery.displayFeatures, equals(viewQuery.displayFeatures));
  });
}
