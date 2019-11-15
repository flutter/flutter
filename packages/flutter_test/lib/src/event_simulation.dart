// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'test_async_utils.dart';

// For the synonym keys, just return the left version of it.
LogicalKeyboardKey _getSynonym(LogicalKeyboardKey origKey) {
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

bool _osIsSupported(String platform) {
  switch (platform) {
    case 'android':
    case 'fuchsia':
    case 'macos':
    case 'linux':
      return true;
  }
  return false;
}

int _getScanCode(LogicalKeyboardKey key, String platform) {
  assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');
  int scanCode;
  Map<int, PhysicalKeyboardKey> map;
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
    case 'linux':
      map = kLinuxToPhysicalKey;
      break;
  }
  for (int code in map.keys) {
    if (key.debugName == map[code].debugName) {
      scanCode = code;
      break;
    }
  }
  return scanCode;
}

int _getKeyCode(LogicalKeyboardKey key, String platform) {
  assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');
  int keyCode;
  Map<int, LogicalKeyboardKey> map;
  switch (platform) {
    case 'android':
      map = kAndroidToLogicalKey;
      break;
    case 'fuchsia':
      map = kFuchsiaToLogicalKey;
      break;
    case 'macos':
      // macOS doesn't do key codes, just scan codes.
      return null;
    case 'linux':
      map = kGlfwToLogicalKey;
      break;
  }
  for (int code in map.keys) {
    if (key.debugName == map[code].debugName) {
      keyCode = code;
      break;
    }
  }
  return keyCode;
}

Map<String, dynamic> _getKeyData(LogicalKeyboardKey key, {String platform, bool isDown = true}) {
  assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');

  key = _getSynonym(key);

  assert(key.debugName != null);
  final int keyCode = platform == 'macos' ? -1 : _getKeyCode(key, platform);
  assert(platform == 'macos' || keyCode != null, 'Key $key not found in $platform keyCode map');
  final int scanCode = _getScanCode(key, platform);
  assert(scanCode != null, 'Physical key for $key not found in $platform scanCode map');

  final Map<String, dynamic> result = <String, dynamic>{
    'type': isDown ? 'keydown' : 'keyup',
    'keymap': platform,
    'character': key.keyLabel,
  };

  switch (platform) {
    case 'android':
      result['keyCode'] = keyCode;
      result['codePoint'] = key.keyLabel?.codeUnitAt(0);
      result['scanCode'] = scanCode;
      result['metaState'] = _getAndroidModifierFlags(key, isDown);
      break;
    case 'fuchsia':
      result['hidUsage'] = key.keyId & LogicalKeyboardKey.hidPlane != 0 ? key.keyId & LogicalKeyboardKey.valueMask : null;
      result['codePoint'] = key.keyLabel?.codeUnitAt(0);
      result['modifiers'] = _getFuchsiaModifierFlags(key, isDown);
      break;
    case 'linux':
      result['toolkit'] = 'glfw';
      result['keyCode'] = keyCode;
      result['scanCode'] = scanCode;
      result['modifiers'] = _getGlfwModifierFlags(key, isDown);
      break;
    case 'macos':
      result['keyCode'] = scanCode;
      result['characters'] = key.keyLabel;
      result['charactersIgnoringModifiers'] = key.keyLabel;
      result['modifiers'] = _getMacOsModifierFlags(key, isDown);
      break;
  }
  return result;
}

int _getAndroidModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
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

int _getGlfwModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
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

int _getFuchsiaModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
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

int _getMacOsModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
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
/// See also:
///
///  - [simulateKeyUpEvent] to simulate the corresponding key up event.
Future<void> simulateKeyDownEvent(LogicalKeyboardKey key, {String platform}) async {
  return TestAsyncUtils.guard<void>(() async {
    platform ??= Platform.operatingSystem;
    assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');

    final Map<String, dynamic> data = _getKeyData(key, platform: platform, isDown: true);
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.keyEvent.name,
      SystemChannels.keyEvent.codec.encodeMessage(data),
      (ByteData data) {},
    );
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
/// See also:
///
///  - [simulateKeyDownEvent] to simulate the corresponding key down event.
Future<void> simulateKeyUpEvent(LogicalKeyboardKey key, {String platform}) async {
  return TestAsyncUtils.guard<void>(() async {
    platform ??= Platform.operatingSystem;
    assert(_osIsSupported(platform), 'Platform $platform not supported for key simulation');

    final Map<String, dynamic> data = _getKeyData(key, platform: platform, isDown: false);
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.keyEvent.name,
      SystemChannels.keyEvent.codec.encodeMessage(data),
      (ByteData data) {},
    );
  });
}
