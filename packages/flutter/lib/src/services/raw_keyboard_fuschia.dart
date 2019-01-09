// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'raw_keyboard.dart';

/// Platform-specific key event data for Fuchsia.
///
/// This object contains information about key events obtained from Fuchsia's
/// `KeyData` interface.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
class RawKeyEventDataFuchsia extends RawKeyEventData {
  /// Creates a key event data structure specific for Fuchsia.
  ///
  /// The [hidUsage], [codePoint], and [modifiers] arguments must not be null.
  const RawKeyEventDataFuchsia({
    this.hidUsage = 0,
    this.codePoint = 0,
    this.modifiers = 0,
  })  : assert(hidUsage != null),
        assert(codePoint != null),
        assert(modifiers != null);

  /// The USB HID usage.
  ///
  /// See <http://www.usb.org/developers/hidpage/Hut1_12v2.pdf> for more
  /// information.
  final int hidUsage;

  /// The Unicode code point represented by the key event, if any.
  ///
  /// If there is no Unicode code point, this value is zero.
  ///
  /// Dead keys are represented as Unicode combining characters.
  final int codePoint;

  /// The modifiers that were present when the key event occurred.
  ///
  /// See <https://fuchsia.googlesource.com/garnet/+/master/public/fidl/fuchsia.ui.input/input_event_constants.fidl>
  /// for the numerical values of the modifiers. Many of these are also
  /// replicated as static constants in this class.
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
  final int modifiers;

  bool _isLeftRightModifierPressed(KeyboardSide side, int anyMask, int leftMask, int rightMask) {
    if (modifiers & anyMask == 0) {
      return false;
    }
    switch (side) {
      case KeyboardSide.any:
        return true;
      case KeyboardSide.both:
        return modifiers & leftMask != 0 && modifiers & rightMask != 0;
      case KeyboardSide.left:
        return modifiers & leftMask != 0;
      case KeyboardSide.right:
        return modifiers & rightMask != 0;
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
        return modifiers & modifierCapsLock != 0;
      case ModifierKey.numLockModifier:
      case ModifierKey.scrollLockModifier:
      case ModifierKey.functionModifier:
      case ModifierKey.symbolModifier:
        // Fuschia doesn't have masks for these keys (yet).
        return false;
    }
    return false;
  }

  // Keyboard modifier masks for Fuschia modifiers.

  /// The [modifier] field indicates that no modifier keys are pressed if it
  /// equals this value.
  static const int modifierNone = 0x0;

  /// This mask is used to check the [modifiers] field to test whether the CAPS
  /// LOCK modifier key is on.
  static const int modifierCapsLock = 0x1;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// SHIFT modifier key is pressed.
  static const int modifierLeftShift = 0x2;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// SHIFT modifier key is pressed.
  static const int modifierRightShift = 0x4;

  /// This mask is used to check the [modifiers] field to test whether one of
  /// the SHIFT modifier keys is pressed.
  static const int modifierShift = modifierLeftShift | modifierRightShift;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// CTRL modifier key is pressed.
  static const int modifierLeftControl = 0x8;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// CTRL modifier key is pressed.
  static const int modifierRightControl = 0x10;

  /// This mask is used to check the [modifiers] field to test whether one of
  /// the CTRL modifier keys is pressed.
  static const int modifierControl = modifierLeftControl | modifierRightControl;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// ALT modifier key is pressed.
  static const int modifierLeftAlt = 0x20;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// ALT modifier key is pressed.
  static const int modifierRightAlt = 0x40;

  /// This mask is used to check the [modifiers] field to test whether one of
  /// the ALT modifier keys is pressed.
  static const int modifierAlt = modifierLeftAlt | modifierRightAlt;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// META modifier key is pressed.
  static const int modifierLeftMeta = 0x80;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// META modifier key is pressed.
  static const int modifierRightMeta = 0x100;

  /// This mask is used to check the [modifiers] field to test whether one of
  /// the META modifier keys is pressed.
  static const int modifierMeta = modifierLeftMeta | modifierRightMeta;

  @override
  String toString() {
    return '$runtimeType(hidUsage: $hidUsage, codePoint: $codePoint, modifiers: $modifiers, modifiers down: $modifiersPressed)';
  }
}
