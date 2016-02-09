// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

final Key blockKey = new Key('test');

void main() {
  test('Cannot scroll a non-overflowing block', () {
    testWidgets((WidgetTester tester) {
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
      tester.pump(); // for SizeObservers

      Point middleOfContainer = tester.getCenter(tester.findText('Hello'));
      Point target = tester.getCenter(tester.findElementByKey(blockKey));
      TestPointer pointer = new TestPointer();
      tester.dispatchEvent(pointer.down(target), target);
      tester.dispatchEvent(pointer.move(target + const Offset(0.0, -10.0)), target);

      tester.pump(const Duration(milliseconds: 1));

      expect(tester.getCenter(tester.findText('Hello')) == middleOfContainer, isTrue);

      tester.dispatchEvent(pointer.up(), target);
    });
  });

  test('Can scroll an overflowing block', () {
    testWidgets((WidgetTester tester) {
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
      tester.pump(); // for SizeObservers

      Point middleOfContainer = tester.getCenter(tester.findText('Hello'));
      Point target = tester.getCenter(tester.findElementByKey(blockKey));
      TestPointer pointer = new TestPointer();
      tester.dispatchEvent(pointer.down(target), target);
      tester.dispatchEvent(pointer.move(target + const Offset(0.0, -10.0)), target);

      tester.pump(const Duration(milliseconds: 1));

      expect(tester.getCenter(tester.findText('Hello')) == middleOfContainer, isFalse);

      tester.dispatchEvent(pointer.up(), target);
    });
  });

  test('Scroll anchor', () {
    testWidgets((WidgetTester tester) {
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
      tester.pump(); // for SizeObservers

      Point target = const Point(200.0, 200.0);
      tester.tapAt(target);
      expect(first, equals(0));
      expect(second, equals(1));

      tester.pumpWidget(buildBlock(ViewportAnchor.start));
      tester.pump(); // for SizeObservers

      tester.tapAt(target);
      expect(first, equals(1));
      expect(second, equals(1));
    });
  });
}
