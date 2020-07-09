// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WIN32_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WIN32_WINDOW_H_

#include <Windows.h>
#include <Windowsx.h>

#include <memory>
#include <string>

namespace flutter {

// A class abstraction for a high DPI aware Win32 Window.  Intended to be
// inherited from by classes that wish to specialize with custom
// rendering and input handling.
class Win32Window {
 public:
  Win32Window();
  virtual ~Win32Window();

  // Initializes as a child window with size using |width| and |height| and
  // |title| to identify the windowclass.  Does not show window, window must be
  // parented into window hierarchy by caller.
  void InitializeChild(const char* title,
                       unsigned int width,
                       unsigned int height);

  HWND GetWindowHandle();

 protected:
  // Converts a c string to a wide unicode string.
  std::wstring NarrowToWide(const char* source);

  // Registers a window class with default style attributes, cursor and
  // icon.
  WNDCLASS RegisterWindowClass(std::wstring& title);

  // OS callback called by message pump.  Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responsponds to changes in DPI.  All other messages are handled by
  // MessageHandler.
  static LRESULT CALLBACK WndProc(HWND const window,
                                  UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  // Processes and route salient window messages for mouse handling,
  // size change and DPI.  Delegates handling of these to member overloads that
  // inheriting classes can handle.
  LRESULT
  MessageHandler(HWND window,
                 UINT const message,
                 WPARAM const wparam,
                 LPARAM const lparam) noexcept;

  // When WM_DPICHANGE process it using |hWnd|, |wParam|.  If
  // |top_level| is set, extract the suggested new size from |lParam| and resize
  // the window to the new suggested size.  If |top_level| is not set, the
  // |lParam| will not contain a suggested size hence ignore it.
  LRESULT
  HandleDpiChange(HWND hWnd, WPARAM wParam, LPARAM lParam, bool top_level);

  // Called when the DPI changes either when a
  // user drags the window between monitors of differing DPI or when the user
  // manually changes the scale factor.
  virtual void OnDpiScale(UINT dpi) = 0;

  // Called when a resize occurs.
  virtual void OnResize(UINT width, UINT height) = 0;

  // Called when the pointer moves within the
  // window bounds.
  virtual void OnPointerMove(double x, double y) = 0;

  // Called when the a mouse button, determined by |button|, goes down.
  virtual void OnPointerDown(double x, double y, UINT button) = 0;

  // Called when the a mouse button, determined by |button|, goes from
  // down to up
  virtual void OnPointerUp(double x, double y, UINT button) = 0;

  // Called when the mouse leaves the window.
  virtual void OnPointerLeave() = 0;

  // Called when the cursor should be set for the client area.
  virtual void OnSetCursor() = 0;

  // Called when text input occurs.
  virtual void OnText(const std::u16string& text) = 0;

  // Called when raw keyboard input occurs.
  virtual void OnKey(int key, int scancode, int action, char32_t character) = 0;

  // Called when mouse scrollwheel input occurs.
  virtual void OnScroll(double delta_x, double delta_y) = 0;

  // Called when the system font change.
  virtual void OnFontChange() = 0;

  UINT GetCurrentDPI();

  UINT GetCurrentWidth();

  UINT GetCurrentHeight();

 private:
  // Release OS resources asociated with window.
  void Destroy();

  // Activates tracking for a "mouse leave" event.
  void TrackMouseLeaveEvent(HWND hwnd);

  // Stores new width and height and calls |OnResize| to notify inheritors
  void HandleResize(UINT width, UINT height);

  // Retrieves a class instance pointer for |window|
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;
  int current_dpi_ = 0;
  int current_width_ = 0;
  int current_height_ = 0;

  // WM_DPICHANGED_BEFOREPARENT defined in more recent Windows
  // SDK
  const static long kWmDpiChangedBeforeParent = 0x02E2;

  // Member variable to hold window handle.
  HWND window_handle_ = nullptr;

  // Member variable to hold the window title.
  std::wstring window_class_name_;

  // Set to true to be notified when the mouse leaves the window.
  bool tracking_mouse_leave_ = false;

  // Keeps track of the last key code produced by a WM_KEYDOWN or WM_SYSKEYDOWN
  // message.
  int keycode_for_char_message_ = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WIN32_WINDOW_H_
