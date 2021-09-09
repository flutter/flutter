// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HardwareKeyboard records pressed keys and enabled locks', (WidgetTester tester) async {
    await simulateKeyDownEvent(LogicalKeyboardKey.numLock, platform: 'windows');
    expect(HardwareKeyboard.instance.physicalKeysPressed,
      equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.logicalKeysPressed,
      equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.lockModesEnabled,
      equals(<KeyboardLockMode>{KeyboardLockMode.numLock}));

    await simulateKeyDownEvent(LogicalKeyboardKey.numpad1, platform: 'windows');
    expect(HardwareKeyboard.instance.physicalKeysPressed,
      equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numLock, PhysicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.logicalKeysPressed,
      equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numLock, LogicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.lockModesEnabled,
      equals(<KeyboardLockMode>{KeyboardLockMode.numLock}));

    await simulateKeyRepeatEvent(LogicalKeyboardKey.numpad1, platform: 'windows');
    expect(HardwareKeyboard.instance.physicalKeysPressed,
      equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numLock, PhysicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.logicalKeysPressed,
      equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numLock, LogicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.lockModesEnabled,
      equals(<KeyboardLockMode>{KeyboardLockMode.numLock}));

    await simulateKeyUpEvent(LogicalKeyboardKey.numLock);
    expect(HardwareKeyboard.instance.physicalKeysPressed,
      equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.logicalKeysPressed,
      equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.lockModesEnabled,
      equals(<KeyboardLockMode>{KeyboardLockMode.numLock}));

    await simulateKeyDownEvent(LogicalKeyboardKey.numLock, platform: 'windows');
    expect(HardwareKeyboard.instance.physicalKeysPressed,
      equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numLock, PhysicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.logicalKeysPressed,
      equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numLock, LogicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.lockModesEnabled,
      equals(<KeyboardLockMode>{}));

    await simulateKeyUpEvent(LogicalKeyboardKey.numpad1, platform: 'windows');
    expect(HardwareKeyboard.instance.physicalKeysPressed,
      equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.logicalKeysPressed,
      equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.lockModesEnabled,
      equals(<KeyboardLockMode>{}));

    await simulateKeyUpEvent(LogicalKeyboardKey.numLock, platform: 'windows');
    expect(HardwareKeyboard.instance.physicalKeysPressed,
      equals(<PhysicalKeyboardKey>{}));
    expect(HardwareKeyboard.instance.logicalKeysPressed,
      equals(<LogicalKeyboardKey>{}));
    expect(HardwareKeyboard.instance.lockModesEnabled,
      equals(<KeyboardLockMode>{}));
  }, variant: KeySimulatorTransitModeVariant.keyDataThenRawKeyData());

  testWidgets('KeyboardManager synthesizes modifier keys in rawKeyData mode', (WidgetTester tester) async {
    final List<KeyEvent> events = <KeyEvent>[];
    HardwareKeyboard.instance.addHandler((KeyEvent event) {
      events.add(event);
      return false;
    });
    // While ShiftLeft is held (the event of which was skipped), press keyA.
    final Map<String, dynamic> rawMessage = kIsWeb ? (
      KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'web',
      )..['metaState'] = RawKeyEventDataWeb.modifierShift
    ) : (
      KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'android',
      )..['metaState'] = RawKeyEventDataAndroid.modifierLeftShift | RawKeyEventDataAndroid.modifierShift
    );
    tester.binding.keyEventManager.handleRawKeyMessage(rawMessage);
    expect(events, hasLength(2));
    expect(events[0].physicalKey, PhysicalKeyboardKey.shiftLeft);
    expect(events[0].logicalKey, LogicalKeyboardKey.shiftLeft);
    expect(events[0].synthesized, true);
    expect(events[1].physicalKey, PhysicalKeyboardKey.keyA);
    expect(events[1].logicalKey, LogicalKeyboardKey.keyA);
    expect(events[1].synthesized, false);
  });

  testWidgets('Dispatch events to all handlers', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    final List<int> logs = <int>[];

    await tester.pumpWidget(
      KeyboardListener(
        autofocus: true,
        focusNode: focusNode,
        child: Container(),
        onKeyEvent: (KeyEvent event) {
          logs.add(1);
        },
      ),
    );

    // Only the Service binding handler.

    expect(await simulateKeyDownEvent(LogicalKeyboardKey.keyA),
      false);
    expect(logs, <int>[1]);
    logs.clear();

    // Add a handler.

    bool handler2Result = false;
    bool handler2(KeyEvent event) {
      logs.add(2);
      return handler2Result;
    }
    HardwareKeyboard.instance.addHandler(handler2);

    expect(await simulateKeyUpEvent(LogicalKeyboardKey.keyA),
      false);
    expect(logs, <int>[2, 1]);
    logs.clear();

    handler2Result = true;

    expect(await simulateKeyDownEvent(LogicalKeyboardKey.keyA),
      true);
    expect(logs, <int>[2, 1]);
    logs.clear();

    // Add another handler.

    handler2Result = false;
    bool handler3Result = false;
    bool handler3(KeyEvent event) {
      logs.add(3);
      return handler3Result;
    }
    HardwareKeyboard.instance.addHandler(handler3);

    expect(await simulateKeyUpEvent(LogicalKeyboardKey.keyA),
      false);
    expect(logs, <int>[2, 3, 1]);
    logs.clear();

    handler2Result = true;

    expect(await simulateKeyDownEvent(LogicalKeyboardKey.keyA),
      true);
    expect(logs, <int>[2, 3, 1]);
    logs.clear();

    handler3Result = true;

    expect(await simulateKeyUpEvent(LogicalKeyboardKey.keyA),
      true);
    expect(logs, <int>[2, 3, 1]);
    logs.clear();

    // Add handler2 again.

    HardwareKeyboard.instance.addHandler(handler2);

    handler3Result = false;
    handler2Result = false;
    expect(await simulateKeyDownEvent(LogicalKeyboardKey.keyA),
      false);
    expect(logs, <int>[2, 3, 2, 1]);
    logs.clear();

    handler2Result = true;
    expect(await simulateKeyUpEvent(LogicalKeyboardKey.keyA),
      true);
    expect(logs, <int>[2, 3, 2, 1]);
    logs.clear();

    // Remove handler2 once.

    HardwareKeyboard.instance.removeHandler(handler2);
    expect(await simulateKeyDownEvent(LogicalKeyboardKey.keyA),
      true);
    expect(logs, <int>[3, 2, 1]);
    logs.clear();
  }, variant: KeySimulatorTransitModeVariant.all());

  // The first key data received from the engine might be an empty key data.
  // In that case, the key data should not be converted to any [KeyEvent]s,
  // but is only used so that *a* key data comes before the raw key message
  // and makes [KeyEventManager] infer [KeyDataTransitMode.keyDataThenRawKeyData].
  testWidgets('Empty keyData yields no event but triggers inferrence', (WidgetTester tester) async {
    final List<KeyEvent> events = <KeyEvent>[];
    final List<RawKeyEvent> rawEvents = <RawKeyEvent>[];
    tester.binding.keyboard.addHandler((KeyEvent event) {
      events.add(event);
      return true;
    });
    RawKeyboard.instance.addListener((RawKeyEvent event) {
      rawEvents.add(event);
    });
    tester.binding.keyEventManager.handleKeyData(const ui.KeyData(
      type: ui.KeyEventType.down,
      timeStamp: Duration.zero,
      logical: 0,
      physical: 0,
      character: 'a',
      synthesized: false,
    ));
    tester.binding.keyEventManager.handleRawKeyMessage(<String, dynamic>{
      'type': 'keydown',
      'keymap': 'windows',
      'keyCode': 0x04,
      'scanCode': 0x04,
      'characterCodePoint': 0,
      'modifiers': 0,
    });
    expect(events.length, 0);
    expect(rawEvents.length, 1);

    // Dispatch another key data to ensure it's in
    // [KeyDataTransitMode.keyDataThenRawKeyData] mode (otherwise assertion
    // will be thrown upon a KeyData).
    tester.binding.keyEventManager.handleKeyData(const ui.KeyData(
      type: ui.KeyEventType.down,
      timeStamp: Duration.zero,
      logical: 0x22,
      physical: 0x70034,
      character: '"',
      synthesized: false,
    ));
    tester.binding.keyEventManager.handleRawKeyMessage(<String, dynamic>{
      'type': 'keydown',
      'keymap': 'windows',
      'keyCode': 0x04,
      'scanCode': 0x04,
      'characterCodePoint': 0,
      'modifiers': 0,
    });
    expect(events.length, 1);
    expect(rawEvents.length, 2);
  });
}
