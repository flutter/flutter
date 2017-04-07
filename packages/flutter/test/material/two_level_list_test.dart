// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('TwoLevelList default control', (WidgetTester tester) async {
    await tester.pumpWidget(new Center(child: new TwoLevelList()));

    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new TwoLevelList(
            children: <Widget>[
              new TwoLevelSublist(
                title: const Text('Title'),
              )
            ]
          )
        )
      )
    );
  });

  testWidgets('TwoLevelList basics', (WidgetTester tester) async {
    final Key topKey = new UniqueKey();
    final Key sublistKey = new UniqueKey();
    final Key bottomKey = new UniqueKey();

    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) {
        return new Material(
          child: new SingleChildScrollView(
            child: new TwoLevelList(
              children: <Widget>[
                new TwoLevelListItem(title: const Text('Top'), key: topKey),
                new TwoLevelSublist(
                  key: sublistKey,
                  title: const Text('Sublist'),
                  children: <Widget>[
                    new TwoLevelListItem(title: const Text('0')),
                    new TwoLevelListItem(title: const Text('1'))
                  ]
                ),
                new TwoLevelListItem(title: const Text('Bottom'), key: bottomKey)
              ]
            )
          )
        );
      }
    };

    await tester.pumpWidget(new MaterialApp(routes: routes));

    expect(find.text('Top'), findsOneWidget);
    expect(find.text('Sublist'), findsOneWidget);
    expect(find.text('Bottom'), findsOneWidget);

    double getY(Key key) => tester.getTopLeft(find.byKey(key)).y;
    double getHeight(Key key) => tester.getSize(find.byKey(key)).height;

    expect(getY(topKey), lessThan(getY(sublistKey)));
    expect(getY(sublistKey), lessThan(getY(bottomKey)));

    // The sublist has a one pixel border above and below.
    expect(getHeight(topKey), equals(getHeight(sublistKey) - 2.0));
    expect(getHeight(bottomKey), equals(getHeight(sublistKey) - 2.0));

    await tester.tap(find.text('Sublist'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Top'), findsOneWidget);
    expect(find.text('Sublist'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Bottom'), findsOneWidget);

    expect(getY(topKey), lessThan(getY(sublistKey)));
    expect(getY(sublistKey), lessThan(getY(bottomKey)));
    expect(getY(bottomKey) - getY(sublistKey), greaterThan(getHeight(topKey)));
    expect(getY(bottomKey) - getY(sublistKey), greaterThan(getHeight(bottomKey)));
  });

  testWidgets('onOpenChanged callback', (WidgetTester tester) async {
    bool didChangeOpen;

    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) {
        return new Material(
          child: new SingleChildScrollView(
            child: new TwoLevelList(
              children: <Widget>[
                new TwoLevelSublist(
                  title: const Text('Sublist'),
                  onOpenChanged: (bool opened) {
                    didChangeOpen = opened;
                  },
                  children: <Widget>[
                    new TwoLevelListItem(title: const Text('0')),
                    new TwoLevelListItem(title: const Text('1'))
                  ]
                ),
              ]
            )
          )
        );
      }
    };

    await tester.pumpWidget(new MaterialApp(routes: routes));

    expect(didChangeOpen, isNull);
    await tester.tap(find.text('Sublist'));
    expect(didChangeOpen, isTrue);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Sublist'));
    expect(didChangeOpen, isFalse);
  });
}
