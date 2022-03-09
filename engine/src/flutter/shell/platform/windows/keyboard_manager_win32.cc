// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <assert.h>
#include <iostream>
#include <memory>
#include <string>

#include "keyboard_manager_win32.h"

#include "keyboard_win32_common.h"

namespace flutter {

namespace {

// The maximum number of pending events to keep before
// emitting a warning on the console about unhandled events.
static constexpr int kMaxPendingEvents = 1000;

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
// following AltRight down event. Flutter then forges a CtrlLeft key up event
// immediately after the corresponding AltRight key up event.
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

// Returns if a character sent by Win32 is a dead key.
static bool IsDeadKey(uint32_t ch) {
  return (ch & kDeadKeyCharMask) != 0;
}

static char32_t CodePointFromSurrogatePair(wchar_t high, wchar_t low) {
  return 0x10000 + ((static_cast<char32_t>(high) & 0x000003FF) << 10) +
         (low & 0x3FF);
}

static uint16_t ResolveKeyCode(uint16_t original,
                               bool extended,
                               uint8_t scancode) {
  switch (original) {
    case VK_SHIFT:
    case VK_LSHIFT:
      return MapVirtualKey(scancode, MAPVK_VSC_TO_VK_EX);
    case VK_MENU:
    case VK_LMENU:
      return extended ? VK_RMENU : VK_LMENU;
    case VK_CONTROL:
    case VK_LCONTROL:
      return extended ? VK_RCONTROL : VK_LCONTROL;
    default:
      return original;
  }
}

static bool IsPrintable(uint32_t c) {
  constexpr char32_t kMinPrintable = ' ';
  constexpr char32_t kDelete = 0x7F;
  return c >= kMinPrintable && c != kDelete;
}

}  // namespace

KeyboardManagerWin32::KeyboardManagerWin32(WindowDelegate* delegate)
    : window_delegate_(delegate),
      last_key_is_ctrl_left_down(false),
      should_synthesize_ctrl_left_up(false) {}

void KeyboardManagerWin32::RedispatchEvent(
    std::unique_ptr<PendingEvent> event) {
  for (const Win32Message& message : event->session) {
    // Never redispatch sys keys, because their original messages have been
    // passed to the system default processor.
    const bool is_syskey =
        message.action == WM_SYSKEYDOWN || message.action == WM_SYSKEYUP;
    if (is_syskey) {
      continue;
    }
    pending_redispatches_.push_back(message);
    UINT result = window_delegate_->Win32DispatchMessage(
        message.action, message.wparam, message.lparam);
    if (result != 0) {
      std::cerr << "Unable to synthesize event for keyboard event."
                << std::endl;
    }
  }
  if (pending_redispatches_.size() > kMaxPendingEvents) {
    std::cerr
        << "There are " << pending_redispatches_.size()
        << " keyboard events that have not yet received a response from the "
        << "framework. Are responses being sent?" << std::endl;
  }
}

bool KeyboardManagerWin32::RemoveRedispatchedMessage(UINT const action,
                                                     WPARAM const wparam,
                                                     LPARAM const lparam) {
  for (auto iter = pending_redispatches_.begin();
       iter != pending_redispatches_.end(); ++iter) {
    if (action == iter->action && wparam == iter->wparam) {
      pending_redispatches_.erase(iter);
      return true;
    }
  }
  return false;
}

void KeyboardManagerWin32::OnKey(std::unique_ptr<PendingEvent> event,
                                 OnKeyCallback callback) {
  if (IsKeyDownAltRight(event->action, event->key, event->extended)) {
    if (last_key_is_ctrl_left_down) {
      should_synthesize_ctrl_left_up = true;
    }
  }
  if (IsKeyDownCtrlLeft(event->action, event->key)) {
    last_key_is_ctrl_left_down = true;
    ctrl_left_scancode = event->scancode;
    should_synthesize_ctrl_left_up = false;
  } else {
    last_key_is_ctrl_left_down = false;
  }
  if (IsKeyUpAltRight(event->action, event->key, event->extended)) {
    if (should_synthesize_ctrl_left_up) {
      should_synthesize_ctrl_left_up = false;
      const LPARAM lParam =
          (1 /* repeat_count */ << 0) | (ctrl_left_scancode << 16) |
          (0 /* extended */ << 24) | (1 /* prev_state */ << 30) |
          (1 /* transition */ << 31);
      window_delegate_->Win32DispatchMessage(WM_KEYUP, VK_CONTROL, lParam);
    }
  }

  const PendingEvent clone = *event;
  window_delegate_->OnKey(clone.key, clone.scancode, clone.action,
                          clone.character, clone.extended, clone.was_down,
                          [this, event = event.release(),
                           callback = std::move(callback)](bool handled) {
                            callback(std::unique_ptr<PendingEvent>(event),
                                     handled);
                          });
}

void KeyboardManagerWin32::DispatchReadyTexts() {
  auto front = pending_texts_.begin();
  for (; front != pending_texts_.end() && front->ready; ++front) {
    window_delegate_->OnText(front->content);
  }
  pending_texts_.erase(pending_texts_.begin(), front);
}

void KeyboardManagerWin32::HandleOnKeyResult(
    std::unique_ptr<PendingEvent> event,
    bool handled,
    std::list<PendingText>::iterator pending_text) {
  if (pending_text != pending_texts_.end()) {
    if (pending_text->placeholder || handled) {
      pending_texts_.erase(pending_text);
    } else {
      pending_text->ready = true;
    }
    DispatchReadyTexts();
  }

  if (handled) {
    return;
  }

  RedispatchEvent(std::move(event));
}

bool KeyboardManagerWin32::HandleMessage(UINT const action,
                                         WPARAM const wparam,
                                         LPARAM const lparam) {
  if (RemoveRedispatchedMessage(action, wparam, lparam)) {
    return false;
  }
  switch (action) {
    case WM_DEADCHAR:
    case WM_SYSDEADCHAR:
    case WM_CHAR:
    case WM_SYSCHAR: {
      const Win32Message message =
          Win32Message{.action = action, .wparam = wparam, .lparam = lparam};
      current_session_.push_back(message);

      std::u16string text;
      char32_t code_point;
      if (message.IsHighSurrogate()) {
        // A high surrogate is always followed by a low surrogate.  Process the
        // session later and consider this message as handled.
        return true;
      } else if (message.IsLowSurrogate()) {
        const Win32Message* last_message =
            current_session_.size() <= 1
                ? nullptr
                : &current_session_[current_session_.size() - 2];
        if (last_message == nullptr || !last_message->IsHighSurrogate()) {
          return false;
        }
        // A low surrogate always follows a high surrogate, marking the end of
        // a char session. Process the session after the if clause.
        text.push_back(static_cast<wchar_t>(last_message->wparam));
        text.push_back(static_cast<wchar_t>(message.wparam));
        code_point =
            CodePointFromSurrogatePair(last_message->wparam, message.wparam);
      } else {
        // A non-surrogate character always appears alone. Process the session
        // after the if clause.
        text.push_back(static_cast<wchar_t>(message.wparam));
        code_point = static_cast<wchar_t>(message.wparam);
      }

      // If this char message is preceded by a key down message, then dispatch
      // the key down message as a key down event first, and only dispatch the
      // OnText if the key down event is not handled.
      if (current_session_.front().IsGeneralKeyDown()) {
        const Win32Message first_message = current_session_.front();
        const uint8_t scancode = (lparam >> 16) & 0xff;
        const uint16_t key_code = first_message.wparam;
        const bool extended = ((lparam >> 24) & 0x01) == 0x01;
        const bool was_down = lparam & 0x40000000;
        // Certain key combinations yield control characters as WM_CHAR's
        // lParam. For example, 0x01 for Ctrl-A. Filter these characters. See
        // https://docs.microsoft.com/en-us/windows/win32/learnwin32/accelerator-tables
        char32_t character;
        if (action == WM_DEADCHAR || action == WM_SYSDEADCHAR) {
          // Mask the resulting char with kDeadKeyCharMask anyway, because in
          // rare cases the bit is *not* set (US INTL Shift-6 circumflex, see
          // https://github.com/flutter/flutter/issues/92654 .)
          character =
              window_delegate_->Win32MapVkToChar(key_code) | kDeadKeyCharMask;
        } else {
          character = IsPrintable(code_point) ? code_point : 0;
        }
        auto event = std::make_unique<PendingEvent>(PendingEvent{
            .key = key_code,
            .scancode = scancode,
            .action = static_cast<UINT>(action == WM_SYSCHAR ? WM_SYSKEYDOWN
                                                             : WM_KEYDOWN),
            .character = character,
            .extended = extended,
            .was_down = was_down,
            .session = std::move(current_session_),
        });
        // Compute the text that might be dispatched later.
        //
        // Of the messages handled here, only WM_CHAR should be treated as
        // characters. WM_SYS*CHAR are not part of text input, and WM_DEADCHAR
        // will be incorporated into a later WM_CHAR with the full character.
        //
        // Checking `character` filters out non-printable event characters.
        std::list<PendingText>::iterator pending_text;
        if (action == WM_CHAR) {
          bool valid = character != 0 && IsPrintable(wparam);
          pending_texts_.push_back(PendingText{
              .ready = false,
              .content = text,
              .placeholder = !valid,
          });
          pending_text = std::prev(pending_texts_.end());
        } else {
          pending_text = pending_texts_.end();
        }
        // SYS messages must not be handled by `HandleMessage` or be
        // redispatched.
        const bool is_syskey = action == WM_SYSCHAR || action == WM_SYSDEADCHAR;
        OnKey(std::move(event),
              [this, pending_text, is_syskey](
                  std::unique_ptr<PendingEvent> event, bool handled) {
                bool real_handled = handled || is_syskey;
                HandleOnKeyResult(std::move(event), handled, pending_text);
              });
        return !is_syskey;
      }

      // If the charcter session is not preceded by a key down message, dispatch
      // the OnText immediately.

      // Only WM_CHAR should be treated as characters. WM_SYS*CHAR are not part
      // of text input, and WM_DEADCHAR will be incorporated into a later
      // WM_CHAR with the full character.
      //
      // Also filter out ASCII control characters, which are sent as WM_CHAR
      // events for all control key shortcuts.
      current_session_.clear();
      if (action == WM_CHAR) {
        pending_texts_.push_back(PendingText{
            .ready = true,
            .content = text,
        });
        DispatchReadyTexts();
      }
      return true;
    }

    case WM_KEYDOWN:
    case WM_SYSKEYDOWN:
    case WM_KEYUP:
    case WM_SYSKEYUP: {
      if (wparam == VK_PACKET) {
        return false;
      }
      current_session_.clear();
      current_session_.push_back(
          Win32Message{.action = action, .wparam = wparam, .lparam = lparam});
      const bool is_keydown_message =
          (action == WM_KEYDOWN || action == WM_SYSKEYDOWN);
      // Check if this key produces a character. If so, the key press should
      // be sent with the character produced at WM_CHAR. Store the produced
      // keycode (it's not accessible from WM_CHAR) to be used in WM_CHAR.
      //
      // Messages with Control or Win modifiers down are never considered as
      // character messages. This allows key combinations such as "CTRL + Digit"
      // to properly produce key down events even though `MapVirtualKey` returns
      // a valid character. See https://github.com/flutter/flutter/issues/85587.
      unsigned int character = window_delegate_->Win32MapVkToChar(wparam);
      UINT next_key_message = PeekNextMessageType(WM_KEYFIRST, WM_KEYLAST);
      bool has_wm_char =
          (next_key_message == WM_DEADCHAR ||
           next_key_message == WM_SYSDEADCHAR || next_key_message == WM_CHAR ||
           next_key_message == WM_SYSCHAR);
      if (character > 0 && is_keydown_message && has_wm_char) {
        // This key down message has following char events. Process later,
        // because the character for the OnKey should be decided by the char
        // events. Consider this event as handled.
        return true;
      }

      // Resolve session: A non-char key event.
      const uint8_t scancode = (lparam >> 16) & 0xff;
      const bool extended = ((lparam >> 24) & 0x01) == 0x01;
      // If the key is a modifier, get its side.
      const uint16_t key_code = ResolveKeyCode(wparam, extended, scancode);
      const bool was_down = lparam & 0x40000000;
      auto event = std::make_unique<PendingEvent>(PendingEvent{
          .key = key_code,
          .scancode = scancode,
          .action = action,
          .character = 0,
          .extended = extended,
          .was_down = was_down,
          .session = std::move(current_session_),
      });
      // SYS messages must not be handled by `HandleMessage` or be
      // redispatched.
      const bool is_syskey = action == WM_SYSKEYDOWN || action == WM_SYSKEYUP;
      OnKey(
          std::move(event),
          [this, is_syskey](std::unique_ptr<PendingEvent> event, bool handled) {
            bool real_handled = handled || is_syskey;
            HandleOnKeyResult(std::move(event), handled, pending_texts_.end());
          });
      return !is_syskey;
    }
    default:
      assert(false);
  }
  return false;
}

UINT KeyboardManagerWin32::PeekNextMessageType(UINT wMsgFilterMin,
                                               UINT wMsgFilterMax) {
  MSG next_message;
  BOOL has_msg = window_delegate_->Win32PeekMessage(
      &next_message, wMsgFilterMin, wMsgFilterMax, PM_NOREMOVE);
  if (!has_msg) {
    return 0;
  }
  return next_message.message;
}

}  // namespace flutter
