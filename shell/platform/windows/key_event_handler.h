// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_KEY_EVENT_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_KEY_EVENT_HANDLER_H_

#include <deque>
#include <memory>
#include <string>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/basic_message_channel.h"
#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/windows/keyboard_hook_handler.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "rapidjson/document.h"

namespace flutter {

class FlutterWindowsView;

// Implements a KeyboardHookHandler
//
// Handles key events and forwards them to the Flutter engine.
class KeyEventHandler : public KeyboardHookHandler {
 public:
  using SendInputDelegate =
      std::function<UINT(UINT cInputs, LPINPUT pInputs, int cbSize)>;

  explicit KeyEventHandler(flutter::BinaryMessenger* messenger,
                           SendInputDelegate delegate = SendInput);

  virtual ~KeyEventHandler();

  // |KeyboardHookHandler|
  bool KeyboardHook(FlutterWindowsView* window,
                    int key,
                    int scancode,
                    int action,
                    char32_t character,
                    bool extended) override;

  // |KeyboardHookHandler|
  void TextHook(FlutterWindowsView* window,
                const std::u16string& text) override;

  // |KeyboardHookHandler|
  void ComposeBeginHook() override;

  // |KeyboardHookHandler|
  void ComposeEndHook() override;

  // |KeyboardHookHandler|
  void ComposeChangeHook(const std::u16string& text, int cursor_pos) override;

 private:
  KEYBDINPUT* FindPendingEvent(uint64_t id);
  void RemovePendingEvent(uint64_t id);
  void AddPendingEvent(uint64_t id, int scancode, int action, bool extended);
  void HandleResponse(bool handled,
                      uint64_t id,
                      int action,
                      bool extended,
                      int scancode,
                      int character);

  // The Flutter system channel for key event messages.
  std::unique_ptr<flutter::BasicMessageChannel<rapidjson::Document>> channel_;

  // The queue of key events that have been sent to the framework but have not
  // yet received a response.
  std::deque<std::pair<uint64_t, KEYBDINPUT>> pending_events_;

  // A function used to dispatch synthesized events. Used in testing to inject a
  // test function to collect events. Defaults to the Windows function
  // SendInput.
  SendInputDelegate send_input_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_KEY_EVENT_HANDLER_H_
