// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  group('SafeArea', () {
    testWidgets('SafeArea - basic', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: const MediaQueryData(padding: const EdgeInsets.all(20.0)),
          child: const SafeArea(
            left: false,
            child: const Placeholder(),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(0.0, 20.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 580.0));
    });

    testWidgets('SafeArea - with minimums', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: const MediaQueryData(padding: const EdgeInsets.all(20.0)),
          child: const SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(0.0, 10.0, 20.0, 30.0),
            child: const Placeholder(),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(20.0, 10.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 570.0));
    });

    testWidgets('SafeArea - nested', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: const MediaQueryData(padding: const EdgeInsets.all(20.0)),
          child: const SafeArea(
            top: false,
            child: const SafeArea(
              right: false,
              child: const Placeholder(),
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(20.0, 20.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 580.0));
    });

    testWidgets('SafeArea - changing', (WidgetTester tester) async {
      const Widget child = const SafeArea(
        bottom: false,
        child: const SafeArea(
          left: false,
          bottom: false,
          child: const Placeholder(),
        ),
      );
      await tester.pumpWidget(
        const MediaQuery(
          data: const MediaQueryData(padding: const EdgeInsets.all(20.0)),
          child: child,
        ),
      );
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(20.0, 20.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 600.0));
      await tester.pumpWidget(
        const MediaQuery(
          data: const MediaQueryData(padding: const EdgeInsets.only(
            left: 100.0,
            top: 30.0,
            right: 0.0,
            bottom: 40.0,
          )),
          child: child,
        ),
      );
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(100.0, 30.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(800.0, 600.0));
    });
  });

  group('SliverSafeArea', () {
    Widget buildWidget(EdgeInsets mediaPadding, Widget sliver) {
      return new MediaQuery(
        data: new MediaQueryData(padding: mediaPadding),
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Viewport(
            offset: new ViewportOffset.fixed(0.0),
            axisDirection: AxisDirection.down,
            slivers: <Widget>[
              const SliverToBoxAdapter(child: const SizedBox(width: 800.0, height: 100.0, child: const Text('before'))),
              sliver,
              const SliverToBoxAdapter(child: const SizedBox(width: 800.0, height: 100.0, child: const Text('after'))),
            ],
          ),
        ),
      );
    }

    void verify(WidgetTester tester, List<Rect> expectedRects) {
      final List<Rect> testAnswers = tester.renderObjectList<RenderBox>(find.byType(SizedBox)).map<Rect>(
        (RenderBox target) {
          final Offset topLeft = target.localToGlobal(Offset.zero);
          final Offset bottomRight = target.localToGlobal(target.size.bottomRight(Offset.zero));
          return new Rect.fromPoints(topLeft, bottomRight);
        }
      ).toList();
      expect(testAnswers, equals(expectedRects));
    }

    testWidgets('SliverSafeArea - basic', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          const EdgeInsets.all(20.0),
          const SliverSafeArea(
            left: false,
            sliver: const SliverToBoxAdapter(child: const SizedBox(width: 800.0, height: 100.0, child: const Text('padded'))),
          ),
        ),
      );
      verify(tester, <Rect>[
        new Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        new Rect.fromLTWH(0.0, 120.0, 780.0, 100.0),
        new Rect.fromLTWH(0.0, 240.0, 800.0, 100.0),
      ]);
    });

    testWidgets('SliverSafeArea - basic', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          const EdgeInsets.all(20.0),
          const SliverSafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(0.0, 10.0, 20.0, 30.0),
            sliver: const SliverToBoxAdapter(child: const SizedBox(width: 800.0, height: 100.0, child: const Text('padded'))),
          ),
        ),
      );
      verify(tester, <Rect>[
        new Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        new Rect.fromLTWH(20.0, 110.0, 760.0, 100.0),
        new Rect.fromLTWH(0.0, 240.0, 800.0, 100.0),
      ]);
    });

    testWidgets('SliverSafeArea - nested', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          const EdgeInsets.all(20.0),
          const SliverSafeArea(
            top: false,
            sliver: const SliverSafeArea(
              right: false,
              sliver: const SliverToBoxAdapter(child: const SizedBox(width: 800.0, height: 100.0, child: const Text('padded'))),
            ),
          ),
        ),
      );
      verify(tester, <Rect>[
        new Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        new Rect.fromLTWH(20.0, 120.0, 760.0, 100.0),
        new Rect.fromLTWH(0.0, 240.0, 800.0, 100.0),
      ]);
    });

    testWidgets('SliverSafeArea - changing', (WidgetTester tester) async {
      const Widget sliver = const SliverSafeArea(
        bottom: false,
        sliver: const SliverSafeArea(
          left: false,
          bottom: false,
          sliver: const SliverToBoxAdapter(child: const SizedBox(width: 800.0, height: 100.0, child: const Text('padded'))),
        ),
      );
      await tester.pumpWidget(
        buildWidget(
          const EdgeInsets.all(20.0),
          sliver,
        ),
      );
      verify(tester, <Rect>[
        new Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        new Rect.fromLTWH(20.0, 120.0, 760.0, 100.0),
        new Rect.fromLTWH(0.0, 220.0, 800.0, 100.0),
      ]);

      await tester.pumpWidget(
        buildWidget(
          const EdgeInsets.only(
            left: 100.0,
            top: 30.0,
            right: 0.0,
            bottom: 40.0,
          ),
          sliver,
        ),
      );
      verify(tester, <Rect>[
        new Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        new Rect.fromLTWH(100.0, 130.0, 700.0, 100.0),
        new Rect.fromLTWH(0.0, 230.0, 800.0, 100.0),
      ]);
    });
  });
}
