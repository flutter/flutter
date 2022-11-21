// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType, GestureSettings, ViewConfiguration;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ViewQuery does not have a default', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          tested = true;
          ViewQuery.of(context); // should throw
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
        '   No ViewQuery widget ancestor found.\n'
        '   Builder widgets require a ViewQuery widget ancestor.\n'
        '   The specific widget that could not find a ViewQuery ancestor was:\n'
        '     Builder\n'
        '   The ownership chain for the affected widget is: "Builder ←\n'
        '     [root]"\n'
        '   No ViewQuery ancestor could be found starting from the context\n'
        '   that was passed to ViewQuery.of(). This can happen because you\n'
        '   have not added a WidgetsApp, CupertinoApp, or MaterialApp widget\n'
        '   (those widgets introduce a ViewQuery), or it can happen if the\n'
        '   context you use comes from a widget above those widgets.\n'
      ),
    );
  });

  testWidgets('ViewQuery.of finds a ViewQueryData when there is one', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      ViewQuery(
        data: const ViewQueryData(),
        child: Builder(
          builder: (BuildContext context) {
            final ViewQueryData data = ViewQuery.of(context);
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

  testWidgets('ViewQuery.maybeOf defaults to null', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          final ViewQueryData? data = ViewQuery.maybeOf(context);
          expect(data, isNull);
          tested = true;
          return Container();
        },
      ),
    );
    expect(tested, isTrue);
  });

  testWidgets('ViewQuery.maybeOf finds a ViewQueryData when there is one', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      ViewQuery(
        data: const ViewQueryData(),
        child: Builder(
          builder: (BuildContext context) {
            final ViewQueryData? data = ViewQuery.maybeOf(context);
            expect(data, isNotNull);
            tested = true;
            return Container();
          },
        ),
      ),
    );
    expect(tested, isTrue);
  });

  testWidgets('ViewQueryData.fromView is sane', (WidgetTester tester) async {
    final ViewQueryData data = ViewQueryData.fromView(WidgetsBinding.instance.window);
    expect(data, hasOneLineDescription);
    expect(data.hashCode, equals(data.copyWith().hashCode));
    expect(data.size, equals(WidgetsBinding.instance.window.physicalSize / WidgetsBinding.instance.window.devicePixelRatio));
    expect(data.gestureSettings.touchSlop, null);
    expect(data.displayFeatures, isEmpty);
  });

  testWidgets('ViewQueryData.copyWith defaults to source', (WidgetTester tester) async {
    final ViewQueryData data = ViewQueryData.fromView(WidgetsBinding.instance.window);
    final ViewQueryData copied = data.copyWith();
    expect(copied.size, data.size);
    expect(copied.devicePixelRatio, data.devicePixelRatio);
    expect(copied.padding, data.padding);
    expect(copied.viewPadding, data.viewPadding);
    expect(copied.viewInsets, data.viewInsets);
    expect(copied.systemGestureInsets, data.systemGestureInsets);
    expect(copied.gestureSettings, data.gestureSettings);
    expect(copied.displayFeatures, data.displayFeatures);
  });

  testWidgets('ViewQuery.copyWith copies specified values', (WidgetTester tester) async {
    // Random and unique double values are used to ensure that the correct
    // values are copied over exactly
    const Size customSize = Size(3.14, 2.72);
    const double customDevicePixelRatio = 1.41;
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

    final ViewQueryData data = ViewQueryData.fromView(WidgetsBinding.instance.window);
    final ViewQueryData copied = data.copyWith(
      size: customSize,
      devicePixelRatio: customDevicePixelRatio,
      padding: customPadding,
      viewPadding: customViewPadding,
      viewInsets: customViewInsets,
      systemGestureInsets: customSystemGestureInsets,
      gestureSettings: gestureSettings,
      displayFeatures: customDisplayFeatures,
    );
    expect(copied.size, customSize);
    expect(copied.devicePixelRatio, customDevicePixelRatio);
    expect(copied.padding, customPadding);
    expect(copied.viewPadding, customViewPadding);
    expect(copied.viewInsets, customViewInsets);
    expect(copied.systemGestureInsets, customSystemGestureInsets);
    expect(copied.gestureSettings, gestureSettings);
    expect(copied.displayFeatures, customDisplayFeatures);
  });

  testWidgets('ViewQuery.removePadding removes specified padding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
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

    late ViewQueryData unpadded;
    await tester.pumpWidget(
      ViewQuery(
        data: const ViewQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return ViewQuery.removePadding(
              context: context,
              removeLeft: true,
              removeTop: true,
              removeRight: true,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = ViewQuery.of(context);
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
    expect(unpadded.padding, EdgeInsets.zero);
    expect(unpadded.viewPadding, viewInsets);
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('ViewQuery.removePadding only removes specified padding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
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

    late ViewQueryData unpadded;
    await tester.pumpWidget(
      ViewQuery(
        data: const ViewQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return ViewQuery.removePadding(
              removeTop: true,
              context: context,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = ViewQuery.of(context);
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
    expect(unpadded.padding, padding.copyWith(top: 0));
    expect(unpadded.viewPadding, viewPadding.copyWith(top: viewInsets.top));
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('ViewQuery.removeViewInsets removes specified viewInsets', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
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

    late ViewQueryData unpadded;
    await tester.pumpWidget(
      ViewQuery(
        data: const ViewQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return ViewQuery.removeViewInsets(
              context: context,
              removeLeft: true,
              removeTop: true,
              removeRight: true,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = ViewQuery.of(context);
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
    expect(unpadded.padding, padding);
    expect(unpadded.viewPadding, padding);
    expect(unpadded.viewInsets, EdgeInsets.zero);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('ViewQuery.removeViewInsets removes only specified viewInsets', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
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

    late ViewQueryData unpadded;
    await tester.pumpWidget(
      ViewQuery(
        data: const ViewQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return ViewQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = ViewQuery.of(context);
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
    expect(unpadded.padding, padding);
    expect(unpadded.viewPadding, viewPadding.copyWith(bottom: 8));
    expect(unpadded.viewInsets, viewInsets.copyWith(bottom: 0));
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('ViewQuery.removeViewPadding removes specified viewPadding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
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

    late ViewQueryData unpadded;
    await tester.pumpWidget(
      ViewQuery(
        data: const ViewQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return ViewQuery.removeViewPadding(
              context: context,
              removeLeft: true,
              removeTop: true,
              removeRight: true,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = ViewQuery.of(context);
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
    expect(unpadded.padding, EdgeInsets.zero);
    expect(unpadded.viewPadding, EdgeInsets.zero);
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('ViewQuery.removeViewPadding removes only specified viewPadding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
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

    late ViewQueryData unpadded;
    await tester.pumpWidget(
      ViewQuery(
        data: const ViewQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return ViewQuery.removeViewPadding(
              context: context,
              removeLeft: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = ViewQuery.of(context);
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
    expect(unpadded.padding, padding.copyWith(left: 0));
    expect(unpadded.viewPadding, viewPadding.copyWith(left: 0));
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('ViewQuery.fromView creates a ViewQuery', (WidgetTester tester) async {
    ViewQueryData? viewQueryAsParentOutside;
    ViewQueryData? viewQueryAsParentInside;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          viewQueryAsParentOutside = ViewQuery.maybeOf(context);
          return ViewQuery.fromView(
            view: WidgetsBinding.instance.platformDispatcher.views.first,
            child: Builder(
              builder: (BuildContext context) {
                viewQueryAsParentInside = ViewQuery.maybeOf(context);
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );

    expect(viewQueryAsParentOutside, isNull);
    expect(viewQueryAsParentInside, isNotNull);
  });

  testWidgets('ViewQueryData.fromView is created using window values', (WidgetTester tester) async {
    final ViewQueryData windowData = ViewQueryData.fromView(WidgetsBinding.instance.window);
    late ViewQueryData fromWindowData;

    await tester.pumpWidget(
      ViewQuery.fromView(
        view: WidgetsBinding.instance.window,
        child: Builder(
          builder: (BuildContext context) {
            fromWindowData = ViewQuery.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(windowData, equals(fromWindowData));
  });

  testWidgets('ViewQuery.removeDisplayFeatures removes specified display features and padding', (WidgetTester tester) async {
    const Size size = Size(82.0, 40.0);
    const double devicePixelRatio = 2.0;
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

    late ViewQueryData subScreenViewQuery;
    await tester.pumpWidget(
      ViewQuery(
        data: const ViewQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return ViewQuery(
              data: ViewQuery.of(context).removeDisplayFeatures(subScreen),
              child: Builder(
                builder: (BuildContext context) {
                  subScreenViewQuery = ViewQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(subScreenViewQuery.size, size);
    expect(subScreenViewQuery.devicePixelRatio, devicePixelRatio);
    expect(subScreenViewQuery.padding, EdgeInsets.zero);
    expect(subScreenViewQuery.viewPadding, EdgeInsets.zero);
    expect(subScreenViewQuery.viewInsets, EdgeInsets.zero);
    expect(subScreenViewQuery.displayFeatures, isEmpty);
  });

  testWidgets('ViewQuery.removePadding only removes specified display features and padding', (WidgetTester tester) async {
    const Size size = Size(82.0, 40.0);
    const double devicePixelRatio = 2.0;
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

    late ViewQueryData subScreenViewQuery;
    await tester.pumpWidget(
      ViewQuery(
        data: const ViewQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return ViewQuery(
              data: ViewQuery.of(context).removeDisplayFeatures(subScreen),
              child: Builder(
                builder: (BuildContext context) {
                  subScreenViewQuery = ViewQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(subScreenViewQuery.size, size);
    expect(subScreenViewQuery.devicePixelRatio, devicePixelRatio);
    expect(
      subScreenViewQuery.padding,
      const EdgeInsets.only(top: 1.0, right: 2.0, bottom: 4.0),
    );
    expect(
      subScreenViewQuery.viewPadding,
      const EdgeInsets.only(top: 6.0, left: 4.0, right: 8.0, bottom: 12.0),
    );
    expect(
      subScreenViewQuery.viewInsets,
      const EdgeInsets.only(top: 5.0, right: 6.0, bottom: 8.0),
    );
    expect(subScreenViewQuery.displayFeatures, <DisplayFeature>[cutoutDisplayFeature]);
  });

  testWidgets('ViewQueryData.gestureSettings is set from window.viewConfiguration', (WidgetTester tester) async {
    tester.binding.window.viewConfigurationTestValue = const ViewConfiguration(
      gestureSettings: GestureSettings(physicalDoubleTapSlop: 100, physicalTouchSlop: 100),
    );

    expect(ViewQueryData.fromView(tester.binding.window).gestureSettings.touchSlop, closeTo(33.33, 0.1)); // Repeating, of course
    tester.binding.window.viewConfigurationTestValue = null;
  });

  testWidgets('ViewQuery can be partially depended-on', (WidgetTester tester) async {
    ViewQueryData data = const ViewQueryData(
      size: Size(800, 600),
      devicePixelRatio: 1.23,
    );

    int sizeBuildCount = 0;
    int devicePixelRatioBuildCount = 0;

    final Widget showSize = Builder(
        builder: (BuildContext context) {
          sizeBuildCount++;
          return Text('size: ${ViewQuery.sizeOf(context)}');
        }
    );

    final Widget showTextScaleFactor = Builder(
        builder: (BuildContext context) {
          devicePixelRatioBuildCount++;
          return Text('devicePixelRatio: ${ViewQuery.devicePixelRatioOf(context)}');
        }
    );

    final Widget page = StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return ViewQuery(
            data: data,
            child: Center(
                child: Column(
                    children: <Widget>[
                      showSize,
                      showTextScaleFactor,
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              data = data.copyWith(size: Size(data.size.width + 100, data.size.height));
                            });
                          },
                          child: const Text('Increase width by 100')
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              data = data.copyWith(devicePixelRatio: data.devicePixelRatio + 0.1);
                            });
                          },
                          child: const Text('Increase devicePixelRatio by 0.1')
                      )
                    ]
                )
            )
        );
      },
    );

    await tester.pumpWidget(MaterialApp(home: page));
    expect(find.text('size: Size(800.0, 600.0)'), findsOneWidget);
    expect(find.text('devicePixelRatio: 1.23'), findsOneWidget);
    expect(sizeBuildCount, 1);
    expect(devicePixelRatioBuildCount, 1);

    await tester.tap(find.text('Increase width by 100'));
    await tester.pumpAndSettle();
    expect(find.text('size: Size(900.0, 600.0)'), findsOneWidget);
    expect(find.text('devicePixelRatio: 1.23'), findsOneWidget);
    expect(sizeBuildCount, 2);
    expect(devicePixelRatioBuildCount, 1);

    await tester.tap(find.text('Increase devicePixelRatio by 0.1'));
    await tester.pumpAndSettle();
    expect(find.text('size: Size(900.0, 600.0)'), findsOneWidget);
    expect(find.text('devicePixelRatio: 1.33'), findsOneWidget);
    expect(sizeBuildCount, 2);
    expect(devicePixelRatioBuildCount, 2);
  });
}
