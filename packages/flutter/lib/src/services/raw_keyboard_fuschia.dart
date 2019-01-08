// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'raw_keyboard.dart';

// Keyboard modifier masks for Fuschia.
const int _kFuschiaModifierNone = 0;
const int _kFuschiaModifierCapsLock = 1;
const int _kFuschiaModifierLeftShift = 2;
const int _kFuschiaModifierRightShift = 4;
const int _kFuschiaModifierShift = 6; // (_kFuschiaModifierLeftShift | _kFuschiaModifierRightShift);
const int _kFuschiaModifierLeftControl = 8;
const int _kFuschiaModifierRightControl = 16;
const int _kFuschiaModifierControl = 24; // (_kFuschiaModifierLeftControl | _kFuschiaModifierRightControl);
const int _kFuschiaModifierLeftAlt = 32;
const int _kFuschiaModifierRightAlt = 64;
const int _kFuschiaModifierAlt = 96; // (_kFuschiaModifierLeftAlt | _kFuschiaModifierRightAlt);
const int _kFuschiaModifierLeftSuper = 128;
const int _kFuschiaModifierRightSuper = 256;
const int _kFuschiaModifierSuper = 384; // (_kFuschiaModifierLeftSuper | _kFuschiaModifierRightSuper);

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
  /// See <http://www.usb.org/developers/hidpage/Hut1_12v2.pdf>
  final int hidUsage;

  /// The Unicode code point represented by the key event, if any.
  /// Dead keys are represented as Unicode combining characters.
  ///
  /// If there is no Unicode code point, this value is zero.
  final int codePoint;

  /// The modifiers that we present when the key event occurred.
  ///
  /// See <https://fuchsia.googlesource.com/garnet/+/master/public/fidl/fuchsia.ui.input/input_event_constants.fidl>
  /// for the numerical values of the modifiers.
  final int modifiers;

  bool _isLeftRightModifierPressed(KeyboardSide side, int anyMask, int leftMask, int rightMask) {
    if (modifiers == _kFuschiaModifierNone || modifiers & anyMask == 0) {
      return false;
    }
    switch (side) {
      case KeyboardSide.any:
        return true;
      case KeyboardSide.both:
        return modifiers & anyMask == anyMask;
      case KeyboardSide.left:
        return modifiers & leftMask != 0;
      case KeyboardSide.right:
        return modifiers & rightMask != 0;
    }
    return false;
  }

  @override
  bool isModifierPressed(ModifierKey key, [KeyboardSide side = KeyboardSide.any]) {
    switch (key) {
      case ModifierKey.ctrlModifier:
        return _isLeftRightModifierPressed(side, _kFuschiaModifierControl, _kFuschiaModifierLeftControl, _kFuschiaModifierRightControl);
      case ModifierKey.shiftModifier:
        return _isLeftRightModifierPressed(side, _kFuschiaModifierShift, _kFuschiaModifierLeftShift, _kFuschiaModifierRightShift);
      case ModifierKey.altModifier:
        return _isLeftRightModifierPressed(side, _kFuschiaModifierAlt, _kFuschiaModifierLeftAlt, _kFuschiaModifierRightAlt);
      case ModifierKey.metaModifier:
        return _isLeftRightModifierPressed(side, _kFuschiaModifierSuper, _kFuschiaModifierLeftSuper, _kFuschiaModifierRightSuper);
      case ModifierKey.capsLockModifier:
        return modifiers & _kFuschiaModifierCapsLock != 0;
      case ModifierKey.numLockModifier:
      case ModifierKey.scrollLockModifier:
      case ModifierKey.functionModifier:
      case ModifierKey.symbolModifier:
        // Fuschia doesn't have masks for these keys (yet).
        return false;
    }
    return false;
  }
}
