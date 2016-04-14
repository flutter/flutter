// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class TestFocusable extends StatelessWidget {
  TestFocusable({
    GlobalKey key,
    this.no,
    this.yes,
    this.autofocus: true
  }) : super(key: key);

  final String no;
  final String yes;
  final bool autofocus;

  @override
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
      expect(tester, doesNotHaveWidget(find.text('a')));
      expect(tester, hasWidget(find.text('A FOCUSED')));
      expect(tester, hasWidget(find.text('b')));
      expect(tester, doesNotHaveWidget(find.text('B FOCUSED')));
      tester.tap(find.text('A FOCUSED'));
      tester.pump();
      expect(tester, doesNotHaveWidget(find.text('a')));
      expect(tester, hasWidget(find.text('A FOCUSED')));
      expect(tester, hasWidget(find.text('b')));
      expect(tester, doesNotHaveWidget(find.text('B FOCUSED')));
      tester.tap(find.text('A FOCUSED'));
      tester.pump();
      expect(tester, doesNotHaveWidget(find.text('a')));
      expect(tester, hasWidget(find.text('A FOCUSED')));
      expect(tester, hasWidget(find.text('b')));
      expect(tester, doesNotHaveWidget(find.text('B FOCUSED')));
      tester.tap(find.text('b'));
      tester.pump();
      expect(tester, hasWidget(find.text('a')));
      expect(tester, doesNotHaveWidget(find.text('A FOCUSED')));
      expect(tester, doesNotHaveWidget(find.text('b')));
      expect(tester, hasWidget(find.text('B FOCUSED')));
      tester.tap(find.text('a'));
      tester.pump();
      expect(tester, doesNotHaveWidget(find.text('a')));
      expect(tester, hasWidget(find.text('A FOCUSED')));
      expect(tester, hasWidget(find.text('b')));
      expect(tester, doesNotHaveWidget(find.text('B FOCUSED')));
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

      expect(tester, hasWidget(find.text('a')));
      expect(tester, doesNotHaveWidget(find.text('A FOCUSED')));

      Focus.moveTo(keyA);
      tester.pump();

      expect(tester, doesNotHaveWidget(find.text('a')));
      expect(tester, hasWidget(find.text('A FOCUSED')));

      Focus.clear(keyA.currentContext);
      tester.pump();

      expect(tester, hasWidget(find.text('a')));
      expect(tester, doesNotHaveWidget(find.text('A FOCUSED')));
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

      expect(tester, hasWidget(find.text('a')));
      expect(tester, doesNotHaveWidget(find.text('A FOCUSED')));

      Focus.moveTo(keyA);
      tester.pump();

      expect(tester, doesNotHaveWidget(find.text('a')));
      expect(tester, hasWidget(find.text('A FOCUSED')));

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

      expect(tester, hasWidget(find.text('a')));
      expect(tester, doesNotHaveWidget(find.text('A FOCUSED')));

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
      expect(tester, hasWidget(find.text('a')));
      expect(tester, doesNotHaveWidget(find.text('A FOCUSED')));

      tester.pump();

      expect(tester, doesNotHaveWidget(find.text('a')));
      expect(tester, hasWidget(find.text('A FOCUSED')));
    });
  });
}
