// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'raw_keyboard.dart';

/// Platform-specific key event data for Android.
///
/// This object contains information about key events obtained from Android's
/// `KeyEvent` interface.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
class RawKeyEventDataAndroid extends RawKeyEventData {
  /// Creates a key event data structure specific for Android.
  ///
  /// The [flags], [codePoint], [keyCode], [scanCode], and [metaState] arguments
  /// must not be null.
  const RawKeyEventDataAndroid({
    this.flags = 0,
    this.codePoint = 0,
    this.keyCode = 0,
    this.scanCode = 0,
    this.metaState = 0,
  })  : assert(flags != null),
        assert(codePoint != null),
        assert(keyCode != null),
        assert(scanCode != null),
        assert(metaState != null);

  /// The current set of additional flags for this event.
  ///
  /// Flags indicate things like repeat state, etc.
  ///
  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getFlags()>
  /// for more information.
  final int flags;

  /// The Unicode code point represented by the key event, if any.
  ///
  /// If there is no Unicode code point, this value is zero.
  ///
  /// Dead keys are represented as Unicode combining characters.
  ///
  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getUnicodeChar()>
  /// for more information.
  final int codePoint;

  /// The hardware key code corresponding to this key event.
  ///
  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getKeyCode()>
  /// for more information.
  final int keyCode;

  /// The hardware scan code corresponding to this key event.
  ///
  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getScanCode()>
  /// for more information.
  final int scanCode;

  /// The modifiers that were present when the key event occurred.
  ///
  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getMetaState()>
  /// for the numerical values of the `metaState`. Many of these constants are
  /// also replicated as static constants in this class.
  ///
  /// See also:
  ///
  ///  * The [modifiersPressed] accessor to get a Set of currently pressed
  ///    modifiers.
  ///  * The [isModifierPressed] function to query if a specific modifier is
  ///    pressed.
  ///  * The [isControlPressed] convenience accessor to see if the CTRL key is
  ///    pressed.
  ///  * The [isShiftPressed] convenience accessor to see if the SHIFT key is
  ///    pressed.
  ///  * The [isAltPressed] convenience accessor to see if the ALT key is
  ///    pressed.
  ///  * The [isMetaPressed] convenience accessor to see if the META key is
  ///    pressed.
  final int metaState;

  bool _isLeftRightModifierPressed(KeyboardSide side, int anyMask, int leftMask, int rightMask) {
    if (metaState & anyMask == 0) {
      return false;
    }
    switch (side) {
      case KeyboardSide.any:
        return true;
      case KeyboardSide.both:
        return metaState & leftMask != 0 && metaState & rightMask != 0;
      case KeyboardSide.left:
        return metaState & leftMask != 0;
      case KeyboardSide.right:
        return metaState & rightMask != 0;
    }
    return false;
  }

  @override
  bool isModifierPressed(ModifierKey key, {KeyboardSide side = KeyboardSide.any}) {
    assert(side != null);
    switch (key) {
      case ModifierKey.controlModifier:
        return _isLeftRightModifierPressed(side, modifierControl, modifierLeftControl, modifierRightControl);
      case ModifierKey.shiftModifier:
        return _isLeftRightModifierPressed(side, modifierShift, modifierLeftShift, modifierRightShift);
      case ModifierKey.altModifier:
        return _isLeftRightModifierPressed(side, modifierAlt, modifierLeftAlt, modifierRightAlt);
      case ModifierKey.metaModifier:
        return _isLeftRightModifierPressed(side, modifierMeta, modifierLeftMeta, modifierRightMeta);
      case ModifierKey.capsLockModifier:
        return metaState & modifierCapsLock != 0;
      case ModifierKey.numLockModifier:
        return metaState & modifierNumLock != 0;
      case ModifierKey.scrollLockModifier:
        return metaState & modifierScrollLock != 0;
      case ModifierKey.functionModifier:
        return metaState & modifierFunction != 0;
      case ModifierKey.symbolModifier:
        return metaState & modifierSym != 0;
    }
    return false;
  }

  // Modifier key masks.

  /// No modifier keys are pressed.
  static const int modifierNone = 0;

  /// This mask is used to check the [metaState] field to test whether one of
  /// the ALT modifier keys is pressed.
  static const int modifierAlt = 0x02;

  /// This mask is used to check the [metaState] field to test whether the left
  /// ALT modifier key is pressed.
  static const int modifierLeftAlt = 0x10;

  /// This mask is used to check the [metaState] field to test whether the right
  /// ALT modifier key is pressed.
  static const int modifierRightAlt = 0x20;

  /// This mask is used to check the [metaState] field to test whether one of
  /// the SHIFT modifier keys is
  /// pressed.
  static const int modifierShift = 0x01;

  /// This mask is used to check the [metaState] field to test whether the left
  /// SHIFT modifier key is pressed.
  static const int modifierLeftShift = 0x40;

  /// This mask is used to check the [metaState] field to test whether the right
  /// SHIFT modifier key is pressed.
  static const int modifierRightShift = 0x80;

  /// This mask is used to check the [metaState] field to test whether the SYM
  /// modifier key is pressed.
  static const int modifierSym = 0x04;

  /// This mask is used to check the [metaState] field to test whether the
  /// Function modifier key (Fn) is pressed.
  static const int modifierFunction = 0x08;

  /// This mask is used to check the [metaState] field to test whether one of
  /// the CTRL modifier keys is pressed.
  static const int modifierControl = 0x1000;

  /// This mask is used to check the [metaState] field to test whether the left
  /// CTRL modifier key is pressed.
  static const int modifierLeftControl = 0x2000;

  /// This mask is used to check the [metaState] field to test whether the right
  /// CTRL modifier key is pressed.
  static const int modifierRightControl = 0x4000;

  /// This mask is used to check the [metaState] field to test whether one of
  /// the META modifier keys is pressed.
  static const int modifierMeta = 0x10000;

  /// This mask is used to check the [metaState] field to test whether the left
  /// META modifier key is pressed.
  static const int modifierLeftMeta = 0x20000;

  /// This mask is used to check the [metaState] field to test whether the right
  /// META modifier key is pressed.
  static const int modifierRightMeta = 0x40000;

  /// This mask is used to check the [metaState] field to test whether the CAPS
  /// LOCK modifier key is on.
  static const int modifierCapsLock = 0x100000;

  /// This mask is used to check the [metaState] field to test whether the NUM
  /// LOCK modifier key is on.
  static const int modifierNumLock = 0x200000;

  /// This mask is used to check the [metaState] field to test whether the
  /// SCROLL LOCK modifier key is on.
  static const int modifierScrollLock = 0x400000;

  @override
  String toString() {
    return '$runtimeType(flags: $flags, codePoint: $codePoint, keyCode: $keyCode, scanCode: $scanCode, metaState: $metaState, modifiers down: $modifiersPressed)';
  }
}
