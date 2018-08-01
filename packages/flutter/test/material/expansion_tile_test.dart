// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  const Color _dividerColor = const Color(0x1f333333);

  testWidgets('ExpansionTile initial state', (WidgetTester tester) async {
    final Key topKey = new UniqueKey();
    const Key expandedKey = const PageStorageKey<String>('expanded');
    const Key collapsedKey = const PageStorageKey<String>('collapsed');
    const Key defaultKey = const PageStorageKey<String>('default');

    final Key tileKey = new UniqueKey();

    await tester.pumpWidget(new MaterialApp(
      theme: new ThemeData(
        platform: TargetPlatform.iOS,
        dividerColor: _dividerColor,
      ),
      home: new Material(
        child: new SingleChildScrollView(
          child: new Column(
            children: <Widget>[
              new ListTile(title: const Text('Top'), key: topKey),
              new ExpansionTile(
                key: expandedKey,
                initiallyExpanded: true,
                title: const Text('Expanded'),
                backgroundColor: Colors.red,
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
              const ExpansionTile(
                key: defaultKey,
                title: const Text('Default'),
                children: const <Widget>[
                  const ListTile(title: const Text('0')),
                ]
              )
            ]
          )
        )
      )
    ));

    double getHeight(Key key) => tester.getSize(find.byKey(key)).height;
    Container getContainer(Key key) => tester.firstWidget(find.descendant(
      of: find.byKey(key),
      matching: find.byType(Container),
    ));

    expect(getHeight(topKey), getHeight(expandedKey) - getHeight(tileKey) - 2.0);
    expect(getHeight(topKey), getHeight(collapsedKey) - 2.0);
    expect(getHeight(topKey), getHeight(defaultKey) - 2.0);

    BoxDecoration expandedContainerDecoration = getContainer(expandedKey).decoration;
    expect(expandedContainerDecoration.color, Colors.red);
    expect(expandedContainerDecoration.border.top.color, _dividerColor);
    expect(expandedContainerDecoration.border.bottom.color, _dividerColor);

    BoxDecoration collapsedContainerDecoration = getContainer(collapsedKey).decoration;
    expect(collapsedContainerDecoration.color, Colors.transparent);
    expect(collapsedContainerDecoration.border.top.color, Colors.transparent);
    expect(collapsedContainerDecoration.border.bottom.color, Colors.transparent);

    await tester.tap(find.text('Expanded'));
    await tester.tap(find.text('Collapsed'));
    await tester.tap(find.text('Default'));

    await tester.pump();

    // Pump to the middle of the animation for expansion.
    await tester.pump(const Duration(milliseconds: 100));
    final BoxDecoration collapsingContainerDecoration = getContainer(collapsedKey).decoration;
    expect(collapsingContainerDecoration.color, Colors.transparent);
    // Opacity should change but color component should remain the same.
    expect(collapsingContainerDecoration.border.top.color, const Color(0x15333333));
    expect(collapsingContainerDecoration.border.bottom.color, const Color(0x15333333));

    // Pump all the way to the end now.
    await tester.pump(const Duration(seconds: 1));

    expect(getHeight(topKey), getHeight(expandedKey) - 2.0);
    expect(getHeight(topKey), getHeight(collapsedKey) - getHeight(tileKey) - 2.0);
    expect(getHeight(topKey), getHeight(defaultKey) - getHeight(tileKey) - 2.0);

    // Expanded should be collapsed now.
    expandedContainerDecoration = getContainer(expandedKey).decoration;
    expect(expandedContainerDecoration.color, Colors.transparent);
    expect(expandedContainerDecoration.border.top.color, Colors.transparent);
    expect(expandedContainerDecoration.border.bottom.color, Colors.transparent);

    // Collapsed should be expanded now.
    collapsedContainerDecoration = getContainer(collapsedKey).decoration;
    expect(collapsedContainerDecoration.color, Colors.transparent);
    expect(collapsedContainerDecoration.border.top.color, _dividerColor);
    expect(collapsedContainerDecoration.border.bottom.color, _dividerColor);
  });
}
