// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

typedef PostInvokeCallback = void Function({Action<Intent> action, Intent intent, ActionDispatcher dispatcher});

class TestIntent extends Intent {
  const TestIntent();
}

class SecondTestIntent extends TestIntent {
  const SecondTestIntent();
}

class ThirdTestIntent extends SecondTestIntent {
  const ThirdTestIntent();
}

class TestAction extends CallbackAction<TestIntent> {
  TestAction({
    required OnInvokeCallback onInvoke,
  })  : assert(onInvoke != null),
        super(onInvoke: onInvoke);

  @override
  bool isEnabled(TestIntent intent) => enabled;

  bool get enabled => _enabled;
  bool _enabled = true;
  set enabled(bool value) {
    if (_enabled == value) {
      return;
    }
    _enabled = value;
    notifyActionListeners();
  }

  @override
  void addActionListener(ActionListenerCallback listener) {
    super.addActionListener(listener);
    listeners.add(listener);
  }

  @override
  void removeActionListener(ActionListenerCallback listener) {
    super.removeActionListener(listener);
    listeners.remove(listener);
  }
  List<ActionListenerCallback> listeners = <ActionListenerCallback>[];

  void _testInvoke(TestIntent intent) => invoke(intent);
}

class TestDispatcher extends ActionDispatcher {
  const TestDispatcher({this.postInvoke});

  final PostInvokeCallback? postInvoke;

  @override
  Object? invokeAction(Action<Intent> action, Intent intent, [BuildContext? context]) {
    final Object? result = super.invokeAction(action, intent, context);
    postInvoke?.call(action: action, intent: intent, dispatcher: this);
    return result;
  }
}

class TestDispatcher1 extends TestDispatcher {
  const TestDispatcher1({PostInvokeCallback? postInvoke}) : super(postInvoke: postInvoke);
}

