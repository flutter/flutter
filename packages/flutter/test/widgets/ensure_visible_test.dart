// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Finder findKey(int i) => find.byKey(ValueKey<int>(i));

Widget buildSingleChildScrollView(Axis scrollDirection, { bool reverse = false }) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(
        width: 600.0,
        height: 400.0,
        child: SingleChildScrollView(
          scrollDirection: scrollDirection,
          reverse: reverse,
          child: ListBody(
            mainAxis: scrollDirection,
            children: <Widget>[
              Container(key: const ValueKey<int>(0), width: 200.0, height: 200.0),
              Container(key: const ValueKey<int>(1), width: 200.0, height: 200.0),
              Container(key: const ValueKey<int>(2), width: 200.0, height: 200.0),
              Container(key: const ValueKey<int>(3), width: 200.0, height: 200.0),
              Container(key: const ValueKey<int>(4), width: 200.0, height: 200.0),
              Container(key: const ValueKey<int>(5), width: 200.0, height: 200.0),
              Container(key: const ValueKey<int>(6), width: 200.0, height: 200.0),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget buildListView(Axis scrollDirection, { bool reverse = false, bool shrinkWrap = false }) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(
        width: 600.0,
        height: 400.0,
        child: ListView(
          scrollDirection: scrollDirection,
          reverse: reverse,
          addSemanticIndexes: false,
          shrinkWrap: shrinkWrap,
          children: <Widget>[
            Container(key: const ValueKey<int>(0), width: 200.0, height: 200.0),
            Container(key: const ValueKey<int>(1), width: 200.0, height: 200.0),
            Container(key: const ValueKey<int>(2), width: 200.0, height: 200.0),
            Container(key: const ValueKey<int>(3), width: 200.0, height: 200.0),
            Container(key: const ValueKey<int>(4), width: 200.0, height: 200.0),
            Container(key: const ValueKey<int>(5), width: 200.0, height: 200.0),
            Container(key: const ValueKey<int>(6), width: 200.0, height: 200.0),
          ],
        ),
      ),
    ),
  );
}

void main() {

  group('SingleChildScrollView', () {
    testWidgets('SingleChildScrollView ensureVisible Axis.vertical', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));

      await tester.pumpWidget(buildSingleChildScrollView(Axis.vertical));

      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getTopLeft(findKey(3)).dy, equals(100.0));

      Scrollable.ensureVisible(findContext(6));
      await tester.pump();
      expect(tester.getTopLeft(findKey(6)).dy, equals(300.0));

      Scrollable.ensureVisible(findContext(4), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(4)).dy, equals(500.0));

      Scrollable.ensureVisible(findContext(0), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(0)).dy, equals(100.0));

      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getTopLeft(findKey(3)).dy, equals(100.0));
    });

    testWidgets('SingleChildScrollView ensureVisible Axis.horizontal', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));

      await tester.pumpWidget(buildSingleChildScrollView(Axis.horizontal));

      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getTopLeft(findKey(3)).dx, equals(100.0));

      Scrollable.ensureVisible(findContext(6));
      await tester.pump();
      expect(tester.getTopLeft(findKey(6)).dx, equals(500.0));

      Scrollable.ensureVisible(findContext(4), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(4)).dx, equals(700.0));

      Scrollable.ensureVisible(findContext(0), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(0)).dx, equals(100.0));

      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getTopLeft(findKey(3)).dx, equals(100.0));
    });

    testWidgets('SingleChildScrollView ensureVisible Axis.vertical reverse', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));

      await tester.pumpWidget(buildSingleChildScrollView(Axis.vertical, reverse: true));

      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getBottomRight(findKey(3)).dy, equals(500.0));

      Scrollable.ensureVisible(findContext(0));
      await tester.pump();
      expect(tester.getBottomRight(findKey(0)).dy, equals(300.0));

      Scrollable.ensureVisible(findContext(2), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(2)).dy, equals(100.0));

      Scrollable.ensureVisible(findContext(6), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(6)).dy, equals(500.0));

      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getBottomRight(findKey(3)).dy, equals(500.0));
    });

    testWidgets('SingleChildScrollView ensureVisible Axis.horizontal reverse', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));

      await tester.pumpWidget(buildSingleChildScrollView(Axis.horizontal, reverse: true));

      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getBottomRight(findKey(3)).dx, equals(700.0));

      Scrollable.ensureVisible(findContext(0));
      await tester.pump();
      expect(tester.getBottomRight(findKey(0)).dx, equals(300.0));

      Scrollable.ensureVisible(findContext(2), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(2)).dx, equals(100.0));

      Scrollable.ensureVisible(findContext(6), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(6)).dx, equals(700.0));

      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getBottomRight(findKey(3)).dx, equals(700.0));
    });

    testWidgets('SingleChildScrollView ensureVisible rotated child', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 600.0,
            height: 400.0,
            child: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Container(height: 200.0),
                  Container(height: 200.0),
                  Container(height: 200.0),
                  Container(
                    height: 200.0,
                    child: Center(
                      child: Transform(
                        transform: Matrix4.rotationZ(math.pi),
                        child: Container(
                          key: const ValueKey<int>(0),
                          width: 100.0,
                          height: 100.0,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                  Container(height: 200.0),
                  Container(height: 200.0),
                  Container(height: 200.0),
                ],
              ),
            ),
          ),
        ),
      );

      Scrollable.ensureVisible(findContext(0));
      await tester.pump();
      expect(tester.getBottomRight(findKey(0)).dy, moreOrLessEquals(100.0, epsilon: 0.1));

      Scrollable.ensureVisible(findContext(0), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(0)).dy, moreOrLessEquals(500.0, epsilon: 0.1));
    });
  });

  group('ListView', () {
    testWidgets('ListView ensureVisible Axis.vertical', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      await tester.pumpWidget(buildListView(Axis.vertical));

      await prepare(480.0);
      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getTopLeft(findKey(3)).dy, equals(100.0));

      await prepare(1083.0);
      Scrollable.ensureVisible(findContext(6));
      await tester.pump();
      expect(tester.getTopLeft(findKey(6)).dy, equals(300.0));

      await prepare(735.0);
      Scrollable.ensureVisible(findContext(4), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(4)).dy, equals(500.0));

      await prepare(123.0);
      Scrollable.ensureVisible(findContext(0), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(0)).dy, equals(100.0));

      await prepare(523.0);
      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getTopLeft(findKey(3)).dy, equals(100.0));
    });

    testWidgets('ListView ensureVisible Axis.horizontal', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      await tester.pumpWidget(buildListView(Axis.horizontal));

      await prepare(23.0);
      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getTopLeft(findKey(3)).dx, equals(100.0));

      await prepare(843.0);
      Scrollable.ensureVisible(findContext(6));
      await tester.pump();
      expect(tester.getTopLeft(findKey(6)).dx, equals(500.0));

      await prepare(415.0);
      Scrollable.ensureVisible(findContext(4), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(4)).dx, equals(700.0));

      await prepare(46.0);
      Scrollable.ensureVisible(findContext(0), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(0)).dx, equals(100.0));

      await prepare(211.0);
      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getTopLeft(findKey(3)).dx, equals(100.0));
    });

    testWidgets('ListView ensureVisible Axis.vertical reverse', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      await tester.pumpWidget(buildListView(Axis.vertical, reverse: true));

      await prepare(211.0);
      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getBottomRight(findKey(3)).dy, equals(500.0));

      await prepare(23.0);
      Scrollable.ensureVisible(findContext(0));
      await tester.pump();
      expect(tester.getBottomRight(findKey(0)).dy, equals(500.0));

      await prepare(230.0);
      Scrollable.ensureVisible(findContext(2), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(2)).dy, equals(100.0));

      await prepare(1083.0);
      Scrollable.ensureVisible(findContext(6), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(6)).dy, equals(300.0));

      await prepare(345.0);
      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getBottomRight(findKey(3)).dy, equals(500.0));
    });

    testWidgets('ListView ensureVisible Axis.horizontal reverse', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      await tester.pumpWidget(buildListView(Axis.horizontal, reverse: true));

      await prepare(211.0);
      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getBottomRight(findKey(3)).dx, equals(700.0));

      await prepare(23.0);
      Scrollable.ensureVisible(findContext(0));
      await tester.pump();
      expect(tester.getBottomRight(findKey(0)).dx, equals(700.0));

      await prepare(230.0);
      Scrollable.ensureVisible(findContext(2), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(2)).dx, equals(100.0));

      await prepare(1083.0);
      Scrollable.ensureVisible(findContext(6), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(6)).dx, equals(300.0));

      await prepare(345.0);
      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getBottomRight(findKey(3)).dx, equals(700.0));
    });

    // TODO(abarth): Unskip this test. See https://github.com/flutter/flutter/issues/7919
    testWidgets('ListView ensureVisible negative child', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      double getOffset() {
        return tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      }

      Widget buildSliver(int i) {
        return SliverToBoxAdapter(
          key: ValueKey<int>(i),
          child: const SizedBox(width: 200.0, height: 200.0),
        );
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 600.0,
              height: 400.0,
              child: Scrollable(
                viewportBuilder: (BuildContext context, ViewportOffset offset) {
                  return Viewport(
                    offset: offset,
                    center: const ValueKey<int>(4),
                    slivers: <Widget>[
                      buildSliver(0),
                      buildSliver(1),
                      buildSliver(2),
                      buildSliver(3),
                      buildSliver(4),
                      buildSliver(5),
                      buildSliver(6),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await prepare(-125.0);
      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(getOffset(), equals(-200.0));

      await prepare(-225.0);
      Scrollable.ensureVisible(findContext(2));
      await tester.pump();
      expect(getOffset(), equals(-400.0));
    }, skip: true); // https://github.com/flutter/flutter/issues/7919

    testWidgets('ListView ensureVisible rotated child', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 600.0,
            height: 400.0,
            child: ListView(
              children: <Widget>[
                Container(height: 200.0),
                Container(height: 200.0),
                Container(height: 200.0),
                Container(
                  height: 200.0,
                  child: Center(
                    child: Transform(
                      transform: Matrix4.rotationZ(math.pi),
                      child: Container(
                        key: const ValueKey<int>(0),
                        width: 100.0,
                        height: 100.0,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
                Container(height: 200.0),
                Container(height: 200.0),
                Container(height: 200.0),
              ],
            ),
          ),
        ),
      ));

      await prepare(321.0);
      Scrollable.ensureVisible(findContext(0));
      await tester.pump();
      expect(tester.getBottomRight(findKey(0)).dy, moreOrLessEquals(100.0, epsilon: 0.1));

      Scrollable.ensureVisible(findContext(0), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(0)).dy, moreOrLessEquals(500.0, epsilon: 0.1));
    });
  });

  group('ListView shrinkWrap', () {
    testWidgets('ListView ensureVisible Axis.vertical', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      await tester.pumpWidget(buildListView(Axis.vertical, shrinkWrap: true));

      await prepare(480.0);
      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getTopLeft(findKey(3)).dy, equals(100.0));

      await prepare(1083.0);
      Scrollable.ensureVisible(findContext(6));
      await tester.pump();
      expect(tester.getTopLeft(findKey(6)).dy, equals(300.0));

      await prepare(735.0);
      Scrollable.ensureVisible(findContext(4), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(4)).dy, equals(500.0));

      await prepare(123.0);
      Scrollable.ensureVisible(findContext(0), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(0)).dy, equals(100.0));

      await prepare(523.0);
      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getTopLeft(findKey(3)).dy, equals(100.0));
    });

    testWidgets('ListView ensureVisible Axis.horizontal', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      await tester.pumpWidget(buildListView(Axis.horizontal, shrinkWrap: true));

      await prepare(23.0);
      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getTopLeft(findKey(3)).dx, equals(100.0));

      await prepare(843.0);
      Scrollable.ensureVisible(findContext(6));
      await tester.pump();
      expect(tester.getTopLeft(findKey(6)).dx, equals(500.0));

      await prepare(415.0);
      Scrollable.ensureVisible(findContext(4), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(4)).dx, equals(700.0));

      await prepare(46.0);
      Scrollable.ensureVisible(findContext(0), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(0)).dx, equals(100.0));

      await prepare(211.0);
      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getTopLeft(findKey(3)).dx, equals(100.0));
    });

    testWidgets('ListView ensureVisible Axis.vertical reverse', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      await tester.pumpWidget(buildListView(Axis.vertical, reverse: true, shrinkWrap: true));

      await prepare(211.0);
      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getBottomRight(findKey(3)).dy, equals(500.0));

      await prepare(23.0);
      Scrollable.ensureVisible(findContext(0));
      await tester.pump();
      expect(tester.getBottomRight(findKey(0)).dy, equals(500.0));

      await prepare(230.0);
      Scrollable.ensureVisible(findContext(2), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(2)).dy, equals(100.0));

      await prepare(1083.0);
      Scrollable.ensureVisible(findContext(6), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(6)).dy, equals(300.0));

      await prepare(345.0);
      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getBottomRight(findKey(3)).dy, equals(500.0));
    });

    testWidgets('ListView ensureVisible Axis.horizontal reverse', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      await tester.pumpWidget(buildListView(Axis.horizontal, reverse: true, shrinkWrap: true));

      await prepare(211.0);
      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getBottomRight(findKey(3)).dx, equals(700.0));

      await prepare(23.0);
      Scrollable.ensureVisible(findContext(0));
      await tester.pump();
      expect(tester.getBottomRight(findKey(0)).dx, equals(700.0));

      await prepare(230.0);
      Scrollable.ensureVisible(findContext(2), alignment: 1.0);
      await tester.pump();
      expect(tester.getTopLeft(findKey(2)).dx, equals(100.0));

      await prepare(1083.0);
      Scrollable.ensureVisible(findContext(6), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(6)).dx, equals(300.0));

      await prepare(345.0);
      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getBottomRight(findKey(3)).dx, equals(700.0));
    });
  });

  group('Scrollable with center', () {
    testWidgets('ensureVisible', (WidgetTester tester) async {
      BuildContext findContext(int i) => tester.element(findKey(i));
      Future<void> prepare(double offset) async {
        tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
        await tester.pump();
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 600.0,
              height: 400.0,
              child: Scrollable(
                viewportBuilder: (BuildContext context, ViewportOffset offset) {
                  return Viewport(
                    offset: offset,
                    center: const ValueKey<String>('center'),
                    slivers: <Widget>[
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(-6), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(-5), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(-4), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(-3), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(-2), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(-1), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(0), width: 200.0, height: 200.0), key: const ValueKey<String>('center')),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(1), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(2), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(3), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(4), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(5), width: 200.0, height: 200.0)),
                      SliverToBoxAdapter(child: Container(key: const ValueKey<int>(6), width: 200.0, height: 200.0)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await prepare(480.0);
      Scrollable.ensureVisible(findContext(3));
      await tester.pump();
      expect(tester.getTopLeft(findKey(3)).dy, equals(100.0));

      await prepare(1083.0);
      Scrollable.ensureVisible(findContext(6));
      await tester.pump();
      expect(tester.getTopLeft(findKey(6)).dy, equals(300.0));

      await prepare(735.0);
      Scrollable.ensureVisible(findContext(4), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(4)).dy, equals(500.0));

      await prepare(123.0);
      Scrollable.ensureVisible(findContext(0), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(0)).dy, equals(500.0));

      await prepare(523.0);
      Scrollable.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getTopLeft(findKey(3)).dy, equals(100.0));


      await prepare(-480.0);
      Scrollable.ensureVisible(findContext(-3));
      await tester.pump();
      expect(tester.getTopLeft(findKey(-3)).dy, equals(100.0));

      await prepare(-1083.0);
      Scrollable.ensureVisible(findContext(-6));
      await tester.pump();
      expect(tester.getTopLeft(findKey(-6)).dy, equals(100.0));

      await prepare(-735.0);
      Scrollable.ensureVisible(findContext(-4), alignment: 1.0);
      await tester.pump();
      expect(tester.getBottomRight(findKey(-4)).dy, equals(500.0));

      await prepare(-523.0);
      Scrollable.ensureVisible(findContext(-3), duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1020));
      expect(tester.getTopLeft(findKey(-3)).dy, equals(100.0));
    });
  });
}
