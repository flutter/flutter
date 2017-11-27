// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('ExpansionTile initial state', (WidgetTester tester) async {
    final Key topKey = new UniqueKey();
    final Key expandedKey = const PageStorageKey<String>('expanded');
    final Key collapsedKey = const PageStorageKey<String>('collapsed');
    final Key defaultKey = const PageStorageKey<String>('default');

    final Key tileKey = new UniqueKey();

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new SingleChildScrollView(
          child: new Column(
            children: <Widget>[
              new ListTile(title: const Text('Top'), key: topKey),
              new ExpansionTile(
                key: expandedKey,
                initiallyExpanded: true,
                title: const Text('Expanded'),
                children: <Widget>[
                  new ListTile(
                    key: tileKey,
                    title: const Text('0')
                  )
                ]
              ),
              new ExpansionTile(
                key: collapsedKey,
                initiallyExpanded: false,
                title: const Text('Collapsed'),
                children: <Widget>[
                  new ListTile(
                    key: tileKey,
                    title: const Text('0')
                  )
                ]
              ),
              new ExpansionTile(
                key: defaultKey,
                title: const Text('Default'),
                children: <Widget>[
                  const ListTile(title: const Text('0')),
                ]
              )
            ]
          )
        )
      )
    ));

    double getHeight(Key key) => tester.getSize(find.byKey(key)).height;

    expect(getHeight(topKey), getHeight(expandedKey) - getHeight(tileKey) - 2.0);
    expect(getHeight(topKey), getHeight(collapsedKey) - 2.0);
    expect(getHeight(topKey), getHeight(defaultKey) - 2.0);

    await tester.tap(find.text('Expanded'));
    await tester.tap(find.text('Collapsed'));
    await tester.tap(find.text('Default'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(getHeight(topKey), getHeight(expandedKey) - 2.0);
    expect(getHeight(topKey), getHeight(collapsedKey) - getHeight(tileKey) - 2.0);
    expect(getHeight(topKey), getHeight(defaultKey) - getHeight(tileKey) - 2.0);
  });
}
