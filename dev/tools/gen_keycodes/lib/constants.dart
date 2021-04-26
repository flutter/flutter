// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/* === LOGICAL KEY BITMASKS === */
// The following constants are used to composite the value for a Flutter logical
// key.
//
// A Flutter logical key supports up to 53-bits, as limited by JavaScript
// integers.

/* Bit 31-0: Value */
// The lower 32 bits represent different values within a plane.

/// Mask for the 32-bit value portion of the code.
const int kValueMask =          0x000FFFFFFFF;


/* Bit 39-32: Source of value */
// The next 8 bits represent where the values come from, consequently how to
// interpret them.

/// Mask for bit #39-32 portion of the code, indicating the source of the value.
const int kSourceMask =         0x0FF00000000;

/// The code prefix for keys that have a Unicode representation, generated from
/// their code points.
///
/// See also:
///
///  * [kUnprintablePlane], for keys that are also generated from code points but
///    unprintable.
const int kUnicodePlane =       0x00000000000;

/// The code prefix for keys generated from their USB HID usages.
const int kHidPlane =           0x00100000000;

/// The code prefix for unrecognized keys that are unique to Android, generated
/// from platform-specific codes.
const int kAndroidPlane =       0x00200000000;

/// The code prefix for unrecognized keys that are unique to Fuchsia, generated
/// from platform-specific codes.
const int kFuchsiaPlane =       0x00300000000;

/// The code prefix for unrecognized keys that are unique to iOS, generated
/// from platform-specific codes.
const int kIosPlane =           0x00400000000;

/// The code prefix for unrecognized keys that are unique to macOS, generated
/// from platform-specific codes.
const int kMacOsPlane =         0x00500000000;

/// The code prefix for unrecognized keys that are unique to Gtk, generated from
/// platform-specific codes.
const int kGtkPlane =           0x00600000000;

/// The code prefix for unrecognized keys that are unique to Windows, generated
/// from platform-specific codes.
const int kWindowsPlane =       0x00700000000;

/// The code prefix for unrecognized keys that are unique to Web, generated from
/// platform-specific codes.
const int kWebPlane =           0x00800000000;

/// The code prefix for keys that do not have a Unicode representation, generated
/// from their code points.
///
/// See also:
///
///  * [kUnicodePlane], for keys that are also generated from code points but
///    printable.
const int kUnprintablePlane =   0x01000000000;


/* Bit 43-40: Key variation */
// The next 4 bits represent keys that have multiple variations, such as a left
// and right variation of a modifier key, or a Numpad variation of a digit key.

/// Mask for bit #43-40 portion of the code, indicating the variation of the key.
const int kVariationMask =      0xF0000000000;

/// The code prefix for pseudo-keys which represent collections of key synonyms,
/// such as Control.
const int kSynonymPlane =       0x20000000000;

/// The code prefix for the left modifier of a pair of modifiers, such as Control
/// Left.
const int kLeftModifierPlane =  0x30000000000;

/// The code prefix for the right modifier of a pair of modifiers, such as Control
/// Right.
const int kRightModifierPlane = 0x40000000000;

/// The code prefix for a Numpad key, such as Numpad 1.
const int kNumpadPlane =        0x50000000000;
