// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ActionDispatcher, () {
    testWidgets('ActionDispatcher invokes actions when asked.', (final WidgetTester tester) async {
      await tester.pumpWidget(Container());
      bool invoked = false;
      const ActionDispatcher dispatcher = ActionDispatcher();
      final Object? result = dispatcher.invokeAction(
        TestAction(
          onInvoke: (final Intent intent) {
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

    void collect({final Action<Intent>? action, final Intent? intent, final ActionDispatcher? dispatcher}) {
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

    testWidgets('Actions widget can invoke actions with default dispatcher', (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (final Intent intent) {
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

    testWidgets('Actions widget can invoke actions with default dispatcher and maybeInvoke', (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (final Intent intent) {
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

    testWidgets('maybeInvoke returns null when no action is found', (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (final Intent intent) {
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
        const DoNothingIntent(),
      );
      expect(result, isNull);
      expect(invoked, isFalse);
    });

    testWidgets('invoke throws when no action is found', (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (final Intent intent) {
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
        const DoNothingIntent(),
      );
      expect(result, isNull);
      expect(invoked, isFalse);
    });

    testWidgets('Actions widget can invoke actions with custom dispatcher', (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const TestIntent intent = TestIntent();
      final Action<Intent> testAction = TestAction(
        onInvoke: (final Intent intent) {
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

    testWidgets('Actions can invoke actions in ancestor dispatcher', (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const TestIntent intent = TestIntent();
      final Action<Intent> testAction = TestAction(
        onInvoke: (final Intent intent) {
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

    testWidgets("Actions can invoke actions in ancestor dispatcher if a lower one isn't specified", (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const TestIntent intent = TestIntent();
      final Action<Intent> testAction = TestAction(
        onInvoke: (final Intent intent) {
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

    testWidgets('Actions widget can be found with of', (final WidgetTester tester) async {
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

    testWidgets('Action can be found with find', (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final ActionDispatcher testDispatcher = TestDispatcher1(postInvoke: collect);
      bool invoked = false;
      final TestAction testAction = TestAction(
        onInvoke: (final Intent intent) {
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

    testWidgets('FocusableActionDetector keeps track of focus and hover even when disabled.', (final WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const Intent intent = TestIntent();
      final FocusNode focusNode = FocusNode(debugLabel: 'Test Node');
      final Action<Intent> testAction = TestAction(
        onInvoke: (final Intent intent) {
          invoked = true;
          return invoked;
        },
      );
      bool hovering = false;
      bool focusing = false;

      Future<void> buildTest(final bool enabled) async {
        await tester.pumpWidget(
          Center(
            child: Actions(
              dispatcher: TestDispatcher1(postInvoke: collect),
              actions: const <Type, Action<Intent>>{},
              child: FocusableActionDetector(
                enabled: enabled,
                focusNode: focusNode,
                shortcuts: const <ShortcutActivator, Intent>{
                  SingleActivator(LogicalKeyboardKey.enter): intent,
                },
                actions: <Type, Action<Intent>>{
                  TestIntent: testAction,
                },
                onShowHoverHighlight: (final bool value) => hovering = value,
                onShowFocusHighlight: (final bool value) => focusing = value,
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

    testWidgets('FocusableActionDetector changes mouse cursor when hovered', (final WidgetTester tester) async {
      await tester.pumpWidget(
        MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.text,
            onShowHoverHighlight: (final _) {},
            onShowFocusHighlight: (final _) {},
            child: Container(),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
      await gesture.addPointer(location: const Offset(1, 1));
      await tester.pump();

      expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

      // Test default
      await tester.pumpWidget(
        MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: FocusableActionDetector(
            onShowHoverHighlight: (final _) {},
            onShowFocusHighlight: (final _) {},
            child: Container(),
          ),
        ),
      );

      expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.forbidden);
    });

    testWidgets('Actions.invoke returns the value of Action.invoke', (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final Object sentinel = Object();
      bool invoked = false;
      const TestIntent intent = TestIntent();
      final Action<Intent> testAction = TestAction(
        onInvoke: (final Intent intent) {
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

    testWidgets('ContextAction can return null', (final WidgetTester tester) async {
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

    testWidgets('Disabled actions stop propagation to an ancestor', (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked = false;
      const TestIntent intent = TestIntent();
      final TestAction enabledTestAction = TestAction(
        onInvoke: (final Intent intent) {
          invoked = true;
          return invoked;
        },
      );
      enabledTestAction.enabled = true;
      final TestAction disabledTestAction = TestAction(
        onInvoke: (final Intent intent) {
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
      expect(result, isNull);
      expect(invoked, isFalse);
      expect(invokedIntent, isNull);
      expect(invokedAction, isNull);
      expect(invokedDispatcher, isNull);
    });
  });

  group('Listening', () {
    testWidgets('can listen to enabled state of Actions', (final WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      bool invoked1 = false;
      bool invoked2 = false;
      bool invoked3 = false;
      final TestAction action1 = TestAction(
        onInvoke: (final Intent intent) {
          invoked1 = true;
          return invoked1;
        },
      );
      final TestAction action2 = TestAction(
        onInvoke: (final Intent intent) {
          invoked2 = true;
          return invoked2;
        },
      );
      final TestAction action3 = TestAction(
        onInvoke: (final Intent intent) {
          invoked3 = true;
          return invoked3;
        },
      );
      bool enabled1 = true;
      action1.addActionListener((final Action<Intent> action) => enabled1 = action.isEnabled(const TestIntent()));
      action1.enabled = false;
      expect(enabled1, isFalse);

      bool enabled2 = true;
      action2.addActionListener((final Action<Intent> action) => enabled2 = action.isEnabled(const SecondTestIntent()));
      action2.enabled = false;
      expect(enabled2, isFalse);

      bool enabled3 = true;
      action3.addActionListener((final Action<Intent> action) => enabled3 = action.isEnabled(const ThirdTestIntent()));
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

      Object? result = Actions.maybeInvoke(
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
            listener: (final Action<Intent> action) => enabledChanged = action.isEnabled(const ThirdTestIntent()),
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
      result = Actions.maybeInvoke<TestIntent>(
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
        final WidgetTester tester, {
          final bool enabled = true,
          final bool directional = false,
          final bool supplyCallbacks = true,
          required final Key key,
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
                shortcuts: const <ShortcutActivator, Intent>{
                  SingleActivator(LogicalKeyboardKey.enter): intent,
                },
                actions: <Type, Action<Intent>>{
                  TestIntent: testAction,
                },
                onShowHoverHighlight: supplyCallbacks ? (final bool value) => hovering = value : null,
                onShowFocusHighlight: supplyCallbacks ? (final bool value) => focusing = value : null,
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
        onInvoke: (final Intent intent) {
          invoked = true;
          return invoked;
        },
      );
    });

    testWidgets('FocusableActionDetector keeps track of focus and hover even when disabled.', (final WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      final GlobalKey containerKey = GlobalKey();

      await pumpTest(tester, key: containerKey);
      focusNode.requestFocus();
      await tester.pump();
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
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
      await pumpTest(tester, key: containerKey);
      expect(focusing, isFalse);
      expect(hovering, isTrue);
      await pumpTest(tester, enabled: false, key: containerKey);
      expect(focusing, isFalse);
      expect(hovering, isFalse);
      await gesture.moveTo(Offset.zero);
      await pumpTest(tester, key: containerKey);
      expect(hovering, isFalse);
      expect(focusing, isFalse);
    });

    testWidgets('FocusableActionDetector shows focus highlight appropriately when focused and disabled', (final WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      final GlobalKey containerKey = GlobalKey();

      await pumpTest(tester, key: containerKey);
      await tester.pump();
      expect(focusing, isFalse);

      await pumpTest(tester, key: containerKey);
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

    testWidgets('FocusableActionDetector can be used without callbacks', (final WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      final GlobalKey containerKey = GlobalKey();

      await pumpTest(tester, key: containerKey, supplyCallbacks: false);
      focusNode.requestFocus();
      await tester.pump();
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
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
      await pumpTest(tester, key: containerKey, supplyCallbacks: false);
      expect(focusing, isFalse);
      expect(hovering, isFalse);
      await pumpTest(tester, enabled: false, key: containerKey, supplyCallbacks: false);
      expect(focusing, isFalse);
      expect(hovering, isFalse);
      await gesture.moveTo(Offset.zero);
      await pumpTest(tester, key: containerKey, supplyCallbacks: false);
      expect(hovering, isFalse);
      expect(focusing, isFalse);
    });

    testWidgets(
      'FocusableActionDetector can prevent its descendants from being focusable',
      (final WidgetTester tester) async {
        final FocusNode buttonNode = FocusNode(debugLabel: 'Test');

        await tester.pumpWidget(
          MaterialApp(
            home: FocusableActionDetector(
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
      },
    );

    testWidgets(
      'FocusableActionDetector can prevent its descendants from being traversable',
          (final WidgetTester tester) async {
        final FocusNode buttonNode1 = FocusNode(debugLabel: 'Button Node 1');
        final FocusNode buttonNode2 = FocusNode(debugLabel: 'Button Node 2');

        await tester.pumpWidget(
          MaterialApp(
            home: FocusableActionDetector(
              child: Column(
                children: <Widget>[
                  MaterialButton(
                    focusNode: buttonNode1,
                    child: const Text('Node 1'),
                    onPressed: () {},
                  ),
                  MaterialButton(
                    focusNode: buttonNode2,
                    child: const Text('Node 2'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        buttonNode1.requestFocus();
        await tester.pump();
        expect(buttonNode1.hasFocus, isTrue);
        expect(buttonNode2.hasFocus, isFalse);
        primaryFocus!.nextFocus();
        await tester.pump();
        expect(buttonNode1.hasFocus, isFalse);
        expect(buttonNode2.hasFocus, isTrue);

        await tester.pumpWidget(
          MaterialApp(
            home: FocusableActionDetector(
              descendantsAreTraversable: false,
              child: Column(
                children: <Widget>[
                  MaterialButton(
                    focusNode: buttonNode1,
                    child: const Text('Node 1'),
                    onPressed: () {},
                  ),
                  MaterialButton(
                    focusNode: buttonNode2,
                    child: const Text('Node 2'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        buttonNode1.requestFocus();
        await tester.pump();
        expect(buttonNode1.hasFocus, isTrue);
        expect(buttonNode2.hasFocus, isFalse);
        primaryFocus!.nextFocus();
        await tester.pump();
        expect(buttonNode1.hasFocus, isTrue);
        expect(buttonNode2.hasFocus, isFalse);
      },
    );

    testWidgets('FocusableActionDetector can exclude Focus semantics', (final WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FocusableActionDetector(
            child: Column(
              children: <Widget>[
                TextButton(
                  onPressed: () {},
                  child: const Text('Button 1'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Button 2'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(FocusableActionDetector)),
        matchesSemantics(
          scopesRoute: true,
          children: <Matcher>[
            // This semantic is from `Focus` widget under `FocusableActionDetector`.
            matchesSemantics(
              isFocusable: true,
              children: <Matcher>[
                matchesSemantics(
                  hasTapAction: true,
                  isButton: true,
                  hasEnabledState: true,
                  isEnabled: true,
                  isFocusable: true,
                  label: 'Button 1',
                  textDirection: TextDirection.ltr,
                ),
                matchesSemantics(
                  hasTapAction: true,
                  isButton: true,
                  hasEnabledState: true,
                  isEnabled: true,
                  isFocusable: true,
                  label: 'Button 2',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      );

      // Set `includeFocusSemantics` to false to exclude semantics
      // from `Focus` widget under `FocusableActionDetector`.
      await tester.pumpWidget(
        MaterialApp(
          home: FocusableActionDetector(
            includeFocusSemantics: false,
            child: Column(
              children: <Widget>[
                TextButton(
                  onPressed: () {},
                  child: const Text('Button 1'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Button 2'),
                ),
              ],
            ),
          ),
        ),
      );

      // Semantics from the `Focus` widget will be removed.
      expect(
        tester.getSemantics(find.byType(FocusableActionDetector)),
        matchesSemantics(
          scopesRoute: true,
          children: <Matcher>[
            matchesSemantics(
              hasTapAction: true,
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              isFocusable: true,
              label: 'Button 1',
              textDirection: TextDirection.ltr,
            ),
            matchesSemantics(
              hasTapAction: true,
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              isFocusable: true,
              label: 'Button 2',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      );
    });
  });

  group('Action subclasses', () {
    testWidgets('CallbackAction passes correct intent when invoked.', (final WidgetTester tester) async {
      late Intent passedIntent;
      final TestAction action = TestAction(onInvoke: (final Intent intent) {
        passedIntent = intent;
        return true;
      });
      const TestIntent intent = TestIntent();
      action._testInvoke(intent);
      expect(passedIntent, equals(intent));
    });

    testWidgets('VoidCallbackAction', (final WidgetTester tester) async {
      bool called = false;
      void testCallback() {
        called = true;
      }
      final VoidCallbackAction action = VoidCallbackAction();
      final VoidCallbackIntent intent = VoidCallbackIntent(testCallback);
      action.invoke(intent);
      expect(called, isTrue);
    });
    testWidgets('Base Action class default toKeyEventResult delegates to consumesKey', (final WidgetTester tester) async {
      expect(
        DefaultToKeyEventResultAction(consumesKey: false).toKeyEventResult(const DefaultToKeyEventResultIntent(), null),
        KeyEventResult.skipRemainingHandlers,
      );
      expect(
        DefaultToKeyEventResultAction(consumesKey: true).toKeyEventResult(const DefaultToKeyEventResultIntent(), null),
        KeyEventResult.handled,
      );
    });
  });

  group('Diagnostics', () {
    testWidgets('default Intent debugFillProperties', (final WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      // ignore: invalid_use_of_protected_member
      const TestIntent().debugFillProperties(builder);

      final List<String> description = builder.properties
        .where((final DiagnosticsNode node) {
          return !node.isFiltered(DiagnosticLevel.info);
        })
        .map((final DiagnosticsNode node) => node.toString())
        .toList();

      expect(description, isEmpty);
    });

    testWidgets('default Actions debugFillProperties', (final WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Actions(
        actions: const <Type, Action<Intent>>{},
        dispatcher: const ActionDispatcher(),
        child: Container(),
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
        .where((final DiagnosticsNode node) {
          return !node.isFiltered(DiagnosticLevel.info);
        })
        .map((final DiagnosticsNode node) => node.toString())
        .toList();

      expect(description.length, equals(2));
      expect(
        description,
        equalsIgnoringHashCodes(<String>[
          'dispatcher: ActionDispatcher#00000',
          'actions: {}',
        ]),
      );
    });

    testWidgets('Actions implements debugFillProperties', (final WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Actions(
        key: const ValueKey<String>('foo'),
        dispatcher: const ActionDispatcher(),
        actions: <Type, Action<Intent>>{
          TestIntent: TestAction(onInvoke: (final Intent intent) => null),
        },
        child: Container(key: const ValueKey<String>('baz')),
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((final DiagnosticsNode node) {
            return !node.isFiltered(DiagnosticLevel.info);
          })
          .map((final DiagnosticsNode node) => node.toString())
          .toList();

      expect(description.length, equals(2));
      expect(
        description,
        equalsIgnoringHashCodes(<String>[
          'dispatcher: ActionDispatcher#00000',
          'actions: {TestIntent: TestAction#00000}',
        ]),
      );
    });
  });

  group('Action overriding', () {
    final List<String> invocations = <String>[];
    BuildContext? invokingContext;

    tearDown(() {
      invocations.clear();
      invokingContext = null;
    });

    testWidgets('Basic usage', (final WidgetTester tester) async {
      late BuildContext invokingContext2;
      late BuildContext invokingContext3;
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent : Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1'), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  invokingContext2 = context2;
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent : Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action2'), context: context2),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        invokingContext3 = context3;
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3'), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      expect(invocations, <String>[
        'action1.invokeAsOverride-pre-super',
        'action2.invokeAsOverride-pre-super',
        'action3.invoke',
        'action2.invokeAsOverride-post-super',
        'action1.invokeAsOverride-post-super',
      ]);

      invocations.clear();
      // Invoke from a different (higher) context.
      Actions.invoke(invokingContext3, LogIntent(log: invocations));
      expect(invocations, <String>[
        'action1.invokeAsOverride-pre-super',
        'action2.invoke',
        'action1.invokeAsOverride-post-super',
      ]);

      invocations.clear();
      // Invoke from a different (higher) context.
      Actions.invoke(invokingContext2, LogIntent(log: invocations));
      expect(invocations, <String>['action1.invoke']);
    });

    testWidgets('Does not break after use', (final WidgetTester tester) async {
      late BuildContext invokingContext2;
      late BuildContext invokingContext3;
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1'), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  invokingContext2 = context2;
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action2'), context: context2),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        invokingContext3 = context3;
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3'), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      // Invoke a bunch of times and verify it still produces the same result.
      final List<BuildContext> randomContexts = <BuildContext>[
        invokingContext!,
        invokingContext2,
        invokingContext!,
        invokingContext3,
        invokingContext3,
        invokingContext3,
        invokingContext2,
      ];

      for (final BuildContext randomContext in randomContexts) {
        Actions.invoke(randomContext, LogIntent(log: invocations));
      }

      invocations.clear();
      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      expect(invocations, <String>[
        'action1.invokeAsOverride-pre-super',
        'action2.invokeAsOverride-pre-super',
        'action3.invoke',
        'action2.invokeAsOverride-post-super',
        'action1.invokeAsOverride-post-super',
      ]);
    });

    testWidgets('Does not override if not overridable', (final WidgetTester tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1'), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  return Actions(
                    actions: <Type, Action<Intent>> { LogIntent : LogInvocationAction(actionName: 'action2') },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3'), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      expect(invocations, <String>[
        'action2.invokeAsOverride-pre-super',
        'action3.invoke',
        'action2.invokeAsOverride-post-super',
      ]);
    });

    testWidgets('The final override controls isEnabled', (final WidgetTester tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1'), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action2', enabled: false), context: context2),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3'), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      expect(invocations, <String>[
        'action1.invokeAsOverride-pre-super',
        'action2.invokeAsOverride-pre-super',
        'action3.invoke',
        'action2.invokeAsOverride-post-super',
        'action1.invokeAsOverride-post-super',
      ]);

      invocations.clear();
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1', enabled: false), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action2'), context: context2),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3'), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      expect(invocations, <String>[]);
    });

    testWidgets('The override can choose to defer isActionEnabled to the overridable', (final WidgetTester tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationButDeferIsEnabledAction(actionName: 'action1'), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action2', enabled: false), context: context2),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3'), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      // Nothing since the final override defers its isActionEnabled state to action2,
      // which is disabled.
      expect(invocations, <String>[]);

      invocations.clear();
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1'), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationButDeferIsEnabledAction(actionName: 'action2'), context: context2),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3', enabled: false), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      // The final override (action1) is enabled so all 3 actions are enabled.
      expect(invocations, <String>[
        'action1.invokeAsOverride-pre-super',
        'action2.invokeAsOverride-pre-super',
        'action3.invoke',
        'action2.invokeAsOverride-post-super',
        'action1.invokeAsOverride-post-super',
      ]);
    });

    testWidgets('Throws on infinite recursions', (final WidgetTester tester) async {
      late StateSetter setState;
      BuildContext? action2LookupContext;
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1'), context: context1),
              },
              child: StatefulBuilder(
                builder: (final BuildContext context2, final StateSetter stateSetter) {
                  setState = stateSetter;
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      if (action2LookupContext != null) LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action2'), context: action2LookupContext!),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3'), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      // Let action2 look up its override using a context below itself, so it
      // will find action3 as its override.
      expect(tester.takeException(), isNull);
      setState(() {
        action2LookupContext = invokingContext;
      });

      await tester.pump();
      expect(tester.takeException(), isNull);

      Object? exception;
      try {
        Actions.invoke(invokingContext!, LogIntent(log: invocations));
      } catch (e) {
        exception = e;
      }
      expect(exception?.toString(), contains('debugAssertIsEnabledMutuallyRecursive'));
    });

    testWidgets('Throws on invoking invalid override', (final WidgetTester tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context) {
            return Actions(
              actions: <Type, Action<Intent>> { LogIntent : TestContextAction() },
              child: Builder(
                builder: (final BuildContext context) {
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1'), context: context),
                    },
                    child: Builder(
                      builder: (final BuildContext context1) {
                        invokingContext = context1;
                        return const SizedBox();
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Object? exception;
      try {
        Actions.invoke(invokingContext!, LogIntent(log: invocations));
      } catch (e) {
        exception = e;
      }
      expect(
        exception?.toString(),
        contains('cannot be handled by an Action of runtime type TestContextAction.'),
      );
    });

    testWidgets('Make an overridable action overridable', (final WidgetTester tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1'), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action2'), context: context2),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(
                              defaultAction: Action<LogIntent>.overridable(
                                defaultAction: Action<LogIntent>.overridable(
                                  defaultAction: LogInvocationAction(actionName: 'action3'),
                                  context: context1,
                                ),
                                context: context2,
                              ),
                              context: context3,
                            ),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      expect(invocations, <String>[
        'action1.invokeAsOverride-pre-super',
        'action2.invokeAsOverride-pre-super',
        'action3.invoke',
        'action2.invokeAsOverride-post-super',
        'action1.invokeAsOverride-post-super',
      ]);
    });

    testWidgets('Overriding Actions can change the intent', (final WidgetTester tester) async {
      final List<String> newLogChannel = <String>[];
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1'), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent: Action<LogIntent>.overridable(defaultAction: RedirectOutputAction(actionName: 'action2', newLog: newLogChannel), context: context2),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3'), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      expect(invocations, <String>[
        'action1.invokeAsOverride-pre-super',
        'action1.invokeAsOverride-post-super',
      ]);
      expect(newLogChannel, <String>[
        'action2.invokeAsOverride-pre-super',
        'action3.invoke',
        'action2.invokeAsOverride-post-super',
      ]);
    });

    testWidgets('Override non-context overridable Actions with a ContextAction', (final WidgetTester tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                // The default Action is a ContextAction subclass.
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationContextAction(actionName: 'action1'), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action2', enabled: false), context: context2),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3'), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      expect(invocations, <String>[
        'action1.invokeAsOverride-pre-super',
        'action2.invokeAsOverride-pre-super',
        'action3.invoke',
        'action2.invokeAsOverride-post-super',
        'action1.invokeAsOverride-post-super',
      ]);

      // Action1 is a ContextAction and action2 & action3 are not.
      // They should not lose information.
      expect(LogInvocationContextAction.invokeContext, isNotNull);
      expect(LogInvocationContextAction.invokeContext, invokingContext);
    });

    testWidgets('Override a ContextAction with a regular Action', (final WidgetTester tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context1) {
            return Actions(
              actions: <Type, Action<Intent>> {
                LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action1'), context: context1),
              },
              child: Builder(
                builder: (final BuildContext context2) {
                  return Actions(
                    actions: <Type, Action<Intent>> {
                      LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationContextAction(actionName: 'action2', enabled: false), context: context2),
                    },
                    child: Builder(
                      builder: (final BuildContext context3) {
                        return Actions(
                          actions: <Type, Action<Intent>> {
                            LogIntent: Action<LogIntent>.overridable(defaultAction: LogInvocationAction(actionName: 'action3'), context: context3),
                          },
                          child: Builder(
                            builder: (final BuildContext context4) {
                              invokingContext = context4;
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(invokingContext!, LogIntent(log: invocations));
      expect(invocations, <String>[
        'action1.invokeAsOverride-pre-super',
        'action2.invokeAsOverride-pre-super',
        'action3.invoke',
        'action2.invokeAsOverride-post-super',
        'action1.invokeAsOverride-post-super',
      ]);

      // Action2 is a ContextAction and action1 & action2 are regular actions.
      // Invoking action2 from action3 should still supply a non-null
      // BuildContext.
      expect(LogInvocationContextAction.invokeContext, isNotNull);
      expect(LogInvocationContextAction.invokeContext, invokingContext);
    });
  });
}

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
    required final OnInvokeCallback onInvoke,
  })  : super(onInvoke: onInvoke);

  @override
  bool isEnabled(final TestIntent intent) => enabled;

  bool get enabled => _enabled;
  bool _enabled = true;
  set enabled(final bool value) {
    if (_enabled == value) {
      return;
    }
    _enabled = value;
    notifyActionListeners();
  }

  @override
  void addActionListener(final ActionListenerCallback listener) {
    super.addActionListener(listener);
    listeners.add(listener);
  }

  @override
  void removeActionListener(final ActionListenerCallback listener) {
    super.removeActionListener(listener);
    listeners.remove(listener);
  }
  List<ActionListenerCallback> listeners = <ActionListenerCallback>[];

  void _testInvoke(final TestIntent intent) => invoke(intent);
}

class TestDispatcher extends ActionDispatcher {
  const TestDispatcher({this.postInvoke});

  final PostInvokeCallback? postInvoke;

  @override
  Object? invokeAction(final Action<Intent> action, final Intent intent, [final BuildContext? context]) {
    final Object? result = super.invokeAction(action, intent, context);
    postInvoke?.call(action: action, intent: intent, dispatcher: this);
    return result;
  }
}

class TestDispatcher1 extends TestDispatcher {
  const TestDispatcher1({super.postInvoke});
}

class TestContextAction extends ContextAction<TestIntent> {
  List<BuildContext?> capturedContexts = <BuildContext?>[];

  @override
  void invoke(covariant final TestIntent intent, [final BuildContext? context]) {
    capturedContexts.add(context);
  }
}

class LogIntent extends Intent {
  const LogIntent({ required this.log });

  final List<String> log;
}

class LogInvocationAction extends Action<LogIntent> {
  LogInvocationAction({ required this.actionName, this.enabled = true });

  final String actionName;

  final bool enabled;

  @override
  bool get isActionEnabled => enabled;

  @override
  void invoke(final LogIntent intent) {
    final Action<LogIntent>? callingAction = this.callingAction;
    if (callingAction == null) {
      intent.log.add('$actionName.invoke');
    } else {
      intent.log.add('$actionName.invokeAsOverride-pre-super');
      callingAction.invoke(intent);
      intent.log.add('$actionName.invokeAsOverride-post-super');
    }
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('actionName', actionName));
  }
}

class LogInvocationContextAction extends ContextAction<LogIntent> {
  LogInvocationContextAction({ required this.actionName, this.enabled = true });

  static BuildContext? invokeContext;

  final String actionName;

  final bool enabled;

  @override
  bool get isActionEnabled => enabled;

  @override
  void invoke(final LogIntent intent, [final BuildContext? context]) {
    invokeContext = context;
    final Action<LogIntent>? callingAction = this.callingAction;
    if (callingAction == null) {
      intent.log.add('$actionName.invoke');
    } else {
      intent.log.add('$actionName.invokeAsOverride-pre-super');
      callingAction.invoke(intent);
      intent.log.add('$actionName.invokeAsOverride-post-super');
    }
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('actionName', actionName));
  }
}

class LogInvocationButDeferIsEnabledAction extends LogInvocationAction {
  LogInvocationButDeferIsEnabledAction({ required super.actionName });

  // Defer `isActionEnabled` to the overridable action.
  @override
  bool get isActionEnabled => callingAction?.isActionEnabled ?? false;
}

class RedirectOutputAction extends LogInvocationAction {
  RedirectOutputAction({
      required super.actionName,
      super.enabled,
      required this.newLog,
  });

  final List<String> newLog;

  @override
  void invoke(final LogIntent intent) => super.invoke(LogIntent(log: newLog));
}

class DefaultToKeyEventResultIntent extends Intent {
  const DefaultToKeyEventResultIntent();
}

class DefaultToKeyEventResultAction extends Action<DefaultToKeyEventResultIntent> {
  DefaultToKeyEventResultAction({
    required final bool consumesKey
  }) : _consumesKey = consumesKey;

  final bool _consumesKey;

  @override
  bool consumesKey(final DefaultToKeyEventResultIntent intent) => _consumesKey;

  @override
  void invoke(final DefaultToKeyEventResultIntent intent) {}
}
