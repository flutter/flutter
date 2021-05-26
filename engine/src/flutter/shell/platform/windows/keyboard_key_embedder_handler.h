// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_KEY_EMBEDDER_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_KEY_EMBEDDER_HANDLER_H_

#include <functional>
#include <map>
#include <memory>
#include <string>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/keyboard_key_handler.h"

namespace flutter {

namespace {}  // namespace

// A delegate of |KeyboardKeyHandler| that handles events by sending
// converted |FlutterKeyEvent|s through the embedder API.
//
// This class communicates with the HardwareKeyboard API in the framework.
class KeyboardKeyEmbedderHandler
    : public KeyboardKeyHandler::KeyboardKeyHandlerDelegate {
 public:
  using SendEvent = std::function<void(const FlutterKeyEvent& /* event */,
                                       FlutterKeyEventCallback /* callback */,
                                       void* /* user_data */)>;
  using GetKeyStateHandler = std::function<SHORT(int /* nVirtKey */)>;

  // Build a KeyboardKeyEmbedderHandler.
  //
  // Use `send_event` to define how the class should dispatch converted
  // flutter events, as well as how to receive the response, to the engine. It's
  // typically FlutterWindowsEngine::SendKeyEvent. The 2nd and 3rd parameter
  // of the SendEvent call might be nullptr.
  //
  // Use `get_key_state` to define how the class should get a reliable result of
  // the state for a virtual key. It's typically Win32's GetKeyState, but can
  // also be nullptr (for UWP).
  explicit KeyboardKeyEmbedderHandler(SendEvent send_event,
                                      GetKeyStateHandler get_key_state);

  virtual ~KeyboardKeyEmbedderHandler();

  // |KeyboardHandlerBase|
  void KeyboardHook(int key,
                    int scancode,
                    int action,
                    char32_t character,
                    bool extended,
                    bool was_down,
                    std::function<void(bool)> callback) override;

 private:
  struct PendingResponse {
    std::function<void(bool, uint64_t)> callback;
    uint64_t response_id;
  };

  // The information for a virtual key that's important enough that its
  // state is checked after every event.
  struct CriticalKey {
    // Last seen value of physical key and logical key for the virtual key.
    //
    // Used to synthesize down events.
    uint64_t physical_key;
    uint64_t logical_key;

    // Whether to ensure the pressing state of the key (usually for modifier
    // keys).
    bool check_pressed;
    // Whether to ensure the toggled state of the key (usually for lock keys).
    //
    // If this is true, `check_pressed` must be true.
    bool check_toggled;
    // Whether the lock key is currently toggled on.
    bool toggled_on;
  };

  // Assign |critical_keys_| with basic information.
  void InitCriticalKeys();
  // Update |critical_keys_| with last seen logical and physical key.
  void UpdateLastSeenCritialKey(int virtual_key,
                                uint64_t physical_key,
                                uint64_t logical_key);
  // Check each key's state from |get_key_state_| and synthesize events
  // if their toggling states have been desynchronized.
  void SynchronizeCritialToggledStates(int this_virtual_key);
  // Check each key's state from |get_key_state_| and synthesize events
  // if their pressing states have been desynchronized.
  void SynchronizeCritialPressedStates();

  std::function<void(const FlutterKeyEvent&, FlutterKeyEventCallback, void*)>
      sendEvent_;
  GetKeyStateHandler get_key_state_;

  // A map from physical keys to logical keys, each entry indicating a pressed
  // key.
  std::map<uint64_t, uint64_t> pressingRecords_;
  // Information for key events that have been sent to the framework but yet
  // to receive the response. Indexed by response IDs.
  std::map<uint64_t, std::unique_ptr<PendingResponse>> pending_responses_;
  // A self-incrementing integer, used as the ID for the next entry for
  // |pending_responses_|.
  uint64_t response_id_;

  // Important keys whose states are checked and guaranteed synchronized
  // on every key event.
  //
  // The following maps map Win32 virtual key to the physical key and logical
  // key they're last seen.
  std::map<UINT, CriticalKey> critical_keys_;

  static uint64_t getPhysicalKey(int scancode, bool extended);
  static uint64_t getLogicalKey(int key, bool extended, int scancode);
  static void HandleResponse(bool handled, void* user_data);
  static void ConvertUtf32ToUtf8_(char* out, char32_t ch);
  static FlutterKeyEvent SynthesizeSimpleEvent(FlutterKeyEventType type,
                                               uint64_t physical,
                                               uint64_t logical,
                                               const char* character);

  static std::map<uint64_t, uint64_t> windowsToPhysicalMap_;
  static std::map<uint64_t, uint64_t> windowsToLogicalMap_;
  static std::map<uint64_t, uint64_t> scanCodeToLogicalMap_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_KEYBOARD_KEY_EMBEDDER_HANDLER_H_
