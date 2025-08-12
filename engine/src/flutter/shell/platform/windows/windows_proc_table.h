// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_PROC_TABLE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_PROC_TABLE_H_

#include <dwmapi.h>
#include <optional>

#include "flutter/fml/macros.h"
#include "flutter/fml/native_library.h"

namespace flutter {

// Lookup table for Windows APIs that aren't available on all versions of
// Windows, or for mocking Windows API calls.
class WindowsProcTable {
 public:
  enum WINDOWCOMPOSITIONATTRIB { WCA_ACCENT_POLICY = 19 };

  struct WINDOWCOMPOSITIONATTRIBDATA {
    WINDOWCOMPOSITIONATTRIB Attrib;
    PVOID pvData;
    SIZE_T cbData;
  };

  WindowsProcTable();
  virtual ~WindowsProcTable();

  // Retrieves the pointer type for a specified pointer.
  //
  // Used to react differently to touch or pen inputs. Returns false on failure.
  // Available on Windows 8 and newer, otherwise returns false.
  virtual BOOL GetPointerType(UINT32 pointer_id,
                              POINTER_INPUT_TYPE* pointer_type) const;

  // Get the preferred languages for the thread, and optionally the process,
  // and system, in that order, depending on the flags.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/api/winnls/nf-winnls-getthreadpreferreduilanguages
  virtual LRESULT GetThreadPreferredUILanguages(DWORD flags,
                                                PULONG count,
                                                PZZWSTR languages,
                                                PULONG length) const;

  // Get whether high contrast is enabled.
  //
  // Available on Windows 8 and newer, otherwise returns false.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/winauto/high-contrast-parameter
  virtual bool GetHighContrastEnabled() const;

  // Get whether the system compositor, DWM, is enabled.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/api/dwmapi/nf-dwmapi-dwmiscompositionenabled
  virtual bool DwmIsCompositionEnabled() const;

  // Issues a flush call that blocks the caller until all of the outstanding
  // surface updates have been made.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/api/dwmapi/nf-dwmapi-dwmflush
  virtual HRESULT DwmFlush() const;

  // Loads the specified cursor resource from the executable (.exe) file
  // associated with an application instance.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-loadcursorw
  virtual HCURSOR LoadCursor(HINSTANCE instance, LPCWSTR cursor_name) const;

  // Sets the cursor shape.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-setcursor
  virtual HCURSOR SetCursor(HCURSOR cursor) const;

  // Enables automatic display scaling of the non-client area portions of the
  // specified top-level window.
  //
  // See:
  // https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enablenonclientdpiscaling
  virtual BOOL EnableNonClientDpiScaling(HWND hwnd) const;

  // Sets the current value of a specified Desktop Window Manager (DWM)
  // attribute applied to a window.
  //
  // See:
  // https://learn.microsoft.com/en-us/windows/win32/dwm/setwindowcompositionattribute
  virtual BOOL SetWindowCompositionAttribute(
      HWND hwnd,
      WINDOWCOMPOSITIONATTRIBDATA* data) const;

  // Extends the window frame into the client area.
  //
  // See:
  // https://learn.microsoft.com/en-us/windows/win32/api/dwmapi/nf-dwmapi-dwmextendframeintoclientarea
  virtual HRESULT DwmExtendFrameIntoClientArea(HWND hwnd,
                                               const MARGINS* pMarInset) const;

  // Sets the value of Desktop Window Manager (DWM) non-client rendering
  // attributes for a window.
  //
  // See:
  // https://learn.microsoft.com/en-us/windows/win32/api/dwmapi/nf-dwmapi-dwmsetwindowattribute
  virtual HRESULT DwmSetWindowAttribute(HWND hwnd,
                                        DWORD dwAttribute,
                                        LPCVOID pvAttribute,
                                        DWORD cbAttribute) const;

  // Calculates the required size of the window rectangle, based on the desired
  // size of the client rectangle and the provided DPI.
  //
  // See:
  // https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-adjustwindowrectexfordpi
  virtual BOOL AdjustWindowRectExForDpi(LPRECT lpRect,
                                        DWORD dwStyle,
                                        BOOL bMenu,
                                        DWORD dwExStyle,
                                        UINT dpi) const;

  // Get the system metrics.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-getsystemmetrics
  virtual int GetSystemMetrics(int nIndex) const;

  // Enumerate display devices.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-enumdisplaydevicesw
  virtual BOOL EnumDisplayDevices(LPCWSTR lpDevice,
                                  DWORD iDevNum,
                                  PDISPLAY_DEVICE lpDisplayDevice,
                                  DWORD dwFlags) const;

  // Enumerate display settings.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-enumdisplaysettingsw
  virtual BOOL EnumDisplaySettings(LPCWSTR lpszDeviceName,
                                   DWORD iModeNum,
                                   DEVMODEW* lpDevMode) const;

  // Get monitor info.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-getmonitorinfow
  virtual BOOL GetMonitorInfo(HMONITOR hMonitor, LPMONITORINFO lpmi) const;

  // Enumerate display monitors.
  //
  // See:
  // https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-enumdisplaymonitors
  virtual BOOL EnumDisplayMonitors(HDC hdc,
                                   LPCRECT lprcClip,
                                   MONITORENUMPROC lpfnEnum,
                                   LPARAM dwData) const;

 private:
  using GetPointerType_ = BOOL __stdcall(UINT32 pointerId,
                                         POINTER_INPUT_TYPE* pointerType);
  using EnableNonClientDpiScaling_ = BOOL __stdcall(HWND hwnd);
  using SetWindowCompositionAttribute_ =
      BOOL __stdcall(HWND, WINDOWCOMPOSITIONATTRIBDATA*);
  using AdjustWindowRectExForDpi_ = BOOL __stdcall(LPRECT lpRect,
                                                   DWORD dwStyle,
                                                   BOOL bMenu,
                                                   DWORD dwExStyle,
                                                   UINT dpi);

  // The User32.dll library, used to resolve functions at runtime.
  fml::RefPtr<fml::NativeLibrary> user32_;

  std::optional<GetPointerType_*> get_pointer_type_;
  std::optional<EnableNonClientDpiScaling_*> enable_non_client_dpi_scaling_;
  std::optional<SetWindowCompositionAttribute_*>
      set_window_composition_attribute_;
  std::optional<AdjustWindowRectExForDpi_*> adjust_window_rect_ext_for_dpi_;

  FML_DISALLOW_COPY_AND_ASSIGN(WindowsProcTable);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_PROC_TABLE_H_
