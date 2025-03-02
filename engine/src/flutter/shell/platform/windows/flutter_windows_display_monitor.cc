#include "flutter_windows_display_monitor.h"

#include <utility>
#include <vector>

#include "flutter/shell/platform/windows/dpi_utils.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace flutter {

FlutterWindowsDisplayMonitor::FlutterWindowsDisplayMonitor(
    FlutterWindowsEngine* engine,
    std::shared_ptr<WindowsProcTable> windows_proc_table)
    : engine_(engine), windows_proc_table_(std::move(windows_proc_table)) {
  if (windows_proc_table_ == nullptr) {
    windows_proc_table_ = std::make_shared<WindowsProcTable>();
  }
}

FlutterWindowsDisplayMonitor::~FlutterWindowsDisplayMonitor() {}

void FlutterWindowsDisplayMonitor::UpdateDisplays() {
  std::vector<FlutterEngineDisplay> displays;

  int display_count = windows_proc_table_->GetSystemMetrics(SM_CMONITORS);

  DISPLAY_DEVICE display_device = {0};
  display_device.cb = sizeof(DISPLAY_DEVICE);

  for (int i = 0;
       windows_proc_table_->EnumDisplayDevices(nullptr, i, &display_device, 0);
       i++) {
    // Skip displays that are not attached to the desktop
    if ((display_device.StateFlags & DISPLAY_DEVICE_ATTACHED_TO_DESKTOP) == 0) {
      continue;
    }

    DEVMODE device_mode = {0};
    device_mode.dmSize = sizeof(DEVMODE);

    if (windows_proc_table_->EnumDisplaySettings(
            display_device.DeviceName, ENUM_CURRENT_SETTINGS, &device_mode)) {
      FlutterEngineDisplay display = {};
      display.struct_size = sizeof(FlutterEngineDisplay);
      display.display_id = i;

      // Set single_display to true if there's only one display
      display.single_display = (display_count == 1);

      // Get the display refresh rate
      display.refresh_rate =
          static_cast<double>(device_mode.dmDisplayFrequency);

      // Get display dimensions
      display.width = device_mode.dmPelsWidth;
      display.height = device_mode.dmPelsHeight;

      // Get the corresponding monitor handle by using a point in the middle of
      // the display
      POINT center_point = {static_cast<LONG>(device_mode.dmPosition.x +
                                              (device_mode.dmPelsWidth / 2)),
                            static_cast<LONG>(device_mode.dmPosition.y +
                                              (device_mode.dmPelsHeight / 2))};
      HMONITOR monitor = windows_proc_table_->MonitorFromPoint(
          center_point, MONITOR_DEFAULTTONULL);

      // If we couldn't get a monitor, fall back to primary
      if (!monitor) {
        monitor = windows_proc_table_->MonitorFromPoint(
            {0, 0}, MONITOR_DEFAULTTOPRIMARY);
      }

      // Calculate device pixel ratio
      UINT dpi = GetDpiForMonitor(monitor);
      display.device_pixel_ratio = static_cast<double>(dpi) / kDefaultDpi;

      displays.push_back(display);
    }
  }

  if (!displays.empty()) {
    engine_->UpdateDisplay(displays.data(), displays.size());
  }
}

bool FlutterWindowsDisplayMonitor::HandleWindowMessage(HWND hwnd,
                                                       UINT message,
                                                       WPARAM wparam,
                                                       LPARAM lparam,
                                                       LRESULT* result) {
  switch (message) {
    case WM_DISPLAYCHANGE:
    case WM_DPICHANGED:
      UpdateDisplays();
      return true;
    default:
      return false;
  }
}

}  // namespace flutter