// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

Future<Null> test(WidgetTester tester, double offset, { double anchor: 0.0 }) {
  return tester.pumpWidget(
    new Directionality(
      textDirection: TextDirection.ltr,
      child: new Viewport(
        anchor: anchor / 600.0,
        offset: new ViewportOffset.fixed(offset),
        slivers: <Widget>[
          const SliverToBoxAdapter(child: const SizedBox(height: 400.0)),
          const SliverToBoxAdapter(child: const SizedBox(height: 400.0)),
          const SliverToBoxAdapter(child: const SizedBox(height: 400.0)),
          const SliverToBoxAdapter(child: const SizedBox(height: 400.0)),
          const SliverToBoxAdapter(child: const SizedBox(height: 400.0)),
        ],
      ),
    ),
  );
}

void verify(WidgetTester tester, List<Offset> idealPositions, List<bool> idealVisibles) {
  final List<Offset> actualPositions = tester.renderObjectList<RenderBox>(find.byType(SizedBox)).map<Offset>(
    (RenderBox target) => target.localToGlobal(const Offset(0.0, 0.0))
  ).toList();
  final List<bool> actualVisibles = tester.renderObjectList<RenderSliverToBoxAdapter>(find.byType(SliverToBoxAdapter)).map<bool>(
    (RenderSliverToBoxAdapter target) => target.geometry.visible
  ).toList();
  expect(actualPositions, equals(idealPositions));
  expect(actualVisibles, equals(idealVisibles));
}

void main() {
  testWidgets('Viewport basic test', (WidgetTester tester) async {
    await test(tester, 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 0.0),
      const Offset(0.0, 400.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 600.0),
    ], <bool>[true, true, false, false, false]);

    await test(tester, 200.0);
    verify(tester, <Offset>[
      const Offset(0.0, -200.0),
      const Offset(0.0, 200.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 600.0),
    ], <bool>[true, true, false, false, false]);

    await test(tester, 600.0);
    verify(tester, <Offset>[
      const Offset(0.0, -600.0),
      const Offset(0.0, -200.0),
      const Offset(0.0, 200.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 600.0),
    ], <bool>[false, true, true, false, false]);

    await test(tester, 900.0);
    verify(tester, <Offset>[
      const Offset(0.0, -900.0),
      const Offset(0.0, -500.0),
      const Offset(0.0, -100.0),
      const Offset(0.0, 300.0),
      const Offset(0.0, 600.0),
    ], <bool>[false, false, true, true, false]);
  });

  testWidgets('Viewport anchor test', (WidgetTester tester) async {
    await test(tester, 0.0, anchor: 100.0);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 100.0),
      const Offset(0.0, 500.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 600.0),
    ], <bool>[true, true, false, false, false]);

    await test(tester, 200.0, anchor: 100.0);
    verify(tester, <Offset>[
      const Offset(0.0, -100.0),
      const Offset(0.0, 300.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 600.0),
    ], <bool>[true, true, false, false, false]);

    await test(tester, 600.0, anchor: 100.0);
    verify(tester, <Offset>[
      const Offset(0.0, -500.0),
      const Offset(0.0, -100.0),
      const Offset(0.0, 300.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 600.0),
    ], <bool>[false, true, true, false, false]);

    await test(tester, 900.0, anchor: 100.0);
    verify(tester, <Offset>[
      const Offset(0.0, -800.0),
      const Offset(0.0, -400.0),
      const Offset(0.0, 0.0),
      const Offset(0.0, 400.0),
      const Offset(0.0, 600.0),
    ], <bool>[false, false, true, true, false]);
  });
}
