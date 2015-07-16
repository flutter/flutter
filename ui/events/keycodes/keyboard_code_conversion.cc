// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/keycodes/keyboard_code_conversion.h"

#include "ui/events/event_constants.h"

namespace ui {

uint16 GetCharacterFromKeyCode(KeyboardCode key_code, int flags) {
  const bool ctrl = (flags & EF_CONTROL_DOWN) != 0;
  const bool shift = (flags & EF_SHIFT_DOWN) != 0;
  const bool upper = shift ^ ((flags & EF_CAPS_LOCK_DOWN) != 0);

  // Following Windows behavior to map ctrl-a ~ ctrl-z to \x01 ~ \x1A.
  if (key_code >= VKEY_A && key_code <= VKEY_Z) {
    return static_cast<uint16>
        (key_code - VKEY_A + (ctrl ? 1 : (upper ? 'A' : 'a')));
  }

  // Other ctrl characters
  if (ctrl) {
    if (shift) {
      // following graphics chars require shift key to input.
      switch (key_code) {
        // ctrl-@ maps to \x00 (Null byte)
        case VKEY_2:
          return 0;
        // ctrl-^ maps to \x1E (Record separator, Information separator two)
        case VKEY_6:
          return 0x1E;
        // ctrl-_ maps to \x1F (Unit separator, Information separator one)
        case VKEY_OEM_MINUS:
          return 0x1F;
        // Returns 0 for all other keys to avoid inputting unexpected chars.
        default:
          return 0;
      }
    } else {
      switch (key_code) {
        // ctrl-[ maps to \x1B (Escape)
        case VKEY_OEM_4:
          return 0x1B;
        // ctrl-\ maps to \x1C (File separator, Information separator four)
        case VKEY_OEM_5:
          return 0x1C;
        // ctrl-] maps to \x1D (Group separator, Information separator three)
        case VKEY_OEM_6:
          return 0x1D;
        // ctrl-Enter maps to \x0A (Line feed)
        case VKEY_RETURN:
          return 0x0A;
        // Returns 0 for all other keys to avoid inputting unexpected chars.
        default:
          return 0;
      }
    }
  }

  // For IME support.
  if (key_code == ui::VKEY_PROCESSKEY)
    return 0xE5;

  // Normal characters
  if (key_code >= VKEY_0 && key_code <= VKEY_9) {
    return shift ? ")!@#$%^&*("[key_code - VKEY_0] :
        static_cast<uint16>(key_code);
  } else if (key_code >= VKEY_NUMPAD0 && key_code <= VKEY_NUMPAD9) {
    return static_cast<uint16>(key_code - VKEY_NUMPAD0 + '0');
  }

  switch (key_code) {
    case VKEY_TAB:
      return '\t';
    case VKEY_RETURN:
      return '\r';
    case VKEY_MULTIPLY:
      return '*';
    case VKEY_ADD:
      return '+';
    case VKEY_SUBTRACT:
      return '-';
    case VKEY_DECIMAL:
      return '.';
    case VKEY_DIVIDE:
      return '/';
    case VKEY_SPACE:
      return ' ';
    case VKEY_OEM_1:
      return shift ? ':' : ';';
    case VKEY_OEM_PLUS:
      return shift ? '+' : '=';
    case VKEY_OEM_COMMA:
      return shift ? '<' : ',';
    case VKEY_OEM_MINUS:
      return shift ? '_' : '-';
    case VKEY_OEM_PERIOD:
      return shift ? '>' : '.';
    case VKEY_OEM_2:
      return shift ? '?' : '/';
    case VKEY_OEM_3:
      return shift ? '~' : '`';
    case VKEY_OEM_4:
      return shift ? '{' : '[';
    case VKEY_OEM_5:
      return shift ? '|' : '\\';
    case VKEY_OEM_6:
      return shift ? '}' : ']';
    case VKEY_OEM_7:
      return shift ? '"' : '\'';
    default:
      return 0;
  }
}

}  // namespace ui
