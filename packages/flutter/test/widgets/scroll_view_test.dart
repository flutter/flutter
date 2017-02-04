// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'states.dart';

void main() {
  testWidgets('ListView control test', (WidgetTester tester) async {
    List<String> log = <String>[];

    await tester.pumpWidget(new ListView(
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

    expect(find.text('Nevada'), findsNothing);

    await tester.scroll(find.text('Alabama'), const Offset(0.0, -4000.0));
    await tester.pump();

    expect(find.text('Alabama'), findsNothing);
    expect(tester.getCenter(find.text('Massachusetts')), equals(const Point(400.0, 100.0)));

    await tester.tap(find.text('Massachusetts'));
    expect(log, equals(<String>['Massachusetts']));
    log.clear();
  });

  testWidgets('ListView restart ballistic activity out of range', (WidgetTester tester) async {
    Widget buildListView(int n) {
      return new ListView(
        children: kStates.take(n).map<Widget>((String state) {
          return new Container(
            height: 200.0,
            decoration: const BoxDecoration(
              backgroundColor: const Color(0xFF0000FF),
            ),
            child: new Text(state),
          );
        }).toList()
      );
    }

    await tester.pumpWidget(buildListView(30));
    await tester.fling(find.byType(ListView), const Offset(0.0, -4000.0), 4000.0);
    await tester.pumpWidget(buildListView(15));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 100));

    Viewport2 viewport = tester.widget(find.byType(Viewport2));
    expect(viewport.offset.pixels, equals(2400.0));
  });

  testWidgets('CustomScrollView control test', (WidgetTester tester) async {
    List<String> log = <String>[];

    await tester.pumpWidget(new CustomScrollView(
      slivers: <Widget>[
        new SliverList(
          delegate: new SliverChildListDelegate(
            kStates.map<Widget>((String state) {
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
            }).toList(),
          ),
        ),
      ],
    ));

    await tester.tap(find.text('Alabama'));
    expect(log, equals(<String>['Alabama']));
    log.clear();

    expect(find.text('Nevada'), findsNothing);

    await tester.scroll(find.text('Alabama'), const Offset(0.0, -4000.0));
    await tester.pump();

    expect(find.text('Alabama'), findsNothing);
    expect(tester.getCenter(find.text('Massachusetts')), equals(const Point(400.0, 100.0)));

    await tester.tap(find.text('Massachusetts'));
    expect(log, equals(<String>['Massachusetts']));
    log.clear();
  });
}
