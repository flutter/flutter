// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "display_monitor.h"

#include <windows.h>

#include "flutter/shell/platform/windows/dpi_utils.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace flutter {

namespace {

// Data structure to pass to the display enumeration callback.
struct MonitorEnumState {
  const DisplayMonitor* display_monitor;
  std::vector<FlutterEngineDisplay>* displays;
};

}  // namespace

DisplayMonitor::DisplayMonitor(FlutterWindowsEngine* engine)
    : engine_(engine), win32_(engine->windows_proc_table()) {}

DisplayMonitor::~DisplayMonitor() {}

BOOL CALLBACK DisplayMonitor::EnumMonitorCallback(HMONITOR monitor,
                                                  HDC hdc,
                                                  LPRECT rect,
                                                  LPARAM data) {
  MonitorEnumState* state = reinterpret_cast<MonitorEnumState*>(data);
  const DisplayMonitor* self = state->display_monitor;
  std::vector<FlutterEngineDisplay>* displays = state->displays;

  MONITORINFOEXW monitor_info = {};
  monitor_info.cbSize = sizeof(monitor_info);
  if (self->win32_->GetMonitorInfoW(monitor, &monitor_info) == 0) {
    // Return TRUE to continue enumeration and skip this monitor.
    // Returning FALSE would stop the entire enumeration process,
    // potentially missing other valid monitors.
    return TRUE;
  }

  DEVMODEW dev_mode = {};
  dev_mode.dmSize = sizeof(dev_mode);
  if (!self->win32_->EnumDisplaySettingsW(monitor_info.szDevice,
                                          ENUM_CURRENT_SETTINGS, &dev_mode)) {
    // Return TRUE to continue enumeration and skip this monitor.
    // Returning FALSE would stop the entire enumeration process,
    // potentially missing other valid monitors.
    return TRUE;
  }

  UINT dpi = GetDpiForMonitor(monitor);

  FlutterEngineDisplay display = {};
  display.struct_size = sizeof(FlutterEngineDisplay);
  display.display_id = reinterpret_cast<FlutterEngineDisplayId>(monitor);
  display.single_display = false;
  display.refresh_rate = dev_mode.dmDisplayFrequency;
  display.width = monitor_info.rcMonitor.right - monitor_info.rcMonitor.left;
  display.height = monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top;
  display.device_pixel_ratio =
      static_cast<double>(dpi) / static_cast<double>(kDefaultDpi);

  displays->push_back(display);
  return TRUE;
}

void DisplayMonitor::UpdateDisplays() {
  auto displays = GetDisplays();
  engine_->UpdateDisplay(displays);
}

bool DisplayMonitor::HandleWindowMessage(HWND hwnd,
                                         UINT message,
                                         WPARAM wparam,
                                         LPARAM lparam,
                                         LRESULT* result) {
  switch (message) {
    case WM_DISPLAYCHANGE:
    case WM_DPICHANGED:
      UpdateDisplays();
      break;
  }
  return false;
}

std::vector<FlutterEngineDisplay> DisplayMonitor::GetDisplays() const {
  std::vector<FlutterEngineDisplay> displays;
  MonitorEnumState state = {this, &displays};
  win32_->EnumDisplayMonitors(nullptr, nullptr, EnumMonitorCallback,
                              reinterpret_cast<LPARAM>(&state));

  if (displays.size() == 1) {
    displays[0].single_display = true;
  }

  return displays;
}

}  // namespace flutter
