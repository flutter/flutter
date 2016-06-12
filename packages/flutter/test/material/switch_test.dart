// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestBoxPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Rect rect) { }
}

class TestDecoration extends Decoration {
  final List<VoidCallback> listeners = <VoidCallback>[];

  @override
  bool get needsListeners => true;

  @override
  void addChangeListener(VoidCallback listener) { listeners.add(listener); }

  @override
  void removeChangeListener(VoidCallback listener) { listeners.remove(listener); }

  @override
  BoxPainter createBoxPainter() => new TestBoxPainter();
}

void main() {
  testWidgets('Switch can toggle on tap', (WidgetTester tester) async {
    Key switchKey = new UniqueKey();
    bool value = false;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Material(
            child: new Center(
              child: new Switch(
                key: switchKey,
                value: value,
                onChanged: (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                }
              )
            )
          );
        }
      )
    );

    expect(value, isFalse);
    await tester.tap(find.byKey(switchKey));
    expect(value, isTrue);
  });

  testWidgets('Switch listens to decorations', (WidgetTester tester) async {
    TestDecoration activeDecoration = new TestDecoration();
    TestDecoration inactiveDecoration = new TestDecoration();

    Widget build(TestDecoration activeDecoration, TestDecoration inactiveDecoration) {
      return new Material(
        child: new Center(
          child: new Switch(
            value: false,
            onChanged: null,
            activeThumbDecoration: activeDecoration,
            inactiveThumbDecoration: inactiveDecoration
          )
        )
      );
    }

    await tester.pumpWidget(build(activeDecoration, inactiveDecoration));

    expect(activeDecoration.listeners.length, 1);
    expect(inactiveDecoration.listeners.length, 1);

    await tester.pumpWidget(build(activeDecoration, null));

    expect(activeDecoration.listeners.length, 1);
    expect(inactiveDecoration.listeners.length, 0);

    await tester.pumpWidget(new Container(key: new UniqueKey()));

    expect(activeDecoration.listeners.length, 0);
    expect(inactiveDecoration.listeners.length, 0);
  });
}