void main() {
  testWidgets('CallbackAction passes correct intent when invoked.', (WidgetTester tester) async {
    late Intent passedIntent;
    final TestAction action = TestAction(onInvoke: (Intent intent) {
      passedIntent = intent;
      return true;
    });
    const TestIntent intent = TestIntent();
    action._testInvoke(intent);
    expect(passedIntent, equals(intent));
  });
  group(ActionDispatcher, () {
    testWidgets('ActionDispatcher invokes actions when asked.', (WidgetTester tester) async {
      await tester.pumpWidget(Container());
      bool invoked = false;
      const ActionDispatcher dispatcher = ActionDispatcher();
      final Object? result = dispatcher.invokeAction(
        TestAction(
          onInvoke: (Intent intent) {
            invoked = true;
            return invoked;
          },
        ),
        const TestIntent(),
      );
      expect(result, isTrue);
      expect(invoked, isTrue);
    });
  });
  group(Actions, () {
    Intent? invokedIntent;
    Action<Intent>? invokedAction;
    ActionDispatcher? invokedDispatcher;

    void collect({Action<Intent>? action, Intent? intent, ActionDispatcher? dispatcher}) {
      invokedIntent = intent;
      invokedAction = action;
      invokedDispatcher = dispatcher;
    }

    void clear() {
      invokedIntent = null;
      invokedAction = null;
      invokedDispatcher = null;
    }

    setUp(clear);

    testWidgets('Actions widget can invoke actions with default dispatcher', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (Intent intent) {
                invoked = true;
                return invoked;
              },
            ),
          },
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final Object? result = Actions.invoke(
        containerKey.currentContext!,
        const TestIntent(),
      );
      expect(result, isTrue);
      expect(invoked, isTrue);
    });
    testWidgets('Actions widget can invoke actions with default dispatcher and maybeInvoke', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (Intent intent) {
                invoked = true;
                return invoked;
              },
            ),
          },
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final Object? result = Actions.maybeInvoke(
        containerKey.currentContext!,
        const TestIntent(),
      );
      expect(result, isTrue);
      expect(invoked, isTrue);
    });
    testWidgets('maybeInvoke returns null when no action is found', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (Intent intent) {
                invoked = true;
                return invoked;
              },
            ),
          },
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final Object? result = Actions.maybeInvoke(
        containerKey.currentContext!,
        DoNothingIntent(),
      );
      expect(result, isNull);
      expect(invoked, isFalse);
    });
    testWidgets('invoke throws when no action is found', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (Intent intent) {
                invoked = true;
                return invoked;
              },
            ),
          },
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final Object? result = Actions.maybeInvoke(
        containerKey.currentContext!,
        DoNothingIntent(),
      );
      expect(result, isNull);
      expect(invoked, isFalse);
    });
    testWidgets('Actions widget can invoke actions with custom dispatcher', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const TestIntent intent = TestIntent();
      final Action<Intent> testAction = TestAction(
        onInvoke: (Intent intent) {
          invoked = true;
          return invoked;
        },
      );

      await tester.pumpWidget(
        Actions(
          dispatcher: TestDispatcher(postInvoke: collect),
          actions: <Type, Action<Intent>>{
            TestIntent: testAction,
          },
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final Object? result = Actions.invoke<TestIntent>(
        containerKey.currentContext!,
        intent,
      );
      expect(result, isTrue);
      expect(invoked, isTrue);
      expect(invokedIntent, equals(intent));
    });
    testWidgets('Actions can invoke actions in ancestor dispatcher', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const TestIntent intent = TestIntent();
      final Action<Intent> testAction = TestAction(
        onInvoke: (Intent intent) {
          invoked = true;
          return invoked;
        },
      );

      await tester.pumpWidget(
        Actions(
          dispatcher: TestDispatcher1(postInvoke: collect),
          actions: <Type, Action<Intent>>{
            TestIntent: testAction,
          },
          child: Actions(
            dispatcher: TestDispatcher(postInvoke: collect),
            actions: const <Type, Action<Intent>>{},
            child: Container(key: containerKey),
          ),
        ),
      );

      await tester.pump();
      final Object? result = Actions.invoke<TestIntent>(
        containerKey.currentContext!,
        intent,
      );
      expect(result, isTrue);
      expect(invoked, isTrue);
      expect(invokedIntent, equals(intent));
      expect(invokedAction, equals(testAction));
      expect(invokedDispatcher.runtimeType, equals(TestDispatcher1));
    });
    testWidgets("Actions can invoke actions in ancestor dispatcher if a lower one isn't specified", (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const TestIntent intent = TestIntent();
      final Action<Intent> testAction = TestAction(
        onInvoke: (Intent intent) {
          invoked = true;
          return invoked;
        },
      );

      await tester.pumpWidget(
        Actions(
          dispatcher: TestDispatcher1(postInvoke: collect),
          actions: <Type, Action<Intent>>{
            TestIntent: testAction,
          },
          child: Actions(
            actions: const <Type, Action<Intent>>{},
            child: Container(key: containerKey),
          ),
        ),
      );

      await tester.pump();
      final Object? result = Actions.invoke<TestIntent>(
        containerKey.currentContext!,
        intent,
      );
      expect(result, isTrue);
      expect(invoked, isTrue);
      expect(invokedIntent, equals(intent));
      expect(invokedAction, equals(testAction));
      expect(invokedDispatcher.runtimeType, equals(TestDispatcher1));
    });
    testWidgets('Actions widget can be found with of', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final ActionDispatcher testDispatcher = TestDispatcher1(postInvoke: collect);

      await tester.pumpWidget(
        Actions(
          dispatcher: testDispatcher,
          actions: const <Type, Action<Intent>>{},
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final ActionDispatcher dispatcher = Actions.of(containerKey.currentContext!);
      expect(dispatcher, equals(testDispatcher));
    });
    testWidgets('Action can be found with find', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final ActionDispatcher testDispatcher = TestDispatcher1(postInvoke: collect);
      bool invoked = false;
      final TestAction testAction = TestAction(
        onInvoke: (Intent intent) {
          invoked = true;
          return invoked;
        },
      );
      await tester.pumpWidget(
        Actions(
          dispatcher: testDispatcher,
          actions: <Type, Action<Intent>>{
            TestIntent: testAction,
          },
          child: Actions(
            actions: const <Type, Action<Intent>>{},
            child: Container(key: containerKey),
          ),
        ),
      );

      await tester.pump();
      expect(Actions.find<TestIntent>(containerKey.currentContext!), equals(testAction));
      expect(() => Actions.find<DoNothingIntent>(containerKey.currentContext!), throwsAssertionError);
      expect(Actions.maybeFind<DoNothingIntent>(containerKey.currentContext!), isNull);

      await tester.pumpWidget(
        Actions(
          dispatcher: testDispatcher,
          actions: <Type, Action<Intent>>{
            TestIntent: testAction,
          },
          child: Actions(
            actions: const <Type, Action<Intent>>{},
            child: Container(key: containerKey),
          ),
        ),
      );

      await tester.pump();
      expect(Actions.find<TestIntent>(containerKey.currentContext!), equals(testAction));
      expect(() => Actions.find<DoNothingIntent>(containerKey.currentContext!), throwsAssertionError);
      expect(Actions.maybeFind<DoNothingIntent>(containerKey.currentContext!), isNull);
    });
    testWidgets('FocusableActionDetector keeps track of focus and hover even when disabled.', (WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const Intent intent = TestIntent();
      final FocusNode focusNode = FocusNode(debugLabel: 'Test Node');
      final Action<Intent> testAction = TestAction(
        onInvoke: (Intent intent) {
          invoked = true;
          return invoked;
        },
      );
      bool hovering = false;
      bool focusing = false;

      Future<void> buildTest(bool enabled) async {
        await tester.pumpWidget(
          Center(
            child: Actions(
              dispatcher: TestDispatcher1(postInvoke: collect),
              actions: const <Type, Action<Intent>>{},
              child: FocusableActionDetector(
                enabled: enabled,
                focusNode: focusNode,
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(LogicalKeyboardKey.enter): intent,
                },
                actions: <Type, Action<Intent>>{
                  TestIntent: testAction,
                },
                onShowHoverHighlight: (bool value) => hovering = value,
                onShowFocusHighlight: (bool value) => focusing = value,
                child: SizedBox(width: 100, height: 100, key: containerKey),
              ),
            ),
          ),
        );
        return tester.pump();
      }

      await buildTest(true);
      focusNode.requestFocus();
      await tester.pump();
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byKey(containerKey)));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(hovering, isTrue);
      expect(focusing, isTrue);
      expect(invoked, isTrue);

      invoked = false;
      await buildTest(false);
      expect(hovering, isFalse);
      expect(focusing, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(invoked, isFalse);
      await buildTest(true);
      expect(focusing, isFalse);
      expect(hovering, isTrue);
      await buildTest(false);
      expect(focusing, isFalse);
      expect(hovering, isFalse);
      await gesture.moveTo(Offset.zero);
      await buildTest(true);
      expect(hovering, isFalse);
      expect(focusing, isFalse);
    });
    testWidgets('FocusableActionDetector changes mouse cursor when hovered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.text,
            onShowHoverHighlight: (_) {},
            onShowFocusHighlight: (_) {},
            child: Container(),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
      await gesture.addPointer(location: const Offset(1, 1));
      addTearDown(gesture.removePointer);
      await tester.pump();

      expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

      // Test default
      await tester.pumpWidget(
        MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: FocusableActionDetector(
            onShowHoverHighlight: (_) {},
            onShowFocusHighlight: (_) {},
            child: Container(),
          ),
        ),
      );

      expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.forbidden);
    });
    testWidgets('Actions.invoke returns the value of Action.invoke', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final Object sentinel = Object();
      bool invoked = false;
      const TestIntent intent = TestIntent();
      final Action<Intent> testAction = TestAction(
        onInvoke: (Intent intent) {
          invoked = true;
          return sentinel;
        },
      );

      await tester.pumpWidget(
        Actions(
          dispatcher: TestDispatcher(postInvoke: collect),
          actions: <Type, Action<Intent>>{
            TestIntent: testAction,
          },
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final Object? result = Actions.invoke<TestIntent>(
        containerKey.currentContext!,
        intent,
      );
      expect(identical(result, sentinel), isTrue);
      expect(invoked, isTrue);
    });
    testWidgets('ContextAction can return null', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      const TestIntent intent = TestIntent();
      final TestContextAction testAction = TestContextAction();

      await tester.pumpWidget(
        Actions(
          dispatcher: TestDispatcher1(postInvoke: collect),
          actions: <Type, Action<Intent>>{
            TestIntent: testAction,
          },
          child: Container(key: containerKey),
        ),
      );

      await tester.pump();
      final Object? result = Actions.invoke<TestIntent>(
        containerKey.currentContext!,
        intent,
      );
      expect(result, isNull);
      expect(invokedIntent, equals(intent));
      expect(invokedAction, equals(testAction));
      expect(invokedDispatcher.runtimeType, equals(TestDispatcher1));
      expect(testAction.capturedContexts.single, containerKey.currentContext);
    });
    testWidgets('Disabled actions allow propagation to an ancestor', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const TestIntent intent = TestIntent();
      final TestAction enabledTestAction = TestAction(
        onInvoke: (Intent intent) {
          invoked = true;
          return invoked;
        },
      );
      enabledTestAction.enabled = true;
      final TestAction disabledTestAction = TestAction(
        onInvoke: (Intent intent) {
          invoked = true;
          return invoked;
        },
      );
      disabledTestAction.enabled = false;

      await tester.pumpWidget(
        Actions(
          dispatcher: TestDispatcher1(postInvoke: collect),
          actions: <Type, Action<Intent>>{
            TestIntent: enabledTestAction,
          },
          child: Actions(
            dispatcher: TestDispatcher(postInvoke: collect),
            actions: <Type, Action<Intent>>{
              TestIntent: disabledTestAction,
            },
            child: Container(key: containerKey),
          ),
        ),
      );

      await tester.pump();
      final Object? result = Actions.invoke<TestIntent>(
        containerKey.currentContext!,
        intent,
      );
      expect(result, isTrue);
      expect(invoked, isTrue);
      expect(invokedIntent, equals(intent));
      expect(invokedAction, equals(enabledTestAction));
      expect(invokedDispatcher.runtimeType, equals(TestDispatcher1));
    });
  });

  group('Listening', () {
    testWidgets('can listen to enabled state of Actions', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked1 = false;
      bool invoked2 = false;
      bool invoked3 = false;
      final TestAction action1 = TestAction(
        onInvoke: (Intent intent) {
          invoked1 = true;
          return invoked1;
        },
      );
      final TestAction action2 = TestAction(
        onInvoke: (Intent intent) {
          invoked2 = true;
          return invoked2;
        },
      );
      final TestAction action3 = TestAction(
        onInvoke: (Intent intent) {
          invoked3 = true;
          return invoked3;
        },
      );
      bool enabled1 = true;
      action1.addActionListener((Action<Intent> action) => enabled1 = action.isEnabled(const TestIntent()));
      action1.enabled = false;
      expect(enabled1, isFalse);

      bool enabled2 = true;
      action2.addActionListener((Action<Intent> action) => enabled2 = action.isEnabled(const SecondTestIntent()));
      action2.enabled = false;
      expect(enabled2, isFalse);

      bool enabled3 = true;
      action3.addActionListener((Action<Intent> action) => enabled3 = action.isEnabled(const ThirdTestIntent()));
      action3.enabled = false;
      expect(enabled3, isFalse);

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<TestIntent>>{
            TestIntent: action1,
            SecondTestIntent: action2,
          },
          child: Actions(
            actions: <Type, Action<TestIntent>>{
              ThirdTestIntent: action3,
            },
            child: Container(key: containerKey),
          ),
        ),
      );

      Object? result = Actions.invoke(
        containerKey.currentContext!,
        const TestIntent(),
      );
      expect(enabled1, isFalse);
      expect(result, isNull);
      expect(invoked1, isFalse);

      action1.enabled = true;
      result = Actions.invoke(
        containerKey.currentContext!,
        const TestIntent(),
      );
      expect(enabled1, isTrue);
      expect(result, isTrue);
      expect(invoked1, isTrue);

      bool? enabledChanged;
      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: action1,
            SecondTestIntent: action2,
          },
          child: ActionListener(
            listener: (Action<Intent> action) => enabledChanged = action.isEnabled(const ThirdTestIntent()),
            action: action2,
            child: Actions(
              actions: <Type, Action<Intent>>{
                ThirdTestIntent: action3,
              },
              child: Container(key: containerKey),
            ),
          ),
        ),
      );

      await tester.pump();
      result = Actions.invoke<TestIntent>(
        containerKey.currentContext!,
        const SecondTestIntent(),
      );
      expect(enabledChanged, isNull);
      expect(enabled2, isFalse);
      expect(result, isNull);
      expect(invoked2, isFalse);

      action2.enabled = true;
      expect(enabledChanged, isTrue);
      result = Actions.invoke<TestIntent>(
        containerKey.currentContext!,
        const SecondTestIntent(),
      );
      expect(enabled2, isTrue);
      expect(result, isTrue);
      expect(invoked2, isTrue);

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: action1,
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              ThirdTestIntent: action3,
            },
            child: Container(key: containerKey),
          ),
        ),
      );

      expect(action1.listeners.length, equals(2));
      expect(action2.listeners.length, equals(1));
      expect(action3.listeners.length, equals(2));

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: action1,
            ThirdTestIntent: action3,
          },
          child: Container(key: containerKey),
        ),
      );

      expect(action1.listeners.length, equals(2));
      expect(action2.listeners.length, equals(1));
      expect(action3.listeners.length, equals(2));

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: action1,
          },
          child: Container(key: containerKey),
        ),
      );

      expect(action1.listeners.length, equals(2));
      expect(action2.listeners.length, equals(1));
      expect(action3.listeners.length, equals(1));

      await tester.pumpWidget(Container());
      await tester.pump();

      expect(action1.listeners.length, equals(1));
      expect(action2.listeners.length, equals(1));
      expect(action3.listeners.length, equals(1));
    });
  });

  group(FocusableActionDetector, () {
    const Intent intent = TestIntent();
    late bool invoked;
    late bool hovering;
    late bool focusing;
    late FocusNode focusNode;
    late Action<Intent> testAction;

    Future<void> pumpTest(
        WidgetTester tester, {
          bool enabled = true,
          bool directional = false,
          bool supplyCallbacks = true,
          required Key key,
        }) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            navigationMode: directional ? NavigationMode.directional : NavigationMode.traditional,
          ),
          child: Center(
            child: Actions(
              dispatcher: const TestDispatcher1(),
              actions: const <Type, Action<Intent>>{},
              child: FocusableActionDetector(
                enabled: enabled,
                focusNode: focusNode,
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(LogicalKeyboardKey.enter): intent,
                },
                actions: <Type, Action<Intent>>{
                  TestIntent: testAction,
                },
                onShowHoverHighlight: supplyCallbacks ? (bool value) => hovering = value : null,
                onShowFocusHighlight: supplyCallbacks ? (bool value) => focusing = value : null,
                child: SizedBox(width: 100, height: 100, key: key),
              ),
            ),
          ),
        ),
      );
      return tester.pump();
    }

    setUp(() async {
      invoked = false;
      hovering = false;
      focusing = false;

      focusNode = FocusNode(debugLabel: 'Test Node');
      testAction = TestAction(
        onInvoke: (Intent intent) {
          invoked = true;
          return invoked;
        },
      );
    });

    testWidgets('FocusableActionDetector keeps track of focus and hover even when disabled.', (WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      final GlobalKey containerKey = GlobalKey();

      await pumpTest(tester, enabled: true, key: containerKey);
      focusNode.requestFocus();
      await tester.pump();
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byKey(containerKey)));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(hovering, isTrue);
      expect(focusing, isTrue);
      expect(invoked, isTrue);

      invoked = false;
      await pumpTest(tester, enabled: false, key: containerKey);
      expect(hovering, isFalse);
      expect(focusing, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(invoked, isFalse);
      await pumpTest(tester, enabled: true, key: containerKey);
      expect(focusing, isFalse);
      expect(hovering, isTrue);
      await pumpTest(tester, enabled: false, key: containerKey);
      expect(focusing, isFalse);
      expect(hovering, isFalse);
      await gesture.moveTo(Offset.zero);
      await pumpTest(tester, enabled: true, key: containerKey);
      expect(hovering, isFalse);
      expect(focusing, isFalse);
    });
    testWidgets('FocusableActionDetector shows focus highlight appropriately when focused and disabled', (WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      final GlobalKey containerKey = GlobalKey();

      await pumpTest(tester, enabled: true, key: containerKey);
      await tester.pump();
      expect(focusing, isFalse);

      await pumpTest(tester, enabled: true, key: containerKey);
      focusNode.requestFocus();
      await tester.pump();
      expect(focusing, isTrue);

      focusing = false;
      await pumpTest(tester, enabled: false, key: containerKey);
      focusNode.requestFocus();
      await tester.pump();
      expect(focusing, isFalse);

      await pumpTest(tester, enabled: false, key: containerKey);
      focusNode.requestFocus();
      await tester.pump();
      expect(focusing, isFalse);

      // In directional navigation, focus should show, even if disabled.
      await pumpTest(tester, enabled: false, key: containerKey, directional: true);
      focusNode.requestFocus();
      await tester.pump();
      expect(focusing, isTrue);
    });
    testWidgets('FocusableActionDetector can be used without callbacks', (WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      final GlobalKey containerKey = GlobalKey();

      await pumpTest(tester, enabled: true, key: containerKey, supplyCallbacks: false);
      focusNode.requestFocus();
      await tester.pump();
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byKey(containerKey)));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(hovering, isFalse);
      expect(focusing, isFalse);
      expect(invoked, isTrue);

      invoked = false;
      await pumpTest(tester, enabled: false, key: containerKey, supplyCallbacks: false);
      expect(hovering, isFalse);
      expect(focusing, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(invoked, isFalse);
      await pumpTest(tester, enabled: true, key: containerKey, supplyCallbacks: false);
      expect(focusing, isFalse);
      expect(hovering, isFalse);
      await pumpTest(tester, enabled: false, key: containerKey, supplyCallbacks: false);
      expect(focusing, isFalse);
      expect(hovering, isFalse);
      await gesture.moveTo(Offset.zero);
      await pumpTest(tester, enabled: true, key: containerKey, supplyCallbacks: false);
      expect(hovering, isFalse);
      expect(focusing, isFalse);
    });

    testWidgets(
        'FocusableActionDetector can prevent its descendants from being focusable',
        (WidgetTester tester) async {
      final FocusNode buttonNode = FocusNode(debugLabel: 'Test');

      await tester.pumpWidget(
        MaterialApp(
          home: FocusableActionDetector(
            descendantsAreFocusable: true,
            child: MaterialButton(
              focusNode: buttonNode,
              child: const Text('Test'),
              onPressed: () {},
            ),
          ),
        ),
      );

      // Button is focusable
      expect(buttonNode.hasFocus, isFalse);
      buttonNode.requestFocus();
      await tester.pump();
      expect(buttonNode.hasFocus, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: FocusableActionDetector(
            descendantsAreFocusable: false,
            child: MaterialButton(
              focusNode: buttonNode,
              child: const Text('Test'),
              onPressed: () {},
            ),
          ),
        ),
      );

      // Button is NOT focusable
      expect(buttonNode.hasFocus, isFalse);
      buttonNode.requestFocus();
      await tester.pump();
      expect(buttonNode.hasFocus, isFalse);
    });
  });

  group('Diagnostics', () {
    testWidgets('default Intent debugFillProperties', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      // ignore: invalid_use_of_protected_member
      const TestIntent().debugFillProperties(builder);

      final List<String> description = builder.properties
        .where((DiagnosticsNode node) {
          return !node.isFiltered(DiagnosticLevel.info);
        })
        .map((DiagnosticsNode node) => node.toString())
        .toList();

      expect(description, isEmpty);
    });
    testWidgets('default Actions debugFillProperties', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Actions(
        actions: const <Type, Action<Intent>>{},
        dispatcher: const ActionDispatcher(),
        child: Container(),
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
        .where((DiagnosticsNode node) {
          return !node.isFiltered(DiagnosticLevel.info);
        })
        .map((DiagnosticsNode node) => node.toString())
        .toList();

      expect(description.length, equals(2));
      expect(description[0], equalsIgnoringHashCodes('dispatcher: ActionDispatcher#00000'));
      expect(description[1], equals('actions: {}'));
    });
    testWidgets('Actions implements debugFillProperties', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Actions(
        key: const ValueKey<String>('foo'),
        dispatcher: const ActionDispatcher(),
        actions: <Type, Action<Intent>>{
          TestIntent: TestAction(onInvoke: (Intent intent) => null),
        },
        child: Container(key: const ValueKey<String>('baz')),
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) {
            return !node.isFiltered(DiagnosticLevel.info);
          })
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description.length, equals(2));
      expect(description[0], equalsIgnoringHashCodes('dispatcher: ActionDispatcher#00000'));
      expect(description[1], equalsIgnoringHashCodes('actions: {TestIntent: TestAction#00000}'));
    });
  });
}

class TestContextAction extends ContextAction<TestIntent> {
  List<BuildContext?> capturedContexts = <BuildContext?>[];

  @override
  Object? invoke(covariant TestIntent intent, [BuildContext? context]) {
    capturedContexts.add(context);
    return null;
  }
}
