// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'test_async_utils.dart';

// TODO(gspencergoog): Replace this with more robust key simulation code once
// the new key event code is in.
// https://github.com/flutter/flutter/issues/33521
// This code can only simulate keys which appear in the key maps.

String _keyLabel(LogicalKeyboardKey key) {
  final String keyLabel = key.keyLabel;
  if (keyLabel.length == 1)
    return keyLabel.toLowerCase();
  return '';
}

/// A class that serves as a namespace for a bunch of keyboard-key generation
/// utilities.
class KeyEventSimulator {
  // Look up a synonym key, and just return the left version of it.
  static LogicalKeyboardKey _getKeySynonym(LogicalKeyboardKey origKey) {
    if (origKey == LogicalKeyboardKey.shift) {
      return LogicalKeyboardKey.shiftLeft;
    }
    if (origKey == LogicalKeyboardKey.alt) {
      return LogicalKeyboardKey.altLeft;
    }
    if (origKey == LogicalKeyboardKey.meta) {
      return LogicalKeyboardKey.metaLeft;
    }
    if (origKey == LogicalKeyboardKey.control) {
      return LogicalKeyboardKey.controlLeft;
    }
    return origKey;
  }

  static bool _osIsSupported(String platform) {
    switch (platform) {
      case 'android':
      case 'fuchsia':
      case 'macos':
      case 'linux':
      case 'web':
      case 'ios':
      case 'windows':
        return true;
    }
    return false;
  }

  static int _getScanCode(PhysicalKeyboardKey key, String platform) {
    assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');
    late Map<int, PhysicalKeyboardKey> map;
    switch (platform) {
      case 'android':
        map = kAndroidToPhysicalKey;
        break;
      case 'fuchsia':
        map = kFuchsiaToPhysicalKey;
        break;
      case 'macos':
        map = kMacOsToPhysicalKey;
        break;
      case 'ios':
        map = kIosToPhysicalKey;
        break;
      case 'linux':
        map = kLinuxToPhysicalKey;
        break;
      case 'windows':
        map = kWindowsToPhysicalKey;
        break;
      case 'web':
        // web doesn't have int type code
        return -1;
    }
    int? scanCode;
    for (final int code in map.keys) {
      if (key.usbHidUsage == map[code]!.usbHidUsage) {
        scanCode = code;
        break;
      }
    }
    assert(scanCode != null, 'Physical key for $key not found in $platform scanCode map');
    return scanCode!;
  }

  static int _getKeyCode(LogicalKeyboardKey key, String platform) {
    assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');
    if (kIsWeb) {
      // web doesn't have int type code. This check is used to treeshake
      // keyboard map code.
      return -1;
    } else {
      late Map<int, LogicalKeyboardKey> map;
      switch (platform) {
        case 'android':
          map = kAndroidToLogicalKey;
          break;
        case 'fuchsia':
          map = kFuchsiaToLogicalKey;
          break;
        case 'macos':
        // macOS doesn't do key codes, just scan codes.
          return -1;
        case 'ios':
        // iOS doesn't do key codes, just scan codes.
          return -1;
        case 'web':
          // web doesn't have int type code.
          return -1;
        case 'linux':
          map = kGlfwToLogicalKey;
          break;
        case 'windows':
          map = kWindowsToLogicalKey;
          break;
      }
      int? keyCode;
      for (final int code in map.keys) {
        if (key.keyId == map[code]!.keyId) {
          keyCode = code;
          break;
        }
      }
      assert(keyCode != null, 'Key $key not found in $platform keyCode map');
      return keyCode!;
    }
  }

  static String _getWebKeyCode(LogicalKeyboardKey key) {
    String? result;
    for (final String code in kWebToLogicalKey.keys) {
      if (key.keyId == kWebToLogicalKey[code]!.keyId) {
        result = code;
        break;
      }
    }
    assert(result != null, 'Key $key not found in web keyCode map');
    return result!;
  }

