// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_MANAGER_H_

#include <windows.h>
#include <deque>
#include <functional>
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
    using KeyEventCallback = std::function<void(bool)>;

    virtual ~WindowDelegate() = default;

    // Called when text input occurs.
    virtual void OnText(const std::u16string& text) = 0;

    // Called when raw keyboard input occurs.
    virtual void OnKey(int key,
                       int scancode,
                       int action,
                       char32_t character,
                       bool extended,
                       bool was_down,
                       KeyEventCallback callback) = 0;

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

    // Win32's |SendInput|.
    //
    // Used to synthesize key events.
    virtual UINT Win32DispatchEvent(UINT cInputs,
                                    LPINPUT pInputs,
                                    int cbSize) = 0;
  };

  using KeyEventCallback = WindowDelegate::KeyEventCallback;

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
  struct PendingEvent {
    uint32_t key;
    uint8_t scancode;
    uint32_t action;
    char32_t character;
    bool extended;
    bool was_down;

    // A value calculated out of critical event information that can be used
    // to identify redispatched events.
    uint64_t hash;
  };

  using OnKeyCallback =
      std::function<void(std::unique_ptr<PendingEvent>, bool)>;

  // Returns true if it's a new event, or false if it's a redispatched event.
  bool OnKey(int key,
             int scancode,
             int action,
             char32_t character,
             bool extended,
             bool was_down,
             OnKeyCallback callback);

  void HandleOnKeyResult(std::unique_ptr<PendingEvent> event,
                         bool handled,
                         int char_action,
                         std::u16string text);

  // Returns the type of the next WM message.
  //
  // The parameters limits the range of interested messages. See Win32's
  // |PeekMessage| for information.
  //
  // If there's no message, returns 0.
  UINT PeekNextMessageType(UINT wMsgFilterMin, UINT wMsgFilterMax);

  void DispatchEvent(const PendingEvent& event);

  // Find an event in the redispatch list that matches the given one.
  //
  // If an matching event is found, removes the matching event from the
  // redispatch list, and returns true. Otherwise, returns false;
  bool RemoveRedispatchedEvent(const PendingEvent& incoming);
  void RedispatchEvent(std::unique_ptr<PendingEvent> event);

  WindowDelegate* window_delegate_;

  // Keeps track of the last key code produced by a WM_KEYDOWN or WM_SYSKEYDOWN
  // message.
  int keycode_for_char_message_ = 0;

  std::map<uint16_t, std::u16string> text_for_scancode_on_redispatch_;

  // Whether the last event is a CtrlLeft key down.
  //
  // This is used to resolve a corner case described in |IsKeyDownAltRight|.
  bool last_key_is_ctrl_left_down;

  // The scancode of the last met CtrlLeft down.
  //
  // This is used to resolve a corner case described in |IsKeyDownAltRight|.
  uint8_t ctrl_left_scancode;

  // Whether a CtrlLeft up should be synthesized upon the next AltRight up.
  //
  // This is used to resolve a corner case described in |IsKeyDownAltRight|.
  bool should_synthesize_ctrl_left_up;

  // The queue of key events that have been redispatched to the system but have
  // not yet been received for a second time.
  std::deque<std::unique_ptr<PendingEvent>> pending_redispatches_;

  // Calculate a hash based on event data for fast comparison for a redispatched
  // event.
  //
  // This uses event data instead of generating a serial number because
  // information can't be attached to the redispatched events, so it has to be
  // possible to compute an ID from the identifying data in the event when it is
  // received again in order to differentiate between events that are new, and
  // events that have been redispatched.
  //
  // Another alternative would be to compute a checksum from all the data in the
  // event (just compute it over the bytes in the struct, probably skipping
  // timestamps), but the fields used are enough to differentiate them, and
  // since Windows does some processing on the events (coming up with virtual
  // key codes, setting timestamps, etc.), it's not clear that the redispatched
  // events would have the same checksums.
  static uint64_t ComputeEventHash(const PendingEvent& event);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_MANAGER_H_
