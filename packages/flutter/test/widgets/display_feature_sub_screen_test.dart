// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DisplayFeatureSubScreen', () {
    testWidgets('without Directionality or anchor', (WidgetTester tester) async {
      const childKey = Key('childKey');
      final MediaQueryData mediaQuery = MediaQueryData.fromView(tester.view).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(390, 0, 410, 600),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.unknown,
          ),
        ],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: mediaQuery,
          child: const DisplayFeatureSubScreen(child: SizedBox.expand(key: childKey)),
        ),
      );

      // With no Directionality or anchorpoint, the widget throws
      final message = tester.takeException().toString();
      expect(message, contains('Directionality'));
    });

    testWidgets('with anchorPoint', (WidgetTester tester) async {
      const childKey = Key('childKey');
      final MediaQueryData mediaQuery = MediaQueryData.fromView(tester.view).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(390, 0, 410, 600),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.unknown,
          ),
        ],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: mediaQuery,
          child: const DisplayFeatureSubScreen(
            anchorPoint: Offset(600, 300),
            child: SizedBox.expand(key: childKey),
          ),
        ),
      );

      // anchorPoint is in the middle of the right screen
      final RenderBox renderBox = tester.renderObject(find.byKey(childKey));
      expect(renderBox.size.width, equals(390.0));
      expect(renderBox.size.height, equals(600.0));
      expect(renderBox.localToGlobal(Offset.zero), equals(const Offset(410, 0)));
    });

    testWidgets('with infinity anchorpoint', (WidgetTester tester) async {
      const childKey = Key('childKey');
      final MediaQueryData mediaQuery = MediaQueryData.fromView(tester.view).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(390, 0, 410, 600),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.unknown,
          ),
        ],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: mediaQuery,
          child: const DisplayFeatureSubScreen(
            anchorPoint: Offset.infinite,
            child: SizedBox.expand(key: childKey),
          ),
        ),
      );

      // anchorPoint is infinite, so the bottom-most & right-most screen is chosen
      final RenderBox renderBox = tester.renderObject(find.byKey(childKey));
      expect(renderBox.size.width, equals(390.0));
      expect(renderBox.size.height, equals(600.0));
      expect(renderBox.localToGlobal(Offset.zero), equals(const Offset(410, 0)));
    });

    testWidgets('with horizontal hinge and anchorPoint', (WidgetTester tester) async {
      const childKey = Key('childKey');
      final MediaQueryData mediaQuery = MediaQueryData.fromView(tester.view).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 290, 800, 310),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.unknown,
          ),
        ],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: mediaQuery,
          child: const DisplayFeatureSubScreen(
            anchorPoint: Offset(1000, 1000),
            child: SizedBox.expand(key: childKey),
          ),
        ),
      );

      final RenderBox renderBox = tester.renderObject(find.byKey(childKey));
      expect(renderBox.size.width, equals(800.0));
      expect(renderBox.size.height, equals(290.0));
      expect(renderBox.localToGlobal(Offset.zero), equals(const Offset(0, 310)));
    });

    testWidgets('with multiple display features and anchorPoint', (WidgetTester tester) async {
      const childKey = Key('childKey');
      final MediaQueryData mediaQuery = MediaQueryData.fromView(tester.view).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 290, 800, 310),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.unknown,
          ),
          const DisplayFeature(
            bounds: Rect.fromLTRB(390, 0, 410, 600),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.unknown,
          ),
        ],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: mediaQuery,
          child: const DisplayFeatureSubScreen(
            anchorPoint: Offset(1000, 1000),
            child: SizedBox.expand(key: childKey),
          ),
        ),
      );

      final RenderBox renderBox = tester.renderObject(find.byKey(childKey));
      expect(renderBox.size.width, equals(390.0));
      expect(renderBox.size.height, equals(290.0));
      expect(renderBox.localToGlobal(Offset.zero), equals(const Offset(410, 310)));
    });

    testWidgets('with non-splitting display features and anchorPoint', (WidgetTester tester) async {
      const childKey = Key('childKey');
      final MediaQueryData mediaQuery = MediaQueryData.fromView(tester.view).copyWith(
        displayFeatures: <DisplayFeature>[
          // Top notch
          const DisplayFeature(
            bounds: Rect.fromLTRB(100, 0, 700, 100),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          ),
          // Bottom notch
          const DisplayFeature(
            bounds: Rect.fromLTRB(100, 500, 700, 600),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          ),
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 300, 800, 300),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
        ],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: mediaQuery,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: DisplayFeatureSubScreen(child: SizedBox.expand(key: childKey)),
          ),
        ),
      );

      // The display features provided are not wide enough to produce sub-screens
      final RenderBox renderBox = tester.renderObject(find.byKey(childKey));
      expect(renderBox.size.width, equals(800.0));
      expect(renderBox.size.height, equals(600.0));
      expect(renderBox.localToGlobal(Offset.zero), equals(Offset.zero));
    });

    testWidgets('child MediaQuery is relative to the sub-screen', (WidgetTester tester) async {
      // This is a regression test for https://github.com/flutter/flutter/issues/192667
      const notch = DisplayFeature(
        bounds: Rect.fromLTRB(500, 0, 600, 50),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      );
      final MediaQueryData mediaQuery = MediaQueryData.fromView(tester.view).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(390, 0, 410, 600),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.unknown,
          ),
          notch,
        ],
      );

      late MediaQueryData childMediaQuery;
      await tester.pumpWidget(
        MediaQuery(
          data: mediaQuery,
          child: DisplayFeatureSubScreen(
            anchorPoint: const Offset(800, 0),
            child: Builder(
              builder: (BuildContext context) {
                childMediaQuery = MediaQuery.of(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(childMediaQuery.size, const Size(390, 600));
      expect(childMediaQuery.displayFeatures, const <DisplayFeature>[
        DisplayFeature(
          bounds: Rect.fromLTRB(90, 0, 190, 50),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
      ]);
    });

    testWidgets('child MediaQuery is unchanged without splitting display features', (
      WidgetTester tester,
    ) async {
      final mediaQuery = MediaQueryData.fromView(tester.view);

      late MediaQueryData childMediaQuery;
      await tester.pumpWidget(
        MediaQuery(
          data: mediaQuery,
          child: DisplayFeatureSubScreen(
            anchorPoint: Offset.zero,
            child: Builder(
              builder: (BuildContext context) {
                childMediaQuery = MediaQuery.of(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(childMediaQuery, same(mediaQuery));
    });

    testWidgets('with size 0 display feature in half-opened posture and anchorPoint', (
      WidgetTester tester,
    ) async {
      const childKey = Key('childKey');
      final MediaQueryData mediaQuery = MediaQueryData.fromView(tester.view).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 300, 800, 300),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: mediaQuery,
          child: const DisplayFeatureSubScreen(
            anchorPoint: Offset(1000, 1000),
            child: SizedBox.expand(key: childKey),
          ),
        ),
      );

      final RenderBox renderBox = tester.renderObject(find.byKey(childKey));
      expect(renderBox.size.width, equals(800.0));
      expect(renderBox.size.height, equals(300.0));
      expect(renderBox.localToGlobal(Offset.zero), equals(const Offset(0, 300)));
    });
  });

  testWidgets('DisplayFeatureSubScreen does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.shrink(child: DisplayFeatureSubScreen(child: Text('X'))),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DisplayFeatureSubScreen)), Size.zero);
  });
}
