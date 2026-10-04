// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_DIALOG_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_DIALOG_H_

#include <optional>

#include "host_window_sized.h"

namespace flutter {
class HostWindowDialog : public HostWindowSized {
 public:
  // Creates a dialog window.
  //
  // If |owner_window| is not null, the dialog will be modal to the owner.
  // This also affects the dialog window's styling.
  //
  // If |sized_to_content| is true, the window is initially sized to the
  // minimum of |constraints| and will automatically resize to its rendered
  // content after each frame. If |resizable| is false, the window will
  // continue to track content size and its resize border is removed.
  // If |resizable| is true, the user may resize the window after the initial
  // content-based sizing.
  //
  // If |sized_to_content| is false, the window is created with the size
  // specified in |preferred_size|.
  HostWindowDialog(WindowManager* window_manager,
                   FlutterWindowsEngine* engine,
                   const WindowSizeRequest& preferred_size,
                   const BoxConstraints& constraints,
                   LPCWSTR title,
                   std::optional<HWND> const& owner_window,
                   bool sized_to_content,
                   bool resizable);

  ~HostWindowDialog() override;

  void SetFullscreen(bool fullscreen,
                     std::optional<FlutterEngineDisplayId> display_id) override;
  bool GetFullscreen() const override;

 protected:
  LRESULT HandleMessage(HWND hwnd,
                        UINT message,
                        WPARAM wparam,
                        LPARAM lparam) override;

 private:
  // Enforces modal behavior. This favors enabling most recently created
  // modal window higest up in the window hierarchy.
  void UpdateModalState();

  static DWORD GetWindowStyleForDialog(std::optional<HWND> const& owner_window,
                                       bool resizable);
  static DWORD GetExtendedWindowStyleForDialog(
      std::optional<HWND> const& owner_window);
  static Rect GetInitialRect(FlutterWindowsEngine* engine,
                             const WindowSizeRequest& preferred_size,
                             const BoxConstraints& constraints,
                             std::optional<HWND> const& owner_window,
                             bool sized_to_content,
                             bool resizable);
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_DIALOG_H_
