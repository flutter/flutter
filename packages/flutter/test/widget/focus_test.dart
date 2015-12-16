// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class TestFocusable extends StatelessComponent {
  TestFocusable(this.no, this.yes, GlobalKey key) : super(key: key);
  final String no;
  final String yes;
  Widget build(BuildContext context) {
    bool focused = Focus.at(context, this);
    return new GestureDetector(
      onTap: () { Focus.moveTo(context, this); },
      child: new Text(focused ? yes : no)
    );
  }
}

void main() {
  test('Can have multiple focused children and they update accordingly', () {
    testWidgets((WidgetTester tester) {
      GlobalKey keyA = new GlobalKey();
      GlobalKey keyB = new GlobalKey();
      tester.pumpWidget(
        new Focus(
          child: new Column(<Widget>[
            // reverse these when you fix https://github.com/flutter/engine/issues/1495
            new TestFocusable('b', 'B FOCUSED', keyB),
            new TestFocusable('a', 'A FOCUSED', keyA),
          ])
        )
      );
      expect(tester.findText('a'),         isNull);
      expect(tester.findText('A FOCUSED'), isNotNull);
      expect(tester.findText('b'),         isNotNull);
      expect(tester.findText('B FOCUSED'), isNull);
      tester.tap(tester.findText('A FOCUSED'));
      tester.pump();
      expect(tester.findText('a'),         isNull);
      expect(tester.findText('A FOCUSED'), isNotNull);
      expect(tester.findText('b'),         isNotNull);
      expect(tester.findText('B FOCUSED'), isNull);
      tester.tap(tester.findText('A FOCUSED'));
      tester.pump();
      expect(tester.findText('a'),         isNull);
      expect(tester.findText('A FOCUSED'), isNotNull);
      expect(tester.findText('b'),         isNotNull);
      expect(tester.findText('B FOCUSED'), isNull);
      tester.tap(tester.findText('b'));
      tester.pump();
      expect(tester.findText('a'),         isNotNull);
      expect(tester.findText('A FOCUSED'), isNull);
      expect(tester.findText('b'),         isNull);
      expect(tester.findText('B FOCUSED'), isNotNull);
      tester.tap(tester.findText('a'));
      tester.pump();
      expect(tester.findText('a'),         isNull);
      expect(tester.findText('A FOCUSED'), isNotNull);
      expect(tester.findText('b'),         isNotNull);
      expect(tester.findText('B FOCUSED'), isNull);
    });
  });
}
