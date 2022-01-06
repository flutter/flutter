// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <assert.h>
#include <string>

#include "keyboard_manager_win32.h"

#include "keyboard_win32_common.h"

namespace flutter {

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

KeyboardManagerWin32::KeyboardManagerWin32(WindowDelegate* delegate)
    : window_delegate_(delegate) {}

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
      std::u16string text({character});
      char32_t code_point = character;
      if (IS_HIGH_SURROGATE(character)) {
        // Save to send later with the trailing surrogate.
        s_pending_high_surrogate = character;
      } else if (IS_LOW_SURROGATE(character) && s_pending_high_surrogate != 0) {
        text.insert(text.begin(), s_pending_high_surrogate);
        // Merge the surrogate pairs for the key event.
        code_point =
            CodePointFromSurrogatePair(s_pending_high_surrogate, character);
        s_pending_high_surrogate = 0;
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
        bool handled = window_delegate_->OnKey(
            keycode_for_char_message_, scancode,
            message == WM_SYSCHAR ? WM_SYSKEYDOWN : WM_KEYDOWN, event_character,
            extended, was_down);
        keycode_for_char_message_ = 0;
        if (handled) {
          // If the OnKey handler handles the message, then return so we don't
          // pass it to OnText, because handling the message indicates that
          // OnKey either just sent it to the framework to be processed.
          //
          // This message will be redispatched if not handled by the framework,
          // during which the OnText (below) might be reached. However, if the
          // original message was preceded by dead chars (such as ^ and e
          // yielding ê), then since the redispatched message is no longer
          // preceded by the dead char, the text will be wrong. Therefore we
          // record the text here for the redispached event to use.
          if (message == WM_CHAR) {
            text_for_scancode_on_redispatch_[scancode] = text;
          }

          // For system characters, always pass them to the default WndProc so
          // that system keys like the ALT-TAB are processed correctly.
          if (message == WM_SYSCHAR) {
            break;
          }
          return true;
        }
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
        auto found_text_iter = text_for_scancode_on_redispatch_.find(scancode);
        if (found_text_iter != text_for_scancode_on_redispatch_.end()) {
          text = found_text_iter->second;
          text_for_scancode_on_redispatch_.erase(found_text_iter);
        }
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
      if (window_delegate_->OnKey(keyCode, scancode, message, 0, extended,
                                  was_down)) {
        // For system keys, always pass them to the default WndProc so that keys
        // like the ALT-TAB or Kanji switches are processed correctly.
        if (is_syskey) {
          break;
        }
        return true;
      }
      break;
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
