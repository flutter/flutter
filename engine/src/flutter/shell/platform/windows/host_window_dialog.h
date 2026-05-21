// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_DIALOG_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_DIALOG_H_

#include <memory>
#include <optional>

#include "host_window.h"
#include "shell/platform/windows/flutter_windows_view.h"

namespace flutter {
class HostWindowDialog : public HostWindow,
                         private FlutterWindowsViewSizingDelegate {
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

  void SetFullscreen(bool fullscreen,
                     std::optional<FlutterEngineDisplayId> display_id) override;
  bool GetFullscreen() const override;

 protected:
  LRESULT HandleMessage(HWND hwnd,
                        UINT message,
                        WPARAM wparam,
                        LPARAM lparam) override;

 private:
  void DidUpdateViewSize(int32_t width, int32_t height) override;
  WindowRect GetWorkArea() const override;

  // Enforces modal behavior. This favors enabling most recently created
  // modal window higest up in the window hierarchy.
  void UpdateModalState();

  void InitialModalState();

  static DWORD GetWindowStyleForDialog(std::optional<HWND> const& owner_window,
                                       bool resizable);
  static DWORD GetExtendedWindowStyleForDialog(
      std::optional<HWND> const& owner_window);
  static Rect GetInitialRect(FlutterWindowsEngine* engine,
                             const WindowSizeRequest& preferred_size,
                             const BoxConstraints& constraints,
                             std::optional<HWND> const& owner_window,
                             bool sized_to_content);

  // Whether the user can manually resize this window.
  const bool resizable_;

  // Used to track whether the view is still alive in tasks posted from the
  // raster thread.
  std::shared_ptr<int> view_alive_;

  // The last physical-pixel width reported to DidUpdateViewSize.
  int width_ = 0;

  // The last physical-pixel height reported to DidUpdateViewSize.
  int height_ = 0;
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_DIALOG_H_
