// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

final Key blockKey = new Key('test');

void main() {
  testWidgets('Cannot scroll a non-overflowing block', (WidgetTester tester) {
      tester.pumpWidget(
        new Block(
          key: blockKey,
          children: <Widget>[
            new Container(
              height: 200.0, // less than 600, the height of the test area
              child: new Text('Hello')
            )
          ]
        )
      );

      Point middleOfContainer = tester.getCenter(find.text('Hello'));
      Point target = tester.getCenter(find.byKey(blockKey));
      TestGesture gesture = tester.startGesture(target);
      gesture.moveBy(const Offset(0.0, -10.0));

      tester.pump(const Duration(milliseconds: 1));

      expect(tester.getCenter(find.text('Hello')) == middleOfContainer, isTrue);

      gesture.up();
  });

  testWidgets('Can scroll an overflowing block', (WidgetTester tester) {
      tester.pumpWidget(
        new Block(
          key: blockKey,
          children: <Widget>[
            new Container(
              height: 2000.0, // more than 600, the height of the test area
              child: new Text('Hello')
            )
          ]
        )
      );

      Point middleOfContainer = tester.getCenter(find.text('Hello'));
      expect(middleOfContainer.x, equals(400.0));
      expect(middleOfContainer.y, equals(1000.0));

      Point target = tester.getCenter(find.byKey(blockKey));
      TestGesture gesture = tester.startGesture(target);
      gesture.moveBy(const Offset(0.0, -10.0));

      tester.pump(); // redo layout

      expect(tester.getCenter(find.text('Hello')), isNot(equals(middleOfContainer)));

      gesture.up();
  });

  testWidgets('Scroll anchor', (WidgetTester tester) {
      int first = 0;
      int second = 0;

      Widget buildBlock(ViewportAnchor scrollAnchor) {
        return new Block(
          key: new UniqueKey(),
          scrollAnchor: scrollAnchor,
          children: <Widget>[
            new GestureDetector(
              onTap: () { ++first; },
              child: new Container(
                height: 2000.0, // more than 600, the height of the test area
                decoration: new BoxDecoration(
                  backgroundColor: new Color(0xFF00FF00)
                )
              )
            ),
            new GestureDetector(
              onTap: () { ++second; },
              child: new Container(
                height: 2000.0, // more than 600, the height of the test area
                decoration: new BoxDecoration(
                  backgroundColor: new Color(0xFF0000FF)
                )
              )
            )
          ]
        );
      }

      tester.pumpWidget(buildBlock(ViewportAnchor.end));

      Point target = const Point(200.0, 200.0);
      tester.tapAt(target);
      expect(first, equals(0));
      expect(second, equals(1));

      tester.pumpWidget(buildBlock(ViewportAnchor.start));

      tester.tapAt(target);
      expect(first, equals(1));
      expect(second, equals(1));
  });
}
