// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WIN32_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WIN32_WINDOW_H_

#include <Windows.h>

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "flutter/shell/platform/common/alert_platform_node_delegate.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/direct_manipulation.h"
#include "flutter/shell/platform/windows/keyboard_manager.h"
#include "flutter/shell/platform/windows/sequential_id_generator.h"
#include "flutter/shell/platform/windows/text_input_manager.h"
#include "flutter/shell/platform/windows/windows_proc_table.h"
#include "flutter/shell/platform/windows/windowsx_shim.h"
#include "flutter/third_party/accessibility/ax/platform/ax_fragment_root_delegate_win.h"
#include "flutter/third_party/accessibility/ax/platform/ax_fragment_root_win.h"
#include "flutter/third_party/accessibility/ax/platform/ax_platform_node_win.h"
#include "flutter/third_party/accessibility/gfx/native_widget_types.h"

namespace flutter {

// A class abstraction for a high DPI aware Win32 Window.  Intended to be
// inherited from by classes that wish to specialize with custom
// rendering and input handling.
class Window : public KeyboardManager::WindowDelegate {
 public:
  Window();
  Window(std::unique_ptr<WindowsProcTable> windows_proc_table,
         std::unique_ptr<TextInputManager> text_input_manager);
  virtual ~Window();

  // Initializes as a child window with size using |width| and |height| and
  // |title| to identify the windowclass.  Does not show window, window must be
  // parented into window hierarchy by caller.
  void InitializeChild(const char* title,
                       unsigned int width,
                       unsigned int height);

  HWND GetWindowHandle();

  // |KeyboardManager::WindowDelegate|
  virtual BOOL Win32PeekMessage(LPMSG lpMsg,
                                UINT wMsgFilterMin,
                                UINT wMsgFilterMax,
                                UINT wRemoveMsg) override;

  // |KeyboardManager::WindowDelegate|
  virtual uint32_t Win32MapVkToChar(uint32_t virtual_key) override;

  // |KeyboardManager::WindowDelegate|
  virtual UINT Win32DispatchMessage(UINT Msg,
                                    WPARAM wParam,
                                    LPARAM lParam) override;

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
  LRESULT HandleMessage(UINT const message,
                        WPARAM const wparam,
                        LPARAM const lparam) noexcept;

  // When WM_DPICHANGE process it using |hWnd|, |wParam|.  If
  // |top_level| is set, extract the suggested new size from |lParam| and resize
  // the window to the new suggested size.  If |top_level| is not set, the
  // |lParam| will not contain a suggested size hence ignore it.
  LRESULT HandleDpiChange(HWND hWnd,
                          WPARAM wParam,
                          LPARAM lParam,
                          bool top_level);

  // Called when the DPI changes either when a
  // user drags the window between monitors of differing DPI or when the user
  // manually changes the scale factor.
  virtual void OnDpiScale(UINT dpi) = 0;

  // Called when a resize occurs.
  virtual void OnResize(UINT width, UINT height) = 0;

  // Called when a paint is requested.
  virtual void OnPaint() = 0;

  // Called when the pointer moves within the
  // window bounds.
  virtual void OnPointerMove(double x,
                             double y,
                             FlutterPointerDeviceKind device_kind,
                             int32_t device_id,
                             int modifiers_state) = 0;

  // Called when the a mouse button, determined by |button|, goes down.
  virtual void OnPointerDown(double x,
                             double y,
                             FlutterPointerDeviceKind device_kind,
                             int32_t device_id,
                             UINT button) = 0;

  // Called when the a mouse button, determined by |button|, goes from
  // down to up
  virtual void OnPointerUp(double x,
                           double y,
                           FlutterPointerDeviceKind device_kind,
                           int32_t device_id,
                           UINT button) = 0;

  // Called when the mouse leaves the window.
  virtual void OnPointerLeave(double x,
                              double y,
                              FlutterPointerDeviceKind device_kind,
                              int32_t device_id) = 0;

  // Called when the cursor should be set for the client area.
  virtual void OnSetCursor() = 0;

  // Called when the OS requests a COM object.
  //
  // The primary use of this function is to supply Windows with wrapped
  // semantics objects for use by Windows accessibility.
  virtual LRESULT OnGetObject(UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam);

  // Called when IME composing begins.
  virtual void OnComposeBegin() = 0;

  // Called when IME composing text is committed.
  virtual void OnComposeCommit() = 0;

  // Called when IME composing ends.
  virtual void OnComposeEnd() = 0;

  // Called when IME composing text or cursor position changes.
  virtual void OnComposeChange(const std::u16string& text, int cursor_pos) = 0;

  // Called when a window is activated in order to configure IME support for
  // multi-step text input.
  virtual void OnImeSetContext(UINT const message,
                               WPARAM const wparam,
                               LPARAM const lparam);

