// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'raw_keyboard.dart';

/// Meta Key Masks for Android.

/// No modifier keys are pressed.
const int _kAndroidModifierNone = 0;

/// This mask is used to check whether one of the ALT modifier keys is pressed.
const int _kAndroidModifierAlt = 0x02;

/// This mask is used to check whether the left ALT modifier key is pressed.
const int _kAndroidModifierLeftAlt = 0x10;

/// This mask is used to check whether the right ALT modifier key is pressed.
const int _kAndroidModifierRightAlt = 0x20;

/// This mask is used to check whether one of the SHIFT modifier keys is
/// pressed.
const int _kAndroidModifierShift = 0x01;

/// This mask is used to check whether the left SHIFT modifier key is pressed.
const int _kAndroidModifierLeftShift = 0x40;

/// This mask is used to check whether the right SHIFT modifier key is pressed.
const int _kAndroidModifierRightShift = 0x80;

/// This mask is used to check whether the SYM modifier key is pressed.
const int _kAndroidModifierSym = 0x04;

/// This mask is used to check whether the Function modifier key is pressed.
const int _kAndroidModifierFunction = 0x08;

/// This mask is used to check whether one of the CTRL modifier keys is pressed.
const int _kAndroidModifierControl = 0x1000;

/// This mask is used to check whether the left CTRL modifier key is pressed.
const int _kAndroidModifierLeftControl = 0x2000;

/// This mask is used to check whether the right CTRL modifier key is pressed.
const int _kAndroidModifierRightControl = 0x4000;

/// This mask is used to check whether one of the META modifier keys is pressed.
const int _kAndroidModifierMeta = 0x10000;

/// This mask is used to check whether the left META modifier key is pressed.
const int _kAndroidModifierLeftMeta = 0x20000;

/// This mask is used to check whether the right META modifier key is pressed.
const int _kAndroidModifierRightMeta = 0x40000;

/// This mask is used to check whether the CAPS LOCK modifier key is on.
const int _kAndroidModifierCapsLock = 0x100000;

/// This mask is used to check whether the NUM LOCK modifier key is on.
const int _kAndroidModifierNumLock = 0x200000;

/// This mask is used to check whether the SCROLL LOCK modifier key is on.
const int _kAndroidModifierScrollLock = 0x400000;

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

  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getFlags()>
  final int flags;

  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getUnicodeChar()>
  final int codePoint;

  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getKeyCode()>
  final int keyCode;

  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getScanCode()>
  final int scanCode;

  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getMetaState()>
  final int metaState;

  @override
  String get unicode => codePoint != 0 ? String.fromCharCode(codePoint) : null;

  bool _isLeftRightModifierPressed(KeyboardSide side, int anyMask, int leftMask, int rightMask) {
    if (metaState == _kAndroidModifierNone || metaState & anyMask == 0) {
      return false;
    }
    switch (side) {
      case KeyboardSide.any:
        return true;
      case KeyboardSide.both:
        final int allMask = anyMask | leftMask | rightMask;
        return metaState & allMask == allMask;
      case KeyboardSide.left:
        return metaState & leftMask != 0;
      case KeyboardSide.right:
        return metaState & rightMask != 0;
    }
    return false;
  }

  @override
  bool isModifierPressed(ModifierKey key, [KeyboardSide side = KeyboardSide.any]) {
    switch (key) {
      case ModifierKey.ctrlModifier:
        return _isLeftRightModifierPressed(side, _kAndroidModifierControl, _kAndroidModifierLeftControl, _kAndroidModifierRightControl);
      case ModifierKey.shiftModifier:
        return _isLeftRightModifierPressed(side, _kAndroidModifierShift, _kAndroidModifierLeftShift, _kAndroidModifierRightShift);
      case ModifierKey.altModifier:
        return _isLeftRightModifierPressed(side, _kAndroidModifierAlt, _kAndroidModifierLeftAlt, _kAndroidModifierRightAlt);
      case ModifierKey.metaModifier:
        return _isLeftRightModifierPressed(side, _kAndroidModifierMeta, _kAndroidModifierLeftMeta, _kAndroidModifierRightMeta);
      case ModifierKey.capsLockModifier:
        return metaState & _kAndroidModifierCapsLock != 0;
      case ModifierKey.numLockModifier:
        return metaState & _kAndroidModifierNumLock != 0;
      case ModifierKey.scrollLockModifier:
        return metaState & _kAndroidModifierScrollLock != 0;
      case ModifierKey.functionModifier:
        return metaState & _kAndroidModifierFunction != 0;
      case ModifierKey.symbolModifier:
        return metaState & _kAndroidModifierSym != 0;
    }
    return false;
  }
}
