// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_MONITOR_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_MONITOR_H_

#include <windows.h>
#include "shell/platform/windows/windows_proc_table.h"

namespace flutter {

class FlutterWindowsEngine;
class DisplayMonitor {
 public:
  DisplayMonitor(FlutterWindowsEngine* engine,
                 std::shared_ptr<WindowsProcTable> windows_proc_table);
  virtual ~DisplayMonitor();

  // Updates the display information and notifies the engine
  void UpdateDisplays();

  // Handles Windows messages related to display changes
  // Returns true if the message was handled and should not be further processed
  bool HandleWindowMessage(HWND hwnd,
                           UINT message,
                           WPARAM wparam,
                           LPARAM lparam,
                           LRESULT* result);

 private:
  FlutterWindowsEngine* engine_;

  std::shared_ptr<WindowsProcTable> win32_;
};
}  // namespace flutter
#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_MONITOR_H_
