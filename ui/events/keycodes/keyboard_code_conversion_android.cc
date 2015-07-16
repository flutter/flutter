// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/keycodes/keyboard_code_conversion_android.h"

#include <android/keycodes.h>

namespace ui {

namespace {

// The Android NDK does not provide values for these yet:
enum {
  AKEYCODE_ESCAPE          = 111,
  AKEYCODE_FORWARD_DEL     = 112,
  AKEYCODE_CTRL_LEFT       = 113,
  AKEYCODE_CTRL_RIGHT      = 114,
  AKEYCODE_CAPS_LOCK       = 115,
  AKEYCODE_SCROLL_LOCK     = 116,
  AKEYCODE_META_LEFT       = 117,
  AKEYCODE_META_RIGHT      = 118,
  AKEYCODE_BREAK           = 121,
  AKEYCODE_MOVE_HOME       = 122,
  AKEYCODE_MOVE_END        = 123,
  AKEYCODE_INSERT          = 124,
  AKEYCODE_MEDIA_PLAY      = 126,
  AKEYCODE_MEDIA_PAUSE     = 127,
  AKEYCODE_F1              = 131,
  AKEYCODE_F2              = 132,
  AKEYCODE_F3              = 133,
  AKEYCODE_F4              = 134,
  AKEYCODE_F5              = 135,
  AKEYCODE_F6              = 136,
  AKEYCODE_F7              = 137,
  AKEYCODE_F8              = 138,
  AKEYCODE_F9              = 139,
  AKEYCODE_F10             = 140,
  AKEYCODE_F11             = 141,
  AKEYCODE_F12             = 142,
  AKEYCODE_NUM_LOCK        = 143,
  AKEYCODE_NUMPAD_0        = 144,
  AKEYCODE_NUMPAD_1        = 145,
  AKEYCODE_NUMPAD_2        = 146,
  AKEYCODE_NUMPAD_3        = 147,
  AKEYCODE_NUMPAD_4        = 148,
  AKEYCODE_NUMPAD_5        = 149,
  AKEYCODE_NUMPAD_6        = 150,
  AKEYCODE_NUMPAD_7        = 151,
  AKEYCODE_NUMPAD_8        = 152,
  AKEYCODE_NUMPAD_9        = 153,
  AKEYCODE_NUMPAD_DIVIDE   = 154,
  AKEYCODE_NUMPAD_MULTIPLY = 155,
  AKEYCODE_NUMPAD_SUBTRACT = 156,
  AKEYCODE_NUMPAD_ADD      = 157,
  AKEYCODE_NUMPAD_DOT      = 158,
  AKEYCODE_VOLUME_MUTE     = 164,
  AKEYCODE_CHANNEL_UP      = 166,
  AKEYCODE_CHANNEL_DOWN    = 167,
};

}  // namespace

KeyboardCode KeyboardCodeFromAndroidKeyCode(int keycode) {
  // Does not provide all key codes, and does not handle all keys.
  switch (keycode) {
    case AKEYCODE_DEL:
      return VKEY_BACK;
    case AKEYCODE_TAB:
      return VKEY_TAB;
    case AKEYCODE_CLEAR:
      return VKEY_CLEAR;
    case AKEYCODE_DPAD_CENTER:
    case AKEYCODE_ENTER:
      return VKEY_RETURN;
    case AKEYCODE_SHIFT_LEFT:
      return VKEY_LSHIFT;
    case AKEYCODE_SHIFT_RIGHT:
      return VKEY_RSHIFT;
    case AKEYCODE_BACK:
      return VKEY_BROWSER_BACK;
    case AKEYCODE_SPACE:
      return VKEY_SPACE;
    case AKEYCODE_MOVE_HOME:
      return VKEY_HOME;
    case AKEYCODE_DPAD_LEFT:
      return VKEY_LEFT;
    case AKEYCODE_DPAD_UP:
      return VKEY_UP;
    case AKEYCODE_DPAD_RIGHT:
      return VKEY_RIGHT;
    case AKEYCODE_DPAD_DOWN:
      return VKEY_DOWN;
    case AKEYCODE_0:
      return VKEY_0;
    case AKEYCODE_1:
      return VKEY_1;
    case AKEYCODE_2:
      return VKEY_2;
    case AKEYCODE_3:
      return VKEY_3;
    case AKEYCODE_4:
      return VKEY_4;
    case AKEYCODE_5:
      return VKEY_5;
    case AKEYCODE_6:
      return VKEY_6;
    case AKEYCODE_7:
      return VKEY_7;
    case AKEYCODE_8:
      return VKEY_8;
    case AKEYCODE_9:
      return VKEY_9;
    case AKEYCODE_A:
      return VKEY_A;
    case AKEYCODE_B:
      return VKEY_B;
    case AKEYCODE_C:
      return VKEY_C;
    case AKEYCODE_D:
      return VKEY_D;
    case AKEYCODE_E:
      return VKEY_E;
    case AKEYCODE_F:
      return VKEY_F;
    case AKEYCODE_G:
      return VKEY_G;
    case AKEYCODE_H:
      return VKEY_H;
    case AKEYCODE_I:
      return VKEY_I;
    case AKEYCODE_J:
      return VKEY_J;
    case AKEYCODE_K:
      return VKEY_K;
    case AKEYCODE_L:
      return VKEY_L;
    case AKEYCODE_M:
      return VKEY_M;
    case AKEYCODE_N:
      return VKEY_N;
    case AKEYCODE_O:
      return VKEY_O;
    case AKEYCODE_P:
      return VKEY_P;
    case AKEYCODE_Q:
      return VKEY_Q;
    case AKEYCODE_R:
      return VKEY_R;
    case AKEYCODE_S:
      return VKEY_S;
    case AKEYCODE_T:
      return VKEY_T;
    case AKEYCODE_U:
      return VKEY_U;
    case AKEYCODE_V:
      return VKEY_V;
    case AKEYCODE_W:
      return VKEY_W;
    case AKEYCODE_X:
      return VKEY_X;
    case AKEYCODE_Y:
      return VKEY_Y;
    case AKEYCODE_Z:
      return VKEY_Z;
    case AKEYCODE_VOLUME_DOWN:
      return VKEY_VOLUME_DOWN;
    case AKEYCODE_VOLUME_UP:
      return VKEY_VOLUME_UP;
    case AKEYCODE_MEDIA_NEXT:
      return VKEY_MEDIA_NEXT_TRACK;
    case AKEYCODE_MEDIA_PREVIOUS:
      return VKEY_MEDIA_PREV_TRACK;
    case AKEYCODE_MEDIA_STOP:
      return VKEY_MEDIA_STOP;
    case AKEYCODE_MEDIA_PAUSE:
      return VKEY_MEDIA_PLAY_PAUSE;
    // Colon key.
    case AKEYCODE_SEMICOLON:
      return VKEY_OEM_1;
    case AKEYCODE_COMMA:
      return VKEY_OEM_COMMA;
    case AKEYCODE_MINUS:
      return VKEY_OEM_MINUS;
    case AKEYCODE_EQUALS:
      return VKEY_OEM_PLUS;
    case AKEYCODE_PERIOD:
      return VKEY_OEM_PERIOD;
    case AKEYCODE_SLASH:
      return VKEY_OEM_2;
    case AKEYCODE_LEFT_BRACKET:
      return VKEY_OEM_4;
    case AKEYCODE_BACKSLASH:
      return VKEY_OEM_5;
    case AKEYCODE_RIGHT_BRACKET:
      return VKEY_OEM_6;
    case AKEYCODE_MUTE:
    case AKEYCODE_VOLUME_MUTE:
      return VKEY_VOLUME_MUTE;
    case AKEYCODE_ESCAPE:
      return VKEY_ESCAPE;
    case AKEYCODE_MEDIA_PLAY:
    case AKEYCODE_MEDIA_PLAY_PAUSE:
      return VKEY_MEDIA_PLAY_PAUSE;
    case AKEYCODE_MOVE_END:
      return VKEY_END;
    case AKEYCODE_ALT_LEFT:
      return VKEY_LMENU;
    case AKEYCODE_ALT_RIGHT:
      return VKEY_RMENU;
    case AKEYCODE_GRAVE:
      return VKEY_OEM_3;
    case AKEYCODE_APOSTROPHE:
      return VKEY_OEM_3;
    case AKEYCODE_MEDIA_REWIND:
      return VKEY_OEM_103;
    case AKEYCODE_MEDIA_FAST_FORWARD:
      return VKEY_OEM_104;
    case AKEYCODE_PAGE_UP:
      return VKEY_PRIOR;
    case AKEYCODE_PAGE_DOWN:
      return VKEY_NEXT;
    case AKEYCODE_FORWARD_DEL:
      return VKEY_DELETE;
    case AKEYCODE_CTRL_LEFT:
      return VKEY_LCONTROL;
    case AKEYCODE_CTRL_RIGHT:
      return VKEY_RCONTROL;
    case AKEYCODE_CAPS_LOCK:
      return VKEY_CAPITAL;
    case AKEYCODE_SCROLL_LOCK:
      return VKEY_SCROLL;
    case AKEYCODE_META_LEFT:
      return VKEY_LWIN;
    case AKEYCODE_META_RIGHT:
      return VKEY_RWIN;
    case AKEYCODE_BREAK:
      return VKEY_PAUSE;
    case AKEYCODE_INSERT:
      return VKEY_INSERT;
    case AKEYCODE_F1:
      return VKEY_F1;
    case AKEYCODE_F2:
      return VKEY_F2;
    case AKEYCODE_F3:
      return VKEY_F3;
    case AKEYCODE_F4:
      return VKEY_F4;
    case AKEYCODE_F5:
      return VKEY_F5;
    case AKEYCODE_F6:
      return VKEY_F6;
    case AKEYCODE_F7:
      return VKEY_F7;
    case AKEYCODE_F8:
      return VKEY_F8;
    case AKEYCODE_F9:
      return VKEY_F9;
    case AKEYCODE_F10:
      return VKEY_F10;
    case AKEYCODE_F11:
      return VKEY_F11;
    case AKEYCODE_F12:
      return VKEY_F12;
    case AKEYCODE_NUM_LOCK:
      return VKEY_NUMLOCK;
    case AKEYCODE_NUMPAD_0:
      return VKEY_NUMPAD0;
    case AKEYCODE_NUMPAD_1:
      return VKEY_NUMPAD1;
    case AKEYCODE_NUMPAD_2:
      return VKEY_NUMPAD2;
    case AKEYCODE_NUMPAD_3:
      return VKEY_NUMPAD3;
    case AKEYCODE_NUMPAD_4:
      return VKEY_NUMPAD4;
    case AKEYCODE_NUMPAD_5:
      return VKEY_NUMPAD5;
    case AKEYCODE_NUMPAD_6:
      return VKEY_NUMPAD6;
    case AKEYCODE_NUMPAD_7:
      return VKEY_NUMPAD7;
    case AKEYCODE_NUMPAD_8:
      return VKEY_NUMPAD8;
    case AKEYCODE_NUMPAD_9:
      return VKEY_NUMPAD9;
    case AKEYCODE_NUMPAD_DIVIDE:
      return VKEY_DIVIDE;
    case AKEYCODE_NUMPAD_MULTIPLY:
      return VKEY_MULTIPLY;
    case AKEYCODE_NUMPAD_SUBTRACT:
      return VKEY_SUBTRACT;
    case AKEYCODE_NUMPAD_ADD:
      return VKEY_ADD;
    case AKEYCODE_NUMPAD_DOT:
      return VKEY_DECIMAL;
    case AKEYCODE_CHANNEL_UP:
      return VKEY_PRIOR;
    case AKEYCODE_CHANNEL_DOWN:
      return VKEY_NEXT;
    default:
      return VKEY_UNKNOWN;
  }
}

}  // namespace ui
