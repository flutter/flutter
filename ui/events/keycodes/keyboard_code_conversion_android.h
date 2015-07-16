// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_KEYCODES_KEYBOARD_CODE_CONVERSION_ANDROID_H_
#define UI_EVENTS_KEYCODES_KEYBOARD_CODE_CONVERSION_ANDROID_H_

#include "ui/events/events_base_export.h"
#include "ui/events/keycodes/keyboard_codes_posix.h"

namespace ui {

EVENTS_BASE_EXPORT KeyboardCode KeyboardCodeFromAndroidKeyCode(int keycode);

}  // namespace ui

#endif  // UI_EVENTS_KEYCODES_KEYBOARD_CODE_CONVERSION_ANDROID_H_
