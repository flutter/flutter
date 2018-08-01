// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('Nested ListView with shrinkWrap', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          shrinkWrap: true,
          children: <Widget>[
            new ListView(
              shrinkWrap: true,
              children: const <Widget>[
                const Text('1'),
                const Text('2'),
                const Text('3'),
              ],
            ),
            new ListView(
              shrinkWrap: true,
              children: const <Widget>[
                const Text('4'),
                const Text('5'),
                const Text('6'),
              ],
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('Underflowing ListView should relayout for additional children', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/5950

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[
            const SizedBox(height: 100.0, child: const Text('100')),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[
            const SizedBox(height: 100.0, child: const Text('100')),
            const SizedBox(height: 200.0, child: const Text('200')),
          ],
        ),
      ),
    );

    expect(find.text('200'), findsOneWidget);
  });

  testWidgets('Underflowing ListView contentExtent should track additional children', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[
            const SizedBox(height: 100.0, child: const Text('100')),
          ],
        ),
      ),
    );

    final RenderSliverList list = tester.renderObject(find.byType(SliverList));
    expect(list.geometry.scrollExtent, equals(100.0));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[
            const SizedBox(height: 100.0, child: const Text('100')),
            const SizedBox(height: 200.0, child: const Text('200')),
          ],
        ),
      ),
    );
    expect(list.geometry.scrollExtent, equals(300.0));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[]
        ),
      ),
    );
    expect(list.geometry.scrollExtent, equals(0.0));
  });

  testWidgets('Overflowing ListView should relayout for missing children', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[
            const SizedBox(height: 300.0, child: const Text('300')),
            const SizedBox(height: 400.0, child: const Text('400')),
          ],
        ),
      ),
    );

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[
            const SizedBox(height: 300.0, child: const Text('300')),
          ],
        ),
      ),
    );

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsNothing);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[]
        ),
      ),
    );

    expect(find.text('300'), findsNothing);
    expect(find.text('400'), findsNothing);
  });

  testWidgets('Overflowing ListView should not relayout for additional children', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[
            const SizedBox(height: 300.0, child: const Text('300')),
            const SizedBox(height: 400.0, child: const Text('400')),
          ],
        ),
      ),
    );

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[
            const SizedBox(height: 300.0, child: const Text('300')),
            const SizedBox(height: 400.0, child: const Text('400')),
            const SizedBox(height: 100.0, child: const Text('100')),
          ],
        ),
      ),
    );

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
    expect(find.text('100'), findsNothing);
  });

  testWidgets('Overflowing ListView should become scrollable', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/5920
    // When a ListView's viewport hasn't overflowed, scrolling is disabled.
    // When children are added that cause it to overflow, scrolling should
    // be enabled.

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[
            const SizedBox(height: 100.0, child: const Text('100')),
          ],
        ),
      ),
    );

    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, 0.0);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: const <Widget>[
            const SizedBox(height: 100.0, child: const Text('100')),
            const SizedBox(height: 200.0, child: const Text('200')),
            const SizedBox(height: 400.0, child: const Text('400')),
          ],
        ),
      ),
    );

    expect(scrollable.position.maxScrollExtent, 100.0);
  });

}