  static PhysicalKeyboardKey _findPhysicalKey(LogicalKeyboardKey key, String platform) {
    assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');
    late Map<dynamic, PhysicalKeyboardKey> map;
    if (kIsWeb) {
      // This check is used to treeshake keymap code.
      map = kWebToPhysicalKey;
    } else {
      switch (platform) {
        case 'android':
          map = kAndroidToPhysicalKey;
          break;
        case 'fuchsia':
          map = kFuchsiaToPhysicalKey;
          break;
        case 'macos':
          map = kMacOsToPhysicalKey;
          break;
        case 'ios':
          map = kIosToPhysicalKey;
          break;
        case 'linux':
          map = kLinuxToPhysicalKey;
          break;
        case 'web':
          map = kWebToPhysicalKey;
          break;
        case 'windows':
          map = kWindowsToPhysicalKey;
          break;
      }
    }
    PhysicalKeyboardKey? result;
    for (final PhysicalKeyboardKey physicalKey in map.values) {
      if (key.debugName == physicalKey.debugName) {
        result = physicalKey;
        break;
      }
    }
    assert(result != null, 'Physical key for $key not found in $platform physical key map');
    return result!;
  }

  /// Get a raw key data map given a [LogicalKeyboardKey] and a platform.
  static Map<String, dynamic> getKeyData(
    LogicalKeyboardKey key, {
    required String platform,
    bool isDown = true,
    PhysicalKeyboardKey? physicalKey,
  }) {
    assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');

    key = _getKeySynonym(key);

    // Find a suitable physical key if none was supplied.
    physicalKey ??= _findPhysicalKey(key, platform);

    assert(key.debugName != null);
    final int keyCode = _getKeyCode(key, platform);
    final int scanCode = _getScanCode(physicalKey, platform);

    final Map<String, dynamic> result = <String, dynamic>{
      'type': isDown ? 'keydown' : 'keyup',
      'keymap': platform,
    };

    if (kIsWeb) {
      result['code'] = _getWebKeyCode(key);
      result['key'] = _keyLabel(key);
      result['metaState'] = _getWebModifierFlags(key, isDown);
      return result;
    }

    switch (platform) {
      case 'android':
        result['keyCode'] = keyCode;
        if (_keyLabel(key).isNotEmpty) {
          result['codePoint'] = _keyLabel(key).codeUnitAt(0);
          result['character'] = _keyLabel(key);
        }
        result['scanCode'] = scanCode;
        result['metaState'] = _getAndroidModifierFlags(key, isDown);
        break;
      case 'fuchsia':
        result['hidUsage'] = physicalKey.usbHidUsage;
        if (_keyLabel(key).isNotEmpty) {
          result['codePoint'] = _keyLabel(key).codeUnitAt(0);
        }
        result['modifiers'] = _getFuchsiaModifierFlags(key, isDown);
        break;
      case 'linux':
        result['toolkit'] = 'glfw';
        result['keyCode'] = keyCode;
        result['scanCode'] = scanCode;
        result['modifiers'] = _getGlfwModifierFlags(key, isDown);
        result['unicodeScalarValues'] = _keyLabel(key).isNotEmpty ? _keyLabel(key).codeUnitAt(0) : 0;
        break;
      case 'macos':
        result['keyCode'] = scanCode;
        if (_keyLabel(key).isNotEmpty) {
          result['characters'] = _keyLabel(key);
          result['charactersIgnoringModifiers'] = _keyLabel(key);
        }
        result['modifiers'] = _getMacOsModifierFlags(key, isDown);
        break;
      case 'ios':
        result['keyCode'] = scanCode;
        result['characters'] = _keyLabel(key);
        result['charactersIgnoringModifiers'] = _keyLabel(key);
        result['modifiers'] = _getIOSModifierFlags(key, isDown);
        break;
      case 'web':
        result['code'] = _getWebKeyCode(key);
        result['key'] = _keyLabel(key);
        result['metaState'] = _getWebModifierFlags(key, isDown);
        break;
      case 'windows':
        result['keyCode'] = keyCode;
        result['scanCode'] = scanCode;
        if (_keyLabel(key).isNotEmpty) {
          result['characterCodePoint'] = _keyLabel(key).codeUnitAt(0);
        }
        result['modifiers'] = _getWindowsModifierFlags(key, isDown);
    }
    return result;
  }

