// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_MANAGER_H_

#include <windows.h>
#include <string>
#include <vector>

#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
class FlutterWindowsEngine;

class DisplayManager {
 public:
  DisplayManager(FlutterWindowsEngine* engine);
  virtual ~DisplayManager();

  std::vector<FlutterEngineDisplay> displays() const;

 private:
  WNDCLASS RegisterWindowClass();

  LRESULT
  HandleMessage(UINT const message,
                WPARAM const wparam,
                LPARAM const lparam) noexcept;

  static LRESULT CALLBACK WndProc(HWND const window,
                                  UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  static BOOL CALLBACK MonitorEnumProc(HMONITOR hMonitor,
                                       HDC,
                                       LPRECT,
                                       LPARAM lParam);

  FlutterWindowsEngine* engine_;
  HWND window_handle_;
  std::wstring window_class_name_;
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_MANAGER_H_
