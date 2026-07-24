// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_MANAGER_H_

#include <windows.h>
#include <memory>
#include <vector>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/windows_proc_table.h"

namespace flutter {

class FlutterWindowsEngine;
class DisplayManagerWin32 {
 public:
  explicit DisplayManagerWin32(FlutterWindowsEngine* engine);
  ~DisplayManagerWin32();

  // Updates the display information and notifies the engine
  void UpdateDisplays();

  // Handles Windows messages related to display changes
  // Returns true if the message was handled and should not be further processed
  bool HandleWindowMessage(HWND hwnd,
                           UINT message,
                           WPARAM wparam,
                           LPARAM lparam,
                           LRESULT* result);

  // Finds the display information associated with the id.
  std::optional<FlutterEngineDisplay> FindById(FlutterEngineDisplayId id);

  // Get the display information for all displays
  std::vector<FlutterEngineDisplay> GetDisplays() const;

  // Converts an HMONITOR handle to a display identifier.
  //
  // HMONITOR values are 32-bit handles that may have the high bit set.
  // Casting one directly to a 64-bit display id sign-extends the value
  // (e.g. 0xE02E16A5 becomes 0xFFFFFFFFE02E16A5), which no longer fits in
  // the signed 64-bit integer that the id is converted to once it crosses
  // into Dart. Truncating to the lower 32 bits keeps the id stable and unique.
  static FlutterEngineDisplayId ToDisplayId(HMONITOR monitor);

 private:
  // Called by EnumDisplayMonitors once for each display.
  static BOOL CALLBACK EnumMonitorCallback(HMONITOR monitor,
                                           HDC hdc,
                                           LPRECT rect,
                                           LPARAM data);

  // Helper method that creates a |FlutterEngineDisplay| from the
  // provided |monitor|.
  std::optional<FlutterEngineDisplay> FromMonitor(HMONITOR monitor) const;

  FlutterWindowsEngine* engine_;

  std::shared_ptr<WindowsProcTable> win32_;
};
}  // namespace flutter
#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_MANAGER_H_
