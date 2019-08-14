// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_DPI_HELPER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_DPI_HELPER_H_

#include <ShellScalingApi.h>
#include <VersionHelpers.h>

namespace flutter {

// A helper class for abstracting various Windows DPI related functions across
// Windows OS versions.
class Win32DpiHelper {
 public:
  Win32DpiHelper();

  ~Win32DpiHelper();

  // Check if Windows Per Monitor V2 DPI scaling functionality is available on
  // current system.
  bool IsPerMonitorV2Available();

  // Wrapper for OS functionality to turn on automatic window non-client scaling
  BOOL EnableNonClientDpiScaling(HWND);

  // Wrapper for OS functionality to return the DPI for |HWND|
  UINT GetDpiForWindow(HWND);

  // Sets the current process to a specified DPI awareness context.
  BOOL SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT);

 private:
  using EnableNonClientDpiScaling_ = BOOL __stdcall(HWND);
  using GetDpiForWindow_ = UINT __stdcall(HWND);
  using SetProcessDpiAwarenessContext_ = BOOL __stdcall(DPI_AWARENESS_CONTEXT);

  EnableNonClientDpiScaling_* enable_non_client_dpi_scaling_ = nullptr;
  GetDpiForWindow_* get_dpi_for_window_ = nullptr;
  SetProcessDpiAwarenessContext_* set_process_dpi_awareness_context_ = nullptr;

  HMODULE user32_module_ = nullptr;
  bool permonitorv2_supported_ = false;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_DPI_HELPER_H_
