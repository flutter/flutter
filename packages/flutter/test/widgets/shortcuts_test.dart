// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef PostInvokeCallback = void Function({Action<Intent> action, Intent intent, BuildContext? context, ActionDispatcher dispatcher});

class TestAction extends CallbackAction<Intent> {
  TestAction({
    required OnInvokeCallback onInvoke,
  })  : assert(onInvoke != null),
        super(onInvoke: onInvoke);

  static const LocalKey key = ValueKey<Type>(TestAction);
}

class TestDispatcher extends ActionDispatcher {
  const TestDispatcher({this.postInvoke});

  final PostInvokeCallback? postInvoke;

  @override
  Object? invokeAction(Action<TestIntent> action, Intent intent, [BuildContext? context]) {
    final Object? result = super.invokeAction(action, intent, context);
    postInvoke?.call(action: action, intent: intent, context: context, dispatcher: this);
    return result;
  }
}

/// An activator that accepts down events that has [key] as the logical key.
///
/// This class is used only to tests. It is intentionally designed poorly by
/// returning null in [triggers], and checks [key] in [accepts].
class DumbLogicalActivator extends ShortcutActivator {
  const DumbLogicalActivator(this.key);

  final LogicalKeyboardKey key;

  @override
  Iterable<LogicalKeyboardKey>? get triggers => null;

  @override
  bool accepts(RawKeyEvent event, RawKeyboard state) {
    return event is RawKeyDownEvent
        && event.logicalKey == key;
  }

  /// Returns a short and readable description of the key combination.
  ///
  /// Intended to be used in debug mode for logging purposes. In release mode,
  /// [debugDescribeKeys] returns an empty string.
  @override
  String debugDescribeKeys() {
    String result = '';
    assert(() {
      result = key.keyLabel;
      return true;
    }());
    return result;
  }
}

class TestIntent extends Intent {
  const TestIntent();
}

class TestIntent2 extends Intent {
  const TestIntent2();
}

class TestShortcutManager extends ShortcutManager {
  TestShortcutManager(this.keys);

  List<LogicalKeyboardKey> keys;

  @override
  KeyEventResult handleKeypress(BuildContext context, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      keys.add(event.logicalKey);
    }
    return super.handleKeypress(context, event);
  }
}

Widget activatorTester(
  ShortcutActivator activator,
  ValueSetter<Intent> onInvoke, [
  ShortcutActivator? activator2,
  ValueSetter<Intent>? onInvoke2,
]) {
  final bool hasSecond = activator2 != null && onInvoke2 != null;
  return Actions(
    key: GlobalKey(),
    actions: <Type, Action<Intent>>{
      TestIntent: TestAction(onInvoke: (Intent intent) {
        onInvoke(intent);
        return true;
      }),
      if (hasSecond)
        TestIntent2: TestAction(onInvoke: (Intent intent) {
          onInvoke2(intent);
        return null;
      }),
    },
    child: Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        activator: const TestIntent(),
        if (hasSecond)
          activator2: const TestIntent2(),
      },
      child: const Focus(
        autofocus: true,
        child: SizedBox(width: 100, height: 100),
      ),
    ),
  );
}

