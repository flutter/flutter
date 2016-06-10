// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class TestBoxPainter extends BoxPainter {
  TestBoxPainter(VoidCallback onChanged): super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) { }
}

class TestDecoration extends Decoration {
  int listeners = 0;

  @override
  Decoration lerpFrom(Decoration a, double t) {
    if (t == 0.0)
      return a;
    if (t == 1.0)
      return this;
    return new TestDecoration();
  }

  @override
  Decoration lerpTo(Decoration b, double t) {
    if (t == 1.0)
      return b;
    if (t == 0.0)
      return this;
    return new TestDecoration();
  }

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    if (onChanged != null)
      listeners += 1;
    return new TestBoxPainter(onChanged);
  }
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

  testWidgets('Switch listens to the decorations it paints', (WidgetTester tester) async {
    TestDecoration activeDecoration = new TestDecoration();
    TestDecoration inactiveDecoration = new TestDecoration();

    Widget build(bool active, TestDecoration activeDecoration, TestDecoration inactiveDecoration) {
      return new Material(
        child: new Center(
          child: new Switch(
            value: active,
            onChanged: null,
            activeThumbDecoration: activeDecoration,
            inactiveThumbDecoration: inactiveDecoration
          )
        )
      );
    }

    // no build yet
    expect(activeDecoration.listeners, 0);
    expect(inactiveDecoration.listeners, 0);

    await tester.pumpWidget(build(false, activeDecoration, inactiveDecoration));
    expect(activeDecoration.listeners, 0);
    expect(inactiveDecoration.listeners, 1);

    await tester.pumpWidget(build(true, activeDecoration, inactiveDecoration));
    // started the animation, but we're on frame 0
    expect(activeDecoration.listeners, 0);
    expect(inactiveDecoration.listeners, 2);

    await tester.pump(const Duration(milliseconds: 30)); // slightly into the animation
    // we're painting some lerped decoration that doesn't exactly match either
    expect(activeDecoration.listeners, 0);
    expect(inactiveDecoration.listeners, 2);

    await tester.pump(const Duration(seconds: 1)); // ended animation
    expect(activeDecoration.listeners, 1);
    expect(inactiveDecoration.listeners, 2);

  });
}
