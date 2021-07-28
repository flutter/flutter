// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
}
