// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> platforms = <String>['linux', 'macos', 'android', 'fuchsia'];

void _verify<T extends KeyEvent>(KeyEvent event, PhysicalKeyboardKey physical, LogicalKeyboardKey logical, String? character) {
  expect(event, isA<T>());
  expect(event.physicalKey, physical);
  expect(event.logicalKey, logical);
  expect(event.character, character);
  expect(event.synthesized, false);
}

void main() {
  testWidgets('simulates keyboard events (RawEvent)', (WidgetTester tester) async {
    debugKeySimulationVehicleOverride = KeyEventVehicle.rawKeyData;

    final List<RawKeyEvent> events = <RawKeyEvent>[];

    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      RawKeyboardListener(
        focusNode: focusNode,
        onKey: events.add,
        child: Container(),
      ),
    );

    focusNode.requestFocus();
    await tester.idle();

    for (final String platform in platforms) {
      await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
      await tester.sendKeyEvent(LogicalKeyboardKey.shift, platform: platform);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA, platform: platform);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA, platform: platform);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.numpad1, platform: platform);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.numpad1, platform: platform);
      await tester.idle();

      expect(events.length, 8);
      for (int i = 0; i < events.length; ++i) {
        final bool isEven = i.isEven;
        if (isEven) {
          expect(events[i].runtimeType, equals(RawKeyDownEvent));
        } else {
          expect(events[i].runtimeType, equals(RawKeyUpEvent));
        }
        if (i < 4) {
          expect(events[i].data.isModifierPressed(ModifierKey.shiftModifier, side: KeyboardSide.left), equals(isEven));
        }
      }
      events.clear();
    }

    await tester.pumpWidget(Container());
    focusNode.dispose();

    debugKeySimulationVehicleOverride = null;
  });

  testWidgets('simulates keyboard events (KeyData then RawKeyEvent)', (WidgetTester tester) async {
    debugKeySimulationVehicleOverride = KeyEventVehicle.keyDataThenRawKeyData;

    final List<KeyEvent> events = <KeyEvent>[];

    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      KeyboardListener(
        focusNode: focusNode,
        onKeyEvent: events.add,
        child: Container(),
      ),
    );

    focusNode.requestFocus();
    await tester.idle();

    // Key press shiftLeft
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    expect(events.length, 1);
    _verify<KeyDownEvent>(events[0], PhysicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftLeft, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.shiftLeft}));
    expect(HardwareKeyboard.instance.logicalKeysPressed, equals(<LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft}));
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.shiftLeft);
    expect(events.length, 1);
    _verify<KeyRepeatEvent>(events[0], PhysicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftLeft, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.shiftLeft}));
    expect(HardwareKeyboard.instance.logicalKeysPressed, equals(<LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft}));
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(events.length, 1);
    _verify<KeyUpEvent>(events[0], PhysicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftLeft, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, isEmpty);
    expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    // Key press keyA
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    expect(events.length, 1);
    _verify<KeyDownEvent>(events[0], PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA, 'a');
    expect(HardwareKeyboard.instance.physicalKeysPressed, equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.keyA}));
    expect(HardwareKeyboard.instance.logicalKeysPressed, equals(<LogicalKeyboardKey>{LogicalKeyboardKey.keyA}));
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyA);
    _verify<KeyRepeatEvent>(events[0], PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA, 'a');
    expect(HardwareKeyboard.instance.physicalKeysPressed, equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.keyA}));
    expect(HardwareKeyboard.instance.logicalKeysPressed, equals(<LogicalKeyboardKey>{LogicalKeyboardKey.keyA}));
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    _verify<KeyUpEvent>(events[0], PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, isEmpty);
    expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    // Key press numpad1
    await tester.sendKeyDownEvent(LogicalKeyboardKey.numpad1);
    _verify<KeyDownEvent>(events[0], PhysicalKeyboardKey.numpad1, LogicalKeyboardKey.numpad1, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.logicalKeysPressed, equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.numpad1);
    _verify<KeyRepeatEvent>(events[0], PhysicalKeyboardKey.numpad1, LogicalKeyboardKey.numpad1, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.logicalKeysPressed, equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numpad1}));
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    await tester.sendKeyUpEvent(LogicalKeyboardKey.numpad1);
    _verify<KeyUpEvent>(events[0], PhysicalKeyboardKey.numpad1, LogicalKeyboardKey.numpad1, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, isEmpty);
    expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    // Key press numLock (1st time)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.numLock);
    _verify<KeyDownEvent>(events[0], PhysicalKeyboardKey.numLock, LogicalKeyboardKey.numLock, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.logicalKeysPressed, equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.lockModesEnabled, equals(<KeyboardLockMode>{KeyboardLockMode.numLock}));
    events.clear();

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.numLock);
    _verify<KeyRepeatEvent>(events[0], PhysicalKeyboardKey.numLock, LogicalKeyboardKey.numLock, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.logicalKeysPressed, equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.lockModesEnabled, equals(<KeyboardLockMode>{KeyboardLockMode.numLock}));
    events.clear();

    await tester.sendKeyUpEvent(LogicalKeyboardKey.numLock);
    _verify<KeyUpEvent>(events[0], PhysicalKeyboardKey.numLock, LogicalKeyboardKey.numLock, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, isEmpty);
    expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
    expect(HardwareKeyboard.instance.lockModesEnabled, equals(<KeyboardLockMode>{KeyboardLockMode.numLock}));
    events.clear();

    // Key press numLock (2nd time)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.numLock);
    _verify<KeyDownEvent>(events[0], PhysicalKeyboardKey.numLock, LogicalKeyboardKey.numLock, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.logicalKeysPressed, equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.numLock);
    _verify<KeyRepeatEvent>(events[0], PhysicalKeyboardKey.numLock, LogicalKeyboardKey.numLock, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, equals(<PhysicalKeyboardKey>{PhysicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.logicalKeysPressed, equals(<LogicalKeyboardKey>{LogicalKeyboardKey.numLock}));
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    await tester.sendKeyUpEvent(LogicalKeyboardKey.numLock);
    _verify<KeyUpEvent>(events[0], PhysicalKeyboardKey.numLock, LogicalKeyboardKey.numLock, null);
    expect(HardwareKeyboard.instance.physicalKeysPressed, isEmpty);
    expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
    expect(HardwareKeyboard.instance.lockModesEnabled, isEmpty);
    events.clear();

    await tester.idle();

    await tester.pumpWidget(Container());
    focusNode.dispose();

    debugKeySimulationVehicleOverride = null;
  });

  testWidgets('simulates using the correct vehicle', (WidgetTester tester) async {
    final List<Object> events = <Object>[];

    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(
      Focus(
        focusNode: focusNode,
        onKey: (FocusNode node, RawKeyEvent event) {
          events.add(event);
          return KeyEventResult.ignored;
        },
        onKeyEvent: (FocusNode node, KeyEvent event) {
          events.add(event);
          return KeyEventResult.ignored;
        },
        child: Container(),
      ),
    );

    focusNode.requestFocus();
    await tester.idle();

    /* Simulate events in rawKeyData vehicle. */
    debugKeySimulationVehicleOverride = KeyEventVehicle.rawKeyData;
    // A (physical keyA, logical keyA) is pressed.
    await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
    expect(events.length, 2);
    expect(events[0], isA<KeyEvent>());
    expect(events[1], isA<RawKeyEvent>());
    events.clear();

    // A (physical keyA, logical keyB) is released with a different logical key.
    await simulateKeyUpEvent(LogicalKeyboardKey.keyB, physicalKey: PhysicalKeyboardKey.keyA);
    expect(events.length, 2);
    // HardwareKeyboard regularizes key events.
    expect(events[0], isA<KeyEvent>());
    expect((events[0] as KeyEvent).logicalKey, LogicalKeyboardKey.keyA);
    // RawKeyboard converts key events trivally.
    expect(events[1], isA<RawKeyEvent>());
    expect((events[1] as RawKeyEvent).logicalKey, LogicalKeyboardKey.keyB);
    events.clear();

    /* Simulate events in keyDataThenRawKeyData vehicle. */
    debugKeySimulationVehicleOverride = KeyEventVehicle.keyDataThenRawKeyData;
    await simulateKeyDownEvent(LogicalKeyboardKey.keyA, platform: 'fuchsia');
    expect(events.length, 2);
    expect(events[0], isA<KeyEvent>());
    expect(events[1], isA<RawKeyEvent>());
    expect((events[1] as RawKeyEvent).data, isA<RawKeyEventDataFuchsia>());
    events.clear();

    await simulateKeyUpEvent(LogicalKeyboardKey.keyA, platform: 'fuchsia');
    expect(events.length, 2);
    expect(events[0], isA<KeyEvent>());
    expect(events[1], isA<RawKeyEvent>());
    expect((events[1] as RawKeyEvent).data, isA<RawKeyEventDataFuchsia>());
    events.clear();

    /* Simulate events in rawKeyData vehicle again .*/
    debugKeySimulationVehicleOverride = KeyEventVehicle.rawKeyData;
    // RawKeyEvents are no longer converted to KeyEvents
    // because a KeyData has been observed.
    await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
    expect(events.length, 1);
    expect(events[0], isA<RawKeyEvent>());
    events.clear();

    await simulateKeyUpEvent(LogicalKeyboardKey.keyA);
    expect(events.length, 1);
    expect(events[0], isA<RawKeyEvent>());
    events.clear();

    debugKeySimulationVehicleOverride = null;
  });
}
