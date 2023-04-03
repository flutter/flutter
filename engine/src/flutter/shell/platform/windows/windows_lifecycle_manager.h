// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_LIFECYCLE_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_LIFECYCLE_MANAGER_H_

#include <Windows.h>

#include <cstdint>
#include <map>
#include <optional>

namespace flutter {

class FlutterWindowsEngine;

/// A manager for lifecycle events of the top-level window.
///
/// Currently handles the following events:
/// WM_CLOSE
class WindowsLifecycleManager {
 public:
  WindowsLifecycleManager(FlutterWindowsEngine* engine);
  virtual ~WindowsLifecycleManager();

  // Called when the engine is notified it should quit, e.g. by an application
  // call to `exitApplication`. When window is std::nullopt, this quits the
  // application. Otherwise, it holds the HWND of the window that initiated the
  // request, and exit_code is unused.
  virtual void Quit(std::optional<HWND> window,
                    std::optional<WPARAM> wparam,
                    std::optional<LPARAM> lparam,
                    UINT exit_code);

  // Intercept top level window messages, only paying attention to WM_CLOSE.
  bool WindowProc(HWND hwnd, UINT msg, WPARAM w, LPARAM l, LRESULT* result);

 protected:
  // Check the number of top-level windows associated with this process, and
  // return true only if there are 1 or fewer.
  virtual bool IsLastWindowOfProcess();

  virtual void DispatchMessage(HWND window,
                               UINT msg,
                               WPARAM wparam,
                               LPARAM lparam);

 private:
  FlutterWindowsEngine* engine_;

  std::map<std::tuple<HWND, WPARAM, LPARAM>, int> sent_close_messages_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_LIFECYCLE_MANAGER_H_
