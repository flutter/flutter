// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_H_

#include <shobjidl.h>
#include <windows.h>
#include <wrl/client.h>
#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "flutter/shell/geometry/geometry.h"
#include "flutter/shell/platform/common/windowing.h"
#include "flutter/shell/platform/windows/window_manager.h"

namespace flutter {

class WindowManager;
class FlutterWindowsView;
class FlutterWindowsViewController;

// A Win32 window that hosts a |FlutterWindow| in its client area.
class HostWindow {
 public:
  virtual ~HostWindow();

  // Creates a native Win32 window with a child view confined to its client
  // area. |controller| is a pointer to the controller that manages the
  // |HostWindow|. |engine| is a pointer to the engine that manages
  // the controller. On success, a valid window handle can be retrieved
  // via |HostWindow::GetWindowHandle|. |nullptr| will be returned
  // on failure.
  static std::unique_ptr<HostWindow> CreateRegularWindow(
      WindowManager* controller,
      FlutterWindowsEngine* engine,
      const WindowSizeRequest& preferred_size,
      const WindowConstraints& preferred_constraints,
      LPCWSTR title);

  // Returns the instance pointer for |hwnd| or nullptr if invalid.
  static HostWindow* GetThisFromHandle(HWND hwnd);

  // Returns the backing window handle, or nullptr if the native window is not
  // created or has already been destroyed.
  HWND GetWindowHandle() const;

  // Resizes the window to accommodate a client area of the given
  // |size|. If the size does not satisfy the constraints, the window will be
  // resized to the minimum or maximum size as appropriate.
  void SetContentSize(const WindowSizeRequest& size);

  // Sets the constaints on the client area of the window.
  // If the current window size does not satisfy the new constraints,
  // the window will be resized to satisy thew new constraints.
  void SetConstraints(const WindowConstraints& constraints);

  // Set the fullscreen state. |display_id| indicates the display where
  // the window should be shown fullscreen; std::nullopt indicates
  // that no display was specified, so the current display may be used.
  void SetFullscreen(bool fullscreen,
                     std::optional<FlutterEngineDisplayId> display_id);

  // Returns |true| if this window is fullscreen, otherwise |false|.
  bool GetFullscreen() const;

  // Given a window identifier, returns the window content size of the
  // window.
  static ActualWindowSize GetWindowContentSize(HWND hwnd);

 private:
  friend WindowManager;

  // Information saved before going into fullscreen mode, used to restore the
  // window afterwards.
  struct SavedWindowInfo {
    LONG style;
    LONG ex_style;
    RECT rect;
    ActualWindowSize client_size;
    int dpi;
    HMONITOR monitor;
    MONITORINFO monitor_info;
  };

  HostWindow(WindowManager* controller,
             FlutterWindowsEngine* engine,
             WindowArchetype archetype,
             std::unique_ptr<FlutterWindowsViewController> view_controller,
             const BoxConstraints& constraints,
             HWND hwnd);

  // Sets the focus to the child view window of |window|.
  static void FocusViewOf(HostWindow* window);

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responds to changes in DPI. Delegates other messages to the controller.
  static LRESULT WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  // Processes and routes salient window messages for mouse handling,
  // size change and DPI. Delegates handling of these to member overloads that
  // inheriting classes can handle.
  LRESULT HandleMessage(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  // Controller for this window.
  WindowManager* const window_manager_ = nullptr;

  // The Flutter engine that owns this window.
  FlutterWindowsEngine* engine_;

  // Controller for the view hosted in this window. Value-initialized if the
  // window is created from an existing top-level native window created by the
  // runner.
  std::unique_ptr<FlutterWindowsViewController> view_controller_;

  // The window archetype.
  WindowArchetype archetype_ = WindowArchetype::kRegular;

  // Backing handle for this window.
  HWND window_handle_ = nullptr;

  // The constraints on the window's client area.
  BoxConstraints box_constraints_;

  // Whether or not the window is currently in a fullscreen state.
  bool is_fullscreen_ = false;

  // Saved window information from before entering fullscreen mode.
  SavedWindowInfo saved_window_info_;

  // Used to mark a window as fullscreen.
  Microsoft::WRL::ComPtr<ITaskbarList2> task_bar_list_;

  FML_DISALLOW_COPY_AND_ASSIGN(HostWindow);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_H_