  static int _getAndroidModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataAndroid.modifierLeftShift | RawKeyEventDataAndroid.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataAndroid.modifierRightShift | RawKeyEventDataAndroid.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataAndroid.modifierLeftMeta | RawKeyEventDataAndroid.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataAndroid.modifierRightMeta | RawKeyEventDataAndroid.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataAndroid.modifierLeftControl | RawKeyEventDataAndroid.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataAndroid.modifierRightControl | RawKeyEventDataAndroid.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataAndroid.modifierLeftAlt | RawKeyEventDataAndroid.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataAndroid.modifierRightAlt | RawKeyEventDataAndroid.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.fn)) {
      result |= RawKeyEventDataAndroid.modifierFunction;
    }
    if (pressed.contains(LogicalKeyboardKey.scrollLock)) {
      result |= RawKeyEventDataAndroid.modifierScrollLock;
    }
    if (pressed.contains(LogicalKeyboardKey.numLock)) {
      result |= RawKeyEventDataAndroid.modifierNumLock;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataAndroid.modifierCapsLock;
    }
    return result;
  }

  static int _getGlfwModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft) || pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= GLFWKeyHelper.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft) || pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= GLFWKeyHelper.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft) || pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= GLFWKeyHelper.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft) || pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= GLFWKeyHelper.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= GLFWKeyHelper.modifierCapsLock;
    }
    return result;
  }

  static int _getWindowsModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shift)) {
      result |= RawKeyEventDataWindows.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataWindows.modifierLeftShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataWindows.modifierRightShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataWindows.modifierLeftMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataWindows.modifierRightMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.control)) {
      result |= RawKeyEventDataWindows.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataWindows.modifierLeftControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataWindows.modifierRightControl;
    }
    if (pressed.contains(LogicalKeyboardKey.alt)) {
      result |= RawKeyEventDataWindows.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataWindows.modifierLeftAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataWindows.modifierRightAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataWindows.modifierCaps;
    }
    if (pressed.contains(LogicalKeyboardKey.numLock)) {
      result |= RawKeyEventDataWindows.modifierNumLock;
    }
    if (pressed.contains(LogicalKeyboardKey.scrollLock)) {
      result |= RawKeyEventDataWindows.modifierScrollLock;
    }
    return result;
  }

  static int _getFuchsiaModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataFuchsia.modifierLeftShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataFuchsia.modifierRightShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataFuchsia.modifierLeftMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataFuchsia.modifierRightMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataFuchsia.modifierLeftControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataFuchsia.modifierRightControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataFuchsia.modifierLeftAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataFuchsia.modifierRightAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataFuchsia.modifierCapsLock;
    }
    return result;
  }

  static int _getWebModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataWeb.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataWeb.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataWeb.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataWeb.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataWeb.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataWeb.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataWeb.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataWeb.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataWeb.modifierCapsLock;
    }
    if (pressed.contains(LogicalKeyboardKey.numLock)) {
      result |= RawKeyEventDataWeb.modifierNumLock;
    }
    if (pressed.contains(LogicalKeyboardKey.scrollLock)) {
      result |= RawKeyEventDataWeb.modifierScrollLock;
    }
    return result;
  }

  static int _getMacOsModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataMacOs.modifierLeftShift | RawKeyEventDataMacOs.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataMacOs.modifierRightShift | RawKeyEventDataMacOs.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataMacOs.modifierLeftCommand | RawKeyEventDataMacOs.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataMacOs.modifierRightCommand | RawKeyEventDataMacOs.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataMacOs.modifierLeftControl | RawKeyEventDataMacOs.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataMacOs.modifierRightControl | RawKeyEventDataMacOs.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataMacOs.modifierLeftOption | RawKeyEventDataMacOs.modifierOption;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataMacOs.modifierRightOption | RawKeyEventDataMacOs.modifierOption;
    }
    final Set<LogicalKeyboardKey> functionKeys = <LogicalKeyboardKey>{
      LogicalKeyboardKey.f1,
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.f3,
      LogicalKeyboardKey.f4,
      LogicalKeyboardKey.f5,
      LogicalKeyboardKey.f6,
      LogicalKeyboardKey.f7,
      LogicalKeyboardKey.f8,
      LogicalKeyboardKey.f9,
      LogicalKeyboardKey.f10,
      LogicalKeyboardKey.f11,
      LogicalKeyboardKey.f12,
      LogicalKeyboardKey.f13,
      LogicalKeyboardKey.f14,
      LogicalKeyboardKey.f15,
      LogicalKeyboardKey.f16,
      LogicalKeyboardKey.f17,
      LogicalKeyboardKey.f18,
      LogicalKeyboardKey.f19,
      LogicalKeyboardKey.f20,
      LogicalKeyboardKey.f21,
    };
    if (pressed.intersection(functionKeys).isNotEmpty) {
      result |= RawKeyEventDataMacOs.modifierFunction;
    }
    if (pressed.intersection(kMacOsNumPadMap.values.toSet()).isNotEmpty) {
      result |= RawKeyEventDataMacOs.modifierNumericPad;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataMacOs.modifierCapsLock;
    }
    return result;
  }

  static int _getIOSModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataIos.modifierLeftShift | RawKeyEventDataIos.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataIos.modifierRightShift | RawKeyEventDataIos.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataIos.modifierLeftCommand | RawKeyEventDataIos.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataIos.modifierRightCommand | RawKeyEventDataIos.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataIos.modifierLeftControl | RawKeyEventDataIos.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataIos.modifierRightControl | RawKeyEventDataIos.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataIos.modifierLeftOption | RawKeyEventDataIos.modifierOption;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataIos.modifierRightOption | RawKeyEventDataIos.modifierOption;
    }
    final Set<LogicalKeyboardKey> functionKeys = <LogicalKeyboardKey>{
      LogicalKeyboardKey.f1,
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.f3,
      LogicalKeyboardKey.f4,
      LogicalKeyboardKey.f5,
      LogicalKeyboardKey.f6,
      LogicalKeyboardKey.f7,
      LogicalKeyboardKey.f8,
      LogicalKeyboardKey.f9,
      LogicalKeyboardKey.f10,
      LogicalKeyboardKey.f11,
      LogicalKeyboardKey.f12,
      LogicalKeyboardKey.f13,
      LogicalKeyboardKey.f14,
      LogicalKeyboardKey.f15,
      LogicalKeyboardKey.f16,
      LogicalKeyboardKey.f17,
      LogicalKeyboardKey.f18,
      LogicalKeyboardKey.f19,
      LogicalKeyboardKey.f20,
      LogicalKeyboardKey.f21,
    };
    if (pressed.intersection(functionKeys).isNotEmpty) {
      result |= RawKeyEventDataIos.modifierFunction;
    }
    if (pressed.intersection(kMacOsNumPadMap.values.toSet()).isNotEmpty) {
      result |= RawKeyEventDataIos.modifierNumericPad;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataIos.modifierCapsLock;
    }
    return result;
  }

  /// Simulates sending a hardware key down event through the system channel.
  ///
  /// This only simulates key presses coming from a physical keyboard, not from a
  /// soft keyboard.
  ///
  /// Specify `platform` as one of the platforms allowed in
  /// [Platform.operatingSystem] to make the event appear to be from that type of
  /// system. Defaults to the operating system that the test is running on. Some
  /// platforms (e.g. Windows, iOS) are not yet supported.
  ///
  /// Keys that are down when the test completes are cleared after each test.
  ///
  /// Returns true if the key event was handled by the framework.
  ///
  /// See also:
  ///
  ///  - [simulateKeyUpEvent] to simulate the corresponding key up event.
  static Future<bool> simulateKeyDownEvent(LogicalKeyboardKey key, {String? platform, PhysicalKeyboardKey? physicalKey}) async {
    return TestAsyncUtils.guard<bool>(() async {
      platform ??= Platform.operatingSystem;
      assert(_osIsSupported(platform!), 'Platform $platform not supported for key simulation');

      final Map<String, dynamic> data = getKeyData(key, platform: platform!, isDown: true, physicalKey: physicalKey);
      bool result = false;
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {
          if (data == null) {
            return;
          }
          final Map<String, dynamic> decoded = SystemChannels.keyEvent.codec.decodeMessage(data) as Map<String, dynamic>;
          if (decoded['handled'] as bool) {
            result = true;
          }
        }
      );
      return result;
    });
  }

  /// Simulates sending a hardware key up event through the system channel.
  ///
  /// This only simulates key presses coming from a physical keyboard, not from a
  /// soft keyboard.
  ///
  /// Specify `platform` as one of the platforms allowed in
  /// [Platform.operatingSystem] to make the event appear to be from that type of
  /// system. Defaults to the operating system that the test is running on. Some
  /// platforms (e.g. Windows, iOS) are not yet supported.
  ///
  /// Returns true if the key event was handled by the framework.
  ///
  /// See also:
  ///
  ///  - [simulateKeyDownEvent] to simulate the corresponding key down event.
  static Future<bool> simulateKeyUpEvent(LogicalKeyboardKey key, {String? platform, PhysicalKeyboardKey? physicalKey}) async {
    return TestAsyncUtils.guard<bool>(() async {
      platform ??= Platform.operatingSystem;
      assert(_osIsSupported(platform!), 'Platform $platform not supported for key simulation');

      final Map<String, dynamic> data = getKeyData(key, platform: platform!, isDown: false, physicalKey: physicalKey);
      bool result = false;
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(data),
        (ByteData? data) {
          if (data == null) {
            return;
          }
          final Map<String, dynamic> decoded = SystemChannels.keyEvent.codec.decodeMessage(data) as Map<String, dynamic>;
          if (decoded['handled'] as bool) {
            result = true;
          }
        }
      );
      return result;
    });
  }
}

