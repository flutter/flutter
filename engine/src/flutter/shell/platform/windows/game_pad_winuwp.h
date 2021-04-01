// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_GAME_PAD_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_GAME_PAD_H_

#include <third_party/cppwinrt/generated/winrt/Windows.Foundation.Collections.h>
#include <third_party/cppwinrt/generated/winrt/Windows.Gaming.Input.h>

#include <functional>
#include <mutex>
#include <vector>

namespace flutter {

// Type definitions for callback funtions.
using GamepadSingleAxisCallback = std::function<void(double)>;
using GamepadDualAxisCallback = std::function<void(double, double)>;
using GamepadButtonCallback =
    std::function<void(winrt::Windows::Gaming::Input::GamepadButtons)>;
using GamepadAddedRemovedCallback = std::function<void()>;

// A class abstraction for a Gamepad input device.  Used to detect when devices
// come and go and provide event hooks for receiving scalar and discrete inputs
// from buttons and analog control surfaces.
class GamepadWinUWP {
 public:
  GamepadWinUWP(GamepadDualAxisCallback,
                GamepadDualAxisCallback,
                GamepadSingleAxisCallback,
                GamepadSingleAxisCallback,
                GamepadButtonCallback,
                GamepadButtonCallback,
                GamepadAddedRemovedCallback);

  // Enumerate and cache any gamepads that are already connected and hook up
  // handlers to detect arrival and departure of new devices.
  void Initialize();

  // Update state of the currently selected gamepad buttons and controllers if
  // one exists.  Raise resulting events with any attached event consumers. Must
  // be called regularly in order to keep state updated.
  void Process();

  // There is a controller currently attached.
  bool HasController() const;

 private:
  // Returns the last item in the collection of currently attached Gamepads.
  const winrt::Windows::Gaming::Input::Gamepad* GetLastGamepad() const;

  // Handers fired when a Gamepad is attached or removed from the system
  // respectively.
  void OnGamepadAdded(winrt::Windows::Foundation::IInspectable const& sender,
                      winrt::Windows::Gaming::Input::Gamepad const& args);
  void OnGamepadRemoved(winrt::Windows::Foundation::IInspectable const& sender,
                        winrt::Windows::Gaming::Input::Gamepad const& args);

  // Scan for attached Gamepad devices.
  void RefreshCachedGamepads();

  // Internal handler used to intercept raw device button presses.
  void GamepadButtonPressedInternal(
      winrt::Windows::Gaming::Input::GamepadButtons b);

  // Functions to propagate controller events to external consumers.
  void RaiseLeftStickMoved(double x, double y);
  void RaiseRightStickMoved(double x, double y);
  void RaiseLeftTriggerMoved(double value);
  void RaiseRightTriggerMoved(double value);
  void RaiseGameGamepadButtonPressed(
      winrt::Windows::Gaming::Input::GamepadButtons);
  void RaiseGameGamepadButtonReleased(
      winrt::Windows::Gaming::Input::GamepadButtons);

  // Storage for attached Gampads.
  std::vector<winrt::Windows::Gaming::Input::Gamepad> enumerated_game_pads_;

  // Storage for the last hardware state returned from the current controller.
  winrt::Windows::Gaming::Input::GamepadReading last_reading_;

  // Pointer to the current GamePad instance if there is one.
  const winrt::Windows::Gaming::Input::Gamepad* current_game_pad_;

  // Mutex to protect access to current gamepad.
  mutable std::mutex gamepad_mutex_;

  // Storage for most recently communicated trigger and stick values.
  double left_trigger_value_;
  double right_trigger_value_;
  double left_stick_x_value_;
  double left_stick_y_value_;
  double right_stick_x_value_;
  double right_stick_y_value_;

  // Storage for most recently pressed buttons.
  winrt::Windows::Gaming::Input::GamepadButtons pressed_buttons_;

  // Storage for callbacks.
  GamepadDualAxisCallback left_stick_callback_;
  GamepadDualAxisCallback right_stick_callback_;
  GamepadSingleAxisCallback left_trigger_callback_;
  GamepadSingleAxisCallback right_trigger_callback_;
  GamepadButtonCallback button_pressed_callback_;
  GamepadButtonCallback button_released_callback_;
  GamepadAddedRemovedCallback arrival_departure_callback_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_GAME_PAD_H_
