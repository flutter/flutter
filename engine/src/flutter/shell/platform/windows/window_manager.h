// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_MANAGER_H_

#include <windows.h>
#include <functional>
#include <optional>
#include <unordered_map>
#include <vector>

#include "flutter/shell/platform/common/public/flutter_export.h"

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/common/isolate_scope.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

class FlutterWindowsEngine;
class HostWindow;
struct WindowingInitRequest;

struct WindowsMessage {
  FlutterViewId view_id;
  HWND hwnd;
  UINT message;
  WPARAM wParam;
  LPARAM lParam;
  LRESULT result;
  bool handled;
};

struct WindowSizing {
  bool has_preferred_view_size;
  double preferred_view_width;
  double preferred_view_height;
  bool has_view_constraints;
  double view_min_width;
  double view_min_height;
  double view_max_width;
  double view_max_height;
};

struct WindowingInitRequest {
  void (*on_message)(WindowsMessage*);
};

struct WindowCreationRequest {
  WindowSizing content_size;
};

// A manager class for managing |HostWindow| instances.
// A unique instance of this class is owned by |FlutterWindowsEngine|.
class WindowManager {
 public:
  explicit WindowManager(FlutterWindowsEngine* engine);
  virtual ~WindowManager() = default;

  void Initialize(const WindowingInitRequest* request);

  bool HasTopLevelWindows() const;

  FlutterViewId CreateRegularWindow(const WindowCreationRequest* request);

  // Message handler called by |HostWindow::WndProc| to process window
  // messages before delegating them to the host window. This allows the
  // manager to process messages that affect the state of other host windows.
  std::optional<LRESULT> HandleMessage(HWND hwnd,
                                       UINT message,
                                       WPARAM wparam,
                                       LPARAM lparam);

  void OnEngineShutdown();

 private:
  // The Flutter engine that owns this manager.
  FlutterWindowsEngine* const engine_;

  // Callback that relays windows messages to the isolate. Set
  // during Initialize().
  std::function<void(WindowsMessage*)> on_message_;

  // Isolate that runs the Dart code. Set during Initialize().
  std::optional<Isolate> isolate_;

  // A map of active windows. Used to destroy remaining windows on engine
  // shutdown.
  std::unordered_map<HWND, std::unique_ptr<HostWindow>> active_windows_;

  FML_DISALLOW_COPY_AND_ASSIGN(WindowManager);
};

}  // namespace flutter

extern "C" {

FLUTTER_EXPORT
void InternalFlutterWindows_WindowManager_Initialize(
    int64_t engine_id,
    const flutter::WindowingInitRequest* request);

FLUTTER_EXPORT
bool InternalFlutterWindows_WindowManager_HasTopLevelWindows(int64_t engine_id);

FLUTTER_EXPORT
FlutterViewId InternalFlutterWindows_WindowManager_CreateRegularWindow(
    int64_t engine_id,
    const flutter::WindowCreationRequest* request);

// Retrives the HWND associated with this |engine_id| and |view_id|. Returns
// NULL if the HWND cannot be found
FLUTTER_EXPORT
HWND InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
    int64_t engine_id,
    FlutterViewId view_id);

struct FlutterWindowSize {
  double width;
  double height;
};

FLUTTER_EXPORT
FlutterWindowSize InternalFlutterWindows_WindowManager_GetWindowContentSize(
    HWND hwnd);

FLUTTER_EXPORT
void InternalFlutterWindows_WindowManager_SetWindowContentSize(
    HWND hwnd,
    const flutter::WindowSizing* size);
}

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_MANAGER_H_
