// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'binding.dart';
import 'test_async_utils.dart';
import 'widget_tester.dart';

// A tuple of `key` and `location` from Web's `KeyboardEvent` class.
//
// See [RawKeyEventDataWeb]'s `key` and `location` fields for details.
@immutable
class _WebKeyLocationPair {
  const _WebKeyLocationPair(this.key, this.location);
  final String key;
  final int location;
}

// TODO(gspencergoog): Replace this with more robust key simulation code once
// the new key event code is in.
// https://github.com/flutter/flutter/issues/33521
// This code can only simulate keys which appear in the key maps.

String? _keyLabel(LogicalKeyboardKey key) {
  final String keyLabel = key.keyLabel;
  if (keyLabel.length == 1) {
    return keyLabel.toLowerCase();
  }
  return null;
}

/// A class that serves as a namespace for a bunch of keyboard-key generation
/// utilities.
abstract final class KeyEventSimulator {
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
      case 'fuchsia':
        map = kFuchsiaToPhysicalKey;
      case 'macos':
        map = kMacOsToPhysicalKey;
      case 'ios':
        map = kIosToPhysicalKey;
      case 'linux':
        map = kLinuxToPhysicalKey;
      case 'windows':
        map = kWindowsToPhysicalKey;
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
        case 'fuchsia':
          map = kFuchsiaToLogicalKey;
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
        case 'windows':
          map = kWindowsToLogicalKey;
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

  static PhysicalKeyboardKey _inferPhysicalKey(LogicalKeyboardKey key) {
    PhysicalKeyboardKey? result;
    for (final PhysicalKeyboardKey physicalKey in PhysicalKeyboardKey.knownPhysicalKeys) {
      if (physicalKey.debugName == key.debugName) {
        result = physicalKey;
        break;
      }
    }
    assert(result != null, 'Unable to infer physical key for $key');
    return result!;
  }

  static _WebKeyLocationPair _getWebKeyLocation(LogicalKeyboardKey key, String keyLabel) {
    String? result;
    for (final MapEntry<String, List<LogicalKeyboardKey?>> entry in kWebLocationMap.entries) {
      final int foundIndex = entry.value.lastIndexOf(key);
      // If foundIndex is -1, then the key is not defined in kWebLocationMap.
      // If foundIndex is 0, then the key is in the standard part of the keyboard,
      // but we have to check `keyLabel` to see if it's remapped or modified.
      if (foundIndex != -1 && foundIndex != 0) {
        return _WebKeyLocationPair(entry.key, foundIndex);
      }
    }
    if (keyLabel.isNotEmpty) {
      return _WebKeyLocationPair(keyLabel, 0);
    }
    for (final String code in kWebToLogicalKey.keys) {
      if (key.keyId == kWebToLogicalKey[code]!.keyId) {
        result = code;
        break;
      }
    }
    assert(result != null, 'Key $key not found in web keyCode map');
    return _WebKeyLocationPair(result!, 0);
  }

  static String _getWebCode(PhysicalKeyboardKey key) {
    String? result;
    for (final MapEntry<String, PhysicalKeyboardKey> entry in kWebToPhysicalKey.entries) {
      if (entry.value.usbHidUsage == key.usbHidUsage) {
        result = entry.key;
        break;
      }
    }
    assert(result != null, 'Key $key not found in web code map');
    return result!;
  }

