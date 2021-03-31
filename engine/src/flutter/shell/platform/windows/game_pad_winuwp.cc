// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/game_pad_winuwp.h"

namespace flutter {

GamepadWinUWP::GamepadWinUWP(GamepadDualAxisCallback leftstick,
                             GamepadDualAxisCallback rightstick,
                             GamepadSingleAxisCallback lefttrigger,
                             GamepadSingleAxisCallback righttrigger,
                             GamepadButtonCallback pressedcb,
                             GamepadButtonCallback releasedcb,
                             GamepadAddedRemovedCallback changedcb)
    : pressed_buttons_(winrt::Windows::Gaming::Input::GamepadButtons::None),
      left_stick_x_value_(0),
      left_stick_y_value_(0),
      right_stick_x_value_(0),
      right_stick_y_value_(0),
      left_trigger_value_(0),
      right_trigger_value_(0) {
  left_stick_callback_ = leftstick;
  right_stick_callback_ = rightstick;

  left_trigger_callback_ = lefttrigger;
  right_trigger_callback_ = righttrigger;

  button_pressed_callback_ = pressedcb;
  button_released_callback_ = releasedcb;

  arrival_departure_callback_ = changedcb;
}

void GamepadWinUWP::Initialize() {
  RefreshCachedGamepads();

  winrt::Windows::Gaming::Input::Gamepad::GamepadAdded(
      {this, &GamepadWinUWP::OnGamepadAdded});
  winrt::Windows::Gaming::Input::Gamepad::GamepadRemoved(
      {this, &GamepadWinUWP::OnGamepadRemoved});

  const std::lock_guard<std::mutex> lock(gamepad_mutex_);
  current_game_pad_ = GetLastGamepad();
}

bool GamepadWinUWP::HasController() const {
  const std::lock_guard<std::mutex> lock(gamepad_mutex_);
  return current_game_pad_ != nullptr;
}

void GamepadWinUWP::OnGamepadAdded(
    winrt::Windows::Foundation::IInspectable const& th,
    winrt::Windows::Gaming::Input::Gamepad const& args) {
  enumerated_game_pads_.push_back(args);

  {
    const std::lock_guard<std::mutex> lock(gamepad_mutex_);
    auto most_recent = GetLastGamepad();
    if (current_game_pad_ != most_recent) {
      current_game_pad_ = most_recent;
    }
  }

  if (this->arrival_departure_callback_ != nullptr) {
    arrival_departure_callback_();
  }
}

void GamepadWinUWP::OnGamepadRemoved(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::Gaming::Input::Gamepad const& /*args*/) {
  RefreshCachedGamepads();
}

void GamepadWinUWP::RefreshCachedGamepads() {
  enumerated_game_pads_.clear();
  auto gamepads = winrt::Windows::Gaming::Input::Gamepad::Gamepads();
  for (auto gamepad : gamepads) {
    enumerated_game_pads_.push_back(gamepad);
  }
}

const winrt::Windows::Gaming::Input::Gamepad* GamepadWinUWP::GetLastGamepad()
    const {
  const winrt::Windows::Gaming::Input::Gamepad* gamepad = nullptr;

  if (!enumerated_game_pads_.empty()) {
    gamepad = &enumerated_game_pads_.back();
  }

  return gamepad;
}

static bool IsValid(double value) {
  return value > 0.1 || value < -0.1;
}

void GamepadWinUWP::Process() {
  {
    const std::lock_guard<std::mutex> lock(gamepad_mutex_);

    if (current_game_pad_ == nullptr) {
      return;
    }

    last_reading_ = current_game_pad_->GetCurrentReading();
  }

  namespace gi = winrt::Windows::Gaming::Input;

  GamepadButtonPressedInternal(last_reading_.Buttons);

  // work out which values have changed since the last reading.
  if (last_reading_.LeftThumbstickX != left_stick_x_value_) {
    left_stick_x_value_ = last_reading_.LeftThumbstickX;
  }

  if (last_reading_.LeftThumbstickY != left_stick_y_value_) {
    left_stick_y_value_ = last_reading_.LeftThumbstickY;
  }

  if (IsValid(left_stick_x_value_) || IsValid(left_stick_y_value_)) {
    RaiseLeftStickMoved(left_stick_x_value_, left_stick_y_value_);
  }

  if (last_reading_.RightThumbstickX != right_stick_x_value_) {
    right_stick_x_value_ = last_reading_.RightThumbstickX;
  }

  if (last_reading_.RightThumbstickY != right_stick_y_value_) {
    right_stick_y_value_ = last_reading_.RightThumbstickY;
  }

  if (IsValid(right_stick_x_value_) || IsValid(right_stick_y_value_)) {
    RaiseRightStickMoved(right_stick_x_value_, right_stick_y_value_);
  }

  // Raise the requisit events based on what's changed since the last reading
  // was taken.
  if (last_reading_.LeftTrigger != 0 &&
      last_reading_.LeftTrigger != left_trigger_value_) {
    left_trigger_value_ = last_reading_.LeftTrigger;
    RaiseLeftTriggerMoved(left_trigger_value_);
  }

  if (last_reading_.RightTrigger != 0 &&
      last_reading_.RightTrigger != right_trigger_value_) {
    right_trigger_value_ = last_reading_.RightTrigger;
    RaiseRightTriggerMoved(right_trigger_value_);
  }
}

void GamepadWinUWP::GamepadButtonPressedInternal(
    winrt::Windows::Gaming::Input::GamepadButtons state) {
  namespace wgi = winrt::Windows::Gaming::Input;

  static const wgi::GamepadButtons AllButtons[] = {
      wgi::GamepadButtons::A,         wgi::GamepadButtons::B,
      wgi::GamepadButtons::DPadDown,  wgi::GamepadButtons::DPadLeft,
      wgi::GamepadButtons::DPadRight, wgi::GamepadButtons::DPadUp};

  for (const auto e : AllButtons) {
    // if button is pressed we have not sent a pressed already
    if (((e & state) == e) && ((pressed_buttons_ & e) != e)) {
      // send pressed callback
      if (button_pressed_callback_ != nullptr) {
        button_pressed_callback_(e);
      }

      // set the bit
      pressed_buttons_ |= e;
    }

    // if button is not pressed and we have sent a pressed already
    if (((e & state) != e) && ((pressed_buttons_ & e) == e)) {
      // send callback
      if (button_released_callback_ != nullptr) {
        button_released_callback_(e);
      }

      // set the pressed bit
      pressed_buttons_ &= ~e;
    }
  }
}

void GamepadWinUWP::RaiseGameGamepadButtonPressed(
    winrt::Windows::Gaming::Input::GamepadButtons b) {}

void GamepadWinUWP::RaiseGameGamepadButtonReleased(
    winrt::Windows::Gaming::Input::GamepadButtons b) {}

void GamepadWinUWP::RaiseLeftStickMoved(double x, double y) {
  if (left_stick_callback_ != nullptr) {
    left_stick_callback_(x, y);
  }
}

void GamepadWinUWP::RaiseRightStickMoved(double x, double y) {
  if (right_stick_callback_ != nullptr) {
    right_stick_callback_(x, y);
  }
}

void GamepadWinUWP::RaiseLeftTriggerMoved(double value) {
  if (left_trigger_callback_ != nullptr) {
    left_trigger_callback_(value);
  }
}

void GamepadWinUWP::RaiseRightTriggerMoved(double value) {
  if (right_trigger_callback_ != nullptr) {
    right_trigger_callback_(value);
  }
}

}  // namespace flutter
