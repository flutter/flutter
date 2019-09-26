// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

typedef PostInvokeCallback = void Function({Action action, Intent intent, FocusNode focusNode, ActionDispatcher dispatcher});

class TestAction extends CallbackAction {
  const TestAction({
    @required OnInvokeCallback onInvoke,
  })  : assert(onInvoke != null),
        super(key, onInvoke: onInvoke);

  static const LocalKey key = ValueKey<Type>(TestAction);

  void _testInvoke(FocusNode node, Intent invocation) => invoke(node, invocation);
}

class TestDispatcher extends ActionDispatcher {
  const TestDispatcher({this.postInvoke});

  final PostInvokeCallback postInvoke;

  @override
  bool invokeAction(Action action, Intent intent, {FocusNode focusNode}) {
    final bool result = super.invokeAction(action, intent, focusNode: focusNode);
    postInvoke?.call(action: action, intent: intent, focusNode: focusNode, dispatcher: this);
    return result;
  }
}

class TestDispatcher1 extends TestDispatcher {
  const TestDispatcher1({PostInvokeCallback postInvoke}) : super(postInvoke: postInvoke);
}

void main() {
  test('$Action passes parameters on when invoked.', () {
    bool invoked = false;
    FocusNode passedNode;
    final TestAction action = TestAction(onInvoke: (FocusNode node, Intent invocation) {
      invoked = true;
      passedNode = node;
    });
    final FocusNode testNode = FocusNode(debugLabel: 'Test Node');
    action._testInvoke(testNode, null);
    expect(passedNode, equals(testNode));
    expect(action.intentKey, equals(TestAction.key));
    expect(invoked, isTrue);
  });
  group(ActionDispatcher, () {
    test('$ActionDispatcher invokes actions when asked.', () {
      bool invoked = false;
      FocusNode passedNode;
      const ActionDispatcher dispatcher = ActionDispatcher();
      final FocusNode testNode = FocusNode(debugLabel: 'Test Node');
      final bool result = dispatcher.invokeAction(
        TestAction(
          onInvoke: (FocusNode node, Intent invocation) {
            invoked = true;
            passedNode = node;
          },
        ),
        const Intent(TestAction.key),
        focusNode: testNode,
      );
      expect(passedNode, equals(testNode));
      expect(result, isTrue);
      expect(invoked, isTrue);
    });
  });
  group(Actions, () {
    Intent invokedIntent;
    Action invokedAction;
    FocusNode invokedNode;
    ActionDispatcher invokedDispatcher;

    void collect({Action action, Intent intent, FocusNode focusNode, ActionDispatcher dispatcher}) {
      invokedIntent = intent;
      invokedAction = action;
      invokedNode = focusNode;
      invokedDispatcher = dispatcher;
    }

    void clear() {
      invokedIntent = null;
      invokedAction = null;
      invokedNode = null;
      invokedDispatcher = null;
    }

    setUp(clear);

    testWidgets('$Actions widget can invoke actions with default dispatcher', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      FocusNode passedNode;
      final FocusNode testNode = FocusNode(debugLabel: 'Test Node');

      await tester.pumpWidget(
        Actions(
          actions: <LocalKey, ActionFactory>{
            TestAction.key: () => TestAction(
                  onInvoke: (FocusNode node, Intent invocation) {
                    invoked = true;
                    passedNode = node;
                  },
                ),
          },
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final bool result = Actions.invoke(
        containerKey.currentContext,
        const Intent(TestAction.key),
        focusNode: testNode,
      );
      expect(passedNode, equals(testNode));
      expect(result, isTrue);
      expect(invoked, isTrue);
    });
    testWidgets('$Actions widget can invoke actions with custom dispatcher', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const Intent intent = Intent(TestAction.key);
      FocusNode passedNode;
      final FocusNode testNode = FocusNode(debugLabel: 'Test Node');
      final Action testAction = TestAction(
        onInvoke: (FocusNode node, Intent intent) {
          invoked = true;
          passedNode = node;
        },
      );

      await tester.pumpWidget(
        Actions(
          dispatcher: TestDispatcher(postInvoke: collect),
          actions: <LocalKey, ActionFactory>{
            TestAction.key: () => testAction,
          },
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final bool result = Actions.invoke(
        containerKey.currentContext,
        intent,
        focusNode: testNode,
      );
      expect(passedNode, equals(testNode));
      expect(invokedNode, equals(testNode));
      expect(result, isTrue);
      expect(invoked, isTrue);
      expect(invokedIntent, equals(intent));
    });
    testWidgets('$Actions can invoke actions in ancestor dispatcher', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const Intent intent = Intent(TestAction.key);
      FocusNode passedNode;
      final FocusNode testNode = FocusNode(debugLabel: 'Test Node');
      final Action testAction = TestAction(
        onInvoke: (FocusNode node, Intent invocation) {
          invoked = true;
          passedNode = node;
        },
      );

      await tester.pumpWidget(
        Actions(
          dispatcher: TestDispatcher1(postInvoke: collect),
          actions: <LocalKey, ActionFactory>{
            TestAction.key: () => testAction,
          },
          child: Actions(
            dispatcher: TestDispatcher(postInvoke: collect),
            actions: const <LocalKey, ActionFactory>{},
            child: Container(key: containerKey),
          ),
        ),
      );

      await tester.pump();
      final bool result = Actions.invoke(
        containerKey.currentContext,
        intent,
        focusNode: testNode,
      );
      expect(passedNode, equals(testNode));
      expect(invokedNode, equals(testNode));
      expect(result, isTrue);
      expect(invoked, isTrue);
      expect(invokedIntent, equals(intent));
      expect(invokedAction, equals(testAction));
      expect(invokedDispatcher.runtimeType, equals(TestDispatcher1));
    });
    testWidgets("$Actions can invoke actions in ancestor dispatcher if a lower one isn't specified", (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const Intent intent = Intent(TestAction.key);
      FocusNode passedNode;
      final FocusNode testNode = FocusNode(debugLabel: 'Test Node');
      final Action testAction = TestAction(
        onInvoke: (FocusNode node, Intent invocation) {
          invoked = true;
          passedNode = node;
        },
      );

      await tester.pumpWidget(
        Actions(
          dispatcher: TestDispatcher1(postInvoke: collect),
          actions: <LocalKey, ActionFactory>{
            TestAction.key: () => testAction,
          },
          child: Actions(
            actions: const <LocalKey, ActionFactory>{},
            child: Container(key: containerKey),
          ),
        ),
      );

      await tester.pump();
      final bool result = Actions.invoke(
        containerKey.currentContext,
        intent,
        focusNode: testNode,
      );
      expect(passedNode, equals(testNode));
      expect(invokedNode, equals(testNode));
      expect(result, isTrue);
      expect(invoked, isTrue);
      expect(invokedIntent, equals(intent));
      expect(invokedAction, equals(testAction));
      expect(invokedDispatcher.runtimeType, equals(TestDispatcher1));
    });
    testWidgets('$Actions widget can be found with of', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final ActionDispatcher testDispatcher = TestDispatcher1(postInvoke: collect);

      await tester.pumpWidget(
        Actions(
          dispatcher: testDispatcher,
          actions: const <LocalKey, ActionFactory>{},
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final ActionDispatcher dispatcher = Actions.of(
        containerKey.currentContext,
        nullOk: true,
      );
      expect(dispatcher, equals(testDispatcher));
    });
  });
  group('Diagnostics', () {
    testWidgets('default $Intent debugFillProperties', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      const Intent(ValueKey<String>('foo')).debugFillProperties(builder);

      final List<String> description = builder.properties
        .where((DiagnosticsNode node) {
          return !node.isFiltered(DiagnosticLevel.info);
        })
        .map((DiagnosticsNode node) => node.toString())
        .toList();

      expect(description, equals(<String>['key: [<\'foo\'>]']));
    });
    testWidgets('$CallbackAction debugFillProperties', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      CallbackAction(
        const ValueKey<String>('foo'),
        onInvoke: (FocusNode node, Intent intent) {},
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) {
            return !node.isFiltered(DiagnosticLevel.info);
          })
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description, equals(<String>['intentKey: [<\'foo\'>]']));
    });
    testWidgets('default $Actions debugFillProperties', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Actions(
        actions: const <LocalKey, ActionFactory>{},
        dispatcher: const ActionDispatcher(),
        child: Container(),
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) {
            return !node.isFiltered(DiagnosticLevel.info);
          })
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description[0], equalsIgnoringHashCodes('dispatcher: ActionDispatcher#00000'));
      expect(description[1], equals('actions: {}'));
    });
    testWidgets('$Actions implements debugFillProperties', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Actions(
        key: const ValueKey<String>('foo'),
        dispatcher: const ActionDispatcher(),
        actions: <LocalKey, ActionFactory>{
          const ValueKey<String>('bar'): () => TestAction(onInvoke: (FocusNode node, Intent intent) {}),
        },
        child: Container(key: const ValueKey<String>('baz')),
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) {
            return !node.isFiltered(DiagnosticLevel.info);
          })
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description[0], equalsIgnoringHashCodes('dispatcher: ActionDispatcher#00000'));
      expect(description[1], equals('actions: {[<\'bar\'>]: Closure: () => TestAction}'));
    }, skip: isBrowser);
  });
}
