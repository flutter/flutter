// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_MANAGER_H_

#include <windows.h>
#include <map>

namespace flutter {

// Handles keyboard and text messages on Win32.
//
// |KeyboardManagerWin32| consumes raw Win32 messages related to key and chars,
// and converts them to |OnKey| or |OnText| calls suitable for
// |KeyboardKeyHandler|.
//
// |KeyboardManagerWin32| requires a |WindowDelegate| to define how to
// access Win32 system calls (to allow mocking) and where to send the results
// of |OnKey| and |OnText| to.
//
// Typically, |KeyboardManagerWin32| is owned by a |WindowWin32|, which also
// implements the window delegate. The |OnKey| and |OnText| results are
// passed to those of |WindowWin32|'s, and consequently, those of
// |FlutterWindowsView|'s.
class KeyboardManagerWin32 {
 public:
  // Define how the keyboard manager accesses Win32 system calls (to allow
  // mocking) and sends the results of |OnKey| and |OnText|.
  //
  // Typically implemented by |WindowWin32|.
  class WindowDelegate {
   public:
    virtual ~WindowDelegate() = default;

    // Called when text input occurs.
    virtual void OnText(const std::u16string& text) = 0;

    // Called when raw keyboard input occurs.
    //
    // Returns true if the event was handled, indicating that DefWindowProc
    // should not be called on the event by the main message loop.
    virtual bool OnKey(int key,
                       int scancode,
                       int action,
                       char32_t character,
                       bool extended,
                       bool was_down) = 0;

    // Win32's PeekMessage.
    //
    // Used to process key messages.
    virtual BOOL Win32PeekMessage(LPMSG lpMsg,
                                  UINT wMsgFilterMin,
                                  UINT wMsgFilterMax,
                                  UINT wRemoveMsg) = 0;

    // Win32's MapVirtualKey(*, MAPVK_VK_TO_CHAR).
    //
    // Used to process key messages.
    virtual uint32_t Win32MapVkToChar(uint32_t virtual_key) = 0;
  };

  KeyboardManagerWin32(WindowDelegate* delegate);

  // Processes Win32 messages related to keyboard and text.
  //
  // All messages related to keyboard and text should be sent here without
  // pre-processing, including WM_{SYS,}KEY{DOWN,UP} and WM_{SYS,}{DEAD,}CHAR.
  // Other message types will trigger assertion error.
  //
  // |HandleMessage| returns true if Flutter keyboard system decides to handle
  // this message synchronously. It doesn't mean that the Flutter framework
  // handles it, which is reported asynchronously later. Not handling this
  // message here usually means that this message is a redispatched message,
  // but there are other rare cases too. |WindowWin32| should forward unhandled
  // messages to |DefWindowProc|.
  bool HandleMessage(UINT const message,
                     WPARAM const wparam,
                     LPARAM const lparam);

 private:
  // Returns the type of the next WM message.
  //
  // The parameters limits the range of interested messages. See Win32's
  // |PeekMessage| for information.
  //
  // If there's no message, returns 0.
  UINT PeekNextMessageType(UINT wMsgFilterMin, UINT wMsgFilterMax);

  WindowDelegate* window_delegate_;

  // Keeps track of the last key code produced by a WM_KEYDOWN or WM_SYSKEYDOWN
  // message.
  int keycode_for_char_message_ = 0;

  std::map<uint16_t, std::u16string> text_for_scancode_on_redispatch_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_MANAGER_H_
