// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library input_event_constants.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;

final int EventType_UNKNOWN = 0;
final int EventType_MOUSE_PRESSED = EventType_UNKNOWN + 1;
final int EventType_MOUSE_DRAGGED = EventType_MOUSE_PRESSED + 1;
final int EventType_MOUSE_RELEASED = EventType_MOUSE_DRAGGED + 1;
final int EventType_MOUSE_MOVED = EventType_MOUSE_RELEASED + 1;
final int EventType_MOUSE_ENTERED = EventType_MOUSE_MOVED + 1;
final int EventType_MOUSE_EXITED = EventType_MOUSE_ENTERED + 1;
final int EventType_KEY_PRESSED = EventType_MOUSE_EXITED + 1;
final int EventType_KEY_RELEASED = EventType_KEY_PRESSED + 1;
final int EventType_MOUSEWHEEL = EventType_KEY_RELEASED + 1;
final int EventType_MOUSE_CAPTURE_CHANGED = EventType_MOUSEWHEEL + 1;
final int EventType_TOUCH_RELEASED = EventType_MOUSE_CAPTURE_CHANGED + 1;
final int EventType_TOUCH_PRESSED = EventType_TOUCH_RELEASED + 1;
final int EventType_TOUCH_MOVED = EventType_TOUCH_PRESSED + 1;
final int EventType_TOUCH_CANCELLED = EventType_TOUCH_MOVED + 1;
final int EventType_DROP_TARGET_EVENT = EventType_TOUCH_CANCELLED + 1;
final int EventType_TRANSLATED_KEY_PRESS = EventType_DROP_TARGET_EVENT + 1;
final int EventType_TRANSLATED_KEY_RELEASE = EventType_TRANSLATED_KEY_PRESS + 1;
final int EventType_GESTURE_SCROLL_BEGIN = EventType_TRANSLATED_KEY_RELEASE + 1;
final int EventType_GESTURE_SCROLL_END = EventType_GESTURE_SCROLL_BEGIN + 1;
final int EventType_GESTURE_SCROLL_UPDATE = EventType_GESTURE_SCROLL_END + 1;
final int EventType_GESTURE_TAP = EventType_GESTURE_SCROLL_UPDATE + 1;
final int EventType_GESTURE_TAP_DOWN = EventType_GESTURE_TAP + 1;
final int EventType_GESTURE_TAP_CANCEL = EventType_GESTURE_TAP_DOWN + 1;
final int EventType_GESTURE_TAP_UNCONFIRMED = EventType_GESTURE_TAP_CANCEL + 1;
final int EventType_GESTURE_DOUBLE_TAP = EventType_GESTURE_TAP_UNCONFIRMED + 1;
final int EventType_GESTURE_BEGIN = EventType_GESTURE_DOUBLE_TAP + 1;
final int EventType_GESTURE_END = EventType_GESTURE_BEGIN + 1;
final int EventType_GESTURE_TWO_FINGER_TAP = EventType_GESTURE_END + 1;
final int EventType_GESTURE_PINCH_BEGIN = EventType_GESTURE_TWO_FINGER_TAP + 1;
final int EventType_GESTURE_PINCH_END = EventType_GESTURE_PINCH_BEGIN + 1;
final int EventType_GESTURE_PINCH_UPDATE = EventType_GESTURE_PINCH_END + 1;
final int EventType_GESTURE_LONG_PRESS = EventType_GESTURE_PINCH_UPDATE + 1;
final int EventType_GESTURE_LONG_TAP = EventType_GESTURE_LONG_PRESS + 1;
final int EventType_GESTURE_SWIPE = EventType_GESTURE_LONG_TAP + 1;
final int EventType_GESTURE_SHOW_PRESS = EventType_GESTURE_SWIPE + 1;
final int EventType_GESTURE_WIN8_EDGE_SWIPE = EventType_GESTURE_SHOW_PRESS + 1;
final int EventType_SCROLL = EventType_GESTURE_WIN8_EDGE_SWIPE + 1;
final int EventType_SCROLL_FLING_START = EventType_SCROLL + 1;
final int EventType_SCROLL_FLING_CANCEL = EventType_SCROLL_FLING_START + 1;
final int EventType_CANCEL_MODE = EventType_SCROLL_FLING_CANCEL + 1;
final int EventType_UMA_DATA = EventType_CANCEL_MODE + 1;

final int EventFlags_NONE = 0;
final int EventFlags_CAPS_LOCK_DOWN = 1;
final int EventFlags_SHIFT_DOWN = 2;
final int EventFlags_CONTROL_DOWN = 4;
final int EventFlags_ALT_DOWN = 8;
final int EventFlags_LEFT_MOUSE_BUTTON = 16;
final int EventFlags_MIDDLE_MOUSE_BUTTON = 32;
final int EventFlags_RIGHT_MOUSE_BUTTON = 64;
final int EventFlags_COMMAND_DOWN = 128;
final int EventFlags_EXTENDED = 256;
final int EventFlags_IS_SYNTHESIZED = 512;
final int EventFlags_ALTGR_DOWN = 1024;
final int EventFlags_MOD3_DOWN = 2048;

final int MouseEventFlags_IS_DOUBLE_CLICK = 65536;
final int MouseEventFlags_IS_TRIPLE_CLICK = 131072;
final int MouseEventFlags_IS_NON_CLIENT = 262144;


