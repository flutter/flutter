// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class TestFocusable extends StatelessComponent {
  TestFocusable({
    GlobalKey key,
    this.no,
    this.yes,
    this.autofocus: true
  }) : super(key: key);

  final String no;
  final String yes;
  final bool autofocus;

  Widget build(BuildContext context) {
    bool focused = Focus.at(context, autofocus: autofocus);
    return new GestureDetector(
      onTap: () { Focus.moveTo(key); },
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
          child: new Column(
            children: <Widget>[
              new TestFocusable(
                key: keyA,
                no: 'a',
                yes: 'A FOCUSED'
              ),
              new TestFocusable(
                key: keyB,
                no: 'b',
                yes: 'B FOCUSED'
              ),
            ]
          )
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

  test('Can blur', () {
    testWidgets((WidgetTester tester) {
      GlobalKey keyA = new GlobalKey();
      tester.pumpWidget(
        new Focus(
          child: new TestFocusable(
            key: keyA,
            no: 'a',
            yes: 'A FOCUSED',
            autofocus: false
          )
        )
      );

      expect(tester.findText('a'),         isNotNull);
      expect(tester.findText('A FOCUSED'), isNull);

      Focus.moveTo(keyA);
      tester.pump();

      expect(tester.findText('a'),         isNull);
      expect(tester.findText('A FOCUSED'), isNotNull);

      Focus.clear(keyA.currentContext);
      tester.pump();

      expect(tester.findText('a'),         isNotNull);
      expect(tester.findText('A FOCUSED'), isNull);
    });
  });
}