/// Simulates sending a hardware key down event through the system channel.
///
/// It is intended for use in writing tests.
///
/// This only simulates key presses coming from a physical keyboard, not from a
/// soft keyboard, and it can only simulate keys that appear in the key maps
/// such as [kAndroidToLogicalKey], [kMacOsToPhysicalKey], etc.
///
/// Specify `platform` as one of the platforms allowed in
/// [Platform.operatingSystem] to make the event appear to be from that type of
/// system. Defaults to the operating system that the test is running on. Some
/// platforms (e.g. Windows, iOS) are not yet supported.
///
/// Keys that are down when the test completes are cleared after each test.
///
/// Returns true if the key event was handled by the framework.
///
/// See also:
///
///  - [simulateKeyUpEvent] to simulate the corresponding key up event.
Future<bool> simulateKeyDownEvent(LogicalKeyboardKey key, {String? platform, PhysicalKeyboardKey? physicalKey}) {
  return KeyEventSimulator.simulateKeyDownEvent(key, platform: platform, physicalKey: physicalKey);
}

/// Simulates sending a hardware key up event through the system channel.
///
/// It is intended for use in writing tests.
///
/// This only simulates key presses coming from a physical keyboard, not from a
/// soft keyboard, and it can only simulate keys that appear in the key maps
/// such as [kAndroidToLogicalKey], [kMacOsToPhysicalKey], etc.
///
/// Specify `platform` as one of the platforms allowed in
/// [Platform.operatingSystem] to make the event appear to be from that type of
/// system. Defaults to the operating system that the test is running on. Some
/// platforms (e.g. Windows, iOS) are not yet supported.
///
/// Returns true if the key event was handled by the framework.
///
/// See also:
///
///  - [simulateKeyDownEvent] to simulate the corresponding key down event.
Future<bool> simulateKeyUpEvent(LogicalKeyboardKey key, {String? platform, PhysicalKeyboardKey? physicalKey}) {
  return KeyEventSimulator.simulateKeyUpEvent(key, platform: platform, physicalKey: physicalKey);
}