  // Called when multi-step text input begins when using an IME.
  virtual void OnImeStartComposition(UINT const message,
                                     WPARAM const wparam,
                                     LPARAM const lparam);

  // Called when edits/commit of multi-step text input occurs when using an IME.
  virtual void OnImeComposition(UINT const message,
                                WPARAM const wparam,
                                LPARAM const lparam);

  // Called when multi-step text input ends when using an IME.
  virtual void OnImeEndComposition(UINT const message,
                                   WPARAM const wparam,
                                   LPARAM const lparam);

  // Called when the user triggers an IME-specific request such as input
  // reconversion, where an existing input sequence is returned to composing
  // mode to select an alternative candidate conversion.
  virtual void OnImeRequest(UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam);

  // Called when the app ends IME composing, such as when the text input client
  // is cleared or changed.
  virtual void AbortImeComposing();

  // Called when the cursor rect has been updated.
  //
  // |rect| is in Win32 window coordinates.
  virtual void UpdateCursorRect(const Rect& rect);

  // Called when accessibility support is enabled or disabled.
  virtual void OnUpdateSemanticsEnabled(bool enabled) = 0;

  // Called when mouse scrollwheel input occurs.
  virtual void OnScroll(double delta_x,
                        double delta_y,
                        FlutterPointerDeviceKind device_kind,
                        int32_t device_id) = 0;

  UINT GetCurrentDPI();

  UINT GetCurrentWidth();

  UINT GetCurrentHeight();

  // Returns the current pixel per scroll tick value.
  virtual float GetScrollOffsetMultiplier();

  // Check if the high contrast feature is enabled on the OS
  virtual bool GetHighContrastEnabled();

  // Creates the ax_fragment_root_, alert_delegate_ and alert_node_ if they do
  // not yet exist.
  // Once set, they are not reset to nullptr.
  void CreateAxFragmentRoot();

  // Called to obtain a pointer to the fragment root delegate.
  virtual ui::AXFragmentRootDelegateWin* GetAxFragmentRootDelegate() = 0;

 protected:
  // Win32's DefWindowProc.
  //
  // Used as the fallback behavior of HandleMessage. Exposed for dependency
  // injection.
  virtual LRESULT Win32DefWindowProc(HWND hWnd,
                                     UINT Msg,
                                     WPARAM wParam,
                                     LPARAM lParam);

  // Returns the root view accessibility node, or nullptr if none.
  virtual gfx::NativeViewAccessible GetNativeViewAccessible() = 0;

  // Handles running DirectManipulation on the window to receive trackpad
  // gestures.
  std::unique_ptr<DirectManipulationOwner> direct_manipulation_owner_;

  // Called when a theme change message is issued
  virtual void OnThemeChange() = 0;

  // Delegate to a alert_node_ used to set the announcement text.
  std::unique_ptr<AlertPlatformNodeDelegate> alert_delegate_;

  // Accessibility node that represents an alert.
  std::unique_ptr<ui::AXPlatformNodeWin> alert_node_;

 private:
  // Release OS resources associated with window.
  void Destroy();

  // Activates tracking for a "mouse leave" event.
  void TrackMouseLeaveEvent(HWND hwnd);

  // Stores new width and height and calls |OnResize| to notify inheritors
  void HandleResize(UINT width, UINT height);

  // Retrieves a class instance pointer for |window|
  static Window* GetThisFromHandle(HWND const window) noexcept;

  // Updates the cached scroll_offset_multiplier_ value based off OS settings.
  void UpdateScrollOffsetMultiplier();

  int current_dpi_ = 0;
  int current_width_ = 0;
  int current_height_ = 0;

  // Holds the conversion factor from lines scrolled to pixels scrolled.
  float scroll_offset_multiplier_;

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

  // Keeps track of the last mouse coordinates by a WM_MOUSEMOVE message.
  double mouse_x_ = 0;
  double mouse_y_ = 0;

  // Abstracts Windows APIs that may not be available on all supported versions
  // of Windows.
  std::unique_ptr<WindowsProcTable> windows_proc_table_;

  // Manages IME state.
  std::unique_ptr<TextInputManager> text_input_manager_;

  // Manages IME state.
  std::unique_ptr<KeyboardManager> keyboard_manager_;

  // Used for temporarily storing the WM_TOUCH-provided touch points.
  std::vector<TOUCHINPUT> touch_points_;

  // Generates touch point IDs for touch events.
  SequentialIdGenerator touch_id_generator_;

  // Timer identifier for DirectManipulation gesture polling.
  const static int kDirectManipulationTimer = 1;

  // Implements IRawElementProviderFragmentRoot when UIA is enabled.
  std::unique_ptr<ui::AXFragmentRootWin> ax_fragment_root_;

  // Allow WindowAXFragmentRootDelegate to access protected method.
  friend class WindowAXFragmentRootDelegate;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WIN32_WINDOW_H_
