// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

Finder findKey(int i) => find.byKey(new ValueKey<int>(i));

Widget buildSingleChildScrollView(Axis scrollDirection, { bool reverse: false }) {
  return new Center(
    child: new SizedBox(
      width: 600.0,
      height: 400.0,
      child: new SingleChildScrollView(
        scrollDirection: scrollDirection,
        reverse: reverse,
        child: new BlockBody(
          mainAxis: scrollDirection,
          children: <Widget>[
            new Container(key: new ValueKey<int>(0), width: 200.0, height: 200.0),
            new Container(key: new ValueKey<int>(1), width: 200.0, height: 200.0),
            new Container(key: new ValueKey<int>(2), width: 200.0, height: 200.0),
            new Container(key: new ValueKey<int>(3), width: 200.0, height: 200.0),
            new Container(key: new ValueKey<int>(4), width: 200.0, height: 200.0),
            new Container(key: new ValueKey<int>(5), width: 200.0, height: 200.0),
            new Container(key: new ValueKey<int>(6), width: 200.0, height: 200.0),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('SingleChildScollView ensureVisible Axis.vertical', (WidgetTester tester) async {
    BuildContext findContext(int i) => tester.element(findKey(i));

    await tester.pumpWidget(buildSingleChildScrollView(Axis.vertical));

    Scrollable2.ensureVisible(findContext(3));
    await tester.pump();
    expect(tester.getTopLeft(findKey(3)).y, equals(100.0));

    Scrollable2.ensureVisible(findContext(6));
    await tester.pump();
    expect(tester.getTopLeft(findKey(6)).y, equals(300.0));

    Scrollable2.ensureVisible(findContext(4), alignment: 1.0);
    await tester.pump();
    expect(tester.getBottomRight(findKey(4)).y, equals(500.0));

    Scrollable2.ensureVisible(findContext(0), alignment: 1.0);
    await tester.pump();
    expect(tester.getTopLeft(findKey(0)).y, equals(100.0));

    Scrollable2.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1020));
    expect(tester.getTopLeft(findKey(3)).y, equals(100.0));
  });

  testWidgets('SingleChildScollView ensureVisible Axis.horizontal', (WidgetTester tester) async {
    BuildContext findContext(int i) => tester.element(findKey(i));

    await tester.pumpWidget(buildSingleChildScrollView(Axis.horizontal));

    Scrollable2.ensureVisible(findContext(3));
    await tester.pump();
    expect(tester.getTopLeft(findKey(3)).x, equals(100.0));

    Scrollable2.ensureVisible(findContext(6));
    await tester.pump();
    expect(tester.getTopLeft(findKey(6)).x, equals(500.0));

    Scrollable2.ensureVisible(findContext(4), alignment: 1.0);
    await tester.pump();
    expect(tester.getBottomRight(findKey(4)).x, equals(700.0));

    Scrollable2.ensureVisible(findContext(0), alignment: 1.0);
    await tester.pump();
    expect(tester.getTopLeft(findKey(0)).x, equals(100.0));

    Scrollable2.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1020));
    expect(tester.getTopLeft(findKey(3)).x, equals(100.0));
  });

  testWidgets('SingleChildScollView ensureVisible Axis.vertical reverse', (WidgetTester tester) async {
    BuildContext findContext(int i) => tester.element(findKey(i));

    await tester.pumpWidget(buildSingleChildScrollView(Axis.vertical, reverse: true));

    Scrollable2.ensureVisible(findContext(3));
    await tester.pump();
    expect(tester.getBottomRight(findKey(3)).y, equals(500.0));

    Scrollable2.ensureVisible(findContext(0));
    await tester.pump();
    expect(tester.getBottomRight(findKey(0)).y, equals(300.0));

    Scrollable2.ensureVisible(findContext(2), alignment: 1.0);
    await tester.pump();
    expect(tester.getTopLeft(findKey(2)).y, equals(100.0));

    Scrollable2.ensureVisible(findContext(6), alignment: 1.0);
    await tester.pump();
    expect(tester.getBottomRight(findKey(6)).y, equals(500.0));

    Scrollable2.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1020));
    expect(tester.getBottomRight(findKey(3)).y, equals(500.0));
  });

  testWidgets('SingleChildScollView ensureVisible Axis.horizontal', (WidgetTester tester) async {
    BuildContext findContext(int i) => tester.element(findKey(i));

    await tester.pumpWidget(buildSingleChildScrollView(Axis.horizontal, reverse: true));

    Scrollable2.ensureVisible(findContext(3));
    await tester.pump();
    expect(tester.getBottomRight(findKey(3)).x, equals(700.0));

    Scrollable2.ensureVisible(findContext(0));
    await tester.pump();
    expect(tester.getBottomRight(findKey(0)).x, equals(300.0));

    Scrollable2.ensureVisible(findContext(2), alignment: 1.0);
    await tester.pump();
    expect(tester.getTopLeft(findKey(2)).x, equals(100.0));

    Scrollable2.ensureVisible(findContext(6), alignment: 1.0);
    await tester.pump();
    expect(tester.getBottomRight(findKey(6)).x, equals(700.0));

    Scrollable2.ensureVisible(findContext(3), duration: const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1020));
    expect(tester.getBottomRight(findKey(3)).x, equals(700.0));
  });

  testWidgets('SingleChildScollView ensureVisible rotated child', (WidgetTester tester) async {
    BuildContext findContext(int i) => tester.element(findKey(i));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          width: 600.0,
          height: 400.0,
          child: new SingleChildScrollView(
            child: new BlockBody(
              children: <Widget>[
                new Container(height: 200.0),
                new Container(height: 200.0),
                new Container(height: 200.0),
                new Container(
                  height: 200.0,
                  child: new Center(
                    child: new Transform(
                      transform: new Matrix4.rotationZ(math.PI),
                      child: new Container(
                        key: new ValueKey<int>(0),
                        width: 100.0,
                        height: 100.0,
                        decoration: const BoxDecoration(
                          backgroundColor: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ),
                new Container(height: 200.0),
                new Container(height: 200.0),
                new Container(height: 200.0),
              ],
            ),
          ),
        ),
      )
    );

    Scrollable2.ensureVisible(findContext(0));
    await tester.pump();
    expect(tester.getBottomRight(findKey(0)).y, closeTo(100.0, 0.1));

    Scrollable2.ensureVisible(findContext(0), alignment: 1.0);
    await tester.pump();
    expect(tester.getTopLeft(findKey(0)).y, closeTo(500.0, 0.1));
  });

}
