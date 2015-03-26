// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library input_event_constants.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;

final int EventType_UNKNOWN = 0;
final int EventType_KEY_PRESSED = EventType_UNKNOWN + 1;
final int EventType_KEY_RELEASED = EventType_KEY_PRESSED + 1;
final int EventType_POINTER_CANCEL = EventType_KEY_RELEASED + 1;
final int EventType_POINTER_DOWN = EventType_POINTER_CANCEL + 1;
final int EventType_POINTER_MOVE = EventType_POINTER_DOWN + 1;
final int EventType_POINTER_UP = EventType_POINTER_MOVE + 1;

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

final int PointerKind_TOUCH = 0;
final int PointerKind_MOUSE = PointerKind_TOUCH + 1;


