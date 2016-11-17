// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Drop down button control test', (WidgetTester tester) async {
    List<String> items = <String>['one', 'two', 'three', 'four'];
    String value = items.first;

    void didChangeValue(String newValue) {
      value = newValue;
    }

    Widget build() {
      return new MaterialApp(
        home: new Material(
          child: new Center(
            child: new DropdownButton<String>(
              value: value,
              items: items.map((String item) {
                return new DropdownMenuItem<String>(
                  value: item,
                  child: new Text(item),
                );
              }).toList(),
              onChanged: didChangeValue,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build());

    await tester.tap(find.text('one'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('one'));

    await tester.tap(find.text('three').last);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('three'));

    await tester.tap(find.text('three'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('three'));

    await tester.pumpWidget(build());

    await tester.tap(find.text('two').last);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('two'));
  });

  testWidgets('Drop down button with no app', (WidgetTester tester) async {
    List<String> items = <String>['one', 'two', 'three', 'four'];
    String value = items.first;

    void didChangeValue(String newValue) {
      value = newValue;
    }

    Widget build() {
      return new Navigator(
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          return new MaterialPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              return new Material(
                child: new Center(
                  child: new DropdownButton<String>(
                    value: value,
                    items: items.map((String item) {
                      return new DropdownMenuItem<String>(
                        value: item,
                        child: new Text(item),
                      );
                    }).toList(),
                    onChanged: didChangeValue,
                  ),
                )
              );
            },
          );
        }
      );
    }

    await tester.pumpWidget(build());

    await tester.tap(find.text('one'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('one'));

    await tester.tap(find.text('three').last);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('three'));

    await tester.tap(find.text('three'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('three'));

    await tester.pumpWidget(build());

    await tester.tap(find.text('two').last);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('two'));
  });

  testWidgets('Drop down screen edges', (WidgetTester tester) async {
    int value = 4;
    List<DropdownMenuItem<int>> items = <DropdownMenuItem<int>>[];
    for (int i = 0; i < 20; ++i)
      items.add(new DropdownMenuItem<int>(value: i, child: new Text('$i')));

    void handleChanged(int newValue) {
      value = newValue;
    }

    DropdownButton<int> button = new DropdownButton<int>(
      value: value,
      onChanged: handleChanged,
      items: items,
    );

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Align(
            alignment: FractionalOffset.topCenter,
            child: button,
          ),
        ),
      ),
    );

    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    // We should have two copies of item 5, one in the menu and one in the
    // button itself.
    expect(tester.elementList(find.text('5')), hasLength(2));

    // We should only have one copy of item 19, which is in the button itself.
    // The copy in the menu shouldn't be in the tree because it's off-screen.
    expect(tester.elementList(find.text('19')), hasLength(1));

    expect(value, 4);
    await tester.tap(find.byConfig(button));
    expect(value, 4);
    // this waits for the route's completer to complete, which calls handleChanged
    await tester.idle();
    expect(value, 4);

    // TODO(abarth): Remove these calls to pump once navigator cleans up its
    // pop transitions.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation
  });

  testWidgets('Drop down button aligns selected menu item', (WidgetTester tester) async {
    Key buttonKey = new UniqueKey();
    List<String> items = <String>['one', 'two', 'wide three', 'four'];
    String value = 'two';

    Widget build() {
      return new MaterialApp(
        home: new Material(
          child: new Center(
            child: new DropdownButton<String>(
              key: buttonKey,
              value: value,
              onChanged: (String value) { },
              items: items.map((String item) {
                return new DropdownMenuItem<String>(
                  key: new ValueKey<String>(item),
                  value: item,
                  child: new Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build());
    RenderBox buttonBox = tester.renderObject(find.byKey(buttonKey));
    assert(buttonBox.attached);

    await tester.tap(find.text('two'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    // The selected dropdown item is both in menu we just popped up, and in
    // the IndexedStack contained by the dropdown button. Both of them should
    // have the same origin and height as the dropdown button.
    List<RenderObject> itemBoxes = tester.renderObjectList(find.byKey(new ValueKey<String>('two'))).toList();
    expect(itemBoxes.length, equals(2));
    for(RenderBox itemBox in itemBoxes) {
      assert(itemBox.attached);
      expect(buttonBox.localToGlobal(Point.origin), equals(itemBox.localToGlobal(Point.origin)));
      expect(buttonBox.size.height, equals(itemBox.size.height));
    }

  });

  testWidgets('Drop down button with isDense:true aligns selected menu item', (WidgetTester tester) async {
    Key buttonKey = new UniqueKey();
    List<String> items = <String>['one', 'two', 'three', 'four'];
    String value = 'two';

    Widget build() {
      return new MaterialApp(
        home: new Material(
          child: new Center(
            child: new DropdownButton<String>(
              key: buttonKey,
              value: value,
              onChanged: (String value) { },
              isDense: true,
              items: items.map((String item) {
                return new DropdownMenuItem<String>(
                  key: new ValueKey<String>(item),
                  value: item,
                  child: new Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build());
    RenderBox buttonBox = tester.renderObject(find.byKey(buttonKey));
    assert(buttonBox.attached);

    await tester.tap(find.text('two'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    // The selected dropdown item is both in menu we just popped up, and in
    // the IndexedStack contained by the dropdown button. Both of them should
    // have the same vertical center as the button.
    List<RenderBox> itemBoxes = tester.renderObjectList(find.byKey(new ValueKey<String>('two'))).toList();
    expect(itemBoxes.length, equals(2));

    // When isDense is true, the button's height is reduced. The menu items'
    // heights are not.
    double menuItemHeight = itemBoxes.map((RenderBox box) => box.size.height).reduce(math.max);
    expect(menuItemHeight, greaterThan(buttonBox.size.height));

    for(RenderBox itemBox in itemBoxes) {
      assert(itemBox.attached);
      Point buttonBoxCenter = buttonBox.size.center(buttonBox.localToGlobal(Point.origin));
      Point itemBoxCenter =  itemBox.size.center(itemBox.localToGlobal(Point.origin));
      expect(buttonBoxCenter.y, equals(itemBoxCenter.y));
    }

  });
}
