// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_HOOK_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_HOOK_HANDLER_H_

#include <string>

namespace flutter {

// Interface for classes that handles keyboard input events.
//
// Keyboard handlers are added to |FlutterWindowsView| in a chain.
// When a key event arrives, |KeyboardHook| is called on each handler
// until the first one that returns true. Then the proper text hooks
// are called on each handler.
class KeyboardHandlerBase {
 public:
  using KeyEventCallback = std::function<void(bool)>;

  virtual ~KeyboardHandlerBase() = default;

  // A function for hooking into keyboard input.
  virtual void KeyboardHook(int key,
                            int scancode,
                            int action,
                            char32_t character,
                            bool extended,
                            bool was_down,
                            KeyEventCallback callback) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_HOOK_HANDLER_H_
