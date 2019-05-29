// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAction extends CallbackAction {
  TestAction({
    LocalKey intentKey,
    ActionCallback onInvoke,
  }) : super(intentKey: intentKey, onInvoke: onInvoke);

  void _testInvoke(FocusNode node, Intent invocation) => invoke(node, invocation);
}

void main() {
  test('$Action passes parameters on when invoked.', () {
    bool invoked = false;
    FocusNode passedNode;
    const ValueKey<String> intentKey = ValueKey<String>('dream');
    final TestAction action = TestAction(
        intentKey: intentKey,
        onInvoke: (FocusNode node, Intent invocation) {
          invoked = true;
          passedNode = node;
        });
    final FocusNode testNode = FocusNode(debugLabel: 'Test Node');
    action._testInvoke(testNode, null);
    expect(passedNode, equals(testNode));
    expect(action.intentKey, equals(intentKey));
    expect(invoked, isTrue);
  });
  group(ActionDispatcher, () {
    test('$ActionDispatcher invokes actions when asked.', () {
      const ValueKey<String> intentKey = ValueKey<String>('dream');
      bool invoked = false;
      FocusNode passedNode;
      const ActionDispatcher dispatcher = ActionDispatcher();
      final FocusNode testNode = FocusNode(debugLabel: 'Test Node');
      final bool result = dispatcher.invokeAction(TestAction(
          intentKey: intentKey,
          onInvoke: (FocusNode node, Intent invocation) {
            invoked = true;
            passedNode = node;
          }), const Intent(intentKey), focusNode: testNode);
      expect(passedNode, equals(testNode));
      expect(result, isTrue);
      expect(invoked, isTrue);
    });
  });
}
