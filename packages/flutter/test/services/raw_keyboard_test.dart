// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _ModifierCheck {
  const _ModifierCheck(this.key, this.side);
  final ModifierKey key;
  final KeyboardSide side;
}

void main() {
  group('RawKeyboard', () {
    testWidgets('keysPressed is maintained', (WidgetTester tester) async {
      for (String platform in <String>['linux', 'android', 'macos', 'fuchsia']) {
        RawKeyboard.instance.clearKeysPressed();
        expect(RawKeyboard.instance.keysPressed, isEmpty, reason: 'on $platform');
        await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{ LogicalKeyboardKey.shiftLeft },
          ),
          reason: 'on $platform',
        );
        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft, platform: platform);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{
              LogicalKeyboardKey.shiftLeft,
              LogicalKeyboardKey.controlLeft,
            },
          ),
          reason: 'on $platform',
        );
        await simulateKeyDownEvent(LogicalKeyboardKey.keyA, platform: platform);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{
              LogicalKeyboardKey.shiftLeft,
              LogicalKeyboardKey.controlLeft,
              LogicalKeyboardKey.keyA,
            },
          ),
          reason: 'on $platform',
        );
        await simulateKeyUpEvent(LogicalKeyboardKey.keyA, platform: platform);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{
              LogicalKeyboardKey.shiftLeft,
              LogicalKeyboardKey.controlLeft,
            },
          ),
          reason: 'on $platform',
        );
        await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft, platform: platform);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{ LogicalKeyboardKey.shiftLeft },
          ),
          reason: 'on $platform',
        );
        await simulateKeyUpEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
        expect(RawKeyboard.instance.keysPressed, isEmpty, reason: 'on $platform');
        // The Fn key isn't mapped on linux.
        if (platform != 'linux') {
          await simulateKeyDownEvent(LogicalKeyboardKey.fn, platform: platform);
          expect(RawKeyboard.instance.keysPressed,
            equals(
              <LogicalKeyboardKey>{
                if (platform != 'macos') LogicalKeyboardKey.fn,
              },
            ),
            reason: 'on $platform');
          await simulateKeyDownEvent(LogicalKeyboardKey.f12, platform: platform);
          expect(
            RawKeyboard.instance.keysPressed,
            equals(
              <LogicalKeyboardKey>{
                if (platform != 'macos') LogicalKeyboardKey.fn,
                LogicalKeyboardKey.f12,
              },
            ),
            reason: 'on $platform',
          );
          await simulateKeyUpEvent(LogicalKeyboardKey.fn, platform: platform);
          expect(
            RawKeyboard.instance.keysPressed,
            equals(
              <LogicalKeyboardKey>{ LogicalKeyboardKey.f12 },
            ),
            reason: 'on $platform',
          );
          await simulateKeyUpEvent(LogicalKeyboardKey.f12, platform: platform);
          expect(RawKeyboard.instance.keysPressed, isEmpty, reason: 'on $platform');
        }
      }
    }, skip: kIsWeb);

    testWidgets('keysPressed modifiers are synchronized with key events on macOS', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'macos',
        isDown: true,
      );
      // Change the modifiers so that they show the shift key as already down
      // when this event is received, but it's not in keysPressed yet.
      data['modifiers'] |= RawKeyEventDataMacOs.modifierLeftShift | RawKeyEventDataMacOs.modifierShift;
      // dispatch the modified data.
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyA},
        ),
      );
    });

    testWidgets('keysPressed modifiers are synchronized with key events on android', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'android',
        isDown: true,
      );
      // Change the modifiers so that they show the shift key as already down
      // when this event is received, but it's not in keysPressed yet.
      data['metaState'] |= RawKeyEventDataAndroid.modifierLeftShift | RawKeyEventDataAndroid.modifierShift;
      // dispatch the modified data.
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyA},
        ),
      );
    });

    testWidgets('keysPressed modifiers are synchronized with key events on fuchsia', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'fuchsia',
        isDown: true,
      );
      // Change the modifiers so that they show the shift key as already down
      // when this event is received, but it's not in keysPressed yet.
      data['modifiers'] |= RawKeyEventDataFuchsia.modifierLeftShift;
      // dispatch the modified data.
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyA},
        ),
      );
    });

    testWidgets('keysPressed modifiers are synchronized with key events on linux', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'linux',
        isDown: true,
      );
      // Change the modifiers so that they show the shift key as already down
      // when this event is received, but it's not in keysPressed yet.
      data['modifiers'] |= GLFWKeyHelper.modifierShift;
      // dispatch the modified data.
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyA},
        ),
      );
    });
  });

  group('RawKeyEventDataAndroid', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      RawKeyEventDataAndroid.modifierAlt | RawKeyEventDataAndroid.modifierLeftAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.left),
      RawKeyEventDataAndroid.modifierAlt | RawKeyEventDataAndroid.modifierRightAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.right),
      RawKeyEventDataAndroid.modifierShift | RawKeyEventDataAndroid.modifierLeftShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.left),
      RawKeyEventDataAndroid.modifierShift | RawKeyEventDataAndroid.modifierRightShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.right),
      RawKeyEventDataAndroid.modifierSym: _ModifierCheck(ModifierKey.symbolModifier, KeyboardSide.all),
      RawKeyEventDataAndroid.modifierFunction: _ModifierCheck(ModifierKey.functionModifier, KeyboardSide.all),
      RawKeyEventDataAndroid.modifierControl | RawKeyEventDataAndroid.modifierLeftControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.left),
      RawKeyEventDataAndroid.modifierControl | RawKeyEventDataAndroid.modifierRightControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.right),
      RawKeyEventDataAndroid.modifierMeta | RawKeyEventDataAndroid.modifierLeftMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.left),
      RawKeyEventDataAndroid.modifierMeta | RawKeyEventDataAndroid.modifierRightMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.right),
      RawKeyEventDataAndroid.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.all),
      RawKeyEventDataAndroid.modifierNumLock: _ModifierCheck(ModifierKey.numLockModifier, KeyboardSide.all),
      RawKeyEventDataAndroid.modifierScrollLock: _ModifierCheck(ModifierKey.scrollLockModifier, KeyboardSide.all),
    };

    test('modifier keys are recognized individually', () {
      for (int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'android',
          'keyCode': 0x04,
          'plainCodePoint': 0x64,
          'codePoint': 0x44,
          'scanCode': 0x20,
          'metaState': modifier,
          'source': 0x101, // Keyboard source.
          'deviceId': 1,
        });
        final RawKeyEventDataAndroid data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
            expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });
    test('modifier keys are recognized when combined', () {
      for (int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataAndroid.modifierFunction) {
          // No need to combine function key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'android',
          'keyCode': 0x04,
          'plainCodePoint': 0x64,
          'codePoint': 0x44,
          'scanCode': 0x20,
          'metaState': modifier | RawKeyEventDataAndroid.modifierFunction,
          'source': 0x101, // Keyboard source.
          'deviceId': 1,
        });
        final RawKeyEventDataAndroid data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key || key == ModifierKey.functionModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataAndroid.modifierFunction}, but isn't.",
            );
            if (key != ModifierKey.functionModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.all));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${RawKeyEventDataAndroid.modifierFunction}.',
            );
          }
        }
      }
    });
    test('Printable keyboard keys are correctly translated', () {
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(<String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 29,
        'plainCodePoint': 'a'.codeUnitAt(0),
        'codePoint': 'A'.codeUnitAt(0),
        'character': 'A',
        'scanCode': 30,
        'metaState': 0x0,
        'source': 0x101, // Keyboard source.
        'deviceId': 1,
      });
      final RawKeyEventDataAndroid data = keyAEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });
    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 111,
        'codePoint': 0,
        'character': null,
        'scanCode': 1,
        'metaState': 0x0,
        'source': 0x101, // Keyboard source.
        'deviceId': 1,
      });
      final RawKeyEventDataAndroid data = escapeKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isNull);
    });
    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 59,
        'plainCodePoint': 0,
        'codePoint': 0,
        'character': null,
        'scanCode': 42,
        'metaState': RawKeyEventDataAndroid.modifierLeftShift,
        'source': 0x101, // Keyboard source.
        'deviceId': 1,
      });
      final RawKeyEventDataAndroid data = shiftLeftKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isNull);
    });
    test('DPAD keys from a joystick give physical key mappings', () {
      final RawKeyEvent joystickDpadDown = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 20,
        'plainCodePoint': 0,
        'codePoint': 0,
        'character': null,
        'scanCode': 0,
        'metaState': 0,
        'source': 0x1000010, // Joystick source.
        'deviceId': 1,
      });
      final RawKeyEventDataAndroid data = joystickDpadDown.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.arrowDown));
      expect(data.logicalKey, equals(LogicalKeyboardKey.arrowDown));
      expect(data.keyLabel, isNull);
    });
    test('Arrow keys from a keyboard give correct physical key mappings', () {
      final RawKeyEvent joystickDpadDown = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 20,
        'plainCodePoint': 0,
        'codePoint': 0,
        'character': null,
        'scanCode': 108,
        'metaState': 0,
        'source': 0x101, // Keyboard source.
      });
      final RawKeyEventDataAndroid data = joystickDpadDown.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.arrowDown));
      expect(data.logicalKey, equals(LogicalKeyboardKey.arrowDown));
      expect(data.keyLabel, isNull);
    });
    test('DPAD center from a game pad gives physical key mappings', () {
      final RawKeyEvent joystickDpadCenter = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 23, // DPAD_CENTER code.
        'plainCodePoint': 0,
        'codePoint': 0,
        'character': null,
        'scanCode': 317, // Left side thumb joystick center click button.
        'metaState': 0,
        'source': 0x501, // Gamepad and keyboard source.
        'deviceId': 1,
      });
      final RawKeyEventDataAndroid data = joystickDpadCenter.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.gameButtonThumbLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.select));
      expect(data.keyLabel, isNull);
    });
    test('Device id is read from message', () {
      final RawKeyEvent joystickDpadCenter = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 23, // DPAD_CENTER code.
        'plainCodePoint': 0,
        'codePoint': 0,
        'character': null,
        'scanCode': 317, // Left side thumb joystick center click button.
        'metaState': 0,
        'source': 0x501, // Gamepad and keyboard source.
        'deviceId': 10,
      });
      final RawKeyEventDataAndroid data = joystickDpadCenter.data;
      expect(data.deviceId, equals(10));
    });
    test('Repeat count is passed correctly', () {
      final RawKeyEvent repeatCountEvent = RawKeyEvent.fromMessage(<String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 29,
        'plainCodePoint': 'a'.codeUnitAt(0),
        'codePoint': 'A'.codeUnitAt(0),
        'character': 'A',
        'scanCode': 30,
        'metaState': 0x0,
        'source': 0x101, // Keyboard source.
        'repeatCount': 42,
      });
      final RawKeyEventDataAndroid data = repeatCountEvent.data;
      expect(data.repeatCount, equals(42));
    });
  });
  group('RawKeyEventDataFuchsia', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      RawKeyEventDataFuchsia.modifierAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.any),
      RawKeyEventDataFuchsia.modifierLeftAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.left),
      RawKeyEventDataFuchsia.modifierRightAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.right),
      RawKeyEventDataFuchsia.modifierShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.any),
      RawKeyEventDataFuchsia.modifierLeftShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.left),
      RawKeyEventDataFuchsia.modifierRightShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.right),
      RawKeyEventDataFuchsia.modifierControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.any),
      RawKeyEventDataFuchsia.modifierLeftControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.left),
      RawKeyEventDataFuchsia.modifierRightControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.right),
      RawKeyEventDataFuchsia.modifierMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.any),
      RawKeyEventDataFuchsia.modifierLeftMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.left),
      RawKeyEventDataFuchsia.modifierRightMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.right),
      RawKeyEventDataFuchsia.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.any),
    };

    test('modifier keys are recognized individually', () {
      for (int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'fuchsia',
          'hidUsage': 0x04,
          'codePoint': 0x64,
          'modifiers': modifier,
        });
        final RawKeyEventDataFuchsia data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });
    test('modifier keys are recognized when combined', () {
      for (int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataFuchsia.modifierCapsLock) {
          // No need to combine caps lock key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'fuchsia',
          'hidUsage': 0x04,
          'codePoint': 0x64,
          'modifiers': modifier | RawKeyEventDataFuchsia.modifierCapsLock,
        });
        final RawKeyEventDataFuchsia data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key || key == ModifierKey.capsLockModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataFuchsia.modifierCapsLock}, but isn't.",
            );
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${RawKeyEventDataFuchsia.modifierCapsLock}.',
            );
          }
        }
      }
    });
    test('Printable keyboard keys are correctly translated', () {
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(<String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x00070004,
        'codePoint': 'a'.codeUnitAt(0),
        'character': 'a',
      });
      final RawKeyEventDataFuchsia data = keyAEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });
    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x00070029,
        'codePoint': null,
        'character': null,
      });
      final RawKeyEventDataFuchsia data = escapeKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isNull);
    });
    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x000700e1,
        'codePoint': null,
        'character': null,
      });
      final RawKeyEventDataFuchsia data = shiftLeftKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isNull);
    });
  }, skip: isBrowser);
  group('RawKeyEventDataMacOs', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      RawKeyEventDataMacOs.modifierOption | RawKeyEventDataMacOs.modifierLeftOption: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.left),
      RawKeyEventDataMacOs.modifierOption | RawKeyEventDataMacOs.modifierRightOption: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.right),
      RawKeyEventDataMacOs.modifierShift | RawKeyEventDataMacOs.modifierLeftShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.left),
      RawKeyEventDataMacOs.modifierShift | RawKeyEventDataMacOs.modifierRightShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.right),
      RawKeyEventDataMacOs.modifierControl | RawKeyEventDataMacOs.modifierLeftControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.left),
      RawKeyEventDataMacOs.modifierControl | RawKeyEventDataMacOs.modifierRightControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.right),
      RawKeyEventDataMacOs.modifierCommand | RawKeyEventDataMacOs.modifierLeftCommand: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.left),
      RawKeyEventDataMacOs.modifierCommand | RawKeyEventDataMacOs.modifierRightCommand: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.right),
      RawKeyEventDataMacOs.modifierOption: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.all),
      RawKeyEventDataMacOs.modifierShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.all),
      RawKeyEventDataMacOs.modifierControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.all),
      RawKeyEventDataMacOs.modifierCommand: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.all),
      RawKeyEventDataMacOs.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.all),
    };

    test('modifier keys are recognized individually', () {
      for (int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'macos',
          'keyCode': 0x04,
          'characters': 'a',
          'charactersIgnoringModifiers': 'a',
          'modifiers': modifier,
        });
        final RawKeyEventDataMacOs data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
            expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });
    test('modifier keys are recognized when combined', () {
      for (int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataMacOs.modifierCapsLock) {
          // No need to combine caps lock key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'macos',
          'keyCode': 0x04,
          'plainCodePoint': 0x64,
          'characters': 'a',
          'charactersIgnoringModifiers': 'a',
          'modifiers': modifier | RawKeyEventDataMacOs.modifierCapsLock,
        });
        final RawKeyEventDataMacOs data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key || key == ModifierKey.capsLockModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataMacOs.modifierCapsLock}, but isn't.",
            );
            if (key != ModifierKey.capsLockModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.all));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${RawKeyEventDataMacOs.modifierCapsLock}.',
            );
          }
        }
      }
    });
    test('Printable keyboard keys are correctly translated', () {
      const String unmodifiedCharacter = 'a';
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x00000000,
        'characters': 'a',
        'charactersIgnoringModifiers': unmodifiedCharacter,
        'modifiers': 0x0,
      });
      final RawKeyEventDataMacOs data = keyAEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });
    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x00000035,
        'characters': '',
        'charactersIgnoringModifiers': '',
        'character': null,
        'modifiers': 0x0,
      });
      final RawKeyEventDataMacOs data = escapeKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isNull);
    });
    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x00000038,
        'characters': '',
        'charactersIgnoringModifiers': '',
        'character': null,
        'modifiers': RawKeyEventDataMacOs.modifierLeftShift,
      });
      final RawKeyEventDataMacOs data = shiftLeftKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isNull);
    });
    test('Unprintable keyboard keys are correctly translated', () {
      final RawKeyEvent leftArrowKey = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x0000007B,
        'characters': '',
        'charactersIgnoringModifiers': '', // NSLeftArrowFunctionKey = 0xF702
        'character': null,
        'modifiers': RawKeyEventDataMacOs.modifierFunction,
      });
      final RawKeyEventDataMacOs data = leftArrowKey.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.arrowLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.arrowLeft));
      expect(data.logicalKey.keyLabel, isNull);
    });
  }, skip: isBrowser);
  group('RawKeyEventDataLinux-GFLW', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      GLFWKeyHelper.modifierAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.any),
      GLFWKeyHelper.modifierShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.any),
      GLFWKeyHelper.modifierControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.any),
      GLFWKeyHelper.modifierMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.any),
      GLFWKeyHelper.modifierNumericPad: _ModifierCheck(ModifierKey.numLockModifier, KeyboardSide.all),
      GLFWKeyHelper.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.all),
    };

    // How modifiers are interpreted depends upon the keyCode for GLFW.
    int keyCodeForModifier(int modifier, {bool isLeft}) {
      switch (modifier) {
        case GLFWKeyHelper.modifierAlt:
          return isLeft ? 342 : 346;
        case GLFWKeyHelper.modifierShift:
          return isLeft ? 340 : 344;
        case GLFWKeyHelper.modifierControl:
          return isLeft ? 341 : 345;
        case GLFWKeyHelper.modifierMeta:
          return isLeft ? 343 : 347;
        case GLFWKeyHelper.modifierNumericPad:
          return 282;
        case GLFWKeyHelper.modifierCapsLock:
          return 280;
        default:
          return 65; // keyA
      }
    }

    test('modifier keys are recognized individually', () {
      for (int modifier in modifierTests.keys) {
        for (bool isDown in <bool>[true, false]) {
          for (bool isLeft in <bool>[true, false]) {
            final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
              'type': isDown ? 'keydown' : 'keyup',
              'keymap': 'linux',
              'toolkit': 'glfw',
              'keyCode': keyCodeForModifier(modifier, isLeft: isLeft),
              'scanCode': 0x00000026,
              'unicodeScalarValues': 97,
              // GLFW modifiers don't include the current key event.
              'modifiers': isDown ? 0 : modifier,
            });
            final RawKeyEventDataLinux data = event.data;
            for (ModifierKey key in ModifierKey.values) {
              if (modifierTests[modifier].key == key) {
                expect(
                  data.isModifierPressed(key, side: modifierTests[modifier].side),
                  isDown ? isTrue : isFalse,
                  reason: "${isLeft ? 'left' : 'right'} $key ${isDown ? 'should' : 'should not'} be pressed with metaState $modifier, when key is ${isDown ? 'down' : 'up'}, but isn't.",
                );
                expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
              } else {
                expect(
                  data.isModifierPressed(key, side: modifierTests[modifier].side),
                  isFalse,
                  reason: "${isLeft ? 'left' : 'right'} $key should not be pressed with metaState $modifier, wwhen key is ${isDown ? 'down' : 'up'}, but is.",
                );
              }
            }
          }
        }
      }
    });
    test('modifier keys are recognized when combined', () {
      for (int modifier in modifierTests.keys) {
        if (modifier == GLFWKeyHelper.modifierControl) {
          // No need to combine CTRL key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'linux',
          'toolkit': 'glfw',
          'keyCode': 65,
          'scanCode': 0x00000026,
          'unicodeScalarValues': 97,
          'modifiers': modifier | GLFWKeyHelper.modifierControl,
        });
        final RawKeyEventDataLinux data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key || key == ModifierKey.controlModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${GLFWKeyHelper.modifierControl}, but isn't.",
            );
            if (key != ModifierKey.controlModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.any));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${GLFWKeyHelper.modifierControl}.',
            );
          }
        }
      }
    });
    test('Printable keyboard keys are correctly translated', () {
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'glfw',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 113,
        'modifiers': 0x0,
      });
      final RawKeyEventDataLinux data = keyAEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyQ));
      expect(data.keyLabel, equals('q'));
    });
    test('Code points with two Unicode scalar values are allowed', () {
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'glfw',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 0x10FFFF,
        'modifiers': 0x0,
      });
      final RawKeyEventDataLinux data = keyAEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey.keyId, equals(0x10FFFF));
      expect(data.keyLabel, equals('􏿿'));
    });

    test('Code points with more than three Unicode scalar values are not allowed', () {
      // |keyCode| and |scanCode| are arbitrary values. This test should fail due to an invalid |unicodeScalarValues|.
      void _createFailingKey() {
        RawKeyEvent.fromMessage(const <String, dynamic>{
          'type': 'keydown',
          'keymap': 'linux',
          'toolkit': 'glfw',
          'keyCode': 65,
          'scanCode': 0x00000026,
          'unicodeScalarValues': 0x1F00000000,
          'modifiers': 0x0,
        });
      }
      expect(() => _createFailingKey(), throwsAssertionError);
    });
    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'glfw',
        'keyCode': 256,
        'scanCode': 0x00000009,
        'unicodeScalarValues': 0,
        'modifiers': 0x0,
      });
      final RawKeyEventDataLinux data = escapeKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isNull);
    });
    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'glfw',
        'keyCode': 340,
        'scanCode': 0x00000032,
        'unicodeScalarValues': 0,
      });
      final RawKeyEventDataLinux data = shiftLeftKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isNull);
    });
  }, skip: isBrowser);

  group('RawKeyEventDataWeb', () {
    const Map<int, ModifierKey> modifierTests = <int, ModifierKey>{
      RawKeyEventDataWeb.modifierAlt: ModifierKey.altModifier,
      RawKeyEventDataWeb.modifierShift: ModifierKey.shiftModifier,
      RawKeyEventDataWeb.modifierControl: ModifierKey.controlModifier,
      RawKeyEventDataWeb.modifierMeta: ModifierKey.metaModifier,
      RawKeyEventDataWeb.modifierCapsLock: ModifierKey.capsLockModifier,
      RawKeyEventDataWeb.modifierNumLock: ModifierKey.numLockModifier,
      RawKeyEventDataWeb.modifierScrollLock: ModifierKey.scrollLockModifier,
    };

    test('modifier keys are recognized individually', () {
      for (int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'web',
          'code': 'RandomCode',
          'key': null,
          'metaState': modifier,
        });
        final RawKeyEventDataWeb data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier] == key) {
            expect(
              data.isModifierPressed(key),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
          } else {
            expect(
              data.isModifierPressed(key),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });
    test('modifier keys are recognized when combined', () {
      for (int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataWeb.modifierMeta) {
          // No need to combine meta key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'web',
          'code': 'RandomCode',
          'key': null,
          'metaState': modifier | RawKeyEventDataWeb.modifierMeta,
        });
        final RawKeyEventDataWeb data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier] == key || key == ModifierKey.metaModifier) {
            expect(
              data.isModifierPressed(key),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataWeb.modifierMeta}, but isn't.",
            );
          } else {
            expect(
              data.isModifierPressed(key),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${RawKeyEventDataWeb.modifierMeta}.',
            );
          }
        }
      }
    });
    test('Printable keyboard keys are correctly translated', () {
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'KeyA',
        'key': 'a',
        'metaState': 0x0,
      });
      final RawKeyEventDataWeb data = keyAEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });
    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'Escape',
        'key': null,
        'metaState': 0x0,
      });
      final RawKeyEventDataWeb data = escapeKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isNull);
    });
    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'ShiftLeft',
        'keyLabel': null,
        'metaState': RawKeyEventDataWeb.modifierShift,
      });
      final RawKeyEventDataWeb data = shiftKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isNull);
    });
    test('Arrow keys from a keyboard give correct physical key mappings', () {
      final RawKeyEvent arrowKeyDown = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'ArrowDown',
        'key': null,
        'metaState': 0x0,
      });
      final RawKeyEventDataWeb data = arrowKeyDown.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.arrowDown));
      expect(data.logicalKey, equals(LogicalKeyboardKey.arrowDown));
      expect(data.keyLabel, isNull);
    });
  });
}
