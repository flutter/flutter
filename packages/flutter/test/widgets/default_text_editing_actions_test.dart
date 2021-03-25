// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

void main() {
  testWidgets('DoNothingAndStopPropagationTextIntent', (WidgetTester tester) async {
    bool moveSelectionLeftCalled = false;
    bool moveSelectionRightCalled = false;
    final TextEditingController controller = TextEditingController(
      text: 'blah1 blah2',
    );

    // MaterialApp sets up DefaultTextEditingActions and Shortcuts internally.
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.arrowRight): const DoNothingAndStopPropagationTextIntent(),
              },
              child: Actions(
                // These Actions intercept default Intents, set a flag that they
                // were called, and then call through to the default Action.
                actions: <Type, Action<Intent>>{
                  MoveSelectionLeftTextIntent: CallbackAction<MoveSelectionLeftTextIntent>(onInvoke: (Intent intent) {
                    moveSelectionLeftCalled = true;
                    Actions.invoke<MoveSelectionLeftTextIntent>(context, const MoveSelectionLeftTextIntent());
                  }),
                  MoveSelectionRightTextIntent: CallbackAction<MoveSelectionRightTextIntent>(onInvoke: (Intent intent) {
                    moveSelectionRightCalled = true;
                    Actions.invoke<MoveSelectionRightTextIntent>(context, const MoveSelectionRightTextIntent());
                  }),
                },
                child: Center(
                  child: EditableText(
                    controller: controller,
                    focusNode: FocusNode(),
                    style: Typography.material2018(platform: TargetPlatform.android).black.subtitle1!,
                    cursorColor: Colors.blue,
                    backgroundCursorColor: Colors.grey,
                    autofocus: true,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ));

    await tester.pump();
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, 11);

    // The left arrow key calls its custom Action and also works as normal.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, 10);
    expect(moveSelectionLeftCalled, isTrue);
    expect(moveSelectionRightCalled, isFalse);

    // The right arrow key is blocked by DoNothingAndStopPropagationTextIntent.
    moveSelectionLeftCalled = false;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, 10);
    expect(moveSelectionLeftCalled, isFalse);
    expect(moveSelectionRightCalled, isFalse);
  });
}
