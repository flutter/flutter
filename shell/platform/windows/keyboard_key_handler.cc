// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/keyboard_key_handler.h"

#include <windows.h>

#include <iostream>

#include "flutter/shell/platform/common/json_message_codec.h"
#include "flutter/shell/platform/windows/keyboard_win32_common.h"

namespace flutter {

namespace {

// The maximum number of pending events to keep before
// emitting a warning on the console about unhandled events.
static constexpr int kMaxPendingEvents = 1000;

// Returns if a character sent by Win32 is a dead key.
bool _IsDeadKey(uint32_t ch) {
  return (ch & kDeadKeyCharMask) != 0;
}

// Returns true if this key is a key down event of ShiftRight.
//
// This is a temporary solution to
// https://github.com/flutter/flutter/issues/81674, and forces ShiftRight
// KeyDown events to not be redispatched regardless of the framework's response.
//
// If a ShiftRight KeyDown event is not handled by the framework and is
// redispatched, Win32 will not send its following KeyUp event and keeps
// recording ShiftRight as being pressed.
static bool IsKeyDownShiftRight(int virtual_key, bool was_down) {
#ifdef WINUWP
  return false;
#else
  return virtual_key == VK_RSHIFT && !was_down;
#endif
}

// Returns true if this key is an AltRight key down event.
//
// This is used to resolve an issue where an AltGr press causes CtrlLeft to hang
// when pressed, as reported in https://github.com/flutter/flutter/issues/78005.
//
// When AltGr is pressed (in a supporting layout such as Spanish), Win32 first
// fires a fake CtrlLeft down event, then an AltRight down event.
// This is significant because this fake CtrlLeft down event will not be paired
// with a up event, which is fine until Flutter redispatches the CtrlDown
// event, which Win32 then interprets as a real event, leaving both Win32 and
// the Flutter framework thinking that CtrlLeft is still pressed.
//
// To resolve this, Flutter recognizes this fake CtrlLeft down event using the
// following AltRight down event. Flutter then synthesizes a CtrlLeft key up
// event immediately after the corresponding AltRight key up event.
//
// One catch is that it is impossible to distinguish the fake CtrlLeft down
// from a normal CtrlLeft down (followed by a AltRight down), since they
// contain the exactly same information, including the GetKeyState result.
// Fortunately, this will require the two events to occur *really* close, which
// would be rare, and a misrecognition would only cause a minor consequence
// where the CtrlLeft is released early; the later, real, CtrlLeft up event will
// be ignored.
static bool IsKeyDownAltRight(int action, int virtual_key, bool extended) {
#ifdef WINUWP
  return false;
#else
  return virtual_key == VK_RMENU && extended &&
         (action == WM_KEYDOWN || action == WM_SYSKEYDOWN);
#endif
}

// Returns true if this key is a key up event of AltRight.
//
// This is used to assist a corner case described in |IsKeyDownAltRight|.
static bool IsKeyUpAltRight(int action, int virtual_key, bool extended) {
#ifdef WINUWP
  return false;
#else
  return virtual_key == VK_RMENU && extended &&
         (action == WM_KEYUP || action == WM_SYSKEYUP);
#endif
}

// Returns true if this key is a key down event of CtrlLeft.
//
// This is used to assist a corner case described in |IsKeyDownAltRight|.
static bool IsKeyDownCtrlLeft(int action, int virtual_key) {
#ifdef WINUWP
  return false;
#else
  return virtual_key == VK_LCONTROL &&
         (action == WM_KEYDOWN || action == WM_SYSKEYDOWN);
#endif
}

}  // namespace

KeyboardKeyHandler::KeyboardKeyHandlerDelegate::~KeyboardKeyHandlerDelegate() =
    default;

KeyboardKeyHandler::KeyboardKeyHandler(EventDispatcher dispatch_event)
    : dispatch_event_(dispatch_event),
      last_sequence_id_(1),
      last_key_is_ctrl_left_down(false),
      should_synthesize_ctrl_left_up(false) {}

KeyboardKeyHandler::~KeyboardKeyHandler() = default;

void KeyboardKeyHandler::AddDelegate(
    std::unique_ptr<KeyboardKeyHandlerDelegate> delegate) {
  delegates_.push_back(std::move(delegate));
}

size_t KeyboardKeyHandler::RedispatchedCount() {
  return pending_redispatches_.size();
}

void KeyboardKeyHandler::DispatchEvent(const PendingEvent& event) {
  // TODO(dkwingsmt) consider adding support for dispatching events for UWP
  // in order to support add-to-app.
  // https://github.com/flutter/flutter/issues/70202
#ifdef WINUWP
  return;
#else
  char32_t character = event.character;

  assert(event.action != WM_SYSKEYDOWN && event.action != WM_SYSKEYUP &&
         "Unexpectedly dispatching a SYS event. SYS events can't be dispatched "
         "and should have been prevented in earlier code.");

  INPUT input_event{
      .type = INPUT_KEYBOARD,
      .ki =
          KEYBDINPUT{
              .wVk = static_cast<WORD>(event.key),
              .wScan = static_cast<WORD>(event.scancode),
              .dwFlags = static_cast<WORD>(
                  KEYEVENTF_SCANCODE |
                  (event.extended ? KEYEVENTF_EXTENDEDKEY : 0x0) |
                  (event.action == WM_KEYUP ? KEYEVENTF_KEYUP : 0x0)),
          },
  };

  UINT accepted = dispatch_event_(1, &input_event, sizeof(input_event));
  if (accepted != 1) {
    std::cerr << "Unable to synthesize event for keyboard event with scancode "
              << event.scancode;
    if (character != 0) {
      std::cerr << " (character " << character << ")";
    }
    std::cerr << std::endl;
    ;
  }
#endif
}

void KeyboardKeyHandler::RedispatchEvent(std::unique_ptr<PendingEvent> event) {
#ifdef WINUWP
  return;
#else
  DispatchEvent(*event);
  pending_redispatches_.push_back(std::move(event));
#endif
}

bool KeyboardKeyHandler::KeyboardHook(int key,
                                      int scancode,
                                      int action,
                                      char32_t character,
                                      bool extended,
                                      bool was_down) {
  std::unique_ptr<PendingEvent> incoming =
      std::make_unique<PendingEvent>(PendingEvent{
          .key = static_cast<uint32_t>(key),
          .scancode = static_cast<uint8_t>(scancode),
          .action = static_cast<uint32_t>(action),
          .character = character,
          .extended = extended,
          .was_down = was_down,
      });
  incoming->hash = ComputeEventHash(*incoming);

  if (RemoveRedispatchedEvent(*incoming)) {
    return false;
  }

  if (IsKeyDownAltRight(action, key, extended)) {
    if (last_key_is_ctrl_left_down) {
      should_synthesize_ctrl_left_up = true;
    }
  }
  if (IsKeyDownCtrlLeft(action, key)) {
    last_key_is_ctrl_left_down = true;
    ctrl_left_scancode = scancode;
    should_synthesize_ctrl_left_up = false;
  } else {
    last_key_is_ctrl_left_down = false;
  }
  if (IsKeyUpAltRight(action, key, extended)) {
    if (should_synthesize_ctrl_left_up) {
      should_synthesize_ctrl_left_up = false;
      PendingEvent ctrl_left_up{
          .key = VK_LCONTROL,
          .scancode = ctrl_left_scancode,
          .action = WM_KEYUP,
          .was_down = true,
      };
      DispatchEvent(ctrl_left_up);
    }
  }

  uint64_t sequence_id = ++last_sequence_id_;
  incoming->sequence_id = sequence_id;
  incoming->unreplied = delegates_.size();
  // There are a few situations where events must not be redispatched.
  // Initializing `any_handled` with true in such cases suffices, since it can
  // only be set to true and is used to disable redispatching.
  const bool must_not_redispatch = IsKeyDownShiftRight(key, was_down);
  incoming->any_handled = must_not_redispatch;

  if (pending_responds_.size() > kMaxPendingEvents) {
    std::cerr
        << "There are " << pending_responds_.size()
        << " keyboard events that have not yet received a response from the "
        << "framework. Are responses being sent?" << std::endl;
  }
  pending_responds_.push_back(std::move(incoming));

  for (const auto& delegate : delegates_) {
    delegate->KeyboardHook(key, scancode, action, character, extended, was_down,
                           [sequence_id, this](bool handled) {
                             ResolvePendingEvent(sequence_id, handled);
                           });
  }

  // |ResolvePendingEvent| might trigger redispatching synchronously,
  // which might occur before |KeyboardHook| is returned. This won't
  // make events out of order though, because |KeyboardHook| will always
  // return true at this time, preventing this event from affecting
  // others.

  return true;
}

bool KeyboardKeyHandler::RemoveRedispatchedEvent(const PendingEvent& incoming) {
  for (auto iter = pending_redispatches_.begin();
       iter != pending_redispatches_.end(); ++iter) {
    if ((*iter)->hash == incoming.hash) {
      pending_redispatches_.erase(iter);
      return true;
    }
  }
  return false;
}

void KeyboardKeyHandler::ResolvePendingEvent(uint64_t sequence_id,
                                             bool handled) {
  // Find the pending event
  for (auto iter = pending_responds_.begin(); iter != pending_responds_.end();
       ++iter) {
    if ((*iter)->sequence_id == sequence_id) {
      PendingEvent& event = **iter;
      event.any_handled = event.any_handled || handled;
      event.unreplied -= 1;
      assert(event.unreplied >= 0);
      // If all delegates have replied, redispatch if no one handled.
      if (event.unreplied == 0) {
        std::unique_ptr<PendingEvent> event_ptr = std::move(*iter);
        pending_responds_.erase(iter);
        // Don't dispatch handled events, and also ignore dead key events and
        // sys events.
        //
        // Redispatching dead keys events makes Win32 ignore the dead key state
        // and redispatches a normal character without combining it with the
        // next letter key. Redispatching sys events is impossible due to
        // the limitation of |SendInput|.
        const bool is_syskey =
            event.action == WM_SYSKEYDOWN || event.action == WM_SYSKEYUP;
        const bool should_redispatch = !event_ptr->any_handled &&
                                       !_IsDeadKey(event_ptr->character) &&
                                       !is_syskey;
        if (should_redispatch) {
          RedispatchEvent(std::move(event_ptr));
        }
      }
      // Return here; |iter| can't do ++ after erase.
      return;
    }
  }
  // The pending event should always be found.
  assert(false);
}

uint64_t KeyboardKeyHandler::ComputeEventHash(const PendingEvent& event) {
  // Calculate a key event ID based on the scan code of the key pressed,
  // and the flags we care about.
  return event.scancode | (((event.action == WM_KEYUP ? KEYEVENTF_KEYUP : 0x0) |
                            (event.extended ? KEYEVENTF_EXTENDEDKEY : 0x0))
                           << 16);
}

}  // namespace flutter
