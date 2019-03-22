// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class TestFocusable extends StatefulWidget {
  const TestFocusable({
    Key key,
    this.debugLabel,
    this.name = 'a',
    this.autofocus = false,
  }) : super(key: key);

  final String debugLabel;
  final String name;
  final bool autofocus;

  @override
  TestFocusableState createState() => TestFocusableState();
}

class TestFocusableState extends State<TestFocusable> {
  FocusNode focusNode = FocusNode();
  bool _didAutofocus = false;

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(debugLabel: widget.debugLabel);
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).reparentIfNeeded(focusNode);
    if (!_didAutofocus && widget.autofocus) {
      _didAutofocus = true;
      FocusScope.of(context).autofocus(focusNode);
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(focusNode);
      },
      child: AnimatedBuilder(
        animation: focusNode,
        builder: (BuildContext context, Widget child) {
          return Text(
            focusNode.hasFocus ? '${widget.name.toUpperCase()} FOCUSED' : widget.name.toLowerCase(),
            textDirection: TextDirection.ltr,
          );
        },
      ),
    );
  }
}

void main() {
  setUp((){
    // Reset the focus manager between tests, to avoid leaking state.
    WidgetsBinding.instance.focusManager.reset();
  });

  testWidgets('Can focus', (WidgetTester tester) async {
    final GlobalKey<TestFocusableState> key = GlobalKey();

    await tester.pumpWidget(
      TestFocusable(key: key, name: 'a'),
    );

    expect(key.currentState.focusNode.hasFocus, isFalse);

    FocusScope.of(key.currentContext).requestFocus(key.currentState.focusNode);
    await tester.pumpAndSettle();

    expect(key.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
  });

  testWidgets('Can unfocus', (WidgetTester tester) async {
    final GlobalKey<TestFocusableState> keyA = GlobalKey();
    final GlobalKey<TestFocusableState> keyB = GlobalKey();
    await tester.pumpWidget(
      Column(
        children: <Widget>[
          TestFocusable(key: keyA, name: 'a'),
          TestFocusable(key: keyB, name: 'b'),
        ],
      ),
    );

    expect(keyA.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('a'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);

    FocusScope.of(keyA.currentContext).requestFocus(keyA.currentState.focusNode);
    await tester.pumpAndSettle();

    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);

    // Set focus to the "B" node to unfocus the "A" node.
    FocusScope.of(keyB.currentContext).requestFocus(keyB.currentState.focusNode);
    await tester.pumpAndSettle();

    expect(keyA.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('a'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('B FOCUSED'), findsOneWidget);
  });

  testWidgets('Can have multiple focused children and they update accordingly', (WidgetTester tester) async {
    final GlobalKey<TestFocusableState> keyA = GlobalKey();
    final GlobalKey<TestFocusableState> keyB = GlobalKey();

    await tester.pumpWidget(
      Column(
        children: <Widget>[
          TestFocusable(
            key: keyA,
            name: 'a',
            autofocus: true,
          ),
          TestFocusable(
            key: keyB,
            name: 'b',
          ),
        ],
      ),
    );

    // Autofocus is delayed one frame.
    await tester.pump();
    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);
    await tester.tap(find.text('A FOCUSED'));
    await tester.pump();
    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);
    await tester.tap(find.text('b'));
    await tester.pump();
    expect(keyA.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('a'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('B FOCUSED'), findsOneWidget);
    await tester.tap(find.text('a'));
    await tester.pump();
    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);
  });

  // This moves a focus node first into a focus scope that is added to its
  // parent, and then out of that focus scope again.
  testWidgets('Can move focus in and out of FocusScope', (WidgetTester tester) async {
    final FocusScopeNode parentFocusScope = FocusScopeNode(debugLabel: 'Parent Scope');
    final FocusScopeNode childFocusScope = FocusScopeNode(debugLabel: 'Child Scope');
    final GlobalKey<TestFocusableState> key = GlobalKey();

    // Initially create the focus inside of the parent FocusScope.
    await tester.pumpWidget(
      FocusScope(
        debugLabel: 'Parent Scope',
        node: parentFocusScope,
        autofocus: true,
        child: Column(
          children: <Widget>[
            TestFocusable(
              key: key,
              name: 'a',
              debugLabel: 'Child',
            ),
          ],
        ),
      ),
    );

    expect(key.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('a'), findsOneWidget);
    FocusScope.of(key.currentContext).requestFocus(key.currentState.focusNode);
    await tester.pumpAndSettle();

    expect(key.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);

    expect(parentFocusScope, hasAGoodToStringDeep);
    expect(
      parentFocusScope.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes('FocusScopeNode#00000\n'
          ' │ context: FocusScope\n'
          ' │ FOCUSED\n'
          ' │ debugLabel: "Parent Scope"\n'
          ' │ focusedChild: FocusNode#00000\n'
          ' │\n'
          ' └─child 1: FocusNode#00000\n'
          '     FOCUSED\n'
          '     debugLabel: "Child"\n'),
    );

    expect(WidgetsBinding.instance.focusManager.rootScope, hasAGoodToStringDeep);
    expect(
      WidgetsBinding.instance.focusManager.rootScope.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes('FocusScopeNode#00000\n'
          ' │ FOCUSED\n'
          ' │ debugLabel: "Root Focus Scope"\n'
          ' │ focusedChild: FocusScopeNode#00000\n'
          ' │\n'
          ' └─child 1: FocusScopeNode#00000\n'
          '   │ context: FocusScope\n'
          '   │ FOCUSED\n'
          '   │ debugLabel: "Parent Scope"\n'
          '   │ focusedChild: FocusNode#00000\n'
          '   │\n'
          '   └─child 1: FocusNode#00000\n'
          '       FOCUSED\n'
          '       debugLabel: "Child"\n'),
    );

    // Add the child focus scope to the focus tree.
    parentFocusScope.setFirstFocus(childFocusScope);
    await tester.pumpAndSettle();
    expect(childFocusScope.isFirstFocus, isTrue);

    // Now add the child focus scope with no child node in it to the tree.
    await tester.pumpWidget(
      FocusScope(
        debugLabel: 'Parent Scope',
        node: parentFocusScope,
        child: Column(
          children: <Widget>[
            TestFocusable(
              key: key,
              debugLabel: 'Child',
            ),
            FocusScope(
              debugLabel: 'Child Scope',
              node: childFocusScope,
              child: Container(),
            ),
          ],
        ),
      ),
    );

    expect(key.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('a'), findsOneWidget);

    // Now move the existing focus node into the child focus scope.
    await tester.pumpWidget(
      FocusScope(
        node: parentFocusScope,
        child: Column(
          children: <Widget>[
            FocusScope(
              node: childFocusScope,
              child: TestFocusable(key: key),
            ),
          ],
        ),
      ),
    );

    key.currentState.focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(key.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);

    // Now remove the child focus scope.
    await tester.pumpWidget(
      FocusScope(
        node: parentFocusScope,
        child: Column(
          children: <Widget>[
            TestFocusable(key: key),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(key.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
  });

  // Arguably, this isn't correct behavior, but it is what happens now.
  testWidgets("Removing focused widget doesn't move focus to next widget", (WidgetTester tester) async {
    final GlobalKey<TestFocusableState> keyA = GlobalKey();
    final GlobalKey<TestFocusableState> keyB = GlobalKey();

    await tester.pumpWidget(
      Column(
        children: <Widget>[
          TestFocusable(
            key: keyA,
            name: 'a',
          ),
          TestFocusable(
            key: keyB,
            name: 'b',
          ),
        ],
      ),
    );

    FocusScope.of(keyA.currentContext).requestFocus(keyA.currentState.focusNode);

    await tester.pumpAndSettle();

    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);

    await tester.pumpWidget(
      Column(
        children: <Widget>[
          TestFocusable(
            key: keyB,
            name: 'b',
          ),
        ],
      ),
    );

    await tester.pump();

    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);
  });

  testWidgets('Adding a new FocusScope attaches the child it to its parent.', (WidgetTester tester) async {
    final GlobalKey<TestFocusableState> keyA = GlobalKey();
    final FocusScopeNode parentFocusScope = FocusScopeNode();
    final FocusScopeNode childFocusScope = FocusScopeNode();

    await tester.pumpWidget(
      FocusScope(
        node: childFocusScope,
        child: TestFocusable(
          key: keyA,
        ),
      ),
    );

    WidgetsBinding.instance.focusManager.rootScope.setFirstFocus(FocusScope.of(keyA.currentContext));
    FocusScope.of(keyA.currentContext).requestFocus(keyA.currentState.focusNode);

    await tester.pumpAndSettle();

    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(childFocusScope.isFirstFocus, isTrue);

    await tester.pumpWidget(
      FocusScope(
        node: parentFocusScope,
        child: FocusScope(
          node: childFocusScope,
          child: TestFocusable(
            key: keyA,
          ),
        ),
      ),
    );

    await tester.pump();
    expect(childFocusScope.isFirstFocus, isTrue);
    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
  });

  // Arguably, this isn't correct behavior, but it is what happens now.
  testWidgets("Removing focused widget doesn't move focus to next widget within FocusScope", (WidgetTester tester) async {
    final GlobalKey<TestFocusableState> keyA = GlobalKey();
    final GlobalKey<TestFocusableState> keyB = GlobalKey();
    final FocusScopeNode parentFocusScope = FocusScopeNode(debugLabel: 'Parent Scope');

    await tester.pumpWidget(
      FocusScope(
        debugLabel: 'Parent Scope',
        node: parentFocusScope,
        autofocus: true,
        child: Column(
          children: <Widget>[
            TestFocusable(
              debugLabel: 'Widget A',
              key: keyA,
              name: 'a',
              autofocus: true,
            ),
            TestFocusable(
              debugLabel: 'Widget B',
              key: keyB,
              name: 'b',
            ),
          ],
        ),
      ),
    );

    FocusScope.of(keyA.currentContext).requestFocus(keyA.currentState.focusNode);
    WidgetsBinding.instance.focusManager.rootScope.setFirstFocus(FocusScope.of(keyA.currentContext));

    await tester.pumpAndSettle();

    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);

    await tester.pumpWidget(
      FocusScope(
        node: parentFocusScope,
        child: Column(
          children: <Widget>[
            TestFocusable(
              key: keyB,
              name: 'b',
            ),
          ],
        ),
      ),
    );

    await tester.pump();

    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);
  });

  // By "pinned", it means kept in the tree by a GlobalKey.
  testWidgets('Removing pinned focused scope moves focus to focused widget within next FocusScope', (WidgetTester tester) async {
    final GlobalKey<TestFocusableState> keyA = GlobalKey();
    final GlobalKey<TestFocusableState> keyB = GlobalKey();
    final GlobalKey<TestFocusableState> scopeKeyA = GlobalKey();
    final GlobalKey<TestFocusableState> scopeKeyB = GlobalKey();
    final FocusScopeNode parentFocusScope1 = FocusScopeNode(debugLabel: 'Parent Scope 1');
    final FocusScopeNode parentFocusScope2 = FocusScopeNode(debugLabel: 'Parent Scope 2');

    await tester.pumpWidget(
      Column(
        children: <Widget>[
          FocusScope(
            key: scopeKeyA,
            node: parentFocusScope1,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  debugLabel: 'Child A',
                  key: keyA,
                  name: 'a',
                  autofocus: true,
                ),
              ],
            ),
          ),
          FocusScope(
            key: scopeKeyB,
            node: parentFocusScope2,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  debugLabel: 'Child B',
                  key: keyB,
                  name: 'b',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    FocusScope.of(keyB.currentContext).requestFocus(keyB.currentState.focusNode);
    FocusScope.of(keyA.currentContext).requestFocus(keyA.currentState.focusNode);
    WidgetsBinding.instance.focusManager.rootScope.setFirstFocus(FocusScope.of(keyB.currentContext));
    WidgetsBinding.instance.focusManager.rootScope.setFirstFocus(FocusScope.of(keyA.currentContext));

    await tester.pumpAndSettle();

    expect(FocusScope.of(keyA.currentContext).isFirstFocus, isTrue);
    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);

    // Since the FocusScope widgets are pinned with GlobalKeys, when the first
    // one gets removed, the second one stays registered with the focus
    // manager and ends up getting the focus since it remains as part of the
    // focus tree.
    await tester.pumpWidget(
      Column(
        children: <Widget>[
          FocusScope(
            key: scopeKeyB,
            node: parentFocusScope2,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  key: keyB,
                  name: 'b',
                  autofocus: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await tester.pump();

    expect(keyB.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('B FOCUSED'), findsOneWidget);
  });

  // Arguably, this isn't correct behavior, but it is what happens now.
  testWidgets("Removing unpinned focused scope doesn't move focus to focused widget within next FocusScope", (WidgetTester tester) async {
    final GlobalKey<TestFocusableState> keyA = GlobalKey();
    final GlobalKey<TestFocusableState> keyB = GlobalKey();
    final FocusScopeNode parentFocusScope1 = FocusScopeNode(debugLabel: 'Parent Scope 1');
    final FocusScopeNode parentFocusScope2 = FocusScopeNode(debugLabel: 'Parent Scope 2');

    await tester.pumpWidget(
      Column(
        children: <Widget>[
          FocusScope(
            node: parentFocusScope1,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  debugLabel: 'Child A',
                  key: keyA,
                  name: 'a',
                  autofocus: true,
                ),
              ],
            ),
          ),
          FocusScope(
            node: parentFocusScope2,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  debugLabel: 'Child B',
                  key: keyB,
                  name: 'b',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    FocusScope.of(keyB.currentContext).requestFocus(keyB.currentState.focusNode);
    FocusScope.of(keyA.currentContext).requestFocus(keyA.currentState.focusNode);
    WidgetsBinding.instance.focusManager.rootScope.setFirstFocus(FocusScope.of(keyB.currentContext));
    WidgetsBinding.instance.focusManager.rootScope.setFirstFocus(FocusScope.of(keyA.currentContext));

    await tester.pumpAndSettle();

    expect(FocusScope.of(keyA.currentContext).isFirstFocus, isTrue);
    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);

    // If the FocusScope widgets are not pinned with GlobalKeys, then the first
    // one remains and gets its guts replaced with the parentFocusScope2 and the
    // "B" test widget, and in the process, the focus manager loses track of the
    // focus.
    await tester.pumpWidget(
      Column(
        children: <Widget>[
          FocusScope(
            node: parentFocusScope2,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  key: keyB,
                  name: 'b',
                  autofocus: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(keyB.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('B FOCUSED'), findsOneWidget);
  });

  // Arguably, this isn't correct behavior, but it is what happens now.
  testWidgets('Moving widget from one scope to another does not retain focus', (WidgetTester tester) async {
    final FocusScopeNode parentFocusScope1 = FocusScopeNode();
    final FocusScopeNode parentFocusScope2 = FocusScopeNode();
    final GlobalKey<TestFocusableState> keyA = GlobalKey();
    final GlobalKey<TestFocusableState> keyB = GlobalKey();

    await tester.pumpWidget(
      Column(
        children: <Widget>[
          FocusScope(
            node: parentFocusScope1,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  key: keyA,
                  name: 'a',
                  autofocus: true,
                ),
              ],
            ),
          ),
          FocusScope(
            node: parentFocusScope2,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  key: keyB,
                  name: 'b',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    FocusScope.of(keyA.currentContext).requestFocus(keyA.currentState.focusNode);
    WidgetsBinding.instance.focusManager.rootScope.setFirstFocus(FocusScope.of(keyA.currentContext));

    await tester.pumpAndSettle();

    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);

    await tester.pumpWidget(
      Column(
        children: <Widget>[
          FocusScope(
            node: parentFocusScope1,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  key: keyB,
                  name: 'b',
                ),
              ],
            ),
          ),
          FocusScope(
            node: parentFocusScope2,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  key: keyA,
                  name: 'a',
                  autofocus: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await tester.pump();

    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);
  });

  // Arguably, this isn't correct behavior, but it is what happens now.
  testWidgets('Moving FocusScopeNodes does not retain focus', (WidgetTester tester) async {
    final FocusScopeNode parentFocusScope1 = FocusScopeNode();
    final FocusScopeNode parentFocusScope2 = FocusScopeNode();
    final GlobalKey<TestFocusableState> keyA = GlobalKey();
    final GlobalKey<TestFocusableState> keyB = GlobalKey();

    await tester.pumpWidget(
      Column(
        children: <Widget>[
          FocusScope(
            node: parentFocusScope1,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  key: keyA,
                  name: 'a',
                  autofocus: true,
                ),
              ],
            ),
          ),
          FocusScope(
            node: parentFocusScope2,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  key: keyB,
                  name: 'b',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    FocusScope.of(keyA.currentContext).requestFocus(keyA.currentState.focusNode);
    WidgetsBinding.instance.focusManager.rootScope.setFirstFocus(FocusScope.of(keyA.currentContext));

    await tester.pumpAndSettle();

    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);

    // This just swaps the FocusScopeNodes that the FocusScopes have in them.
    await tester.pumpWidget(
      Column(
        children: <Widget>[
          FocusScope(
            node: parentFocusScope2,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  key: keyA,
                  name: 'a',
                  autofocus: true,
                ),
              ],
            ),
          ),
          FocusScope(
            node: parentFocusScope1,
            child: Column(
              children: <Widget>[
                TestFocusable(
                  key: keyB,
                  name: 'b',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await tester.pump();

    expect(keyA.currentState.focusNode.hasFocus, isTrue);
    expect(find.text('A FOCUSED'), findsOneWidget);
    expect(keyB.currentState.focusNode.hasFocus, isFalse);
    expect(find.text('b'), findsOneWidget);
  });
}
