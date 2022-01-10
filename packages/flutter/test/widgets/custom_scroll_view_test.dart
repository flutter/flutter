// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/96024
  testWidgets('CustomScrollView.center update test', (WidgetTester tester) async {
    final Key centerKey = UniqueKey();
    late StateSetter setState;
    bool hasKey = false;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: CustomScrollView(
        center: centerKey,
        slivers: <Widget>[
          const SliverToBoxAdapter(key: Key('a'), child: SizedBox(height: 100.0)),
          StatefulBuilder(
            key: centerKey,
            builder: (BuildContext context, StateSetter setter) {
              setState = setter;
              if (hasKey) {
                return const SliverToBoxAdapter(
                  key: Key('b'),
                  child: SizedBox(height: 100.0),
                );
              } else {
                return const SliverToBoxAdapter(
                  child: SizedBox(height: 100.0),
                );
              }
            },
          ),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    // Change the center key will trigger the old RenderObject remove and a new
    // RenderObject insert.
    setState(() {
      hasKey = true;
    });

    await tester.pumpAndSettle();

    // Pass without throw.
  });

  testWidgets('CustomScrollView.center', (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(key: Key('a'), child: SizedBox(height: 100.0)),
          SliverToBoxAdapter(key: Key('b'), child: SizedBox(height: 100.0)),
        ],
        center: Key('a'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.descendant(of: find.byKey(const Key('a')), matching: find.byType(SizedBox))),
      const Rect.fromLTRB(0.0, 0.0, 800.0, 100.0),
    );
    expect(
      tester.getRect(find.descendant(of: find.byKey(const Key('b')), matching: find.byType(SizedBox))),
      const Rect.fromLTRB(0.0, 100.0, 800.0, 200.0),
    );
  });

  testWidgets('CustomScrollView.center', (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(key: Key('a'), child: SizedBox(height: 100.0)),
          SliverToBoxAdapter(key: Key('b'), child: SizedBox(height: 100.0)),
        ],
        center: Key('b'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(
        find.descendant(
          of: find.byKey(const Key('a'), skipOffstage: false),
          matching: find.byType(SizedBox, skipOffstage: false),
        ),
      ),
      const Rect.fromLTRB(0.0, -100.0, 800.0, 0.0),
    );
    expect(
      tester.getRect(
        find.descendant(
          of: find.byKey(const Key('b')),
          matching: find.byType(SizedBox),
        ),
      ),
      const Rect.fromLTRB(0.0, 0.0, 800.0, 100.0),
    );
  });

  testWidgets('CustomScrollView.anchor', (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(key: Key('a'), child: SizedBox(height: 100.0)),
          SliverToBoxAdapter(key: Key('b'), child: SizedBox(height: 100.0)),
        ],
        center: Key('b'),
        anchor: 1.0,
      ),
    ));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(
        find.descendant(
          of: find.byKey(const Key('a')),
          matching: find.byType(SizedBox),
        ),
      ),
      const Rect.fromLTRB(0.0, 500.0, 800.0, 600.0),
    );
    expect(
      tester.getRect(
        find.descendant(
          of: find.byKey(const Key('b'), skipOffstage: false),
          matching: find.byType(SizedBox, skipOffstage: false),
        ),
      ),
      const Rect.fromLTRB(0.0, 600.0, 800.0, 700.0),
    );
  });
}
