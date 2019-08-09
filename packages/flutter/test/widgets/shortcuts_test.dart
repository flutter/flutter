// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/services/keyboard_key.dart';
import 'package:flutter/src/services/keyboard_maps.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void sendFakeKeyEvent(Map<String, dynamic> data) {
  ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.keyEvent.name,
    SystemChannels.keyEvent.codec.encodeMessage(data),
    (ByteData data) {},
  );
}

typedef PostInvokeCallback = void Function({Action action, Intent intent, FocusNode focusNode, ActionDispatcher dispatcher});

class TestAction extends CallbackAction {
  const TestAction({
    @required OnInvokeCallback onInvoke,
  })  : assert(onInvoke != null),
        super(key, onInvoke: onInvoke);

  static const LocalKey key = ValueKey<Type>(TestAction);
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

class TestIntent extends Intent {
  const TestIntent() : super(TestAction.key);
}

class DoNothingAction extends Action {
  const DoNothingAction({
    @required OnInvokeCallback onInvoke,
  })  : assert(onInvoke != null),
        super(key);

  static const LocalKey key = ValueKey<Type>(DoNothingAction);

  @override
  void invoke(FocusNode node, Intent invocation) {}
}

class DoNothingIntent extends Intent {
  const DoNothingIntent() : super(DoNothingAction.key);
}

class TestShortcutManager extends ShortcutManager {
  TestShortcutManager(this.keys);

  List<LogicalKeyboardKey> keys;

  @override
  bool handleKeypress(BuildContext context, RawKeyEvent event, {LogicalKeySet keysPressed}) {
    keys.add(event.logicalKey);
    return super.handleKeypress(context, event, keysPressed: keysPressed);
  }
}

void testKeypress(LogicalKeyboardKey key) {
  assert(key.debugName != null);
  int keyCode;
  kAndroidToLogicalKey.forEach((int code, LogicalKeyboardKey codeKey) {
    if (key == codeKey) {
      keyCode = code;
    }
  });
  assert(keyCode != null, 'Key $key not found in Android key map');
  int scanCode;
  kAndroidToPhysicalKey.forEach((int code, PhysicalKeyboardKey codeKey) {
    if (key.debugName == codeKey.debugName) {
      scanCode = code;
    }
  });
  assert(scanCode != null, 'Physical key for $key not found in Android key map');
  sendFakeKeyEvent(<String, dynamic>{
    'type': 'keydown',
    'keymap': 'android',
    'keyCode': keyCode,
    'plainCodePoint': 0,
    'codePoint': 0,
    'character': null,
    'scanCode': scanCode,
    'metaState': 0,
  });
}

void main() {
  group(LogicalKeySet, () {
    test('$LogicalKeySet passes parameters correctly.', () {
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
          }));
      expect(
          set2.keys,
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
          }));
      expect(
          set3.keys,
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
            LogicalKeyboardKey.keyC,
          }));
      expect(
          set4.keys,
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
            LogicalKeyboardKey.keyC,
            LogicalKeyboardKey.keyD,
          }));
      expect(
          setFromSet.keys,
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
            LogicalKeyboardKey.keyC,
            LogicalKeyboardKey.keyD,
          }));
    });
    test('$LogicalKeySet works as a map key.', () {
      final LogicalKeySet set1 = LogicalKeySet(LogicalKeyboardKey.keyA);
      final LogicalKeySet set2 = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
      );
      final Map<LogicalKeySet, String> map = <LogicalKeySet, String>{set1: 'one'};
      expect(map.containsKey(set1), isTrue);
      expect(map.containsKey(LogicalKeySet(LogicalKeyboardKey.keyA)), isTrue);
      expect(
          set2,
          equals(LogicalKeySet.fromSet(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
          })));
    });
    test('$KeySet diagnostics work.', () {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) {
            return !node.isFiltered(DiagnosticLevel.info);
          })
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description.length, equals(1));
      expect(
          description[0],
          equalsIgnoringHashCodes(
              'keys: {LogicalKeyboardKey#00000(keyId: "0x00000061", keyLabel: "a", debugName: "Key A"), LogicalKeyboardKey#00000(keyId: "0x00000062", keyLabel: "b", debugName: "Key B")}'));
    });
  });
  group(Shortcuts, () {
    testWidgets('$ShortcutManager handles shortcuts', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        Actions(
          actions: <LocalKey, ActionFactory>{
            TestAction.key: () => TestAction(onInvoke: (FocusNode node, Intent intent) {
                  invoked = true;
                  return true;
                }),
          },
          child: Shortcuts(
            manager: testManager,
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.shift): const TestIntent(),
            },
            child: Focus(
              autofocus: true,
              child: Container(key: containerKey, width: 100, height: 100),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(containerKey.currentContext), isNotNull);
      testKeypress(LogicalKeyboardKey.shiftLeft);
      expect(invoked, isTrue);
      expect(pressedKeys, equals(<LogicalKeyboardKey>[LogicalKeyboardKey.shiftLeft]));
    });
    testWidgets("$Shortcuts passes to the next $Shortcuts widget if it doesn't map the key", (WidgetTester tester) async {
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
            actions: <LocalKey, ActionFactory>{
              TestAction.key: () => TestAction(onInvoke: (FocusNode node, Intent intent) {
                invoked = true;
                return true;
              }),
            },
            child: Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.keyA): const DoNothingIntent(),
              },
              child: Focus(
                autofocus: true,
                child: Container(key: containerKey, width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(containerKey.currentContext), isNotNull);
      testKeypress(LogicalKeyboardKey.shiftLeft);
      expect(invoked, isTrue);
      expect(pressedKeys, equals(<LogicalKeyboardKey>[LogicalKeyboardKey.shiftLeft]));
    });
  });
}
