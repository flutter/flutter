// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'states.dart';

const Duration _frameDuration = const Duration(milliseconds: 100);

void main() {
  testWidgets('PageView control test', (WidgetTester tester) async {
    List<String> log = <String>[];

    await tester.pumpWidget(new PageView(
      children: kStates.map<Widget>((String state) {
        return new GestureDetector(
          onTap: () {
            log.add(state);
          },
          child: new Container(
            height: 200.0,
            decoration: const BoxDecoration(
              backgroundColor: const Color(0xFF0000FF),
            ),
            child: new Text(state),
          ),
        );
      }).toList()
    ));

    await tester.tap(find.text('Alabama'));
    expect(log, equals(<String>['Alabama']));
    log.clear();

    expect(find.text('Alaska'), findsNothing);

    await tester.scroll(find.byType(PageView), const Offset(-10.0, 0.0));
    await tester.pump();

    expect(find.text('Alabama'), findsOneWidget);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);

    await tester.pumpUntilNoTransientCallbacks(_frameDuration);

    expect(find.text('Alabama'), findsOneWidget);
    expect(find.text('Alaska'), findsNothing);

    await tester.scroll(find.byType(PageView), const Offset(-401.0, 0.0));
    await tester.pumpUntilNoTransientCallbacks(_frameDuration);

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);

    await tester.tap(find.text('Alaska'));
    expect(log, equals(<String>['Alaska']));
    log.clear();

    await tester.fling(find.byType(PageView), const Offset(-200.0, 0.0), 1000.0);
    await tester.pumpUntilNoTransientCallbacks(_frameDuration);

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsNothing);
    expect(find.text('Arizona'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(200.0, 0.0), 1000.0);
    await tester.pumpUntilNoTransientCallbacks(_frameDuration);

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);
  });

  testWidgets('PageView does not squish when overscrolled', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      theme: new ThemeData(platform: TargetPlatform.iOS),
      home: new PageView(
        children: new List<Widget>.generate(10, (int i) {
          return new Container(
            key: new ValueKey<int>(i),
            decoration: const BoxDecoration(
              backgroundColor: const Color(0xFF0000FF),
            ),
          );
        }),
      ),
    ));

    Size sizeOf(int i) => tester.getSize(find.byKey(new ValueKey<int>(i)));
    double leftOf(int i) => tester.getTopLeft(find.byKey(new ValueKey<int>(i))).x;

    expect(leftOf(0), equals(0.0));
    expect(sizeOf(0), equals(const Size(800.0, 600.0)));

    await tester.scroll(find.byType(PageView), const Offset(100.0, 0.0));
    await tester.pump();

    expect(leftOf(0), equals(100.0));
    expect(sizeOf(0), equals(const Size(800.0, 600.0)));

    await tester.scroll(find.byType(PageView), const Offset(-200.0, 0.0));
    await tester.pump();

    expect(leftOf(0), equals(-100.0));
    expect(sizeOf(0), equals(const Size(800.0, 600.0)));
  });
}
