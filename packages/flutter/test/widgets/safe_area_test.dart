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
          data: MediaQueryData(padding: EdgeInsets.all(20.0)),
          child: SafeArea(
            left: false,
            child: Placeholder(),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(0.0, 20.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 580.0));
    });

    testWidgets('SafeArea - with minimums', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.all(20.0)),
          child: SafeArea(
            top: false,
            minimum: EdgeInsets.fromLTRB(0.0, 10.0, 20.0, 30.0),
            child: Placeholder(),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(20.0, 10.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 570.0));
    });

    testWidgets('SafeArea - nested', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.all(20.0)),
          child: SafeArea(
            top: false,
            child: SafeArea(
              right: false,
              child: Placeholder(),
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(20.0, 20.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 580.0));
    });

    testWidgets('SafeArea - changing', (WidgetTester tester) async {
      const Widget child = SafeArea(
        bottom: false,
        child: SafeArea(
          left: false,
          bottom: false,
          child: Placeholder(),
        ),
      );
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.all(20.0)),
          child: child,
        ),
      );
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(20.0, 20.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 600.0));
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(
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
      return MediaQuery(
        data: MediaQueryData(padding: mediaPadding),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Viewport(
            offset: ViewportOffset.fixed(0.0),
            axisDirection: AxisDirection.down,
            slivers: <Widget>[
              const SliverToBoxAdapter(child: SizedBox(width: 800.0, height: 100.0, child: Text('before'))),
              sliver,
              const SliverToBoxAdapter(child: SizedBox(width: 800.0, height: 100.0, child: Text('after'))),
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
          return Rect.fromPoints(topLeft, bottomRight);
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
            sliver: SliverToBoxAdapter(child: SizedBox(width: 800.0, height: 100.0, child: Text('padded'))),
          ),
        ),
      );
      verify(tester, <Rect>[
        Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        Rect.fromLTWH(0.0, 120.0, 780.0, 100.0),
        Rect.fromLTWH(0.0, 240.0, 800.0, 100.0),
      ]);
    });

    testWidgets('SliverSafeArea - basic', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          const EdgeInsets.all(20.0),
          const SliverSafeArea(
            top: false,
            minimum: EdgeInsets.fromLTRB(0.0, 10.0, 20.0, 30.0),
            sliver: SliverToBoxAdapter(child: SizedBox(width: 800.0, height: 100.0, child: Text('padded'))),
          ),
        ),
      );
      verify(tester, <Rect>[
        Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        Rect.fromLTWH(20.0, 110.0, 760.0, 100.0),
        Rect.fromLTWH(0.0, 240.0, 800.0, 100.0),
      ]);
    });

    testWidgets('SliverSafeArea - nested', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          const EdgeInsets.all(20.0),
          const SliverSafeArea(
            top: false,
            sliver: SliverSafeArea(
              right: false,
              sliver: SliverToBoxAdapter(child: SizedBox(width: 800.0, height: 100.0, child: Text('padded'))),
            ),
          ),
        ),
      );
      verify(tester, <Rect>[
        Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        Rect.fromLTWH(20.0, 120.0, 760.0, 100.0),
        Rect.fromLTWH(0.0, 240.0, 800.0, 100.0),
      ]);
    });

    testWidgets('SliverSafeArea - changing', (WidgetTester tester) async {
      const Widget sliver = SliverSafeArea(
        bottom: false,
        sliver: SliverSafeArea(
          left: false,
          bottom: false,
          sliver: SliverToBoxAdapter(child: SizedBox(width: 800.0, height: 100.0, child: Text('padded'))),
        ),
      );
      await tester.pumpWidget(
        buildWidget(
          const EdgeInsets.all(20.0),
          sliver,
        ),
      );
      verify(tester, <Rect>[
        Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        Rect.fromLTWH(20.0, 120.0, 760.0, 100.0),
        Rect.fromLTWH(0.0, 220.0, 800.0, 100.0),
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
        Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        Rect.fromLTWH(100.0, 130.0, 700.0, 100.0),
        Rect.fromLTWH(0.0, 230.0, 800.0, 100.0),
      ]);
    });
  });
}
