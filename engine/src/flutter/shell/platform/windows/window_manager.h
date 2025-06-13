// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_MANAGER_H_

#include <windows.h>
#include <optional>
#include <unordered_map>
#include <vector>

#include "flutter/shell/platform/common/public/flutter_export.h"

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/common/isolate_scope.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

class FlutterWindowsEngine;
class FlutterHostWindow;
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

struct FlutterWindowSizing {
  bool has_size;
  double width;
  double height;
  bool has_constraints;
  double min_width;
  double min_height;
  double max_width;
  double max_height;
};

struct WindowingInitRequest {
  void (*on_message)(WindowsMessage*);
};

struct WindowCreationRequest {
  FlutterWindowSizing content_size;
};

// A manager class for managing |FlutterHostWindow| instances.
// A unique instance of this class is owned by |FlutterWindowsEngine|.
class WindowManager {
 public:
  explicit WindowManager(FlutterWindowsEngine* engine);
  virtual ~WindowManager() = default;

  void Initialize(const WindowingInitRequest* request);

  bool HasTopLevelWindows() const;

  FlutterViewId CreateRegularWindow(const WindowCreationRequest* request);

  // Message handler called by |FlutterHostWindow::WndProc| to process window
  // messages before delegating them to the host window. This allows the
  // controller to process messages that affect the state of other host windows.
  std::optional<LRESULT> HandleMessage(HWND hwnd,
                                       UINT message,
                                       WPARAM wparam,
                                       LPARAM lparam);

  void OnEngineShutdown();

 private:
  // The Flutter engine that owns this controller.
  FlutterWindowsEngine* const engine_;

  // Callback that relays windows messages to the isolate. Set
  // during Initialize().
  void (*on_message_)(WindowsMessage*) = nullptr;

  // Isolate that runs the Dart code. Set during Initialize().
  std::optional<Isolate> isolate_;

  // Messages received before the controller is initialized from dart
  // code. Buffered until Initialize() is called.
  std::vector<WindowsMessage> pending_messages_;

  // A map of active windows. Used to destroy remaining windows on engine
  // shutdown.
  std::unordered_map<HWND, std::unique_ptr<FlutterHostWindow>> active_windows_;

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
    const flutter::FlutterWindowSizing* size);
}

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_MANAGER_H_
