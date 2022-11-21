// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PlatformQuery.of finds a PlatformQueryData when there is one', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      PlatformQuery(
        data: const PlatformQueryData(),
        child: Builder(
          builder: (BuildContext context) {
            final PlatformQueryData data = PlatformQuery.of(context);
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

  testWidgets('PlatformQuery.maybeOf defaults to null', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          final PlatformQueryData? data = PlatformQuery.maybeOf(context);
          expect(data, isNull);
          tested = true;
          return Container();
        },
      ),
    );
    expect(tested, isTrue);
  });

  testWidgets('PlatformQuery.maybeOf finds a PlatformQueryData when there is one', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      PlatformQuery(
        data: const PlatformQueryData(),
        child: Builder(
          builder: (BuildContext context) {
            final PlatformQueryData? data = PlatformQuery.maybeOf(context);
            expect(data, isNotNull);
            tested = true;
            return Container();
          },
        ),
      ),
    );
    expect(tested, isTrue);
  });

  testWidgets('PlatformQueryData.fromPlatformDispatcher is sane', (WidgetTester tester) async {
    final PlatformQueryData data = PlatformQueryData.fromPlatformDispatcher(WidgetsBinding.instance.platformDispatcher);
    expect(data, hasOneLineDescription);
    expect(data.hashCode, equals(data.copyWith().hashCode));
    expect(data.accessibleNavigation, false);
    expect(data.invertColors, false);
    expect(data.disableAnimations, false);
    expect(data.boldText, false);
    expect(data.highContrast, false);
    expect(data.platformBrightness, Brightness.light);
  });

  testWidgets('PlatformQueryData.copyWith defaults to source', (WidgetTester tester) async {
    final PlatformQueryData data = PlatformQueryData.fromPlatformDispatcher(WidgetsBinding.instance.platformDispatcher);
    final PlatformQueryData copied = data.copyWith();
    expect(copied.textScaleFactor, data.textScaleFactor);
    expect(copied.alwaysUse24HourFormat, data.alwaysUse24HourFormat);
    expect(copied.accessibleNavigation, data.accessibleNavigation);
    expect(copied.invertColors, data.invertColors);
    expect(copied.disableAnimations, data.disableAnimations);
    expect(copied.boldText, data.boldText);
    expect(copied.highContrast, data.highContrast);
    expect(copied.platformBrightness, data.platformBrightness);
  });

  testWidgets('PlatformQuery.copyWith copies specified values', (WidgetTester tester) async {
    // Random and unique double values are used to ensure that the correct
    // values are copied over exactly
    const double customTextScaleFactor = 1.62;

    final PlatformQueryData data = PlatformQueryData.fromPlatformDispatcher(WidgetsBinding.instance.platformDispatcher);
    final PlatformQueryData copied = data.copyWith(
      textScaleFactor: customTextScaleFactor,
      alwaysUse24HourFormat: true,
      accessibleNavigation: true,
      invertColors: true,
      disableAnimations: true,
      boldText: true,
      highContrast: true,
      platformBrightness: Brightness.dark,
      navigationMode: NavigationMode.directional,
    );
    expect(copied.textScaleFactor, customTextScaleFactor);
    expect(copied.alwaysUse24HourFormat, true);
    expect(copied.accessibleNavigation, true);
    expect(copied.invertColors, true);
    expect(copied.disableAnimations, true);
    expect(copied.boldText, true);
    expect(copied.highContrast, true);
    expect(copied.platformBrightness, Brightness.dark);
    expect(copied.navigationMode, NavigationMode.directional);
  });

  testWidgets('PlatformQuery.textScaleFactorOf', (WidgetTester tester) async {
    late double outsideTextScaleFactor;
    late double insideTextScaleFactor;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideTextScaleFactor = PlatformQuery.textScaleFactorOf(context);
          return PlatformQuery(
            data: const PlatformQueryData(
              textScaleFactor: 4.0,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideTextScaleFactor = PlatformQuery.textScaleFactorOf(context);
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

  testWidgets('PlatformQuery.platformBrightnessOf', (WidgetTester tester) async {
    late Brightness outsideBrightness;
    late Brightness insideBrightness;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideBrightness = PlatformQuery.platformBrightnessOf(context);
          return PlatformQuery(
            data: const PlatformQueryData(
              platformBrightness: Brightness.dark,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideBrightness = PlatformQuery.platformBrightnessOf(context);
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

  testWidgets('PlatformQuery.highContrastOf', (WidgetTester tester) async {
    late bool outsideHighContrast;
    late bool insideHighContrast;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideHighContrast = PlatformQuery.highContrastOf(context);
          return PlatformQuery(
            data: const PlatformQueryData(
              highContrast: true,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideHighContrast = PlatformQuery.highContrastOf(context);
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

  testWidgets('PlatformQuery.boldTextOverride', (WidgetTester tester) async {
    late bool outsideBoldTextOverride;
    late bool insideBoldTextOverride;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideBoldTextOverride = PlatformQuery.boldTextOf(context);
          return PlatformQuery(
            data: const PlatformQueryData(
              boldText: true,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideBoldTextOverride = PlatformQuery.boldTextOf(context);
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

  testWidgets('PlatformQuery.fromPlatformDispatcher creates a PlatformQuery', (WidgetTester tester) async {
    PlatformQueryData? platformQueryAsParentOutside;
    PlatformQueryData? platformQueryAsParentInside;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          platformQueryAsParentOutside = PlatformQuery.maybeOf(context);
          return PlatformQuery.fromPlatformDispatcher(
            child: Builder(
              builder: (BuildContext context) {
                platformQueryAsParentInside = PlatformQuery.maybeOf(context);
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );

    expect(platformQueryAsParentOutside, isNull);
    expect(platformQueryAsParentInside, isNotNull);
  });

  testWidgets('PlatformQueryData.fromWindow is created using window values', (WidgetTester tester) async {
    final PlatformQueryData windowData = PlatformQueryData.fromPlatformDispatcher(WidgetsBinding.instance.platformDispatcher);
    late PlatformQueryData fromWindowData;

    await tester.pumpWidget(
      PlatformQuery.fromPlatformDispatcher(
        child: Builder(
          builder: (BuildContext context) {
            fromWindowData = PlatformQuery.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(windowData, equals(fromWindowData));
  });

  testWidgets('PlatformQuery can be partially depended-on', (WidgetTester tester) async {
    PlatformQueryData data = const PlatformQueryData(
        boldText: true,
        textScaleFactor: 1.1
    );

    int boldTextCount = 0;
    int textScaleFactorBuildCount = 0;

    final Widget showSize = Builder(
        builder: (BuildContext context) {
          boldTextCount++;
          return Text('boldText: ${PlatformQuery.boldTextOf(context)}');
        }
    );

    final Widget showTextScaleFactor = Builder(
        builder: (BuildContext context) {
          textScaleFactorBuildCount++;
          return Text('textScaleFactor: ${PlatformQuery.textScaleFactorOf(context).toStringAsFixed(1)}');
        }
    );

    final Widget page = StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return PlatformQuery(
          data: data,
          child: Center(
            child: Column(
              children: <Widget>[
                showSize,
                showTextScaleFactor,
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      data = data.copyWith(boldText: !data.boldText);
                    });
                  },
                  child: const Text('Toggle boldText'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      data = data.copyWith(textScaleFactor: data.textScaleFactor + 0.1);
                    });
                  },
                  child: const Text('Increase textScaleFactor by 0.1'),
                ),
              ],
            ),
          ),
        );
      },
    );

    await tester.pumpWidget(MaterialApp(home: page));
    expect(find.text('boldText: true'), findsOneWidget);
    expect(find.text('textScaleFactor: 1.1'), findsOneWidget);
    expect(boldTextCount, 1);
    expect(textScaleFactorBuildCount, 1);

    await tester.tap(find.text('Toggle boldText'));
    await tester.pumpAndSettle();
    expect(find.text('boldText: false'), findsOneWidget);
    expect(find.text('textScaleFactor: 1.1'), findsOneWidget);
    expect(boldTextCount, 2);
    expect(textScaleFactorBuildCount, 1);

    await tester.tap(find.text('Increase textScaleFactor by 0.1'));
    await tester.pumpAndSettle();
    expect(find.text('boldText: false'), findsOneWidget);
    expect(find.text('textScaleFactor: 1.2'), findsOneWidget);
    expect(boldTextCount, 2);
    expect(textScaleFactorBuildCount, 2);
  });
}
