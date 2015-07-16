// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_PLATFORM_X11_KEYBOARD_CODE_CONVERSION_X11_H_
#define UI_EVENTS_PLATFORM_X11_KEYBOARD_CODE_CONVERSION_X11_H_

#include "base/basictypes.h"
#include "ui/events/events_base_export.h"
#include "ui/events/keycodes/keyboard_codes_posix.h"

typedef union _XEvent XEvent;
typedef struct _XDisplay XDisplay;

namespace ui {

EVENTS_BASE_EXPORT KeyboardCode KeyboardCodeFromXKeyEvent(const XEvent* xev);

EVENTS_BASE_EXPORT KeyboardCode KeyboardCodeFromXKeysym(unsigned int keysym);

EVENTS_BASE_EXPORT const char* CodeFromXEvent(const XEvent* xev);

// Returns a character on a standard US PC keyboard from an XEvent.
EVENTS_BASE_EXPORT uint16 GetCharacterFromXEvent(const XEvent* xev);

// Converts a KeyboardCode into an X KeySym.
EVENTS_BASE_EXPORT int XKeysymForWindowsKeyCode(KeyboardCode keycode,
                                                bool shift);

// Returns a XKeyEvent keycode (scancode) for a KeyboardCode. Keyboard layouts
// are usually not injective, so inverse mapping should be avoided when
// practical. A round-trip keycode -> KeyboardCode -> keycode will not
// necessarily return the original keycode.
EVENTS_BASE_EXPORT unsigned int XKeyCodeForWindowsKeyCode(KeyboardCode key_code,
                                                          int flags,
                                                          XDisplay* display);

// Converts an X keycode into ui::KeyboardCode.
EVENTS_BASE_EXPORT KeyboardCode
DefaultKeyboardCodeFromHardwareKeycode(unsigned int hardware_code);

// Initializes a core XKeyEvent from an XI2 key event.
EVENTS_BASE_EXPORT void InitXKeyEventFromXIDeviceEvent(const XEvent& src,
                                                       XEvent* dst);

}  // namespace ui

#endif  // UI_EVENTS_PLATFORM_X11_KEYBOARD_CODE_CONVERSION_X11_H_
