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
class WindowsProcTable;
class FlutterWindowsView;
class FlutterWindowsViewController;

// A Win32 window that hosts a |FlutterWindow| in its client area.
class HostWindow {
 public:
  virtual ~HostWindow();

  // Creates a regular Win32 window with a child view confined to its client
  // area. |window_manager| is a pointer to the window manager that manages the
  // |HostWindow|. |engine| is a pointer to the engine that manages
  // the window manager. |preferred_size| is the preferred size of the window.
  // |preferred_constraints| are the constraints set on the window's size.
  // |title| is the title of the window.
  //
  // On success, a valid window handle can be retrieved
  // via |HostWindow::GetWindowHandle|. |nullptr| will be returned
  // on failure.
  static std::unique_ptr<HostWindow> CreateRegularWindow(
      WindowManager* window_manager,
      FlutterWindowsEngine* engine,
      const WindowSizeRequest& preferred_size,
      const WindowConstraints& preferred_constraints,
      LPCWSTR title);

  // Creates a dialog Win32 window with a child view confined to its client
  // area. |window_manager| is a pointer to the window manager that manages the
  // |HostWindow|. |engine| is a pointer to the engine that manages
  // the window manager. |preferred_size| is the preferred size of the window.
  // |preferred_constraints| are the constraints set on the window's size.
  // |title| is the title of the window. |parent| is the parent of this dialog,
  // which can be `nullptr`.
  //
  // On success, a valid window handle can be retrieved
  // via |HostWindow::GetWindowHandle|. `nullptr` will be returned
  // on failure.
  static std::unique_ptr<HostWindow> CreateDialogWindow(
      WindowManager* window_manager,
      FlutterWindowsEngine* engine,
      const WindowSizeRequest& preferred_size,
      const WindowConstraints& preferred_constraints,
      LPCWSTR title,
      HWND parent);

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
  virtual void SetFullscreen(bool fullscreen,
                             std::optional<FlutterEngineDisplayId> display_id);

  // Returns |true| if this window is fullscreen, otherwise |false|.
  virtual bool GetFullscreen() const;

  // Given a window identifier, returns the window content size of the
  // window.
  static ActualWindowSize GetWindowContentSize(HWND hwnd);

  // Returns the owner window, or nullptr if none.
  HostWindow* GetOwnerWindow() const;

  // This method is called when a dialog is created or destroyed.
  // It walks the path of child windows to make sure that the right
  // windows are enabled or disabled.
  void UpdateModalStateLayer();

 protected:
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

  // Construct a host window.
  //
  // See:
  // - https://learn.microsoft.com/windows/win32/winmsg/window-styles
  // - https://learn.microsoft.com/windows/win32/winmsg/extended-window-styles
  HostWindow(WindowManager* window_manager,
             FlutterWindowsEngine* engine,
             WindowArchetype archetype,
             DWORD window_style,
             DWORD extended_window_style,
             const BoxConstraints& box_constraints,
             Rect const initial_window_rect,
             LPCWSTR title,
             std::optional<HWND> const& owner_window);

  // Calculates the required window size, in physical coordinates, to
  // accommodate the given |client_size|, in logical coordinates, constrained by
  // optional |smallest| and |biggest|, for a window with the specified
  // |window_style| and |extended_window_style|. If |owner_hwnd| is not null,
  // the DPI of the display with the largest area of intersection with
  // |owner_hwnd| is used for the calculation; otherwise, the primary display's
  // DPI is used. The resulting size includes window borders, non-client areas,
  // and drop shadows. On error, returns std::nullopt and logs an error message.
  static std::optional<Size> GetWindowSizeForClientSize(
      WindowsProcTable const& win32,
      Size const& client_size,
      std::optional<Size> smallest,
      std::optional<Size> biggest,
      DWORD window_style,
      DWORD extended_window_style,
      std::optional<HWND> const& owner_hwnd);

  // Processes and routes salient window messages for mouse handling,
  // size change and DPI. Delegates handling of these to member overloads that
  // inheriting classes can handle.
  virtual LRESULT HandleMessage(HWND hwnd,
                                UINT message,
                                WPARAM wparam,
                                LPARAM lparam);

  // Sets the focus to the child view window of |window|.
  static void FocusRootViewOf(HostWindow* window);

  // Enables or disables mouse and keyboard input to this window and all its
  // descendants.
  void EnableRecursively(bool enable);

  // Returns the first enabled descendant window. If the current window itself
  // is enabled, returns the current window. If no window is enabled, returns
  // `nullptr`.
  HostWindow* FindFirstEnabledDescendant() const;

  // Returns windows owned by this window.
  std::vector<HostWindow*> GetOwnedWindows() const;

  // Disables mouse and keyboard input to the window and all its descendants.
  void DisableRecursively();

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responds to changes in DPI. Delegates other messages to the controller.
  static LRESULT WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

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
  HWND window_handle_;

  // The constraints on the window's client area.
  BoxConstraints box_constraints_;

  // True while handling WM_DESTROY; used to detect in-progress destruction.
  bool is_being_destroyed_ = false;

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