  static PhysicalKeyboardKey _findPhysicalKeyByPlatform(LogicalKeyboardKey key, String platform) {
    assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');
    late Map<dynamic, PhysicalKeyboardKey> map;
    if (kIsWeb) {
      // This check is used to treeshake keymap code.
      map = kWebToPhysicalKey;
    } else {
      switch (platform) {
        case 'android':
          map = kAndroidToPhysicalKey;
        case 'fuchsia':
          map = kFuchsiaToPhysicalKey;
        case 'macos':
          map = kMacOsToPhysicalKey;
        case 'ios':
          map = kIosToPhysicalKey;
        case 'linux':
          map = kLinuxToPhysicalKey;
        case 'web':
          map = kWebToPhysicalKey;
        case 'windows':
          map = kWindowsToPhysicalKey;
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
    String? character,
  }) {
    assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');

    key = _getKeySynonym(key);

    // Find a suitable physical key if none was supplied.
    physicalKey ??= _findPhysicalKeyByPlatform(key, platform);

    assert(key.debugName != null);

    final Map<String, dynamic> result = <String, dynamic>{
      'type': isDown ? 'keydown' : 'keyup',
      'keymap': platform,
    };

    final String resultCharacter = character ?? _keyLabel(key) ?? '';
    void assignWeb() {
      final _WebKeyLocationPair keyLocation = _getWebKeyLocation(key, resultCharacter);
      final PhysicalKeyboardKey actualPhysicalKey = physicalKey ?? _inferPhysicalKey(key);
      result['code'] = _getWebCode(actualPhysicalKey);
      result['key'] = keyLocation.key;
      result['location'] = keyLocation.location;
      result['metaState'] = _getWebModifierFlags(key, isDown);
    }
    if (kIsWeb) {
      assignWeb();
      return result;
    }
    final int keyCode = _getKeyCode(key, platform);
    final int scanCode = _getScanCode(physicalKey, platform);

    switch (platform) {
      case 'android':
        result['keyCode'] = keyCode;
        if (resultCharacter.isNotEmpty) {
          result['codePoint'] = resultCharacter.codeUnitAt(0);
          result['character'] = resultCharacter;
        }
        result['scanCode'] = scanCode;
        result['metaState'] = _getAndroidModifierFlags(key, isDown);
      case 'fuchsia':
        result['hidUsage'] = physicalKey.usbHidUsage;
        if (resultCharacter.isNotEmpty) {
          result['codePoint'] = resultCharacter.codeUnitAt(0);
        }
        result['modifiers'] = _getFuchsiaModifierFlags(key, isDown);
      case 'linux':
        result['toolkit'] = 'glfw';
        result['keyCode'] = keyCode;
        result['scanCode'] = scanCode;
        result['modifiers'] = _getGlfwModifierFlags(key, isDown);
        result['unicodeScalarValues'] = resultCharacter.isNotEmpty ? resultCharacter.codeUnitAt(0) : 0;
      case 'macos':
        result['keyCode'] = scanCode;
        if (resultCharacter.isNotEmpty) {
          result['characters'] = resultCharacter;
          result['charactersIgnoringModifiers'] = resultCharacter;
        }
        result['modifiers'] = _getMacOsModifierFlags(key, isDown);
      case 'ios':
        result['keyCode'] = scanCode;
        result['characters'] = resultCharacter;
        result['charactersIgnoringModifiers'] = resultCharacter;
        result['modifiers'] = _getIOSModifierFlags(key, isDown);
      case 'windows':
        result['keyCode'] = keyCode;
        result['scanCode'] = scanCode;
        if (resultCharacter.isNotEmpty) {
          result['characterCodePoint'] = resultCharacter.codeUnitAt(0);
        }
        result['modifiers'] = _getWindowsModifierFlags(key, isDown);
      case 'web':
        assignWeb();
    }
    return result;
  }

  static int _getAndroidModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    // ignore: deprecated_member_use
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
    // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierLeftShift | RawKeyEventDataAndroid.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierRightShift | RawKeyEventDataAndroid.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierLeftMeta | RawKeyEventDataAndroid.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierRightMeta | RawKeyEventDataAndroid.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierLeftControl | RawKeyEventDataAndroid.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierRightControl | RawKeyEventDataAndroid.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierLeftAlt | RawKeyEventDataAndroid.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierRightAlt | RawKeyEventDataAndroid.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.fn)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierFunction;
    }
    if (pressed.contains(LogicalKeyboardKey.scrollLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierScrollLock;
    }
    if (pressed.contains(LogicalKeyboardKey.numLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierNumLock;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataAndroid.modifierCapsLock;
    }
    return result;
  }

  static int _getGlfwModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    // ignore: deprecated_member_use
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft) || pressed.contains(LogicalKeyboardKey.shiftRight)) {
      // ignore: deprecated_member_use
      result |= GLFWKeyHelper.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft) || pressed.contains(LogicalKeyboardKey.metaRight)) {
      // ignore: deprecated_member_use
      result |= GLFWKeyHelper.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft) || pressed.contains(LogicalKeyboardKey.controlRight)) {
      // ignore: deprecated_member_use
      result |= GLFWKeyHelper.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft) || pressed.contains(LogicalKeyboardKey.altRight)) {
      // ignore: deprecated_member_use
      result |= GLFWKeyHelper.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      // ignore: deprecated_member_use
      result |= GLFWKeyHelper.modifierCapsLock;
    }
    return result;
  }

  static int _getWindowsModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    // ignore: deprecated_member_use
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shift)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierLeftShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierRightShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierLeftMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierRightMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.control)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierLeftControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierRightControl;
    }
    if (pressed.contains(LogicalKeyboardKey.alt)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierLeftAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierRightAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierCaps;
    }
    if (pressed.contains(LogicalKeyboardKey.numLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierNumLock;
    }
    if (pressed.contains(LogicalKeyboardKey.scrollLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWindows.modifierScrollLock;
    }
    return result;
  }

  static int _getFuchsiaModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    // ignore: deprecated_member_use
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataFuchsia.modifierLeftShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataFuchsia.modifierRightShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataFuchsia.modifierLeftMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataFuchsia.modifierRightMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataFuchsia.modifierLeftControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataFuchsia.modifierRightControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataFuchsia.modifierLeftAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataFuchsia.modifierRightAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataFuchsia.modifierCapsLock;
    }
    return result;
  }

  static int _getWebModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    // ignore: deprecated_member_use
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierCapsLock;
    }
    if (pressed.contains(LogicalKeyboardKey.numLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierNumLock;
    }
    if (pressed.contains(LogicalKeyboardKey.scrollLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataWeb.modifierScrollLock;
    }
    return result;
  }

  static int _getMacOsModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
      // ignore: deprecated_member_use
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataMacOs.modifierLeftShift | RawKeyEventDataMacOs.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataMacOs.modifierRightShift | RawKeyEventDataMacOs.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataMacOs.modifierLeftCommand | RawKeyEventDataMacOs.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataMacOs.modifierRightCommand | RawKeyEventDataMacOs.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataMacOs.modifierLeftControl | RawKeyEventDataMacOs.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataMacOs.modifierRightControl | RawKeyEventDataMacOs.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataMacOs.modifierLeftOption | RawKeyEventDataMacOs.modifierOption;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      // ignore: deprecated_member_use
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
      // ignore: deprecated_member_use
      result |= RawKeyEventDataMacOs.modifierFunction;
    }
    if (pressed.intersection(kMacOsNumPadMap.values.toSet()).isNotEmpty) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataMacOs.modifierNumericPad;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataMacOs.modifierCapsLock;
    }
    return result;
  }

  static int _getIOSModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    int result = 0;
    // ignore: deprecated_member_use
    final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataIos.modifierLeftShift | RawKeyEventDataIos.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataIos.modifierRightShift | RawKeyEventDataIos.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataIos.modifierLeftCommand | RawKeyEventDataIos.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataIos.modifierRightCommand | RawKeyEventDataIos.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataIos.modifierLeftControl | RawKeyEventDataIos.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataIos.modifierRightControl | RawKeyEventDataIos.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataIos.modifierLeftOption | RawKeyEventDataIos.modifierOption;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      // ignore: deprecated_member_use
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
      // ignore: deprecated_member_use
      result |= RawKeyEventDataIos.modifierFunction;
    }
    if (pressed.intersection(kMacOsNumPadMap.values.toSet()).isNotEmpty) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataIos.modifierNumericPad;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      // ignore: deprecated_member_use
      result |= RawKeyEventDataIos.modifierCapsLock;
    }
    return result;
  }

  static Future<bool> _simulateKeyEventByRawEvent(ValueGetter<Map<String, dynamic>> buildKeyData) async {
    return TestAsyncUtils.guard<bool>(() async {
      final Completer<bool> result = Completer<bool>();
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(buildKeyData()),
        (ByteData? data) {
          if (data == null) {
            result.complete(false);
            return;
          }
          final Map<String, Object?> decoded = SystemChannels.keyEvent.codec.decodeMessage(data)! as Map<String, dynamic>;
          result.complete(decoded['handled']! as bool);
        }
      );
      return result.future;
    });
  }

  static final Map<String, PhysicalKeyboardKey> _debugNameToPhysicalKey = (() {
    final Map<String, PhysicalKeyboardKey> result = <String, PhysicalKeyboardKey>{};
    for (final PhysicalKeyboardKey key in PhysicalKeyboardKey.knownPhysicalKeys) {
      final String? debugName = key.debugName;
      if (debugName != null) {
        result[debugName] = key;
      }
    }
    return result;
  })();
  static PhysicalKeyboardKey _findPhysicalKey(LogicalKeyboardKey key) {
    final PhysicalKeyboardKey? result = _debugNameToPhysicalKey[key.debugName];
    assert(result != null, 'Physical key for $key not found in known physical keys');
    return result!;
  }

  // ignore: deprecated_member_use
  static const KeyDataTransitMode _defaultTransitMode = KeyDataTransitMode.rawKeyData;

  // The simulation transit mode for [simulateKeyDownEvent], [simulateKeyUpEvent],
  // and [simulateKeyRepeatEvent].
  //
  // Simulation transit mode is the mode that simulated key events are constructed
  // and delivered. For detailed introduction, see [KeyDataTransitMode] and
  // its values.
  //
  // The `_transitMode` defaults to [KeyDataTransitMode.rawKeyEvent], and can be
  // overridden with [debugKeyEventSimulatorTransitModeOverride]. In widget tests, it
  // is often set with [KeySimulationModeVariant].
  // ignore: deprecated_member_use
  static KeyDataTransitMode get _transitMode {
    // ignore: deprecated_member_use
    KeyDataTransitMode? result;
    assert(() {
      // ignore: deprecated_member_use
      result = debugKeyEventSimulatorTransitModeOverride;
      return true;
    }());
    return result ?? _defaultTransitMode;
  }

  static String get _defaultPlatform => kIsWeb ? 'web' : Platform.operatingSystem;

  /// Simulates sending a hardware key down event.
  ///
  /// This only simulates key presses coming from a physical keyboard, not from a
  /// soft keyboard.
  ///
  /// Specify `platform` as one of the platforms allowed in
  /// [Platform.operatingSystem] to make the event appear to be from that type of
  /// system. Defaults to the operating system that the test is running on.
  ///
  /// Keys that are down when the test completes are cleared after each test.
  ///
  /// Returns true if the key event was handled by the framework.
  ///
  /// See also:
  ///
  ///  * [simulateKeyUpEvent] to simulate the corresponding key up event.
  static Future<bool> simulateKeyDownEvent(
    LogicalKeyboardKey key, {
    String? platform,
    PhysicalKeyboardKey? physicalKey,
    String? character,
  }) async {
    Future<bool> simulateByRawEvent() {
      return _simulateKeyEventByRawEvent(() {
        platform ??= _defaultPlatform;
        return getKeyData(key, platform: platform!, physicalKey: physicalKey, character: character);
      });
    }
    switch (_transitMode) {
      // ignore: deprecated_member_use
      case KeyDataTransitMode.rawKeyData:
        return simulateByRawEvent();
      // ignore: deprecated_member_use
      case KeyDataTransitMode.keyDataThenRawKeyData:
        final LogicalKeyboardKey logicalKey = _getKeySynonym(key);
        // ignore: deprecated_member_use
        final bool resultByKeyEvent = ServicesBinding.instance.keyEventManager.handleKeyData(
          ui.KeyData(
            type: ui.KeyEventType.down,
            physical: (physicalKey ?? _findPhysicalKey(logicalKey)).usbHidUsage,
            logical: logicalKey.keyId,
            timeStamp: Duration.zero,
            character: character ?? _keyLabel(key),
            synthesized: false,
          ),
        );
        return (await simulateByRawEvent()) || resultByKeyEvent;
    }
  }

  /// Simulates sending a hardware key up event through the system channel.
  ///
  /// This only simulates key presses coming from a physical keyboard, not from a
  /// soft keyboard.
  ///
  /// Specify `platform` as one of the platforms allowed in
  /// [Platform.operatingSystem] to make the event appear to be from that type of
  /// system. Defaults to the operating system that the test is running on.
  ///
  /// Returns true if the key event was handled by the framework.
  ///
  /// See also:
  ///
  ///  * [simulateKeyDownEvent] to simulate the corresponding key down event.
  static Future<bool> simulateKeyUpEvent(
    LogicalKeyboardKey key, {
    String? platform,
    PhysicalKeyboardKey? physicalKey,
  }) async {
    Future<bool> simulateByRawEvent() {
      return _simulateKeyEventByRawEvent(() {
        platform ??= _defaultPlatform;
        return getKeyData(key, platform: platform!, isDown: false, physicalKey: physicalKey);
      });
    }
    switch (_transitMode) {
      // ignore: deprecated_member_use
      case KeyDataTransitMode.rawKeyData:
        return simulateByRawEvent();
      // ignore: deprecated_member_use
      case KeyDataTransitMode.keyDataThenRawKeyData:
        final LogicalKeyboardKey logicalKey = _getKeySynonym(key);
        // ignore: deprecated_member_use
        final bool resultByKeyEvent = ServicesBinding.instance.keyEventManager.handleKeyData(
          ui.KeyData(
            type: ui.KeyEventType.up,
            physical: (physicalKey ?? _findPhysicalKey(logicalKey)).usbHidUsage,
            logical: logicalKey.keyId,
            timeStamp: Duration.zero,
            character: null,
            synthesized: false,
          ),
        );
        return (await simulateByRawEvent()) || resultByKeyEvent;
    }
  }

  /// Simulates sending a hardware key repeat event through the system channel.
  ///
  /// This only simulates key presses coming from a physical keyboard, not from a
  /// soft keyboard.
  ///
  /// Specify `platform` as one of the platforms allowed in
  /// [Platform.operatingSystem] to make the event appear to be from that type of
  /// system. Defaults to the operating system that the test is running on.
  ///
  /// Returns true if the key event was handled by the framework.
  ///
  /// See also:
  ///
  ///  * [simulateKeyDownEvent] to simulate the corresponding key down event.
  static Future<bool> simulateKeyRepeatEvent(
    LogicalKeyboardKey key, {
    String? platform,
    PhysicalKeyboardKey? physicalKey,
    String? character,
  }) async {
    Future<bool> simulateByRawEvent() {
      return _simulateKeyEventByRawEvent(() {
        platform ??= _defaultPlatform;
        return getKeyData(key, platform: platform!, physicalKey: physicalKey, character: character);
      });
    }
    switch (_transitMode) {
      // ignore: deprecated_member_use
      case KeyDataTransitMode.rawKeyData:
        return simulateByRawEvent();
      // ignore: deprecated_member_use
      case KeyDataTransitMode.keyDataThenRawKeyData:
        final LogicalKeyboardKey logicalKey = _getKeySynonym(key);
        // ignore: deprecated_member_use
        final bool resultByKeyEvent = ServicesBinding.instance.keyEventManager.handleKeyData(
          ui.KeyData(
            type: ui.KeyEventType.repeat,
            physical: (physicalKey ?? _findPhysicalKey(logicalKey)).usbHidUsage,
            logical: logicalKey.keyId,
            timeStamp: Duration.zero,
            character: character ?? _keyLabel(key),
            synthesized: false,
          ),
        );
        return (await simulateByRawEvent()) || resultByKeyEvent;
    }
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
/// system. Defaults to the operating system that the test is running on.
///
/// Keys that are down when the test completes are cleared after each test.
///
/// Returns true if the key event was handled by the framework.
///
/// See also:
///
///  * [simulateKeyUpEvent] and [simulateKeyRepeatEvent] to simulate the
///    corresponding key up and repeat event.
Future<bool> simulateKeyDownEvent(
  LogicalKeyboardKey key, {
  String? platform,
  PhysicalKeyboardKey? physicalKey,
  String? character,
}) async {
  final bool handled = await KeyEventSimulator.simulateKeyDownEvent(key, platform: platform, physicalKey: physicalKey, character: character);
  final ServicesBinding binding = ServicesBinding.instance;
  if (!handled && binding is TestWidgetsFlutterBinding) {
    await binding.testTextInput.handleKeyDownEvent(key);
  }
  return handled;
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
/// system. Defaults to the operating system that the test is running on.
///
/// Returns true if the key event was handled by the framework.
///
/// See also:
///
///  * [simulateKeyDownEvent] and [simulateKeyRepeatEvent] to simulate the
///    corresponding key down and repeat event.
Future<bool> simulateKeyUpEvent(
  LogicalKeyboardKey key, {
  String? platform,
  PhysicalKeyboardKey? physicalKey,
}) async {
  final bool handled = await KeyEventSimulator.simulateKeyUpEvent(key, platform: platform, physicalKey: physicalKey);
  final ServicesBinding binding = ServicesBinding.instance;
  if (!handled && binding is TestWidgetsFlutterBinding) {
    await binding.testTextInput.handleKeyUpEvent(key);
  }
  return handled;
}

/// Simulates sending a hardware key repeat event through the system channel.
///
/// This only simulates key presses coming from a physical keyboard, not from a
/// soft keyboard.
///
/// Specify `platform` as one of the platforms allowed in
/// [Platform.operatingSystem] to make the event appear to be from that type of
/// system. Defaults to the operating system that the test is running on.
///
/// Returns true if the key event was handled by the framework.
///
/// See also:
///
///  - [simulateKeyDownEvent] and [simulateKeyUpEvent] to simulate the
///    corresponding key down and up event.
Future<bool> simulateKeyRepeatEvent(
  LogicalKeyboardKey key, {
  String? platform,
  PhysicalKeyboardKey? physicalKey,
  String? character,
}) {
  return KeyEventSimulator.simulateKeyRepeatEvent(key, platform: platform, physicalKey: physicalKey, character: character);
}

/// A [TestVariant] that runs tests with transit modes set to different values
/// of [KeyDataTransitMode].
@Deprecated(
  'No longer supported. Transit mode is always key data only. '
  'This feature was deprecated after v3.18.0-2.0.pre.',
)
class KeySimulatorTransitModeVariant extends TestVariant<KeyDataTransitMode> {
  /// Creates a [KeySimulatorTransitModeVariant] that tests the given [values].
  @Deprecated(
    'No longer supported. Transit mode is always key data only. '
    'This feature was deprecated after v3.18.0-2.0.pre.',
  )
  const KeySimulatorTransitModeVariant(this.values);

  /// Creates a [KeySimulatorTransitModeVariant] for each value option of
  /// [KeyDataTransitMode].
  @Deprecated(
    'No longer supported. Transit mode is always key data only. '
    'This feature was deprecated after v3.18.0-2.0.pre.',
  )
  KeySimulatorTransitModeVariant.all()
    : this(KeyDataTransitMode.values.toSet());

  /// Creates a [KeySimulatorTransitModeVariant] that only contains
  /// [KeyDataTransitMode.keyDataThenRawKeyData].
  @Deprecated(
    'No longer supported. Transit mode is always key data only. '
    'This feature was deprecated after v3.18.0-2.0.pre.',
  )
  KeySimulatorTransitModeVariant.keyDataThenRawKeyData()
    : this(<KeyDataTransitMode>{KeyDataTransitMode.keyDataThenRawKeyData});

  @override
  final Set<KeyDataTransitMode> values;

  @override
  String describeValue(KeyDataTransitMode value) {
    switch (value) {
      case KeyDataTransitMode.rawKeyData:
        return 'RawKeyEvent';
      case KeyDataTransitMode.keyDataThenRawKeyData:
        return 'ui.KeyData then RawKeyEvent';
    }
  }

  @override
  Future<KeyDataTransitMode?> setUp(KeyDataTransitMode value) async {
    final KeyDataTransitMode? previousSetting = debugKeyEventSimulatorTransitModeOverride;
    debugKeyEventSimulatorTransitModeOverride = value;
    return previousSetting;
  }

  @override
  Future<void> tearDown(KeyDataTransitMode value, KeyDataTransitMode? memento) async {
    // ignore: invalid_use_of_visible_for_testing_member
    RawKeyboard.instance.clearKeysPressed();
    // ignore: invalid_use_of_visible_for_testing_member
    HardwareKeyboard.instance.clearState();
    // ignore: invalid_use_of_visible_for_testing_member
    ServicesBinding.instance.keyEventManager.clearState();
    debugKeyEventSimulatorTransitModeOverride = memento;
  }
}
