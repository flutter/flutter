// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_GAME_PAD_CURSOR_WINUWP_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_GAME_PAD_CURSOR_WINUWP_H_

#include <DispatcherQueue.h>
#include <third_party/cppwinrt/generated/winrt/Windows.Foundation.Collections.h>
#include <third_party/cppwinrt/generated/winrt/Windows.Graphics.Display.h>
#include <third_party/cppwinrt/generated/winrt/Windows.System.Profile.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.Composition.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.Core.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.ViewManagement.Core.h>
#include "third_party/cppwinrt/generated/winrt/Windows.System.Threading.h"

#include "flutter/shell/platform/windows/display_helper_winuwp.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/game_pad_winuwp.h"

namespace flutter {

// A class abstraction for a mouse cursor driven by a gamepad.  This abstraction
// is primarily intended for devices like XBOX that do not have traditional
// mouse input.
class GamepadCursorWinUWP {
 public:
  GamepadCursorWinUWP(
      WindowBindingHandlerDelegate* view,
      DisplayHelperWinUWP* displayhelper,
      winrt::Windows::UI::Core::CoreWindow const& window,
      winrt::Windows::UI::Composition::Compositor const& compositor,
      winrt::Windows::UI::Composition::VisualCollection const& rootcollection);

 private:
  // Pointer to a DisplayHelperWinUWP object used to get window bounds, DPI and
  // other display-related aspects.
  DisplayHelperWinUWP* display_helper_;

  // Current active compositor. nullptr if not set.
  winrt::Windows::UI::Composition::Compositor compositor_{nullptr};

  // Window that is hosting this emulated cursor.
  winrt::Windows::UI::Core::CoreWindow window_{nullptr};

  // The root of the composition tree that this class will add a cursor visual
  // to.
  winrt::Windows::UI::Composition::VisualCollection root_collection_{nullptr};

  // Called when the user is interacting with the GamePad and moving the mouse
  // cursor.  Prevents the mouse cursor from being hidden by resetting the
  // inactivity timer.
  void SetCursorTimeout();

  // Sets the frequency, in milliseconds, that the gamepad is polled for
  // movement updates.
  void SetMouseMovePollingFrequency(int ms);

  // Notifies current |WindowBindingHandlerDelegate| of gamepad right stick
  // events as emulated mouse move events.
  void OnGamepadLeftStickMoved(double x, double y);

  // Notifies current |WindowBindingHandlerDelegate| of gamepad right stick
  // events delivered as scroll events.
  void OnGamepadRightStickMoved(double x, double y);

  // Notifies current |WindowBindingHandlerDelegate| of left gamepad move events
  // delivered as emulated mouse button events.
  void OnGamepadButtonPressed(
      winrt::Windows::Gaming::Input::GamepadButtons buttons);

  // Notifies current |WindowBindingHandlerDelegate| of left gamepad move events
  // delivered as emulated mouse button events.
  void OnGamepadButtonReleased(
      winrt::Windows::Gaming::Input::GamepadButtons buttons);

  // Show and hide the emulated mouse cursor when a gamepad arrives / departs
  void OnGamepadControllersChanged();

  // Creates a visual representing the emulated cursor and add to the visual
  // tree.
  winrt::Windows::UI::Composition::Visual CreateCursorVisual();

  // Starts a timer used to update the position of the cursor visual as the
  // gamepad updates the position.
  void StartGamepadTimer();

  // Stops time used to move the cursor.
  void StopGamepadTimer();

  // Configure callbacks to notify when Gamepad hardware events are received.
  void ConfigureGamepad();

  winrt::Windows::Foundation::Numerics::float3 GetScaledInput(
      const winrt::Windows::Foundation::Numerics::float3 input);

  // Object responsible for handling the low level interactions with the
  // gamepad.
  std::unique_ptr<GamepadWinUWP> game_pad_{nullptr};

  // Pointer to a FlutterWindowsView that can be
  // used to update engine windowing and input state.
  WindowBindingHandlerDelegate* binding_handler_delegate_;

  // Multiplier used to map controller velocity to an appropriate scroll input.
  static constexpr double kControllerScrollMultiplier = 3;

  // Multiplier used to scale gamepad input to mouse equivalent response.
  static constexpr int kCursorScale = 7;

  // Number of inactive seconds after which emulated cursor is hidden (ms).
  static constexpr int kInactivePeriod = 5;

  // Frequency to poll for input when no active interaction (ms).
  static constexpr int kReducedPollingFrequency = 250;

  // Frequency to poll for input when user is interacting (ms).
  static constexpr int kNormalPollingFrequency = 10;

  // Scancode definitions for dpad to cursor mapping.
  static constexpr int kScanLeft = 75;
  static constexpr int kScanRight = 77;
  static constexpr int kScanUp = 72;
  static constexpr int kScanDown = 80;

  // Timer object used to update the cursor visual.
  winrt::Windows::System::DispatcherQueueTimer cursor_move_timer_{nullptr};

  // Timer object used to hide the mouse cursor when the user isn't interacting
  // with the Gamepad.
  winrt::Windows::System::DispatcherQueueTimer emulated_cursor_hide_timer_{
      nullptr};

  // Composition visual representing the emulated
  // cursor visual.
  winrt::Windows::UI::Composition::Visual cursor_visual_{nullptr};
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_GAME_PAD_CURSOR_WINUWP_H_
