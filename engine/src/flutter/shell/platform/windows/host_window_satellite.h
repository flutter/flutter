// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_SATELLITE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_SATELLITE_H_

#include <cstdint>
#include <optional>

#include "flutter/shell/platform/windows/host_window_sized.h"
#include "flutter/shell/platform/windows/window_manager.h"

namespace flutter {

// A satellite window is an auxiliary top-level window that is owned by, and
// follows the movement of, another window.
//
// Unlike a tooltip or a popup, a satellite is decorated and activatable. Its
// position callback runs only once, for the initial placement, after the first
// frame has been rendered and before the window is shown; afterwards the
// satellite keeps whatever offset it has from its parent, moving by the same
// delta whenever the parent moves. A satellite cannot be minimized on its own,
// and may be reparented at runtime without changing its screen position.
class HostWindowSatellite : public HostWindowSized {
 public:
  // Creates a satellite window anchored to |parent|.
  HostWindowSatellite(WindowManager* window_manager,
                      FlutterWindowsEngine* engine,
                      const WindowSizeRequest& preferred_size,
                      const BoxConstraints& constraints,
                      GetWindowPositionCallback get_position_callback,
                      HWND parent,
                      LPCWSTR title,
                      bool sized_to_content,
                      bool resizable);

  ~HostWindowSatellite() override;

  // Called by the window this satellite is anchored to when it has moved.
  // Shifts the satellite by the same delta so it retains its relative offset.
  void OnParentMoved();

  // Changes the window that this satellite is anchored to. The satellite keeps
  // its current screen position; only future movement deltas are computed
  // against |new_parent|.
  void SetSatelliteParent(HWND new_parent);

 protected:
  LRESULT HandleMessage(HWND hwnd,
                        UINT message,
                        WPARAM wparam,
                        LPARAM lparam) override;

  // HostWindow:
  //
  // Runs the initial placement, unless it has already run, before the window
  // is shown for the first time.
  void OnFirstFrame() override;

  // HostWindowSized:
  void ApplyContentSize(int32_t physical_width,
                        int32_t physical_height) override;

 private:
  // Returns the window style used for a satellite window. Satellites are
  // decorated and activatable, but never minimizable.
  static DWORD GetWindowStyleForSatellite(bool resizable);

  // Returns the rectangle the satellite window is created with.
  //
  // The size is derived from |preferred_size| (or, when |sized_to_content| is
  // true, from the smallest size allowed by |constraints|). The origin is left
  // at CW_USEDEFAULT: the satellite is placed by the positioner once its
  // content has been rendered, while the window is still hidden.
  static Rect GetInitialRect(FlutterWindowsEngine* engine,
                             const WindowSizeRequest& preferred_size,
                             const BoxConstraints& constraints,
                             HWND parent,
                             bool sized_to_content,
                             bool resizable);

  // FlutterWindowsViewSizingDelegate:
  //
  // Overridden to report the work area of the monitor that the parent window
  // is on. Until the initial placement runs, the satellite itself may not yet
  // be on the monitor it will end up on.
  WindowRect GetWorkArea() const override;

  // Invokes |get_position_callback_| with the satellite's current frame size
  // and moves the window to the returned rectangle. Does nothing after the
  // first successful call.
  void ApplyInitialPosition();

  // Computes the placement rectangle for a satellite of |window_size| anchored
  // to |parent_|, by invoking |get_position_callback_| in |isolate_|. Returns
  // std::nullopt if |get_position_callback_| is null.
  std::optional<WindowRect> ComputePosition(
      const WindowSize& window_size) const;

  GetWindowPositionCallback get_position_callback_;

  // The window this satellite is anchored to.
  HWND parent_;

  Isolate isolate_;

  // The last observed top-left corner of the parent window, in screen
  // coordinates. Used to compute movement deltas.
  POINT last_parent_pos_ = {0, 0};

  // Whether the one-shot initial placement has already run.
  bool initial_position_applied_ = false;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_SATELLITE_H_
