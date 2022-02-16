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
//
// ## Terminology
//
// The keyboard system follows the following terminology instead of the
// inconsistent/incomplete one used by Win32:
//
//  * Message: An invocation of |WndProc|, which consists of an
//    action, an lparam, and a wparam.
//  * Action: The type of a message.
//  * Session: One to three messages that should be processed together, such
//    as a key down message followed by char messages.
//  * Event: A FlutterKeyEvent/ui.KeyData sent to the framework.
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

    // Win32's |SendMessage|.
    //
    // Used to synthesize key messages.
    virtual UINT Win32DispatchMessage(UINT Msg,
                                      WPARAM wParam,
                                      LPARAM lParam) = 0;
  };

  using KeyEventCallback = WindowDelegate::KeyEventCallback;

  explicit KeyboardManagerWin32(WindowDelegate* delegate);

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

 protected:
  struct Win32Message {
    UINT action;
    WPARAM wparam;
    LPARAM lparam;

    bool IsHighSurrogate() const { return IS_HIGH_SURROGATE(wparam); }

    bool IsLowSurrogate() const { return IS_LOW_SURROGATE(wparam); }

    bool IsGeneralKeyDown() const {
      return action == WM_KEYDOWN || action == WM_SYSKEYDOWN;
    }
  };

  struct PendingEvent {
    WPARAM key;
    uint8_t scancode;
    UINT action;
    char32_t character;
    bool extended;
    bool was_down;

    std::vector<Win32Message> session;
  };

  virtual void RedispatchEvent(std::unique_ptr<PendingEvent> event);

 private:
  using OnKeyCallback =
      std::function<void(std::unique_ptr<PendingEvent>, bool)>;

  struct PendingText {
    bool ready;
    std::u16string content;
    bool placeholder = false;
  };

  // Returns true if it's a new event, or false if it's a redispatched event.
  void OnKey(std::unique_ptr<PendingEvent> event, OnKeyCallback callback);

  // From `pending_texts_`, pop all front elements that are ready, dispatch
  // them to |OnText|, and remove them.
  void DispatchReadyTexts();

  // Handle the result of |OnKey|, which might dispatch the text result to
  // |OnText|.
  //
  // The `pending_text` is either a valid iterator of `pending_texts`, or its
  // end(). In the latter case, this OnKey message does not contain a text.
  void HandleOnKeyResult(std::unique_ptr<PendingEvent> event,
                         bool handled,
                         std::list<PendingText>::iterator pending_text);

  // Returns the type of the next WM message.
  //
  // The parameters limits the range of interested messages. See Win32's
  // |PeekMessage| for information.
  //
  // If there's no message, returns 0.
  UINT PeekNextMessageType(UINT wMsgFilterMin, UINT wMsgFilterMax);

  // Find an event in the redispatch list that matches the given one.
  //
  // If an matching event is found, removes the matching event from the
  // redispatch list, and returns true. Otherwise, returns false;
  bool RemoveRedispatchedMessage(UINT action, WPARAM wparam, LPARAM lparam);

  WindowDelegate* window_delegate_;

  // Keeps track of all messages during the current session.
  //
  // At the end of a session, it is moved to the `PendingEvent`, which is
  // passed to `OnKey`.
  std::vector<Win32Message> current_session_;

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

  // A queue of potential texts derived from char messages.
  //
  // The text might or might not be ready when they're added, and they might
  // become ready or removed later. `DispatchReadyTexts` is used to dispatch all
  // ready texts from the front to `OnText`. This queue is used to ensure
  // they're dispatched in their arrival order.
  std::list<PendingText> pending_texts_;

  // The queue of messages that have been redispatched to the system but have
  // not yet been received for a second time.
  std::deque<Win32Message> pending_redispatches_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_MANAGER_H_
