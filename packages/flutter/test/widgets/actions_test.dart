// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAction extends CallbackAction {
  TestAction({
    String name,
    ActionCallback onInvoke,
  }) : super(name: name, onInvoke: onInvoke);

  void _testInvoke(FocusNode node, ActionTag invocation) => invoke(node, invocation);
}

void main() {
  test('$Action passes parameters on when invoked.', () {
    bool invoked = false;
    FocusNode passedNode;
    final TestAction action = TestAction(
        name: 'dream',
        onInvoke: (FocusNode node, ActionTag invocation) {
          invoked = true;
          passedNode = node;
        });
    final FocusNode testNode = FocusNode(debugLabel: 'Test Node');
    action._testInvoke(testNode, null);
    expect(passedNode, equals(testNode));
    expect(action.name, equals('dream'));
    expect(invoked, isTrue);
  });
  group(ActionDispatcher, () {
    test('$ActionDispatcher invokes actions when asked.', () {
      bool invoked = false;
      FocusNode passedNode;
      final ActionDispatcher dispatcher = ActionDispatcher(actions: <String, ActionFactory>{
        'dream': () => TestAction(
            name: 'dream',
            onInvoke: (FocusNode node, ActionTag invocation) {
              invoked = true;
              passedNode = node;
            })
      });
      final FocusNode testNode = FocusNode(debugLabel: 'Test Node');
      final Action action = dispatcher.invokeAction(const ActionTag('dream'), node: testNode);
      expect(passedNode, equals(testNode));
      expect(action.name, equals('dream'));
      expect(invoked, isTrue);
    });
  });
}
