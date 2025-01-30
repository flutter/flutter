// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_HOST_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_HOST_WINDOW_H_

#include <windows.h>

#include <memory>
#include <set>
#include <string>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/common/windowing.h"

namespace flutter {

class FlutterHostWindowController;
class FlutterWindowsViewController;

// A Win32 window that hosts a |FlutterWindow| in its client area.
class FlutterHostWindow {
 public:
  // Creates a native Win32 window with a child view confined to its client
  // area. |controller| is a pointer to the controller that manages the
  // |FlutterHostWindow|. On success, a valid window handle can be retrieved via
  // |FlutterHostWindow::GetWindowHandle|.
  FlutterHostWindow(FlutterHostWindowController* controller,
                    WindowCreationSettings const& settings);
  virtual ~FlutterHostWindow();

  // Returns the instance pointer for |hwnd| or nulllptr if invalid.
  static FlutterHostWindow* GetThisFromHandle(HWND hwnd);

  // Returns the window archetype.
  WindowArchetype GetArchetype() const;

  // Returns the hosted Flutter view's ID.
  FlutterViewId GetFlutterViewId() const;

  // Returns the owned windows.
  std::set<FlutterHostWindow*> const& GetOwnedWindows() const;

  // Returns the owner window, or nullptr if there is not owner.
  FlutterHostWindow* GetOwnerWindow() const;

  // Returns the position relative to the owner, in logical coordinates, or
  // std::nullopt if there is no owner.
  std::optional<Point> GetRelativePosition() const;

  // Returns the current window state, or std::nullopt if the archetype is not
  // WindowArchetype::kRegular.
  std::optional<WindowState> GetState() const;

  // Returns the backing window handle, or nullptr if the native window is not
  // created or has already been destroyed.
  HWND GetWindowHandle() const;

  // Sets whether closing this window will quit the application.
  void SetQuitOnClose(bool quit_on_close);

  // Returns whether closing this window will quit the application.
  bool GetQuitOnClose() const;

 private:
  friend FlutterHostWindowController;

  // Set the focus to the child view window of |window|.
  static void FocusViewOf(FlutterHostWindow* window);

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responds to changes in DPI. Delegates other messages to the controller.
  static LRESULT WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  // Closes this window's popups and returns the count of closed popups.
  std::size_t CloseOwnedPopups();

  // Finds the first enabled descendant window. If the current window itself is
  // enabled, returns the current window.
  FlutterHostWindow* FindFirstEnabledDescendant() const;

  // Processes and routes salient window messages for mouse handling,
  // size change and DPI. Delegates handling of these to member overloads that
  // inheriting classes can handle.
  LRESULT HandleMessage(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  // Inserts |content| into the window tree.
  void SetChildContent(HWND content);

  // Controller for this window.
  FlutterHostWindowController* const window_controller_;

  // Controller for the view hosted by this window.
  std::unique_ptr<FlutterWindowsViewController> view_controller_;

  // The window archetype.
  WindowArchetype archetype_ = WindowArchetype::kRegular;

  // Windows that have this window as their owner window.
  std::set<FlutterHostWindow*> owned_windows_;

  // The number of popups in |owned_windows_| (for quick popup existence
  // checks).
  std::size_t num_owned_popups_ = 0;

  // Indicates if closing this window will quit the application.
  bool quit_on_close_ = false;

  // Backing handle for this window.
  HWND window_handle_ = nullptr;

  // Backing handle for the hosted view window.
  HWND child_content_ = nullptr;

  // Offset between this window's top-left position and its owner's, in physical
  // coordinates.
  POINT offset_from_owner_ = {0, 0};

  // Whether the non-client area can be redrawn as inactive. Temporarily
  // disabled during owned popup destruction to prevent flickering.
  bool enable_redraw_non_client_as_inactive_ = true;

  // The minimum size of the window's client area, if defined.
  std::optional<Size> min_size_;

  // The maximum size of the window's client area, if defined.
  std::optional<Size> max_size_;

  // The window state. Used by WindowArchetype::kRegular.
  std::optional<WindowState> state_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterHostWindow);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_HOST_WINDOW_H_
