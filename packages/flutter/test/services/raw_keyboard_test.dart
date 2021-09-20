// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _ModifierCheck {
  const _ModifierCheck(this.key, this.side);
  final ModifierKey key;
  final KeyboardSide side;
}

void main() {
  group('RawKeyboard', () {
    testWidgets('The correct character is produced', (WidgetTester tester) async {
      for (final String platform in <String>['linux', 'android', 'macos', 'fuchsia', 'windows']) {
        String character = '';
        void handleKey(RawKeyEvent event) {
          expect(event.character, equals(character), reason: 'on $platform');
        }
        RawKeyboard.instance.addListener(handleKey);
        character = 'a';
        await simulateKeyDownEvent(LogicalKeyboardKey.keyA, platform: platform);
        character = '`';
        await simulateKeyDownEvent(LogicalKeyboardKey.backquote, platform: platform);
        RawKeyboard.instance.removeListener(handleKey);
      }
    });

    testWidgets('No character is produced for non-printables', (WidgetTester tester) async {
      for (final String platform in <String>['linux', 'android', 'macos', 'fuchsia', 'windows', 'web']) {
        void handleKey(RawKeyEvent event) {
          expect(event.character, isNull, reason: 'on $platform');
        }
        RawKeyboard.instance.addListener(handleKey);
        await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
        RawKeyboard.instance.removeListener(handleKey);
      }
    });

    testWidgets('keysPressed is maintained', (WidgetTester tester) async {
      for (final String platform in <String>['linux', 'android', 'macos', 'fuchsia', 'windows', 'ios']) {
        RawKeyboard.instance.clearKeysPressed();
        expect(RawKeyboard.instance.keysPressed, isEmpty, reason: 'on $platform');
        await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{ LogicalKeyboardKey.shiftLeft,
            // Linux doesn't have a concept of left/right keys, so they're all
            // shown as down when either is pressed.
            if (platform == 'linux') LogicalKeyboardKey.shiftRight,
          },
        ),
          reason: 'on $platform',
        );
        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft, platform: platform);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{
              LogicalKeyboardKey.shiftLeft,
              if (platform == 'linux') LogicalKeyboardKey.shiftRight,
              LogicalKeyboardKey.controlLeft,
              if (platform == 'linux') LogicalKeyboardKey.controlRight,
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
              if (platform == 'linux') LogicalKeyboardKey.shiftRight,
              LogicalKeyboardKey.controlLeft,
              if (platform == 'linux') LogicalKeyboardKey.controlRight,
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
              if (platform == 'linux') LogicalKeyboardKey.shiftRight,
              LogicalKeyboardKey.controlLeft,
              if (platform == 'linux') LogicalKeyboardKey.controlRight,
            },
          ),
          reason: 'on $platform',
        );
        await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft, platform: platform);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{
              LogicalKeyboardKey.shiftLeft,
              if (platform == 'linux') LogicalKeyboardKey.shiftRight,
            },
          ),
          reason: 'on $platform',
        );
        await simulateKeyUpEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
        expect(RawKeyboard.instance.keysPressed, isEmpty, reason: 'on $platform');
        // The Fn key isn't mapped on linux or Windows.
        if (platform != 'linux' && platform != 'windows' && platform != 'ios') {
          await simulateKeyDownEvent(LogicalKeyboardKey.fn, platform: platform);
          expect(
            RawKeyboard.instance.keysPressed,
            equals(
              <LogicalKeyboardKey>{
                if (platform != 'macos') LogicalKeyboardKey.fn,
              },
            ),
            reason: 'on $platform',
          );
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
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    testWidgets('keysPressed is correct when modifier is released before key', (WidgetTester tester) async {
      for (final String platform in <String>['linux', 'android', 'macos', 'fuchsia', 'windows', 'ios']) {
        RawKeyboard.instance.clearKeysPressed();
        expect(RawKeyboard.instance.keysPressed, isEmpty, reason: 'on $platform');
        await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft, platform: platform, physicalKey: PhysicalKeyboardKey.shiftLeft);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{
              LogicalKeyboardKey.shiftLeft,
              // Linux doesn't have a concept of left/right keys, so they're all
              // shown as down when either is pressed.
              if (platform == 'linux') LogicalKeyboardKey.shiftRight,
            },
          ),
          reason: 'on $platform',
        );
        // TODO(gspencergoog): Switch to capital A when the new key event code
        // is finished that can simulate real keys.
        // https://github.com/flutter/flutter/issues/33521
        // This should really be done with a simulated capital A, but the event
        // simulation code doesn't really support that, since it only can
        // simulate events that appear in the key maps (and capital letters
        // don't appear there).
        await simulateKeyDownEvent(LogicalKeyboardKey.keyA, platform: platform, physicalKey: PhysicalKeyboardKey.keyA);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{
              LogicalKeyboardKey.shiftLeft,
              if (platform == 'linux') LogicalKeyboardKey.shiftRight,
              LogicalKeyboardKey.keyA,
            },
          ),
          reason: 'on $platform',
        );
        await simulateKeyUpEvent(LogicalKeyboardKey.shiftLeft, platform: platform, physicalKey: PhysicalKeyboardKey.shiftLeft);
        expect(
          RawKeyboard.instance.keysPressed,
          equals(
            <LogicalKeyboardKey>{
              LogicalKeyboardKey.keyA,
            },
          ),
          reason: 'on $platform',
        );
        await simulateKeyUpEvent(LogicalKeyboardKey.keyA, platform: platform, physicalKey: PhysicalKeyboardKey.keyA);
        expect(RawKeyboard.instance.keysPressed, isEmpty, reason: 'on $platform');
      }
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/76741

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
      data['modifiers'] = (data['modifiers'] as int) | RawKeyEventDataMacOs.modifierLeftShift | RawKeyEventDataMacOs.modifierShift;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyA},
        ),
      );
    }, skip: isBrowser); // [intended] This is a macOS-specific test.

    testWidgets('keysPressed modifiers are synchronized with key events on iOS', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'ios',
        isDown: true,
      );
      // Change the modifiers so that they show the shift key as already down
      // when this event is received, but it's not in keysPressed yet.
      data['modifiers'] = (data['modifiers'] as int) | RawKeyEventDataMacOs.modifierLeftShift | RawKeyEventDataMacOs.modifierShift;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyA},
        ),
      );
    }, skip: isBrowser); // [intended] This is an iOS-specific test.

    testWidgets('keysPressed modifiers are synchronized with key events on Windows', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'windows',
        isDown: true,
      );
      // Change the modifiers so that they show the shift key as already down
      // when this event is received, but it's not in keysPressed yet.
      data['modifiers'] = (data['modifiers'] as int) | RawKeyEventDataWindows.modifierLeftShift | RawKeyEventDataWindows.modifierShift;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyA},
        ),
      );
    }, skip: isBrowser); // [intended] This is a Windows-specific test.

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
      data['metaState'] = (data['metaState'] as int) | RawKeyEventDataAndroid.modifierLeftShift | RawKeyEventDataAndroid.modifierShift;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyA},
        ),
      );
    }, skip: isBrowser); // [intended] This is an Android-specific test.

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
      data['modifiers'] = (data['modifiers'] as int) | RawKeyEventDataFuchsia.modifierLeftShift;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyA},
        ),
      );
    }, skip: isBrowser); // [intended] This is a Fuchsia-specific test.

    testWidgets('keysPressed modifiers are synchronized with key events on Linux GLFW', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'linux',
        isDown: true,
      );
      // Change the modifiers so that they show the shift key as already down
      // when this event is received, but it's not in keysPressed yet.
      data['modifiers'] = (data['modifiers'] as int) | GLFWKeyHelper.modifierShift;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftLeft,
            // Linux doesn't have a concept of left/right keys, so they're all
            // shown as down when either is pressed.
            LogicalKeyboardKey.shiftRight,
            LogicalKeyboardKey.keyA,
          },
        ),
      );
    }, skip: isBrowser); // [intended] This is a GLFW-specific test.

    testWidgets('keysPressed modifiers are synchronized with key events on web', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event. Change the modifiers so
      // that they show the shift key as already down when this event is
      // received, but it's not in keysPressed yet.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'web',
        isDown: true,
      );
      data['metaState'] = (data['metaState'] as int) | RawKeyEventDataWeb.modifierShift;
      // Dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftLeft,
            LogicalKeyboardKey.keyA,
          },
        ),
      );

      // Generate the data for a regular key up event. Don't set the modifiers
      // for shift so that they show the shift key as already up when this event
      // is received, and it's in keysPressed.
      final Map<String, dynamic> data2 = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'web',
        isDown: false,
      )..['metaState'] = 0;
      // Dispatch the modified data.
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data2),
        (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{},
        ),
      );

      // Press right modifier key
      final Map<String, dynamic> data3 = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.shiftRight,
        platform: 'web',
        isDown: true,
      );
      data['metaState'] = (data['metaState'] as int) | RawKeyEventDataWeb.modifierShift;
      // Dispatch the modified data.
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data3),
        (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftRight,
          },
        ),
      );

      // Release the key
      final Map<String, dynamic> data4 = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.shiftRight,
        platform: 'web',
        isDown: false,
      )..['metaState'] = 0;
      // Dispatch the modified data.
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data4),
        (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{},
        ),
      );
    });

    testWidgets('sided modifiers without a side set return all sides on Android', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'android',
        isDown: true,
      );
      // Set only the generic "down" modifier, without setting a side.
      data['metaState'] = (data['metaState'] as int) |
        RawKeyEventDataAndroid.modifierShift |
        RawKeyEventDataAndroid.modifierAlt |
        RawKeyEventDataAndroid.modifierControl |
        RawKeyEventDataAndroid.modifierMeta;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
            (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftLeft,
            LogicalKeyboardKey.shiftRight,
            LogicalKeyboardKey.altLeft,
            LogicalKeyboardKey.altRight,
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.controlRight,
            LogicalKeyboardKey.metaLeft,
            LogicalKeyboardKey.metaRight,
            LogicalKeyboardKey.keyA,
          },
        ),
      );
    }, skip: isBrowser); // [intended] This is an Android-specific test.

    testWidgets('sided modifiers without a side set return all sides on macOS', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'macos',
        isDown: true,
      );
      // Set only the generic "shift down" modifier, without setting a side.
      data['modifiers'] = (data['modifiers'] as int) |
          RawKeyEventDataMacOs.modifierShift |
          RawKeyEventDataMacOs.modifierOption |
          RawKeyEventDataMacOs.modifierCommand |
          RawKeyEventDataMacOs.modifierControl;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
            (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftLeft,
            LogicalKeyboardKey.shiftRight,
            LogicalKeyboardKey.altLeft,
            LogicalKeyboardKey.altRight,
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.controlRight,
            LogicalKeyboardKey.metaLeft,
            LogicalKeyboardKey.metaRight,
            LogicalKeyboardKey.keyA,
          },
        ),
      );
    }, skip: isBrowser); // [intended] This is a macOS-specific test.

    testWidgets('sided modifiers without a side set return all sides on iOS', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'ios',
        isDown: true,
      );
      // Set only the generic "shift down" modifier, without setting a side.
      data['modifiers'] = (data['modifiers'] as int) |
          RawKeyEventDataIos.modifierShift |
          RawKeyEventDataIos.modifierOption |
          RawKeyEventDataIos.modifierCommand |
          RawKeyEventDataIos.modifierControl;
      // dispatch the modified data.
      await ServicesBinding.instance?.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
            (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftLeft,
            LogicalKeyboardKey.shiftRight,
            LogicalKeyboardKey.altLeft,
            LogicalKeyboardKey.altRight,
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.controlRight,
            LogicalKeyboardKey.metaLeft,
            LogicalKeyboardKey.metaRight,
            LogicalKeyboardKey.keyA,
          },
        ),
      );
    }, skip: isBrowser); // [intended] This is an iOS-specific test.

    testWidgets('sided modifiers without a side set return all sides on Windows', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'windows',
        isDown: true,
      );
      // Set only the generic "shift down" modifier, without setting a side.
      // Windows doesn't have a concept of "either" for the Windows (meta) key.
      data['modifiers'] = (data['modifiers'] as int) |
          RawKeyEventDataWindows.modifierShift |
          RawKeyEventDataWindows.modifierAlt |
          RawKeyEventDataWindows.modifierControl;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
            (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftLeft,
            LogicalKeyboardKey.shiftRight,
            LogicalKeyboardKey.altLeft,
            LogicalKeyboardKey.altRight,
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.controlRight,
            LogicalKeyboardKey.keyA,
          },
        ),
      );
    }, skip: isBrowser); // [intended] This is a Windows-specific test.

    testWidgets('sided modifiers without a side set return all sides on Linux GLFW', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'linux',
        isDown: true,
      );
      // Set only the generic "shift down" modifier, without setting a side.
      // Windows doesn't have a concept of "either" for the Windows (meta) key.
      data['modifiers'] = (data['modifiers'] as int) |
        GLFWKeyHelper.modifierShift |
        GLFWKeyHelper.modifierAlt |
        GLFWKeyHelper.modifierControl |
        GLFWKeyHelper.modifierMeta;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
            (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftLeft,
            LogicalKeyboardKey.shiftRight,
            LogicalKeyboardKey.altLeft,
            LogicalKeyboardKey.altRight,
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.controlRight,
            LogicalKeyboardKey.metaLeft,
            LogicalKeyboardKey.metaRight,
            LogicalKeyboardKey.keyA,
          },
        ),
      );
    }, skip: isBrowser); // [intended] This is a GLFW-specific test.

    testWidgets('sided modifiers without a side set return left sides on web', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'web',
        isDown: true,
      );
      // Set only the generic "shift down" modifier, without setting a side.
      data['metaState'] = (data['metaState'] as int) |
        RawKeyEventDataWeb.modifierShift |
        RawKeyEventDataWeb.modifierAlt |
        RawKeyEventDataWeb.modifierControl |
        RawKeyEventDataWeb.modifierMeta;
      // dispatch the modified data.
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
            (ByteData? data) {},
      );
      expect(
        RawKeyboard.instance.keysPressed,
        equals(
          <LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftLeft,
            LogicalKeyboardKey.altLeft,
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.metaLeft,
            LogicalKeyboardKey.keyA,
          },
        ),
      );
    });

    testWidgets('RawKeyboard asserts if no keys are in keysPressed after receiving a key down event', (WidgetTester tester) async {
      final Map<String, dynamic> keyEventMessage;
      if (kIsWeb) {
        keyEventMessage = const <String, dynamic>{
          'type': 'keydown',
          'keymap': 'web',
          'code': 'ShiftLeft', // Left shift code
          'metaState': 0x0, // No shift key metaState set!
        };
      } else {
        keyEventMessage = const <String, dynamic>{
          'type': 'keydown',
          'keymap': 'android',
          'keyCode': 0x3b, // Left shift key keyCode
          'scanCode': 0x2a,
          'metaState': 0x0, // No shift key metaState set!
          'source': 0x101,
          'deviceId': 1,
        };
      }

      expect(
        () async {
          await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
            SystemChannels.keyEvent.name,
            SystemChannels.keyEvent.codec.encodeMessage(keyEventMessage),
            (ByteData? data) { },
          );
        },
        throwsA(isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          '.toString()',
          contains('Attempted to send a key down event when no keys are in keysPressed'),
        )),
      );
    });

    testWidgets('Dispatch events to all handlers', (WidgetTester tester) async {
      final FocusNode focusNode = FocusNode();
      final List<int> logs = <int>[];

      await tester.pumpWidget(
        RawKeyboardListener(
          autofocus: true,
          focusNode: focusNode,
          child: Container(),
          onKey: (RawKeyEvent event) {
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

      void handler2(RawKeyEvent event) {
        logs.add(2);
      }
      RawKeyboard.instance.addListener(handler2);

      expect(await simulateKeyUpEvent(LogicalKeyboardKey.keyA),
        false);
      expect(logs, <int>[1, 2]);
      logs.clear();

      // Add another handler.

      void handler3(RawKeyEvent event) {
        logs.add(3);
      }
      RawKeyboard.instance.addListener(handler3);

      expect(await simulateKeyDownEvent(LogicalKeyboardKey.keyA),
        false);
      expect(logs, <int>[1, 2, 3]);
      logs.clear();

      // Add handler2 again.

      RawKeyboard.instance.addListener(handler2);

      expect(await simulateKeyUpEvent(LogicalKeyboardKey.keyA),
        false);
      expect(logs, <int>[1, 2, 3, 2]);
      logs.clear();

      // Remove handler2 once.

      RawKeyboard.instance.removeListener(handler2);
      expect(await simulateKeyDownEvent(LogicalKeyboardKey.keyA),
        false);
      expect(logs, <int>[1, 3, 2]);
      logs.clear();
    }, variant: KeySimulatorTransitModeVariant.all());
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
      for (final int modifier in modifierTests.keys) {
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
        final RawKeyEventDataAndroid data = event.data as RawKeyEventDataAndroid;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
            expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });

    test('modifier keys are recognized when combined', () {
      for (final int modifier in modifierTests.keys) {
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
        final RawKeyEventDataAndroid data = event.data as RawKeyEventDataAndroid;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key || key == ModifierKey.functionModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataAndroid.modifierFunction}, but isn't.",
            );
            if (key != ModifierKey.functionModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.all));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
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
      final RawKeyEventDataAndroid data = keyAEvent.data as RawKeyEventDataAndroid;
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
        'scanCode': 1,
        'metaState': 0x0,
        'source': 0x101, // Keyboard source.
        'deviceId': 1,
      });
      final RawKeyEventDataAndroid data = escapeKeyEvent.data as RawKeyEventDataAndroid;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isEmpty);
    });

    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 59,
        'plainCodePoint': 0,
        'codePoint': 0,
        'scanCode': 42,
        'metaState': RawKeyEventDataAndroid.modifierLeftShift,
        'source': 0x101, // Keyboard source.
        'deviceId': 1,
      });
      final RawKeyEventDataAndroid data = shiftLeftKeyEvent.data as RawKeyEventDataAndroid;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isEmpty);
    });

    test('DPAD keys from a joystick give physical key mappings', () {
      final RawKeyEvent joystickDpadDown = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 20,
        'plainCodePoint': 0,
        'codePoint': 0,
        'scanCode': 0,
        'metaState': 0,
        'source': 0x1000010, // Joystick source.
        'deviceId': 1,
      });
      final RawKeyEventDataAndroid data = joystickDpadDown.data as RawKeyEventDataAndroid;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.arrowDown));
      expect(data.logicalKey, equals(LogicalKeyboardKey.arrowDown));
      expect(data.keyLabel, isEmpty);
    });

    test('Arrow keys from a keyboard give correct physical key mappings', () {
      final RawKeyEvent joystickDpadDown = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 20,
        'plainCodePoint': 0,
        'codePoint': 0,
        'scanCode': 108,
        'metaState': 0,
        'source': 0x101, // Keyboard source.
      });
      final RawKeyEventDataAndroid data = joystickDpadDown.data as RawKeyEventDataAndroid;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.arrowDown));
      expect(data.logicalKey, equals(LogicalKeyboardKey.arrowDown));
      expect(data.keyLabel, isEmpty);
    });

    test('DPAD center from a game pad gives physical key mappings', () {
      final RawKeyEvent joystickDpadCenter = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 23, // DPAD_CENTER code.
        'plainCodePoint': 0,
        'codePoint': 0,
        'scanCode': 317, // Left side thumb joystick center click button.
        'metaState': 0,
        'source': 0x501, // Gamepad and keyboard source.
        'deviceId': 1,
      });
      final RawKeyEventDataAndroid data = joystickDpadCenter.data as RawKeyEventDataAndroid;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.gameButtonThumbLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.select));
      expect(data.keyLabel, isEmpty);
    });

    test('Device id is read from message', () {
      final RawKeyEvent joystickDpadCenter = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 23, // DPAD_CENTER code.
        'plainCodePoint': 0,
        'codePoint': 0,
        'scanCode': 317, // Left side thumb joystick center click button.
        'metaState': 0,
        'source': 0x501, // Gamepad and keyboard source.
        'deviceId': 10,
      });
      final RawKeyEventDataAndroid data = joystickDpadCenter.data as RawKeyEventDataAndroid;
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
      final RawKeyEventDataAndroid data = repeatCountEvent.data as RawKeyEventDataAndroid;
      expect(data.repeatCount, equals(42));
    });

    testWidgets('Key events are responded to correctly.', (WidgetTester tester) async {
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      // Generate the data for a regular key down event.
      final Map<String, dynamic> data = KeyEventSimulator.getKeyData(
        LogicalKeyboardKey.keyA,
        platform: 'android',
        isDown: true,
      );
      Map<String, dynamic>? message;
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {
          message = SystemChannels.keyEvent.codec.decodeMessage(data) as Map<String, dynamic>;
        },
      );
      expect(message, equals(<String, dynamic>{ 'handled': false }));
      message = null;

      // Set up a widget that will receive focused text events.
      final FocusNode focusNode = FocusNode(debugLabel: 'Test Node');
      await tester.pumpWidget(
        Focus(
          focusNode: focusNode,
          onKey: (FocusNode node, RawKeyEvent event) {
            return KeyEventResult.handled; // handle all events.
          },
          child: const SizedBox(),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();

      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {
          message = SystemChannels.keyEvent.codec.decodeMessage(data) as Map<String, dynamic>;
        },
      );
      expect(message, equals(<String, dynamic>{ 'handled': true }));
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(SystemChannels.keyEvent.name, null);
    });

    test('data.toString', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 29,
        'plainCodePoint': 97,
        'codePoint': 65,
        'character': 'A',
        'scanCode': 30,
        'metaState': 0x0,
        'source': 0x101, // Keyboard source.
        'repeatCount': 42,
      }).data.toString(), equalsIgnoringHashCodes(
        'RawKeyEventDataAndroid#00000('
        'flags: 0, codePoint: 65, plainCodePoint: 97, keyCode: 29, '
        'scanCode: 30, metaState: 0)'));
    });

    test('data.equality', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 29,
        'plainCodePoint': 97,
        'codePoint': 65,
        'character': 'A',
        'scanCode': 30,
        'metaState': 0x0,
        'source': 0x101, // Keyboard source.
        'repeatCount': 42,
      }).data, const RawKeyEventDataAndroid(
        flags: 0,
        codePoint: 65,
        plainCodePoint: 97,
        keyCode: 29,
        scanCode: 30,
        metaState: 0,
      ));

      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 29,
        'plainCodePoint': 97,
        'codePoint': 65,
        'character': 'A',
        'scanCode': 30,
        'metaState': 0x0,
        'source': 0x101, // Keyboard source.
        'repeatCount': 42,
      }).data, isNot(equals(const RawKeyEventDataAndroid())));
    });
  }, skip: isBrowser); // [intended] This is an Android-specific group.

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
      for (final int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'fuchsia',
          'hidUsage': 0x04,
          'codePoint': 0x64,
          'modifiers': modifier,
        });
        final RawKeyEventDataFuchsia data = event.data as RawKeyEventDataFuchsia;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });

    test('modifier keys are recognized when combined', () {
      for (final int modifier in modifierTests.keys) {
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
        final RawKeyEventDataFuchsia data = event.data as RawKeyEventDataFuchsia;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key || key == ModifierKey.capsLockModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataFuchsia.modifierCapsLock}, but isn't.",
            );
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
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
      final RawKeyEventDataFuchsia data = keyAEvent.data as RawKeyEventDataFuchsia;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });

    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x00070029,
      });
      final RawKeyEventDataFuchsia data = escapeKeyEvent.data as RawKeyEventDataFuchsia;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isEmpty);
    });

    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x000700e1,
      });
      final RawKeyEventDataFuchsia data = shiftLeftKeyEvent.data as RawKeyEventDataFuchsia;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isEmpty);
    });

    test('data.toString', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x00070004,
        'codePoint': 97,
        'character': 'a',
        'modifiers': 0x10,
      }).data.toString(), equalsIgnoringHashCodes(
        'RawKeyEventDataFuchsia#00000(hidUsage: 458756, codePoint: 97, modifiers: 16)'));
    });

    test('data.equality', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x00070004,
        'codePoint': 97,
        'character': 'a',
        'modifiers': 0x10,
      }).data, const RawKeyEventDataFuchsia(
        hidUsage: 0x00070004,
        codePoint: 97,
        modifiers: 0x10,
      ));

      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x00070004,
        'codePoint': 97,
        'character': 'a',
        'modifiers': 0x10,
      }).data, isNot(equals(const RawKeyEventDataFuchsia())));
    });
  }, skip: isBrowser); // [intended] This is a Fuchsia-specific group.

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
      for (final int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'macos',
          'keyCode': 0x04,
          'characters': 'a',
          'charactersIgnoringModifiers': 'a',
          'modifiers': modifier,
        });
        final RawKeyEventDataMacOs data = event.data as RawKeyEventDataMacOs;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
            expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });

    test('modifier keys are recognized when combined', () {
      for (final int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataMacOs.modifierCapsLock) {
          // No need to combine caps lock key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'macos',
          'keyCode': 0x04,
          'characters': 'a',
          'charactersIgnoringModifiers': 'a',
          'modifiers': modifier | RawKeyEventDataMacOs.modifierCapsLock,
        });
        final RawKeyEventDataMacOs data = event.data as RawKeyEventDataMacOs;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key || key == ModifierKey.capsLockModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataMacOs.modifierCapsLock}, but isn't.",
            );
            if (key != ModifierKey.capsLockModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.all));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
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
      final RawKeyEventDataMacOs data = keyAEvent.data as RawKeyEventDataMacOs;
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
        'modifiers': 0x0,
      });
      final RawKeyEventDataMacOs data = escapeKeyEvent.data as RawKeyEventDataMacOs;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isEmpty);
    });

    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x00000038,
        'characters': '',
        'charactersIgnoringModifiers': '',
        'modifiers': RawKeyEventDataMacOs.modifierLeftShift,
      });
      final RawKeyEventDataMacOs data = shiftLeftKeyEvent.data as RawKeyEventDataMacOs;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isEmpty);
    });

    test('Unprintable keyboard keys are correctly translated', () {
      final RawKeyEvent leftArrowKey = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x0000007B,
        'characters': '',
        'charactersIgnoringModifiers': '', // NSLeftArrowFunctionKey = 0xF702
        'modifiers': RawKeyEventDataMacOs.modifierFunction,
      });
      final RawKeyEventDataMacOs data = leftArrowKey.data as RawKeyEventDataMacOs;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.arrowLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.arrowLeft));
    });

    test('data.toString', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x00000060,
        'characters': 'A',
        'charactersIgnoringModifiers': 'a',
        'modifiers': 0x10,
      }).data.toString(), equalsIgnoringHashCodes(
        'RawKeyEventDataMacOs#00000(characters: A, charactersIgnoringModifiers: a, keyCode: 96, modifiers: 16)'));
    });

    test('data.equality', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x00000060,
        'characters': 'A',
        'charactersIgnoringModifiers': 'a',
        'modifiers': 0x10,
      }).data, const RawKeyEventDataMacOs(
        keyCode: 0x00000060,
        characters: 'A',
        charactersIgnoringModifiers: 'a',
        modifiers: 0x10,
      ));

      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x00000060,
        'characters': 'A',
        'charactersIgnoringModifiers': 'a',
        'modifiers': 0x10,
      }).data, isNot(equals(const RawKeyEventDataMacOs())));
    });
  }, skip: isBrowser); // [intended] This is a macOS-specific group.

  group('RawKeyEventDataIos', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      RawKeyEventDataIos.modifierOption | RawKeyEventDataIos.modifierLeftOption: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.left),
      RawKeyEventDataIos.modifierOption | RawKeyEventDataIos.modifierRightOption: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.right),
      RawKeyEventDataIos.modifierShift | RawKeyEventDataIos.modifierLeftShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.left),
      RawKeyEventDataIos.modifierShift | RawKeyEventDataIos.modifierRightShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.right),
      RawKeyEventDataIos.modifierControl | RawKeyEventDataIos.modifierLeftControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.left),
      RawKeyEventDataIos.modifierControl | RawKeyEventDataIos.modifierRightControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.right),
      RawKeyEventDataIos.modifierCommand | RawKeyEventDataIos.modifierLeftCommand: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.left),
      RawKeyEventDataIos.modifierCommand | RawKeyEventDataIos.modifierRightCommand: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.right),
      RawKeyEventDataIos.modifierOption: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.all),
      RawKeyEventDataIos.modifierShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.all),
      RawKeyEventDataIos.modifierControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.all),
      RawKeyEventDataIos.modifierCommand: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.all),
      RawKeyEventDataIos.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.all),
    };

    test('modifier keys are recognized individually', () {
      for (final int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'ios',
          'keyCode': 0x04,
          'characters': 'a',
          'charactersIgnoringModifiers': 'a',
          'modifiers': modifier,
        });
        final RawKeyEventDataIos data = event.data as RawKeyEventDataIos;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
            expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });

    test('modifier keys are recognized when combined', () {
      for (final int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataIos.modifierCapsLock) {
          // No need to combine caps lock key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'ios',
          'keyCode': 0x04,
          'characters': 'a',
          'charactersIgnoringModifiers': 'a',
          'modifiers': modifier | RawKeyEventDataIos.modifierCapsLock,
        });
        final RawKeyEventDataIos data = event.data as RawKeyEventDataIos;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key || key == ModifierKey.capsLockModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataIos.modifierCapsLock}, but isn't.",
            );
            if (key != ModifierKey.capsLockModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.all));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${RawKeyEventDataIos.modifierCapsLock}.',
            );
          }
        }
      }
    });

    test('Printable keyboard keys are correctly translated', () {
      const String unmodifiedCharacter = 'a';
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'ios',
        'keyCode': 0x00000004,
        'characters': 'a',
        'charactersIgnoringModifiers': unmodifiedCharacter,
        'modifiers': 0x0,
      });
      final RawKeyEventDataIos data = keyAEvent.data as RawKeyEventDataIos;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });

    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'ios',
        'keyCode': 0x00000029,
        'characters': '',
        'charactersIgnoringModifiers': '',
        'modifiers': 0x0,
      });
      final RawKeyEventDataIos data = escapeKeyEvent.data as RawKeyEventDataIos;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isEmpty);
    });

    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'ios',
        'keyCode': 0x000000e1,
        'characters': '',
        'charactersIgnoringModifiers': '',
        'modifiers': RawKeyEventDataIos.modifierLeftShift,
      });
      final RawKeyEventDataIos data = shiftLeftKeyEvent.data as RawKeyEventDataIos;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isEmpty);
    });

    test('Unprintable keyboard keys are correctly translated', () {
      final RawKeyEvent leftArrowKey = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'ios',
        'keyCode': 0x00000050,
        'characters': '',
        'charactersIgnoringModifiers': 'UIKeyInputLeftArrow',
        'modifiers': RawKeyEventDataIos.modifierFunction,
      });
      final RawKeyEventDataIos data = leftArrowKey.data as RawKeyEventDataIos;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.arrowLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.arrowLeft));
    });

    test('data.toString', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'ios',
        'keyCode': 0x00000004,
        'characters': 'A',
        'charactersIgnoringModifiers': 'a',
        'modifiers': 0x10,
      }).data.toString(), equalsIgnoringHashCodes(
        'RawKeyEventDataIos#00000(characters: A, charactersIgnoringModifiers: a, keyCode: 4, modifiers: 16)'));
    });

    test('data.equality', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'ios',
        'keyCode': 0x00000004,
        'characters': 'A',
        'charactersIgnoringModifiers': 'a',
        'modifiers': 0x10,
      }).data, const RawKeyEventDataIos(
        keyCode: 0x00000004,
        characters: 'A',
        charactersIgnoringModifiers: 'a',
        modifiers: 0x10,
      ));

      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'ios',
        'keyCode': 0x00000004,
        'characters': 'A',
        'charactersIgnoringModifiers': 'a',
        'modifiers': 0x10,
      }).data, isNot(equals(const RawKeyEventDataIos())));
    });
  }, skip: isBrowser); // [intended] This is an iOS-specific group.

  group('RawKeyEventDataWindows', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      RawKeyEventDataWindows.modifierLeftAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.left),
      RawKeyEventDataWindows.modifierRightAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.right),
      RawKeyEventDataWindows.modifierLeftShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.left),
      RawKeyEventDataWindows.modifierRightShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.right),
      RawKeyEventDataWindows.modifierLeftControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.left),
      RawKeyEventDataWindows.modifierRightControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.right),
      RawKeyEventDataWindows.modifierLeftMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.left),
      RawKeyEventDataWindows.modifierRightMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.right),
      RawKeyEventDataWindows.modifierShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.all),
      RawKeyEventDataWindows.modifierControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.all),
      RawKeyEventDataWindows.modifierAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.all),
      RawKeyEventDataWindows.modifierCaps: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.all),
      RawKeyEventDataWindows.modifierNumLock: _ModifierCheck(ModifierKey.numLockModifier, KeyboardSide.all),
      RawKeyEventDataWindows.modifierScrollLock: _ModifierCheck(ModifierKey.scrollLockModifier, KeyboardSide.all),
    };

    test('modifier keys are recognized individually', () {
      for (final int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'windows',
          'keyCode': 0x04,
          'characterCodePoint': 0,
          'scanCode': 0x04,
          'modifiers': modifier,
        });
        final RawKeyEventDataWindows data = event.data as RawKeyEventDataWindows;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: "$key should be pressed with modifier $modifier, but isn't.",
            );
            expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });

    test('modifier keys are recognized when combined', () {
      for (final int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataWindows.modifierCaps) {
          // No need to combine caps lock key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'windows',
          'keyCode': 0x04,
          'characterCodePoint': 0,
          'scanCode': 0x04,
          'modifiers': modifier | RawKeyEventDataWindows.modifierCaps,
        });
        final RawKeyEventDataWindows data = event.data as RawKeyEventDataWindows;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key || key == ModifierKey.capsLockModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataWindows.modifierCaps}, but isn't.",
            );
            if (key != ModifierKey.capsLockModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.all));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${RawKeyEventDataWindows.modifierCaps}.',
            );
          }
        }
      }
    });

    test('Printable keyboard keys are correctly translated', () {
      const int unmodifiedCharacter = 97; // ASCII value for 'a'.
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'windows',
        'keyCode': 0x00000000,
        'characterCodePoint': unmodifiedCharacter,
        'scanCode': 0x0000001e,
        'modifiers': 0x0,
      });
      final RawKeyEventDataWindows data = keyAEvent.data as RawKeyEventDataWindows;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });

    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'windows',
        'keyCode': 27, // keycode for escape key
        'scanCode': 0x00000001, // scanCode for escape key
        'characterCodePoint': 0,
        'modifiers': 0x0,
      });
      final RawKeyEventDataWindows data = escapeKeyEvent.data as RawKeyEventDataWindows;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isEmpty);
    });

    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'windows',
        'keyCode': 160, // keyCode for left shift.
        'scanCode': 0x0000002a,  // scanCode for left shift.
        'characterCodePoint': 0,
        'modifiers': RawKeyEventDataWindows.modifierLeftShift,
      });
      final RawKeyEventDataWindows data = shiftLeftKeyEvent.data as RawKeyEventDataWindows;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isEmpty);
    });

    test('Unprintable keyboard keys are correctly translated', () {
      final RawKeyEvent leftArrowKey = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'windows',
        'keyCode': 37, // keyCode for left arrow.
        'scanCode': 0x0000e04b, // scanCode for left arrow.
        'characterCodePoint': 0,
        'modifiers': 0,
      });
      final RawKeyEventDataWindows data = leftArrowKey.data as RawKeyEventDataWindows;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.arrowLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.arrowLeft));
    });

    testWidgets('Win32 VK_PROCESSKEY events are skipped', (WidgetTester tester) async {
      const  String platform = 'windows';
      bool lastHandled = true;
      final List<RawKeyEvent> events = <RawKeyEvent>[];
      // Simulate raw events because VK_PROCESSKEY does not exist in the key mapping.
      Future<void> simulateKeyEventMessage(String type, int keyCode, int scanCode) {
        return ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.keyEvent.name,
          SystemChannels.keyEvent.codec.encodeMessage(<String, dynamic>{
            'type': type,
            'keymap': platform,
            'keyCode': keyCode,
            'scanCode': scanCode,
            'modifiers': 0,
          }),
          (ByteData? data) {
            final Map<String, dynamic> decoded = SystemChannels.keyEvent.codec.decodeMessage(data) as Map<String, dynamic>;
            lastHandled = decoded['handled'] as bool;
          },
        );
      }
      RawKeyboard.instance.addListener(events.add);
      await simulateKeyEventMessage('keydown', 229, 30);
      expect(events, isEmpty);
      expect(lastHandled, true);
      expect(RawKeyboard.instance.keysPressed, isEmpty);
      await simulateKeyEventMessage('keyup', 65, 30);
      expect(events, isEmpty);
      expect(lastHandled, true);
      expect(RawKeyboard.instance.keysPressed, isEmpty);
    });

    test('data.toString', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'windows',
        'keyCode': 0x00000010,
        'characterCodePoint': 10,
        'scanCode': 0x0000001e,
        'modifiers': 0x20,
      }).data.toString(), equalsIgnoringHashCodes(
        'RawKeyEventDataWindows#00000(keyCode: 16, scanCode: 30, characterCodePoint: 10, modifiers: 32)'));
    });

    test('data.equality', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'windows',
        'keyCode': 0x00000010,
        'characterCodePoint': 10,
        'scanCode': 0x0000001e,
        'modifiers': 0x20,
      }).data, const RawKeyEventDataWindows(
        keyCode: 0x00000010,
        scanCode: 0x1e,
        modifiers: 0x20,
        characterCodePoint: 10,
      ));

      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'windows',
        'keyCode': 0x00000010,
        'characterCodePoint': 10,
        'scanCode': 0x0000001e,
        'modifiers': 0x20,
      }).data, isNot(equals(const RawKeyEventDataWindows())));
    });
  }, skip: isBrowser); // [intended] This is a Windows-specific group.

  group('RawKeyEventDataLinux-GLFW', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      GLFWKeyHelper.modifierAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.all),
      GLFWKeyHelper.modifierShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.all),
      GLFWKeyHelper.modifierControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.all),
      GLFWKeyHelper.modifierMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.all),
      GLFWKeyHelper.modifierNumericPad: _ModifierCheck(ModifierKey.numLockModifier, KeyboardSide.all),
      GLFWKeyHelper.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.all),
    };

    // How modifiers are interpreted depends upon the keyCode for GLFW.
    int keyCodeForModifier(int modifier, {required bool isLeft}) {
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
      for (final int modifier in modifierTests.keys) {
        for (final bool isDown in <bool>[true, false]) {
          for (final bool isLeft in <bool>[true, false]) {
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
            final RawKeyEventDataLinux data = event.data as RawKeyEventDataLinux;
            for (final ModifierKey key in ModifierKey.values) {
              if (modifierTests[modifier]!.key == key) {
                expect(
                  data.isModifierPressed(key, side: modifierTests[modifier]!.side),
                  isDown ? isTrue : isFalse,
                  reason: "${isLeft ? 'left' : 'right'} $key ${isDown ? 'should' : 'should not'} be pressed with metaState $modifier, when key is ${isDown ? 'down' : 'up'}, but isn't.",
                );
                expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
              } else {
                expect(
                  data.isModifierPressed(key, side: modifierTests[modifier]!.side),
                  isFalse,
                  reason: "${isLeft ? 'left' : 'right'} $key should not be pressed with metaState $modifier, when key is ${isDown ? 'down' : 'up'}, but is.",
                );
              }
            }
          }
        }
      }
    });

    test('modifier keys are recognized when combined', () {
      for (final int modifier in modifierTests.keys) {
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
        final RawKeyEventDataLinux data = event.data as RawKeyEventDataLinux;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key || key == ModifierKey.controlModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${GLFWKeyHelper.modifierControl}, but isn't.",
            );
            if (key != ModifierKey.controlModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.all));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
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
      final RawKeyEventDataLinux data = keyAEvent.data as RawKeyEventDataLinux;
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
      final RawKeyEventDataLinux data = keyAEvent.data as RawKeyEventDataLinux;
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
      final RawKeyEventDataLinux data = escapeKeyEvent.data as RawKeyEventDataLinux;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isEmpty);
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
      final RawKeyEventDataLinux data = shiftLeftKeyEvent.data as RawKeyEventDataLinux;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isEmpty);
    });

    test('data.toString', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'glfw',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 0x10FFFF,
        'modifiers': 0x10,
      }).data.toString(), equalsIgnoringHashCodes(
       'RawKeyEventDataLinux#00000(toolkit: GLFW, unicodeScalarValues: 1114111, scanCode: 38, keyCode: 65, modifiers: 16, isDown: true)'));
    });

    test('data.equality', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'glfw',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 0x10FFFF,
        'modifiers': 0x10,
      }).data, RawKeyEventDataLinux(
        keyHelper: KeyHelper('glfw'),
        unicodeScalarValues: 0x10FFFF,
        keyCode: 65,
        scanCode: 0x26,
        modifiers: 0x10,
        isDown: true,
      ));

      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'glfw',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 0x10FFFF,
        'modifiers': 0x10,
      }).data, isNot(equals(RawKeyEventDataLinux(
        keyHelper: KeyHelper('glfw'), isDown: true)),
      ));
    });
  }, skip: isBrowser); // [intended] This is a GLFW-specific group.

  group('RawKeyEventDataLinux-GTK', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      GtkKeyHelper.modifierMod1: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.all),
      GtkKeyHelper.modifierShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.all),
      GtkKeyHelper.modifierControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.all),
      GtkKeyHelper.modifierMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.all),
      GtkKeyHelper.modifierMod2: _ModifierCheck(ModifierKey.numLockModifier, KeyboardSide.all),
      GtkKeyHelper.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.all),
    };

    // How modifiers are interpreted depends upon the keyCode for GTK.
    int keyCodeForModifier(int modifier, {required bool isLeft}) {
      switch (modifier) {
        case GtkKeyHelper.modifierMod1:
          return 65513;
        case GtkKeyHelper.modifierShift:
          return isLeft ? 65505 : 65506;
        case GtkKeyHelper.modifierControl:
          return isLeft ? 65507 : 65508;
        case GtkKeyHelper.modifierMeta:
          return isLeft ? 65515 : 65516;
        case GtkKeyHelper.modifierMod2:
          return 65407;
        case GtkKeyHelper.modifierCapsLock:
          return 65509;
        default:
          return 65; // keyA
      }
    }

    test('modifier keys are recognized individually', () {
      for (final int modifier in modifierTests.keys) {
        for (final bool isDown in <bool>[true, false]) {
          for (final bool isLeft in <bool>[true, false]) {
            final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
              'type': isDown ? 'keydown' : 'keyup',
              'keymap': 'linux',
              'toolkit': 'gtk',
              'keyCode': keyCodeForModifier(modifier, isLeft: isLeft),
              'scanCode': 0x00000026,
              'unicodeScalarValues': 97,
              // GTK modifiers don't include the current key event.
              'modifiers': isDown ? 0 : modifier,
            });
            final RawKeyEventDataLinux data = event.data as RawKeyEventDataLinux;
            for (final ModifierKey key in ModifierKey.values) {
              if (modifierTests[modifier]!.key == key) {
                expect(
                  data.isModifierPressed(key, side: modifierTests[modifier]!.side),
                  isDown ? isTrue : isFalse,
                  reason: "${isLeft ? 'left' : 'right'} $key ${isDown ? 'should' : 'should not'} be pressed with metaState $modifier, when key is ${isDown ? 'down' : 'up'}, but isn't.",
                );
                expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
              } else {
                expect(
                  data.isModifierPressed(key, side: modifierTests[modifier]!.side),
                  isFalse,
                  reason: "${isLeft ? 'left' : 'right'} $key should not be pressed with metaState $modifier, when key is ${isDown ? 'down' : 'up'}, but is.",
                );
              }
            }
          }
        }
      }
    });

    test('modifier keys are recognized when combined', () {
      for (final int modifier in modifierTests.keys) {
        if (modifier == GtkKeyHelper.modifierControl) {
          // No need to combine CTRL key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'linux',
          'toolkit': 'gtk',
          'keyCode': 65,
          'scanCode': 0x00000026,
          'unicodeScalarValues': 97,
          'modifiers': modifier | GtkKeyHelper.modifierControl,
        });
        final RawKeyEventDataLinux data = event.data as RawKeyEventDataLinux;
        for (final ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier]!.key == key || key == ModifierKey.controlModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${GtkKeyHelper.modifierControl}, but isn't.",
            );
            if (key != ModifierKey.controlModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier]!.side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.all));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier]!.side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${GtkKeyHelper.modifierControl}.',
            );
          }
        }
      }
    });

    test('Printable keyboard keys are correctly translated', () {
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'gtk',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 113,
        'modifiers': 0x0,
      });
      final RawKeyEventDataLinux data = keyAEvent.data as RawKeyEventDataLinux;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyQ));
      expect(data.keyLabel, equals('q'));
    });

    test('Code points with two Unicode scalar values are allowed', () {
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'gtk',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 0x10FFFF,
        'modifiers': 0x0,
      });
      final RawKeyEventDataLinux data = keyAEvent.data as RawKeyEventDataLinux;
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
          'toolkit': 'gtk',
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
        'toolkit': 'gtk',
        'keyCode': 65307,
        'scanCode': 0x00000009,
        'unicodeScalarValues': 0,
        'modifiers': 0x0,
      });
      final RawKeyEventDataLinux data = escapeKeyEvent.data as RawKeyEventDataLinux;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isEmpty);
    });

    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'gtk',
        'keyCode': 65505,
        'scanCode': 0x00000032,
        'unicodeScalarValues': 0,
      });
      final RawKeyEventDataLinux data = shiftLeftKeyEvent.data as RawKeyEventDataLinux;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isEmpty);
    });

    test('data.toString', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'gtk',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 113,
        'modifiers': 0x10,
      }).data.toString(), equalsIgnoringHashCodes(
        'RawKeyEventDataLinux#00000(toolkit: GTK, unicodeScalarValues: 113, scanCode: 38, keyCode: 65, modifiers: 16, isDown: true)'));
    });

    test('data.equality', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'gtk',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 113,
        'modifiers': 0x10,
      }).data, RawKeyEventDataLinux(
        keyHelper: KeyHelper('gtk'),
        unicodeScalarValues: 113,
        keyCode: 65,
        scanCode: 0x26,
        modifiers: 0x10,
        isDown: true,
      ));

      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'gtk',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 113,
        'modifiers': 0x10,
      }).data, isNot(equals(RawKeyEventDataLinux(
        keyHelper: KeyHelper('glfw'),
        unicodeScalarValues: 113,
        keyCode: 65,
        scanCode: 0x26,
        modifiers: 0x10,
        isDown: true,
      ))));

      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'gtk',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'unicodeScalarValues': 113,
        'modifiers': 0x10,
      }).data, isNot(equals(RawKeyEventDataLinux(
        keyHelper: KeyHelper('gtk'), isDown: true)),
      ));
    });
  }, skip: isBrowser); // [intended] This is a GTK-specific group.

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
      for (final int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'web',
          'code': 'RandomCode',
          'metaState': modifier,
        });
        final RawKeyEventDataWeb data = event.data as RawKeyEventDataWeb;
        for (final ModifierKey key in ModifierKey.values) {
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
      for (final int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataWeb.modifierMeta) {
          // No need to combine meta key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'web',
          'code': 'RandomCode',
          'metaState': modifier | RawKeyEventDataWeb.modifierMeta,
        });
        final RawKeyEventDataWeb data = event.data as RawKeyEventDataWeb;
        for (final ModifierKey key in ModifierKey.values) {
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
        'location': 0,
        'metaState': 0x0,
      });
      final RawKeyEventDataWeb data = keyAEvent.data as RawKeyEventDataWeb;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });

    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'Escape',
        'key': 'Escape',
        'location': 0,
        'metaState': 0x0,
      });
      final RawKeyEventDataWeb data = escapeKeyEvent.data as RawKeyEventDataWeb;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isEmpty);
    });

    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'ShiftLeft',
        'key': 'Shift',
        'location': 1,
        'metaState': RawKeyEventDataWeb.modifierShift,
      });
      final RawKeyEventDataWeb data = shiftKeyEvent.data as RawKeyEventDataWeb;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isEmpty);
    });

    test('Arrow keys from a keyboard give correct physical key mappings', () {
      final RawKeyEvent arrowKeyDown = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'ArrowDown',
        'key': 'ArrowDown',
        'location': 0,
        'metaState': 0x0,
      });
      final RawKeyEventDataWeb data = arrowKeyDown.data as RawKeyEventDataWeb;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.arrowDown));
      expect(data.logicalKey, equals(LogicalKeyboardKey.arrowDown));
      expect(data.keyLabel, isEmpty);
    });

    test('Unrecognized keys are mapped to Web plane', () {
      final RawKeyEvent arrowKeyDown = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'Unrecog1',
        'key': 'Unrecog2',
        'location': 0,
        'metaState': 0x0,
      });
      final RawKeyEventDataWeb data = arrowKeyDown.data as RawKeyEventDataWeb;
      // This might be easily broken on Web if the code fails to acknowledge
      // that JavaScript doesn't handle 64-bit bit-wise operation.
      expect(data.physicalKey.usbHidUsage, greaterThan(0x01700000000));
      expect(data.physicalKey.usbHidUsage, lessThan(0x01800000000));
      expect(data.logicalKey.keyId, greaterThan(0x01700000000));
      expect(data.logicalKey.keyId, lessThan(0x01800000000));
      expect(data.keyLabel, isEmpty);
    });

    test('data.toString', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'KeyA',
        'key': 'a',
        'location': 2,
        'metaState': 0x10,
      }).data.toString(), equalsIgnoringHashCodes(
        'RawKeyEventDataWeb#00000(code: KeyA, key: a, location: 2, metaState: 16)'));

      // Without location
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'KeyA',
        'key': 'a',
        'metaState': 0x10,
      }).data.toString(), equalsIgnoringHashCodes(
        'RawKeyEventDataWeb#00000(code: KeyA, key: a, location: 0, metaState: 16)'));
    });

    test('data.equality', () {
      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'KeyA',
        'key': 'a',
        'location': 2,
        'metaState': 0x10,
      }).data, const RawKeyEventDataWeb(
        key: 'a',
        code: 'KeyA',
        location: 2,
        metaState: 0x10,
      ));

      expect(RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'KeyA',
        'key': 'a',
        'location': 2,
        'metaState': 0x10,
      }).data, isNot(equals(const RawKeyEventDataWeb(code: 'KeyA', key: 'a'))));
    });
  });
}
