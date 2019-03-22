// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/foundation.dart';

import 'keyboard_key.dart';
import 'keyboard_maps.dart';
import 'raw_keyboard.dart';

/// Base class for window-specific key mappings.
///
/// Given that there might be multiple window toolkit implementations (GLFW, GTK, QT, etc), this creates a common
/// interface for each of the different toolkits.
abstract class KeyHelper {
  
  /// Returns a [KeyboardSide] enum value that describes which side or sides of
  /// the given keyboard modifier key were pressed at the time of this event.
  KeyboardSide getModifierSide(ModifierKey key);

  /// Returns true if the given [ModifierKey] was pressed at the time of this
  /// event.
  bool isModifierPressed(ModifierKey key, int modifiers, {KeyboardSide side = KeyboardSide.any});

  /// The numpad key from the specific key code mapping.
  LogicalKeyboardKey numpadKey(int keyCode);

  /// The logical key key from the specific key code mapping.
  LogicalKeyboardKey logicalKey(int keyCode);
}


class GLFWKeyHelper extends KeyHelper {
  /// This mask is used to check the [modifiers] field to test whether the CAPS
  /// LOCK modifier key is on.
  ///
  /// {@template flutter.services.logicalKeyboardKey.modifiers}
  /// Use this value if you need to decode the [modifiers] field yourself, but
  /// it's much easier to use [isModifierPressed] if you just want to know if
  /// a modifier is pressed.
  /// {@endtemplate}
  static const int modifierCapsLock = 0x0010;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// SHIFT modifier keys is pressed.
  ///
  /// {@macro flutter.services.logicalKeyboardKey.modifiers}
  static const int modifierShift = 0x0001;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// CTRL modifier keys is pressed.
  ///
  /// {@macro flutter.services.logicalKeyboardKey.modifiers}
  static const int modifierControl = 0x0002;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// ALT modifier keys is pressed.
  ///
  /// {@macro flutter.services.logicalKeyboardKey.modifiers}
  static const int modifierAlt = 0x0004;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// Meta(SUPER) modifier keys is pressed.
  ///
  /// {@macro flutter.services.logicalKeyboardKey.modifiers}
  static const int modifierMeta = 0x0008;


  /// This mask is used to check the [modifiers] field to test whether any key in
  /// the numeric keypad is pressed.
  ///
  /// {@macro flutter.services.logicalKeyboardKey.modifiers}
  static const int modifierNumericPad = 0x0020;

  @override
  bool isModifierPressed(ModifierKey key, int modifiers, {KeyboardSide side = KeyboardSide.any}) {
    switch (key) {
      case ModifierKey.controlModifier:
      return modifiers & modifierControl != 0;
      case ModifierKey.shiftModifier:
            return modifiers & modifierShift != 0;
      case ModifierKey.altModifier:
            return modifiers & modifierAlt != 0;
      case ModifierKey.metaModifier:
            return modifiers & modifierMeta != 0;
      case ModifierKey.capsLockModifier:
        return modifiers & modifierCapsLock != 0;
      case ModifierKey.numLockModifier:
        return modifiers & modifierNumericPad != 0;
      case ModifierKey.functionModifier:
      case ModifierKey.symbolModifier:
      case ModifierKey.scrollLockModifier:
        // These are not used in GLFW keyboards.
        return false;
    }
    return false;
  }

  @override
  KeyboardSide getModifierSide(ModifierKey key) {
    // Neither GLFW or X11 provide a distiction between left and right modifiers, so defaults to KeyboardSide.any.
    // https://code.woboq.org/qt5/include/X11/X.h.html#_M/ShiftMask
    return KeyboardSide.any;
  }

  @override
  LogicalKeyboardKey numpadKey(int keyCode) {
    return kGlfwNumpadMap[keyCode];
  }

  @override
  LogicalKeyboardKey logicalKey(int keyCode) {
      return kGlfwToLogicalKey[keyCode];
  }
}
