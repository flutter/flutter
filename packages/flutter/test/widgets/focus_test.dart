// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class TestFocusable extends StatefulWidget {
  const TestFocusable({
    Key key,
    this.no,
    this.yes,
    this.autofocus = true,
  }) : super(key: key);

  final String no;
  final String yes;
  final bool autofocus;

  @override
  TestFocusableState createState() => TestFocusableState();
}

class TestFocusableState extends State<TestFocusable> {
  final FocusNode focusNode = FocusNode();
  bool _didAutofocus = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAutofocus && widget.autofocus) {
      _didAutofocus = true;
      FocusScope.of(context).autofocus(focusNode);
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { FocusScope.of(context).requestFocus(focusNode); },
      child: AnimatedBuilder(
        animation: focusNode,
        builder: (BuildContext context, Widget child) {
          return Text(focusNode.hasFocus ? widget.yes : widget.no, textDirection: TextDirection.ltr);
        },
      ),
    );
  }
}

void main() {
  testWidgets('Can have multiple focused children and they update accordingly', (WidgetTester tester) async {
    await tester.pumpWidget(
      Column(
        children: const <Widget>[
          TestFocusable(
            no: 'a',
            yes: 'A FOCUSED',
          ),
          TestFocusable(
            no: 'b',
            yes: 'B FOCUSED',
          ),
        ],
      ),
    );

    // Autofocus is delayed one frame.
    await tester.pump();

    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('B FOCUSED'), findsNothing);
    await tester.tap(find.text('A FOCUSED'));
    await tester.idle();
    await tester.pump();
    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('B FOCUSED'), findsNothing);
    await tester.tap(find.text('A FOCUSED'));
    await tester.idle();
    await tester.pump();
    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('B FOCUSED'), findsNothing);
    await tester.tap(find.text('b'));
    await tester.idle();
    await tester.pump();
    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);
    expect(find.text('b'), findsNothing);
    expect(find.text('B FOCUSED'), findsOneWidget);
    await tester.tap(find.text('a'));
    await tester.idle();
    await tester.pump();
    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('B FOCUSED'), findsNothing);
  });

  testWidgets('Can blur', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestFocusable(
        no: 'a',
        yes: 'A FOCUSED',
        autofocus: false,
      ),
    );

    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);

    final TestFocusableState state = tester.state(find.byType(TestFocusable));
    FocusScope.of(state.context).requestFocus(state.focusNode);
    await tester.idle();
    await tester.pump();

    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);

    state.focusNode.unfocus();
    await tester.idle();
    await tester.pump();

    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);
  });

  testWidgets('Can move focus to scope', (WidgetTester tester) async {
    final FocusScopeNode parentFocusScope = FocusScopeNode();
    final FocusScopeNode childFocusScope = FocusScopeNode();

    await tester.pumpWidget(
      FocusScope(
        node: parentFocusScope,
        autofocus: true,
        child: Row(
          textDirection: TextDirection.ltr,
          children: const <Widget>[
            TestFocusable(
              no: 'a',
              yes: 'A FOCUSED',
              autofocus: false,
            ),
          ],
        ),
      ),
    );

    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);

    final TestFocusableState state = tester.state(find.byType(TestFocusable));
    FocusScope.of(state.context).requestFocus(state.focusNode);
    await tester.idle();
    await tester.pump();

    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);

    expect(parentFocusScope, hasAGoodToStringDeep);
    expect(
      parentFocusScope.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
          'FocusScopeNode#00000\n'
          '   focus: FocusNode#00000(FOCUSED)\n'
      ),
    );

    expect(WidgetsBinding.instance.focusManager.rootScope, hasAGoodToStringDeep);
    expect(
      WidgetsBinding.instance.focusManager.rootScope.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'FocusScopeNode#00000\n'
        ' └─child 1: FocusScopeNode#00000\n'
        '     focus: FocusNode#00000(FOCUSED)\n'
      ),
    );

    parentFocusScope.setFirstFocus(childFocusScope);
    await tester.idle();

    await tester.pumpWidget(
      FocusScope(
        node: parentFocusScope,
        child: Row(
          textDirection: TextDirection.ltr,
          children: <Widget>[
            const TestFocusable(
              no: 'a',
              yes: 'A FOCUSED',
              autofocus: false,
            ),
            FocusScope(
              node: childFocusScope,
              child: Container(
                width: 50.0,
                height: 50.0,
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);

    await tester.pumpWidget(
      FocusScope(
        node: parentFocusScope,
        child: Row(
          textDirection: TextDirection.ltr,
          children: const <Widget>[
            TestFocusable(
              no: 'a',
              yes: 'A FOCUSED',
              autofocus: false,
            ),
          ],
        ),
      ),
    );

    // Focus has received the removal notification but we haven't rebuilt yet.
    expect(find.text('a'), findsOneWidget);
    expect(find.text('A FOCUSED'), findsNothing);

    await tester.pump();

    expect(find.text('a'), findsNothing);
    expect(find.text('A FOCUSED'), findsOneWidget);

    parentFocusScope.detach();
  });
}
