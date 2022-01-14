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

// Returns if a character sent by Win32 is a dead key.
static bool _IsDeadKey(uint32_t ch) {
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

void KeyboardManagerWin32::DispatchEvent(const PendingEvent& event) {
  assert(event.action != WM_SYSKEYDOWN && event.action != WM_SYSKEYUP &&
         "Unexpectedly dispatching a SYS event. SYS events can't be dispatched "
         "and should have been prevented in earlier code.");

  char32_t character = event.character;

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

  UINT accepted = window_delegate_->Win32DispatchEvent(1, &input_event,
                                                       sizeof(input_event));
  if (accepted != 1) {
    std::cerr << "Unable to synthesize event for keyboard event with scancode "
              << event.scancode;
    if (character != 0) {
      std::cerr << " (character " << character << ")";
    }
    std::cerr << std::endl;
  }
}

void KeyboardManagerWin32::RedispatchEvent(
    std::unique_ptr<PendingEvent> event) {
  DispatchEvent(*event);
  if (pending_redispatches_.size() > kMaxPendingEvents) {
    std::cerr
        << "There are " << pending_redispatches_.size()
        << " keyboard events that have not yet received a response from the "
        << "framework. Are responses being sent?" << std::endl;
  }
  pending_redispatches_.push_back(std::move(event));
}

bool KeyboardManagerWin32::RemoveRedispatchedEvent(
    const PendingEvent& incoming) {
  for (auto iter = pending_redispatches_.begin();
       iter != pending_redispatches_.end(); ++iter) {
    if ((*iter)->hash == incoming.hash) {
      pending_redispatches_.erase(iter);
      return true;
    }
  }
  return false;
}

bool KeyboardManagerWin32::OnKey(int key,
                                 int scancode,
                                 int action,
                                 char32_t character,
                                 bool extended,
                                 bool was_down,
                                 OnKeyCallback callback) {
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

  window_delegate_->OnKey(key, scancode, action, character, extended, was_down,
                          [this, event = incoming.release(),
                           callback = std::move(callback)](bool handled) {
                            callback(std::unique_ptr<PendingEvent>(event),
                                     handled);
                          });
  return true;
}

void KeyboardManagerWin32::HandleOnKeyResult(
    std::unique_ptr<PendingEvent> event,
    bool handled,
    int char_action,
    std::u16string text) {
  // First, patch |handled|, because some key events must always be treated as
  // handled.
  //
  // Redispatching dead keys events makes Win32 ignore the dead key state
  // and redispatches a normal character without combining it with the
  // next letter key.
  //
  // Redispatching sys events is impossible due to the limitation of
  // |SendInput|.
  const bool is_syskey =
      event->action == WM_SYSKEYDOWN || event->action == WM_SYSKEYUP;
  const bool real_handled = handled || _IsDeadKey(event->character) ||
                            is_syskey ||
                            IsKeyDownShiftRight(event->key, event->was_down);

  // For handled events, that's all.
  if (real_handled) {
    return;
  }

  // For unhandled events, dispatch them to OnText.

  // Of the messages handled here, only WM_CHAR should be treated as
  // characters. WM_SYS*CHAR are not part of text input, and WM_DEADCHAR
  // will be incorporated into a later WM_CHAR with the full character.
  // Non-printable event characters have been filtered out before being passed
  // to OnKey.
  if (char_action == WM_CHAR && event->character != 0) {
    window_delegate_->OnText(text);
  }

  RedispatchEvent(std::move(event));
}

bool KeyboardManagerWin32::HandleMessage(UINT const message,
                                         WPARAM const wparam,
                                         LPARAM const lparam) {
  switch (message) {
    case WM_DEADCHAR:
    case WM_SYSDEADCHAR:
    case WM_CHAR:
    case WM_SYSCHAR: {
      static wchar_t s_pending_high_surrogate = 0;

      wchar_t character = static_cast<wchar_t>(wparam);
      std::u16string text;
      char32_t code_point;
      if (IS_HIGH_SURROGATE(character)) {
        // Save to send later with the trailing surrogate.
        s_pending_high_surrogate = character;
        return true;
      } else if (IS_LOW_SURROGATE(character) && s_pending_high_surrogate != 0) {
        text.push_back(s_pending_high_surrogate);
        text.push_back(character);
        // Merge the surrogate pairs for the key event.
        code_point =
            CodePointFromSurrogatePair(s_pending_high_surrogate, character);
        s_pending_high_surrogate = 0;
      } else {
        text.push_back(character);
        code_point = character;
      }

      const unsigned int scancode = (lparam >> 16) & 0xff;

      // All key presses that generate a character should be sent from
      // WM_CHAR. In order to send the full key press information, the keycode
      // is persisted in keycode_for_char_message_ obtained from WM_KEYDOWN.
      //
      // A high surrogate is always followed by a low surrogate, while a
      // non-surrogate character always appears alone. Filter out high
      // surrogates so that it's the low surrogate message that triggers
      // the onKey, asks if the framework handles it (which can only be done
      // once), and calls OnText during the redispatched messages.
      if (keycode_for_char_message_ != 0 && !IS_HIGH_SURROGATE(character)) {
        const bool extended = ((lparam >> 24) & 0x01) == 0x01;
        const bool was_down = lparam & 0x40000000;
        // Certain key combinations yield control characters as WM_CHAR's
        // lParam. For example, 0x01 for Ctrl-A. Filter these characters. See
        // https://docs.microsoft.com/en-us/windows/win32/learnwin32/accelerator-tables
        char32_t event_character;
        if (message == WM_DEADCHAR || message == WM_SYSDEADCHAR) {
          // Mask the resulting char with kDeadKeyCharMask anyway, because in
          // rare cases the bit is *not* set (US INTL Shift-6 circumflex, see
          // https://github.com/flutter/flutter/issues/92654 .)
          event_character =
              window_delegate_->Win32MapVkToChar(keycode_for_char_message_) |
              kDeadKeyCharMask;
        } else {
          event_character = IsPrintable(code_point) ? code_point : 0;
        }
        bool is_new_event =
            OnKey(keycode_for_char_message_, scancode,
                  message == WM_SYSCHAR ? WM_SYSKEYDOWN : WM_KEYDOWN,
                  event_character, extended, was_down,
                  [this, message, text](std::unique_ptr<PendingEvent> event,
                                        bool handled) {
                    HandleOnKeyResult(std::move(event), handled, message, text);
                  });
        if (!is_new_event) {
          break;
        }
        keycode_for_char_message_ = 0;

        // For system characters, always pass them to the default WndProc so
        // that system keys like the ALT-TAB are processed correctly.
        if (message == WM_SYSCHAR) {
          break;
        }
        return true;
      }

      // Of the messages handled here, only WM_CHAR should be treated as
      // characters. WM_SYS*CHAR are not part of text input, and WM_DEADCHAR
      // will be incorporated into a later WM_CHAR with the full character.
      // Also filter out:
      // - Lead surrogates, which like dead keys will be send once combined.
      // - ASCII control characters, which are sent as WM_CHAR events for all
      //   control key shortcuts.
      if (message == WM_CHAR && s_pending_high_surrogate == 0 &&
          IsPrintable(character)) {
        window_delegate_->OnText(text);
      }
      return true;
    }

    case WM_KEYDOWN:
    case WM_SYSKEYDOWN:
    case WM_KEYUP:
    case WM_SYSKEYUP: {
      const bool is_keydown_message =
          (message == WM_KEYDOWN || message == WM_SYSKEYDOWN);
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
        keycode_for_char_message_ = wparam;
        return true;
      }
      unsigned int keyCode(wparam);
      const uint8_t scancode = (lparam >> 16) & 0xff;
      const bool extended = ((lparam >> 24) & 0x01) == 0x01;
      // If the key is a modifier, get its side.
      keyCode = ResolveKeyCode(keyCode, extended, scancode);
      const bool was_down = lparam & 0x40000000;
      bool is_syskey = message == WM_SYSKEYDOWN || message == WM_SYSKEYUP;
      bool is_new_event = OnKey(
          keyCode, scancode, message, 0, extended, was_down,
          [this](std::unique_ptr<PendingEvent> event, bool handled) {
            HandleOnKeyResult(std::move(event), handled, 0, std::u16string());
          });
      if (!is_new_event) {
        break;
      }
      // For system keys, always pass them to the default WndProc so that keys
      // like the ALT-TAB or Kanji switches are processed correctly.
      if (is_syskey) {
        break;
      }
      return true;
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

uint64_t KeyboardManagerWin32::ComputeEventHash(const PendingEvent& event) {
  // Calculate a key event ID based on the scan code of the key pressed,
  // and the flags we care about.
  return event.scancode | (((event.action == WM_KEYUP ? KEYEVENTF_KEYUP : 0x0) |
                            (event.extended ? KEYEVENTF_EXTENDEDKEY : 0x0))
                           << 16);
}

}  // namespace flutter
