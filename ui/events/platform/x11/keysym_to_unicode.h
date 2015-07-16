// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_PLATFORM_X11_KEYSYM_TO_UNICODE_H_
#define UI_EVENTS_PLATFORM_X11_KEYSYM_TO_UNICODE_H_

#include <cstdint>

namespace ui {

// Returns a Unicode character corresponding to the given |keysym|.  If the
// |keysym| doesn't represent a printable character, returns zero.  We don't
// support characters outside the Basic Plane, and this function returns zero
// in that case.
uint16_t GetUnicodeCharacterFromXKeySym(unsigned long keysym);

}  // namespace ui

#endif  // UI_EVENTS_PLATFORM_X11_KEYSYM_TO_UNICODE_H_
