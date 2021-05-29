// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class TestLeftIntent extends Intent {}
class TestRightIntent extends Intent {}

void main() {
  testWidgets('DoNothingAndStopPropagationTextIntent', (WidgetTester tester) async {
    bool leftCalled = false;
    bool rightCalled = false;
    final TextEditingController controller = TextEditingController(
      text: 'blah1 blah2',
    );
    final FocusNode focusNodeTarget = FocusNode();
    final FocusNode focusNodeNonTarget = FocusNode();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.arrowLeft): TestLeftIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowRight): TestRightIntent(),
              },
              child: Shortcuts(
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(LogicalKeyboardKey.arrowRight): const DoNothingAndStopPropagationTextIntent(),
                },
                child: Actions(
                  // These Actions intercept default Intents, set a flag that they
                  // were called, and then call through to the default Action.
                  actions: <Type, Action<Intent>>{
                    TestLeftIntent: CallbackAction<TestLeftIntent>(onInvoke: (Intent intent) {
                      leftCalled = true;
                    }),
                    TestRightIntent: CallbackAction<TestRightIntent>(onInvoke: (Intent intent) {
                      rightCalled = true;
                    }),
                  },
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        EditableText(
                          controller: controller,
                          focusNode: focusNodeTarget,
                          style: Typography.material2018(platform: TargetPlatform.android).black.subtitle1!,
                          cursorColor: Colors.blue,
                          backgroundCursorColor: Colors.grey,
                        ),
                        Focus(
                          focusNode: focusNodeNonTarget,
                          child: const Text('focusable'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ));

    // Focus on the EditableText, which is a TextEditingActionTarget.
    focusNodeTarget.requestFocus();
    await tester.pump();
    expect(focusNodeTarget.hasFocus, isTrue);
    expect(focusNodeNonTarget.hasFocus, isFalse);
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, 11);

    // The left arrow key's Action is called.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(leftCalled, isTrue);
    expect(rightCalled, isFalse);
    leftCalled = false;

    // The right arrow key is blocked by DoNothingAndStopPropagationTextIntent.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(rightCalled, isFalse);
    expect(leftCalled, isFalse);

    // Focus on the other node, which is not a TextEditingActionTarget.
    focusNodeNonTarget.requestFocus();
    await tester.pump();
    expect(focusNodeTarget.hasFocus, isFalse);
    expect(focusNodeNonTarget.hasFocus, isTrue);

    // The left arrow key's Action is called as normal.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(leftCalled, isTrue);
    expect(rightCalled, isFalse);
    leftCalled = false;

    // The right arrow key's Action is also called. That's because
    // DoNothingAndStopPropagationTextIntent only applies if a
    // TextEditingActionTarget is currently focused.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(leftCalled, isFalse);
    expect(rightCalled, isTrue);
  });
}
