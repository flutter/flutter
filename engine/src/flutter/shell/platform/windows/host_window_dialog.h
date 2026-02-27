// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_DIALOG_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_DIALOG_H_

#include "host_window.h"

namespace flutter {
class HostWindowDialog : public HostWindow {
 public:
  // Creates a dialog window.
  //
  // If |owner_window| is not null, the dialog will be modal to the owner.
  // This also affects the dialog window's styling.
  HostWindowDialog(WindowManager* window_manager,
                   FlutterWindowsEngine* engine,
                   const WindowSizeRequest& preferred_size,
                   const BoxConstraints& constraints,
                   LPCWSTR title,
                   std::optional<HWND> const& owner_window);

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

  static Rect GetInitialRect(FlutterWindowsEngine* engine,
                             const WindowSizeRequest& preferred_size,
                             const BoxConstraints& constraints,
                             std::optional<HWND> const& owner_window);
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_DIALOG_H_
