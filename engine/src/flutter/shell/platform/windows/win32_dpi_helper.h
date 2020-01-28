// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_DPI_HELPER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_DPI_HELPER_H_

#include <ShellScalingApi.h>
#include <VersionHelpers.h>

namespace flutter {

/// A helper class for abstracting various Windows DPI related functions across
/// Windows OS versions.
class Win32DpiHelper {
 public:
  Win32DpiHelper();

  ~Win32DpiHelper();

  /// Returns the current DPI. Supports all DPI awareness modes, and is backward
  /// compatible down to Windows Vista.
  UINT GetDpi(HWND);

 private:
  using GetDpiForWindow_ = UINT __stdcall(HWND);
  using GetDpiForMonitor_ = HRESULT __stdcall(HMONITOR hmonitor,
                                              MONITOR_DPI_TYPE dpiType,
                                              UINT* dpiX,
                                              UINT* dpiY);
  using MonitorFromWindow_ = HMONITOR __stdcall(HWND hwnd, DWORD dwFlags);

  GetDpiForWindow_* get_dpi_for_window_ = nullptr;
  GetDpiForMonitor_* get_dpi_for_monitor_ = nullptr;
  MonitorFromWindow_* monitor_from_window_ = nullptr;

  HMODULE user32_module_ = nullptr;
  HMODULE shlib_module_ = nullptr;
  bool dpi_for_window_supported_ = false;
  bool dpi_for_monitor_supported_ = false;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_DPI_HELPER_H_
