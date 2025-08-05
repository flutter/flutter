// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/display_manager.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"

#include "flutter/fml/logging.h"

namespace flutter {
DisplayManager::DisplayManager(FlutterWindowsEngine* engine) : engine_(engine) {
  WNDCLASS window_class = RegisterWindowClass();
  window_handle_ =
      CreateWindowEx(0, window_class.lpszClassName, L"", 0, 0, 0, 0, 0,
                     HWND_MESSAGE, nullptr, window_class.hInstance, nullptr);

  if (window_handle_) {
    SetWindowLongPtr(window_handle_, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(this));
  } else {
    auto error = GetLastError();
    LPWSTR message = nullptr;
    size_t size = FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL, error, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        reinterpret_cast<LPWSTR>(&message), 0, NULL);
    OutputDebugString(message);
    LocalFree(message);
  }
}

DisplayManager::~DisplayManager() {
  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  UnregisterClass(window_class_name_.c_str(), nullptr);
}
#include <iostream>
std::vector<FlutterEngineDisplay> DisplayManager::displays() const {
  std::vector<FlutterEngineDisplay> displays;
  EnumDisplayMonitors(nullptr, nullptr, MonitorEnumProc,
                      reinterpret_cast<LPARAM>(&displays));

  if (displays.size() == 1) {
    displays[0].single_display = true;
    displays[0].display_id = 0;  // ignored when single_display is true
  }

  return displays;
}

WNDCLASS DisplayManager::RegisterWindowClass() {
  window_class_name_ = L"FlutterDisplayManager";

  WNDCLASS window_class{};
  window_class.hCursor = nullptr;
  window_class.lpszClassName = window_class_name_.c_str();
  window_class.style = 0;
  window_class.cbClsExtra = 0;
  window_class.cbWndExtra = 0;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hIcon = nullptr;
  window_class.hbrBackground = 0;
  window_class.lpszMenuName = nullptr;
  window_class.lpfnWndProc = WndProc;
  RegisterClass(&window_class);
  return window_class;
}

LRESULT
DisplayManager::HandleMessage(UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DISPLAYCHANGE:
    case WM_DEVICECHANGE: {
      if (engine_->running()) {
        engine_->OnDisplaysChanged(displays());
      }
      break;
    }
  }
  return DefWindowProcW(window_handle_, message, wparam, lparam);
}

LRESULT DisplayManager::WndProc(HWND const window,
                                UINT const message,
                                WPARAM const wparam,
                                LPARAM const lparam) noexcept {
  if (auto* that = reinterpret_cast<DisplayManager*>(
          GetWindowLongPtr(window, GWLP_USERDATA))) {
    return that->HandleMessage(message, wparam, lparam);
  } else {
    return DefWindowProc(window, message, wparam, lparam);
  }
}

BOOL CALLBACK DisplayManager::MonitorEnumProc(HMONITOR hMonitor,
                                              HDC,
                                              LPRECT,
                                              LPARAM lParam) {
  auto displays = reinterpret_cast<std::vector<FlutterEngineDisplay>*>(lParam);

  MONITORINFOEX monitor_info = {};
  monitor_info.cbSize = sizeof(MONITORINFOEX);
  if (!GetMonitorInfo(hMonitor, &monitor_info)) {
    return TRUE;
  }

  // Get display settings
  DEVMODE dev_mode = {};
  dev_mode.dmSize = sizeof(DEVMODE);
  bool has_display_settings = EnumDisplaySettings(
      monitor_info.szDevice, ENUM_CURRENT_SETTINGS, &dev_mode);

  FlutterEngineDisplay display;
  display.struct_size = sizeof(FlutterEngineDisplay);
  display.display_id = reinterpret_cast<FlutterEngineDisplayId>(hMonitor);
  display.single_display = false;
  display.width = monitor_info.rcMonitor.right - monitor_info.rcMonitor.left;
  display.height = monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top;
  display.refresh_rate = has_display_settings
                             ? static_cast<double>(dev_mode.dmDisplayFrequency)
                             : 0.0;

  // Approximate device pixel ratio using system DPI
  UINT dpi_x = 96;
  HDC screen_dc = GetDC(nullptr);
  if (screen_dc) {
    dpi_x = GetDeviceCaps(screen_dc, LOGPIXELSX);
    ReleaseDC(nullptr, screen_dc);
  }
  display.device_pixel_ratio = dpi_x / 96.0;

  displays->push_back(display);
  return TRUE;
}

}  // namespace flutter