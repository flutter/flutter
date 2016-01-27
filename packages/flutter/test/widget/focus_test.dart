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
      GlobalKey keyFocus = new GlobalKey();
      GlobalKey keyA = new GlobalKey();
      GlobalKey keyB = new GlobalKey();
      tester.pumpWidget(
        new Focus(
          key: keyFocus,
          child: new Column(
            children: <Widget>[
              // reverse these when you fix https://github.com/flutter/engine/issues/1495
              new TestFocusable(
                key: keyB,
                no: 'b',
                yes: 'B FOCUSED'
              ),
              new TestFocusable(
                key: keyA,
                no: 'a',
                yes: 'A FOCUSED'
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
      GlobalKey keyFocus = new GlobalKey();
      GlobalKey keyA = new GlobalKey();
      tester.pumpWidget(
        new Focus(
          key: keyFocus,
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

  test('Can move focus to scope', () {
    testWidgets((WidgetTester tester) {
      GlobalKey keyParentFocus = new GlobalKey();
      GlobalKey keyChildFocus = new GlobalKey();
      GlobalKey keyA = new GlobalKey();
      tester.pumpWidget(
        new Focus(
          key: keyParentFocus,
          child: new Row(
            children: [
              new TestFocusable(
                key: keyA,
                no: 'a',
                yes: 'A FOCUSED',
                autofocus: false
              )
            ]
          )
        )
      );

      expect(tester.findText('a'),         isNotNull);
      expect(tester.findText('A FOCUSED'), isNull);

      Focus.moveTo(keyA);
      tester.pump();

      expect(tester.findText('a'),         isNull);
      expect(tester.findText('A FOCUSED'), isNotNull);

      Focus.moveScopeTo(keyChildFocus, context: keyA.currentContext);

      tester.pumpWidget(
        new Focus(
          key: keyParentFocus,
          child: new Row(
            children: [
              new TestFocusable(
                key: keyA,
                no: 'a',
                yes: 'A FOCUSED',
                autofocus: false
              ),
              new Focus(
                key: keyChildFocus,
                child: new Container(
                  width: 50.0,
                  height: 50.0
                )
              )
            ]
          )
        )
      );

      expect(tester.findText('a'),         isNotNull);
      expect(tester.findText('A FOCUSED'), isNull);

      tester.pumpWidget(
        new Focus(
          key: keyParentFocus,
          child: new Row(
            children: [
              new TestFocusable(
                key: keyA,
                no: 'a',
                yes: 'A FOCUSED',
                autofocus: false
              )
            ]
          )
        )
      );

      // Focus has received the removal notification but we haven't rebuilt yet.
      expect(tester.findText('a'),         isNotNull);
      expect(tester.findText('A FOCUSED'), isNull);

      tester.pump();

      expect(tester.findText('a'),         isNull);
      expect(tester.findText('A FOCUSED'), isNotNull);
    });
  });
}
