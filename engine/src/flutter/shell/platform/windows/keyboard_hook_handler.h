// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_HOOK_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_HOOK_HANDLER_H_

#include "flutter/shell/platform/windows/public/flutter_windows.h"

namespace flutter {

class Win32FlutterWindow;

// Abstract class for handling keyboard input events.
class KeyboardHookHandler {
 public:
  virtual ~KeyboardHookHandler() = default;

  // A function for hooking into keyboard input.
  virtual void KeyboardHook(Win32FlutterWindow* window,
                            int key,
                            int scancode,
                            int action,
                            int mods) = 0;

  // A function for hooking into unicode code point input.
  virtual void CharHook(Win32FlutterWindow* window,
                        unsigned int code_point) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_HOOK_HANDLER_H_