void main() {
  group(LogicalKeySet, () {
    test('LogicalKeySet passes parameters correctly.', () {
      final LogicalKeySet set1 = LogicalKeySet(LogicalKeyboardKey.keyA);
      final LogicalKeySet set2 = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
      );
      final LogicalKeySet set3 = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
      );
      final LogicalKeySet set4 = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyD,
      );
      final LogicalKeySet setFromSet = LogicalKeySet.fromSet(<LogicalKeyboardKey>{
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyD,
      });
      expect(
        set1.keys,
        equals(<LogicalKeyboardKey>{
          LogicalKeyboardKey.keyA,
        }),
      );
      expect(
        set2.keys,
        equals(<LogicalKeyboardKey>{
          LogicalKeyboardKey.keyA,
          LogicalKeyboardKey.keyB,
        }),
      );
      expect(
        set3.keys,
        equals(<LogicalKeyboardKey>{
          LogicalKeyboardKey.keyA,
          LogicalKeyboardKey.keyB,
          LogicalKeyboardKey.keyC,
        }),
      );
      expect(
        set4.keys,
        equals(<LogicalKeyboardKey>{
          LogicalKeyboardKey.keyA,
          LogicalKeyboardKey.keyB,
          LogicalKeyboardKey.keyC,
          LogicalKeyboardKey.keyD,
        }),
      );
      expect(
        setFromSet.keys,
        equals(<LogicalKeyboardKey>{
          LogicalKeyboardKey.keyA,
          LogicalKeyboardKey.keyB,
          LogicalKeyboardKey.keyC,
          LogicalKeyboardKey.keyD,
        }),
      );
    });
    test('LogicalKeySet works as a map key.', () {
      final LogicalKeySet set1 = LogicalKeySet(LogicalKeyboardKey.keyA);
      final LogicalKeySet set2 = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyD,
      );
      final LogicalKeySet set3 = LogicalKeySet(
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyA,
      );
      final LogicalKeySet set4 = LogicalKeySet.fromSet(<LogicalKeyboardKey>{
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyA,
      });
      final Map<LogicalKeySet, String> map = <LogicalKeySet, String>{set1: 'one'};
      expect(set2 == set3, isTrue);
      expect(set2 == set4, isTrue);
      expect(set2.hashCode, set3.hashCode);
      expect(set2.hashCode, set4.hashCode);
      expect(map.containsKey(set1), isTrue);
      expect(map.containsKey(LogicalKeySet(LogicalKeyboardKey.keyA)), isTrue);
      expect(
          set2,
          equals(LogicalKeySet.fromSet(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
            LogicalKeyboardKey.keyC,
            LogicalKeyboardKey.keyD,
          })),
      );
    });
    testWidgets('handles two keys', (WidgetTester tester) async {
      int invoked = 0;
      await tester.pumpWidget(activatorTester(
        LogicalKeySet(
          LogicalKeyboardKey.keyC,
          LogicalKeyboardKey.control,
        ),
        (Intent intent) { invoked += 1; },
      ));
      await tester.pump();

      // LCtrl -> KeyC: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 1);
      invoked = 0;

      // KeyC -> LCtrl: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 1);
      invoked = 0;

      // RCtrl -> KeyC: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
      expect(invoked, 1);
      invoked = 0;

      // LCtrl -> LShift -> KeyC: Reject
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, 0);
      invoked = 0;

      // LCtrl -> KeyA -> KeyC: Reject
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      expect(invoked, 0);
      invoked = 0;

      expect(RawKeyboard.instance.keysPressed, isEmpty);
    });

    test('LogicalKeySet.hashCode is stable', () {
      final LogicalKeySet set1 = LogicalKeySet(LogicalKeyboardKey.keyA);
      expect(set1.hashCode, set1.hashCode);

      final LogicalKeySet set2 = LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB);
      expect(set2.hashCode, set2.hashCode);

      final LogicalKeySet set3 = LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC);
      expect(set3.hashCode, set3.hashCode);

      final LogicalKeySet set4 = LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyD);
      expect(set4.hashCode, set4.hashCode);
    });

    test('LogicalKeySet.hashCode is order-independent', () {
      expect(
        LogicalKeySet(LogicalKeyboardKey.keyA).hashCode,
        LogicalKeySet(LogicalKeyboardKey.keyA).hashCode,
      );
      expect(
        LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB).hashCode,
        LogicalKeySet(LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyA).hashCode,
      );
      expect(
        LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC).hashCode,
        LogicalKeySet(LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyA).hashCode,
      );
      expect(
        LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyD).hashCode,
        LogicalKeySet(LogicalKeyboardKey.keyD, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyA).hashCode,
      );
    });

    testWidgets('isActivatedBy works as expected', (WidgetTester tester) async {
      // Collect some key events to use for testing.
      final List<RawKeyEvent> events = <RawKeyEvent>[];
      await tester.pumpWidget(
        Focus(
          autofocus: true,
          onKey: (FocusNode node, RawKeyEvent event) {
            events.add(event);
            return KeyEventResult.ignored;
          },
          child: const SizedBox(),
        ),
      );

      final LogicalKeySet set = LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.control);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      expect(ShortcutActivator.isActivatedBy(set, events[0]), isTrue);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(ShortcutActivator.isActivatedBy(set, events[0]), isFalse);
    });

    test('LogicalKeySet diagnostics work.', () {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
      ).debugFillProperties(builder);

      final List<String> description = builder.properties.where((DiagnosticsNode node) {
        return !node.isFiltered(DiagnosticLevel.info);
      }).map((DiagnosticsNode node) => node.toString()).toList();

      expect(description.length, equals(1));
      expect(description[0], equals('keys: Key A + Key B'));
    });
  });

  group(SingleActivator, () {
    testWidgets('handles Ctrl-C', (WidgetTester tester) async {
      int invoked = 0;
      await tester.pumpWidget(activatorTester(
        const SingleActivator(
          LogicalKeyboardKey.keyC,
          control: true,
        ),
        (Intent intent) { invoked += 1; },
      ));
      await tester.pump();

      // LCtrl -> KeyC: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 1);
      invoked = 0;

      // KeyC -> LCtrl: Reject
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      invoked = 0;

      // LShift -> LCtrl -> KeyC: Reject
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      invoked = 0;

      // With Ctrl-C pressed, KeyA -> Release KeyA: Reject
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      invoked = 0;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      expect(invoked, 0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      invoked = 0;

      // LCtrl -> KeyA -> KeyC: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      invoked = 0;

      // RCtrl -> KeyC: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
      expect(invoked, 1);
      invoked = 0;

      // LCtrl -> RCtrl -> KeyC: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
      expect(invoked, 1);
      invoked = 0;

      // While holding Ctrl-C, press KeyA: Reject
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 1);
      invoked = 0;

      expect(RawKeyboard.instance.keysPressed, isEmpty);
    }, variant: KeySimulatorTransitModeVariant.all());

    testWidgets('handles repeated events', (WidgetTester tester) async {
      int invoked = 0;
      await tester.pumpWidget(activatorTester(
        const SingleActivator(
          LogicalKeyboardKey.keyC,
          control: true,
        ),
        (Intent intent) { invoked += 1; },
      ));
      await tester.pump();

      // LCtrl -> KeyC: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 2);
      invoked = 0;

      expect(RawKeyboard.instance.keysPressed, isEmpty);
    }, variant: KeySimulatorTransitModeVariant.all());

    testWidgets('rejects repeated events if requested', (WidgetTester tester) async {
      int invoked = 0;
      await tester.pumpWidget(activatorTester(
        const SingleActivator(
          LogicalKeyboardKey.keyC,
          control: true,
          includeRepeats: false,
        ),
        (Intent intent) { invoked += 1; },
      ));
      await tester.pump();

      // LCtrl -> KeyC: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 1);
      invoked = 0;

      expect(RawKeyboard.instance.keysPressed, isEmpty);
    }, variant: KeySimulatorTransitModeVariant.all());

    testWidgets('handles Shift-Ctrl-C', (WidgetTester tester) async {
      int invoked = 0;
      await tester.pumpWidget(activatorTester(
        const SingleActivator(
          LogicalKeyboardKey.keyC,
          shift: true,
          control: true,
        ),
        (Intent intent) { invoked += 1; },
      ));
      await tester.pump();

      // LShift -> LCtrl -> KeyC: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, 1);
      invoked = 0;

      // LCtrl -> LShift -> KeyC: Accept
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, 1);
      invoked = 0;

      // LCtrl -> KeyC -> LShift: Reject
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, 0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, 0);
      invoked = 0;

      expect(RawKeyboard.instance.keysPressed, isEmpty);
    });

    testWidgets('isActivatedBy works as expected', (WidgetTester tester) async {
      // Collect some key events to use for testing.
      final List<RawKeyEvent> events = <RawKeyEvent>[];
      await tester.pumpWidget(
        Focus(
          autofocus: true,
          onKey: (FocusNode node, RawKeyEvent event) {
            events.add(event);
            return KeyEventResult.ignored;
          },
          child: const SizedBox(),
        ),
      );

      const SingleActivator singleActivator = SingleActivator(LogicalKeyboardKey.keyA, control: true);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      expect(ShortcutActivator.isActivatedBy(singleActivator, events[1]), isTrue);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(ShortcutActivator.isActivatedBy(singleActivator, events[1]), isFalse);
    });

    group('diagnostics.', () {
      test('single key', () {
        final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

        const SingleActivator(
          LogicalKeyboardKey.keyA,
        ).debugFillProperties(builder);

        final List<String> description = builder.properties.where((DiagnosticsNode node) {
          return !node.isFiltered(DiagnosticLevel.info);
        }).map((DiagnosticsNode node) => node.toString()).toList();

        expect(description.length, equals(1));
        expect(description[0], equals('keys: Key A'));
      });

      test('no repeats', () {
        final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

        const SingleActivator(
          LogicalKeyboardKey.keyA,
          includeRepeats: false,
        ).debugFillProperties(builder);

        final List<String> description = builder.properties.where((DiagnosticsNode node) {
          return !node.isFiltered(DiagnosticLevel.info);
        }).map((DiagnosticsNode node) => node.toString()).toList();

        expect(description.length, equals(2));
        expect(description[0], equals('keys: Key A'));
        expect(description[1], equals('excluding repeats'));
      });

      test('combination', () {
        final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

        const SingleActivator(
          LogicalKeyboardKey.keyA,
          control: true,
          shift: true,
          alt: true,
          meta: true,
        ).debugFillProperties(builder);

        final List<String> description = builder.properties.where((DiagnosticsNode node) {
          return !node.isFiltered(DiagnosticLevel.info);
        }).map((DiagnosticsNode node) => node.toString()).toList();

        expect(description.length, equals(1));
        expect(description[0], equals('keys: Control + Alt + Meta + Shift + Key A'));
      });
    });
  });

  group(Shortcuts, () {
    testWidgets('Default constructed Shortcuts has empty shortcuts', (WidgetTester tester) async {
      final ShortcutManager manager = ShortcutManager();
      expect(manager.shortcuts, isNotNull);
      expect(manager.shortcuts, isEmpty);
      const Shortcuts shortcuts = Shortcuts(shortcuts: <LogicalKeySet, Intent>{}, child: SizedBox());
      await tester.pumpWidget(shortcuts);
      expect(shortcuts.shortcuts, isNotNull);
      expect(shortcuts.shortcuts, isEmpty);
    });
    testWidgets('Shortcuts.of and maybeOf find shortcuts', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      await tester.pumpWidget(
        Shortcuts(
          manager: testManager,
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.shift): const TestIntent(),
          },
          child: Focus(
            autofocus: true,
            child: SizedBox(key: containerKey, width: 100, height: 100),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.maybeOf(containerKey.currentContext!), isNotNull);
      expect(Shortcuts.maybeOf(containerKey.currentContext!), equals(testManager));
      expect(Shortcuts.of(containerKey.currentContext!), equals(testManager));
    });
    testWidgets('Shortcuts.of and maybeOf work correctly without shortcuts', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      await tester.pumpWidget(Container(key: containerKey));
      expect(Shortcuts.maybeOf(containerKey.currentContext!), isNull);
      late FlutterError error;
      try {
        Shortcuts.of(containerKey.currentContext!);
      } on FlutterError catch (e) {
        error = e;
      } finally {
        expect(error, isNotNull);
        expect(error.diagnostics.length, 5);
        expect(error.diagnostics[2].level, DiagnosticLevel.info);
        expect(
          error.diagnostics[2].toStringDeep(),
          'No Shortcuts ancestor could be found starting from the context\n'
          'that was passed to Shortcuts.of().\n',
        );
        expect(error.toStringDeep(), equalsIgnoringHashCodes(
          'FlutterError\n'
          '   Unable to find a Shortcuts widget in the context.\n'
          '   Shortcuts.of() was called with a context that does not contain a\n'
          '   Shortcuts widget.\n'
          '   No Shortcuts ancestor could be found starting from the context\n'
          '   that was passed to Shortcuts.of().\n'
          '   The context used was:\n'
          '     Container-[GlobalKey#00000]\n',
        ));
      }
    });
    testWidgets('ShortcutManager handles shortcuts', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (Intent intent) {
                invoked = true;
                return true;
              },
            ),
          },
          child: Shortcuts(
            manager: testManager,
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.shift): const TestIntent(),
            },
            child: Focus(
              autofocus: true,
              child: SizedBox(key: containerKey, width: 100, height: 100),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(containerKey.currentContext!), isNotNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, isTrue);
      expect(pressedKeys, equals(<LogicalKeyboardKey>[LogicalKeyboardKey.shiftLeft]));
    });
    testWidgets('ShortcutManager ignores keypresses with no primary focus', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (Intent intent) {
                invoked = true;
                return true;
              },
            ),
          },
          child: Shortcuts(
            manager: testManager,
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.shift): const TestIntent(),
            },
            child: SizedBox(key: containerKey, width: 100, height: 100),
          ),
        ),
      );
      await tester.pump();
      expect(primaryFocus, isNull);
      expect(Shortcuts.of(containerKey.currentContext!), isNotNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, isFalse);
      expect(pressedKeys, isEmpty);
    });
    testWidgets("Shortcuts passes to the next Shortcuts widget if it doesn't map the key", (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        Shortcuts(
          manager: testManager,
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.shift): const TestIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              TestIntent: TestAction(
                onInvoke: (Intent intent) {
                  invoked = true;
                  return invoked;
                },
              ),
            },
            child: Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.keyA): Intent.doNothing,
              },
              child: Focus(
                autofocus: true,
                child: SizedBox(key: containerKey, width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(containerKey.currentContext!), isNotNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, isTrue);
      expect(pressedKeys, equals(<LogicalKeyboardKey>[LogicalKeyboardKey.shiftLeft]));
    });
    testWidgets('Shortcuts can disable a shortcut with Intent.doNothing', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Shortcuts(
            manager: testManager,
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.shift): const TestIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                TestIntent: TestAction(
                  onInvoke: (Intent intent) {
                    invoked = true;
                    return invoked;
                  },
                ),
              },
              child: Shortcuts(
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(LogicalKeyboardKey.shift): Intent.doNothing,
                },
                child: Focus(
                  autofocus: true,
                  child: SizedBox(key: containerKey, width: 100, height: 100),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(containerKey.currentContext!), isNotNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, isFalse);
      expect(pressedKeys, isEmpty);
    });
    testWidgets("Shortcuts that aren't bound to an action don't absorb keys meant for text fields", (WidgetTester tester) async {
      final GlobalKey textFieldKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Shortcuts(
              manager: testManager,
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.keyA): const TestIntent(),
              },
              child: TextField(key: textFieldKey, autofocus: true),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(textFieldKey.currentContext!), isNotNull);
      final bool handled = await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      expect(handled, isFalse);
      expect(pressedKeys, equals(<LogicalKeyboardKey>[LogicalKeyboardKey.keyA]));
    });
    testWidgets('Shortcuts that are bound to an action do override text fields', (WidgetTester tester) async {
      final GlobalKey textFieldKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Shortcuts(
              manager: testManager,
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.keyA): const TestIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  TestIntent: TestAction(
                    onInvoke: (Intent intent) {
                      invoked = true;
                      return invoked;
                    },
                  ),
                },
                child: TextField(key: textFieldKey, autofocus: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(textFieldKey.currentContext!), isNotNull);
      final bool result = await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      expect(result, isTrue);
      expect(pressedKeys, equals(<LogicalKeyboardKey>[LogicalKeyboardKey.keyA]));
      expect(invoked, isTrue);
    });
    testWidgets('Shortcuts can override intents that apply to text fields', (WidgetTester tester) async {
      final GlobalKey textFieldKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Shortcuts(
              manager: testManager,
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.keyA): const TestIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  TestIntent: TestAction(
                    onInvoke: (Intent intent) {
                      invoked = true;
                      return invoked;
                    },
                  ),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    TestIntent: DoNothingAction(consumesKey: false),
                  },
                  child: TextField(key: textFieldKey, autofocus: true),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(textFieldKey.currentContext!), isNotNull);
      final bool result = await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      expect(result, isFalse);
      expect(invoked, isFalse);
    });
    testWidgets('Shortcuts can override intents that apply to text fields with DoNothingAndStopPropagationIntent', (WidgetTester tester) async {
      final GlobalKey textFieldKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Shortcuts(
              manager: testManager,
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.keyA): const TestIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  TestIntent: TestAction(
                    onInvoke: (Intent intent) {
                      invoked = true;
                      return invoked;
                    },
                  ),
                },
                child: Shortcuts(
                  shortcuts: <LogicalKeySet, Intent>{
                    LogicalKeySet(LogicalKeyboardKey.keyA): DoNothingAndStopPropagationIntent(),
                  },
                  child: TextField(key: textFieldKey, autofocus: true),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(textFieldKey.currentContext!), isNotNull);
      final bool result = await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      expect(result, isFalse);
      expect(invoked, isFalse);
    });
    test('Shortcuts diagnostics work.', () {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.keyA,
          ): const ActivateIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.arrowRight,
          ): const DirectionalFocusIntent(TraversalDirection.right),
        },
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final List<String> description = builder.properties.where((DiagnosticsNode node) {
        return !node.isFiltered(DiagnosticLevel.info);
      }).map((DiagnosticsNode node) => node.toString()).toList();

      expect(description.length, equals(1));
      expect(
        description[0],
        equalsIgnoringHashCodes(
          'shortcuts: {{Shift + Key A}: ActivateIntent#00000, {Shift + Arrow Right}: DirectionalFocusIntent#00000}',
        ),
      );
    });
    test('Shortcuts diagnostics work when debugLabel specified.', () {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Shortcuts(
        debugLabel: '<Debug Label>',
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
          ): const ActivateIntent(),
        },
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final List<String> description = builder.properties.where((DiagnosticsNode node) {
        return !node.isFiltered(DiagnosticLevel.info);
      }).map((DiagnosticsNode node) => node.toString()).toList();

      expect(description.length, equals(1));
      expect(description[0], equals('shortcuts: <Debug Label>'));
    });
    test('Shortcuts diagnostics work when manager specified.', () {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Shortcuts(
        manager: ShortcutManager(),
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
          ): const ActivateIntent(),
        },
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final List<String> description = builder.properties.where((DiagnosticsNode node) {
        return !node.isFiltered(DiagnosticLevel.info);
      }).map((DiagnosticsNode node) => node.toString()).toList();

      expect(description.length, equals(2));
      expect(description[0], equalsIgnoringHashCodes('manager: ShortcutManager#00000(shortcuts: {})'));
      expect(description[1], equalsIgnoringHashCodes('shortcuts: {{Key A + Key B}: ActivateIntent#00000}'));
    });

    testWidgets('Shortcuts support multiple intents', (WidgetTester tester) async {
      tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      bool? value = true;
      Widget buildApp() {
        return MaterialApp(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.space): const PrioritizedIntents(
              orderedIntents: <Intent>[
                ActivateIntent(),
                ScrollIntent(direction: AxisDirection.down, type: ScrollIncrementType.page),
              ],
            ),
            LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
            LogicalKeySet(LogicalKeyboardKey.pageUp): const ScrollIntent(direction: AxisDirection.up, type: ScrollIncrementType.page),
          },
          home: Material(
            child: Center(
              child: ListView(
                primary: true,
                children: <Widget> [
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Checkbox(
                        value: value,
                        onChanged: (bool? newValue) => setState(() { value = newValue; }),
                        focusColor: Colors.orange[500],
                      );
                    },
                  ),
                  Container(
                    color: Colors.blue,
                    height: 1000,
                  ),
                ],
              ),
            ),
          ),
        );
      }
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(
        tester.binding.focusManager.primaryFocus!.toStringShort(),
        equalsIgnoringHashCodes('FocusScopeNode#00000(_ModalScopeState<dynamic> Focus Scope [PRIMARY FOCUS])'),
      );
      final ScrollController controller = PrimaryScrollController.of(
        tester.element(find.byType(ListView)),
      )!;
      expect(controller.position.pixels, 0.0);
      expect(value, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      // ScrollView scrolls
      expect(controller.position.pixels, 448.0);
      expect(value, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      // Focus is now on the checkbox.
      expect(
        tester.binding.focusManager.primaryFocus!.toStringShort(),
        equalsIgnoringHashCodes('FocusNode#00000([PRIMARY FOCUS])'),
      );
      expect(value, isTrue);
      expect(controller.position.pixels, 0.0);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      // Checkbox is toggled, scroll view does not scroll.
      expect(value, isFalse);
      expect(controller.position.pixels, 0.0);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(controller.position.pixels, 0.0);
    });

    testWidgets('Shortcuts support activators that returns null in triggers', (WidgetTester tester) async {
      int invoked = 0;
      await tester.pumpWidget(activatorTester(
        const DumbLogicalActivator(LogicalKeyboardKey.keyC),
        (Intent intent) { invoked += 1; },
        const SingleActivator(LogicalKeyboardKey.keyC, control: true),
        (Intent intent) { invoked += 10; },
      ));
      await tester.pump();

      // Press KeyC: Accepted by DumbLogicalActivator
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      invoked = 0;

      // Press ControlLeft + KeyC: Accepted by SingleActivator
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 10);
      invoked = 0;

      // Press ControlLeft + ShiftLeft + KeyC: Accepted by DumbLogicalActivator
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(invoked, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, 1);
      invoked = 0;
    });
  });

  group('CharacterActivator', () {
    testWidgets('is triggered on events with correct character', (WidgetTester tester) async {
      int invoked = 0;
      await tester.pumpWidget(activatorTester(
        const CharacterActivator('?'),
        (Intent intent) { invoked += 1; },
      ));
      await tester.pump();

      // Press KeyC: Accepted by DumbLogicalActivator
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.slash, character: '?');
      expect(invoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, 1);
      invoked = 0;
    }, variant: KeySimulatorTransitModeVariant.all());

    testWidgets('handles repeated events', (WidgetTester tester) async {
      int invoked = 0;
      await tester.pumpWidget(activatorTester(
        const CharacterActivator('?'),
        (Intent intent) { invoked += 1; },
      ));
      await tester.pump();

      // Press KeyC: Accepted by DumbLogicalActivator
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.slash, character: '?');
      expect(invoked, 1);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.slash, character: '?');
      expect(invoked, 2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, 2);
      invoked = 0;
    }, variant: KeySimulatorTransitModeVariant.all());


    testWidgets('isActivatedBy works as expected', (WidgetTester tester) async {
      // Collect some key events to use for testing.
      final List<RawKeyEvent> events = <RawKeyEvent>[];
      await tester.pumpWidget(
        Focus(
          autofocus: true,
          onKey: (FocusNode node, RawKeyEvent event) {
            events.add(event);
            return KeyEventResult.ignored;
          },
          child: const SizedBox(),
        ),
      );

      const CharacterActivator characterActivator = CharacterActivator('a');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      expect(ShortcutActivator.isActivatedBy(characterActivator, events[0]), isTrue);
    });
  });

  group('CallbackShortcuts', () {
    testWidgets('trigger on key events', (WidgetTester tester) async {
      int invokedA = 0;
      int invokedB = 0;
      await tester.pumpWidget(
        CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyA): () {
              invokedA += 1;
            },
            const SingleActivator(LogicalKeyboardKey.keyB): () {
              invokedB += 1;
            },
          },
          child: const Focus(
            autofocus: true,
            child: Placeholder(),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      expect(invokedA, equals(1));
      expect(invokedB, equals(0));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      expect(invokedA, equals(1));
      expect(invokedB, equals(0));
      invokedA = 0;
      invokedB = 0;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
      expect(invokedA, equals(0));
      expect(invokedB, equals(1));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
      expect(invokedA, equals(0));
      expect(invokedB, equals(1));
    });

    testWidgets('nested CallbackShortcuts stop propagation', (WidgetTester tester) async {
      int invokedOuter = 0;
      int invokedInner = 0;
      await tester.pumpWidget(
        CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyA): () {
              invokedOuter += 1;
            },
          },
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.keyA): () {
                invokedInner += 1;
              },
            },
            child: const Focus(
              autofocus: true,
              child: Placeholder(),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      expect(invokedOuter, equals(0));
      expect(invokedInner, equals(1));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      expect(invokedOuter, equals(0));
      expect(invokedInner, equals(1));
    });

    testWidgets('non-overlapping nested CallbackShortcuts fire appropriately', (WidgetTester tester) async {
      int invokedOuter = 0;
      int invokedInner = 0;
      await tester.pumpWidget(
        CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const CharacterActivator('b'): () {
              invokedOuter += 1;
            },
          },
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const CharacterActivator('a'): () {
                invokedInner += 1;
              },
            },
            child: const Focus(
              autofocus: true,
              child: Placeholder(),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      expect(invokedOuter, equals(0));
      expect(invokedInner, equals(1));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
      expect(invokedOuter, equals(1));
      expect(invokedInner, equals(1));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
      expect(invokedOuter, equals(1));
      expect(invokedInner, equals(1));
    });

    testWidgets('Works correctly with Shortcuts too', (WidgetTester tester) async {
      int invokedCallbackA = 0;
      int invokedCallbackB = 0;
      int invokedActionA = 0;
      int invokedActionB = 0;

      void clear() {
        invokedCallbackA = 0;
        invokedCallbackB = 0;
        invokedActionA = 0;
        invokedActionB = 0;
      }

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            TestIntent: TestAction(
              onInvoke: (Intent intent) {
                invokedActionA += 1;
                return true;
              },
            ),
            TestIntent2: TestAction(
              onInvoke: (Intent intent) {
                invokedActionB += 1;
                return true;
              },
            ),
          },
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const CharacterActivator('b'): () {
                invokedCallbackB += 1;
              },
            },
            child: Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.keyA): const TestIntent(),
                LogicalKeySet(LogicalKeyboardKey.keyB): const TestIntent2(),
              },
              child: CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const CharacterActivator('a'): () {
                    invokedCallbackA += 1;
                  },
                },
                child: const Focus(
                  autofocus: true,
                  child: Placeholder(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      expect(invokedCallbackA, equals(1));
      expect(invokedCallbackB, equals(0));
      expect(invokedActionA, equals(0));
      expect(invokedActionB, equals(0));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      clear();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
      expect(invokedCallbackA, equals(0));
      expect(invokedCallbackB, equals(0));
      expect(invokedActionA, equals(0));
      expect(invokedActionB, equals(1));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
    });
  });
}
