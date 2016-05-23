// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

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
  testWidgets('Can have multiple focused children and they update accordingly', (WidgetTester tester) async {
    GlobalKey keyFocus = new GlobalKey();
    GlobalKey keyA = new GlobalKey();
    GlobalKey keyB = new GlobalKey();
    await tester.pumpWidget(
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
    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('B FOCUSED'), findsNothing);
    await tester.tap(find.text('A FOCUSED'));
    await tester.pump();
    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('B FOCUSED'), findsNothing);
    await tester.tap(find.text('A FOCUSED'));
    await tester.pump();
    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('B FOCUSED'), findsNothing);
    await tester.tap(find.text('b'));
    await tester.pump();
    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);
    expect(find.text('b'), findsNothing);
    expect(find.text('B FOCUSED'), findsOneWidget);
    await tester.tap(find.text('a'));
    await tester.pump();
    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('B FOCUSED'), findsNothing);
  });

  testWidgets('Can blur', (WidgetTester tester) async {
    GlobalKey keyFocus = new GlobalKey();
    GlobalKey keyA = new GlobalKey();
    await tester.pumpWidget(
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

    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);

    Focus.moveTo(keyA);
    await tester.pump();

    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);

    Focus.clear(keyA.currentContext);
    await tester.pump();

    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);
  });

  testWidgets('Can move focus to scope', (WidgetTester tester) async {
    GlobalKey keyParentFocus = new GlobalKey();
    GlobalKey keyChildFocus = new GlobalKey();
    GlobalKey keyA = new GlobalKey();
    await tester.pumpWidget(
      new Focus(
        key: keyParentFocus,
        child: new Row(
          children: <Widget>[
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

    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);

    Focus.moveTo(keyA);
    await tester.pump();

    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);

    Focus.moveScopeTo(keyChildFocus, context: keyA.currentContext);

    await tester.pumpWidget(
      new Focus(
        key: keyParentFocus,
        child: new Row(
          children: <Widget>[
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

    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);

    await tester.pumpWidget(
      new Focus(
        key: keyParentFocus,
        child: new Row(
          children: <Widget>[
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
    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);

    await tester.pump();

    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);
  });
}
