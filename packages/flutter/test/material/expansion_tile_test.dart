// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

class TestIcon extends StatefulWidget {
  const TestIcon({Key key}) : super(key: key);

  @override
  TestIconState createState() => TestIconState();
}

class TestIconState extends State<TestIcon> {
  IconThemeData iconTheme;

  @override
  Widget build(BuildContext context) {
    iconTheme = IconTheme.of(context);
    return const Icon(Icons.expand_more);
  }
}

class TestText extends StatefulWidget {
  const TestText(this.text, {Key key}) : super(key: key);

  final String text;

  @override
  TestTextState createState() => TestTextState();
}

class TestTextState extends State<TestText> {
  TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    textStyle = DefaultTextStyle.of(context).style;
    return Text(widget.text);
  }
}

void main() {
  const Color _dividerColor = Color(0x1f333333);
  const Color _accentColor = Colors.blueAccent;
  const Color _unselectedWidgetColor = Colors.black54;
  const Color _headerColor = Colors.black45;

  testWidgets('ExpansionTile initial state', (WidgetTester tester) async {
    final Key topKey = UniqueKey();
    const Key expandedKey = PageStorageKey<String>('expanded');
    const Key collapsedKey = PageStorageKey<String>('collapsed');
    const Key defaultKey = PageStorageKey<String>('default');

    final Key tileKey = UniqueKey();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        dividerColor: _dividerColor,
      ),
      home: Material(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ListTile(title: const Text('Top'), key: topKey),
              ExpansionTile(
                key: expandedKey,
                initiallyExpanded: true,
                title: const Text('Expanded'),
                backgroundColor: Colors.red,
                children: <Widget>[
                  ListTile(
                    key: tileKey,
                    title: const Text('0'),
                  ),
                ],
              ),
              ExpansionTile(
                key: collapsedKey,
                initiallyExpanded: false,
                title: const Text('Collapsed'),
                children: <Widget>[
                  ListTile(
                    key: tileKey,
                    title: const Text('0'),
                  ),
                ],
              ),
              const ExpansionTile(
                key: defaultKey,
                title: Text('Default'),
                children: <Widget>[
                  ListTile(title: Text('0')),
                ],
              ),
            ],
          ),
        ),
      ),
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

  testWidgets('ListTileTheme', (WidgetTester tester) async {
    final Key expandedTitleKey = UniqueKey();
    final Key collapsedTitleKey = UniqueKey();
    final Key expandedIconKey = UniqueKey();
    final Key collapsedIconKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          accentColor: _accentColor,
          unselectedWidgetColor: _unselectedWidgetColor,
          textTheme: const TextTheme(subhead: TextStyle(color: _headerColor)),
        ),
        home: Material(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const ListTile(title: Text('Top')),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: TestText('Expanded', key: expandedTitleKey),
                  backgroundColor: Colors.red,
                  children: const <Widget>[ListTile(title: Text('0'))],
                  trailing: TestIcon(key: expandedIconKey),
                ),
                ExpansionTile(
                  initiallyExpanded: false,
                  title: TestText('Collapsed', key: collapsedTitleKey),
                  children: const <Widget>[ListTile(title: Text('0'))],
                  trailing: TestIcon(key: collapsedIconKey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Color iconColor(Key key) => tester.state<TestIconState>(find.byKey(key)).iconTheme.color;
    Color textColor(Key key) => tester.state<TestTextState>(find.byKey(key)).textStyle.color;

    expect(textColor(expandedTitleKey), _accentColor);
    expect(textColor(collapsedTitleKey), _headerColor);
    expect(iconColor(expandedIconKey), _accentColor);
    expect(iconColor(collapsedIconKey), _unselectedWidgetColor);

    // Tap both tiles to change their state: collapse and extend respectively
    await tester.tap(find.text('Expanded'));
    await tester.tap(find.text('Collapsed'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(textColor(expandedTitleKey), _headerColor);
    expect(textColor(collapsedTitleKey), _accentColor);
    expect(iconColor(expandedIconKey), _unselectedWidgetColor);
    expect(iconColor(collapsedIconKey), _accentColor);
  });
}
