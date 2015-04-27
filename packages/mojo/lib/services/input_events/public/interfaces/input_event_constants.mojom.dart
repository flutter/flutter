// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library input_event_constants.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;

const int EventType_UNKNOWN = 0;
const int EventType_KEY_PRESSED = 1;
const int EventType_KEY_RELEASED = 2;
const int EventType_POINTER_CANCEL = 3;
const int EventType_POINTER_DOWN = 4;
const int EventType_POINTER_MOVE = 5;
const int EventType_POINTER_UP = 6;

const int EventFlags_NONE = 0;
const int EventFlags_CAPS_LOCK_DOWN = 1;
const int EventFlags_SHIFT_DOWN = 2;
const int EventFlags_CONTROL_DOWN = 4;
const int EventFlags_ALT_DOWN = 8;
const int EventFlags_LEFT_MOUSE_BUTTON = 16;
const int EventFlags_MIDDLE_MOUSE_BUTTON = 32;
const int EventFlags_RIGHT_MOUSE_BUTTON = 64;
const int EventFlags_COMMAND_DOWN = 128;
const int EventFlags_EXTENDED = 256;
const int EventFlags_IS_SYNTHESIZED = 512;
const int EventFlags_ALTGR_DOWN = 1024;
const int EventFlags_MOD3_DOWN = 2048;

const int MouseEventFlags_IS_DOUBLE_CLICK = 65536;
const int MouseEventFlags_IS_TRIPLE_CLICK = 131072;
const int MouseEventFlags_IS_NON_CLIENT = 262144;

const int PointerKind_TOUCH = 0;
const int PointerKind_MOUSE = 1;


