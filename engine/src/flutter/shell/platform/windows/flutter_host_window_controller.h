// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_HOST_WINDOW_CONTROLLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_HOST_WINDOW_CONTROLLER_H_

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
  int64_t view_id;
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

// A controller class for managing |FlutterHostWindow| instances.
// A unique instance of this class is owned by |FlutterWindowsEngine| and used
// in |WindowingHandler| to handle methods and messages enabling multi-window
// support.
class FlutterHostWindowController {
 public:
  explicit FlutterHostWindowController(FlutterWindowsEngine* engine);
  virtual ~FlutterHostWindowController() = default;

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

  // Gets the engine that owns this controller.
  FlutterWindowsEngine* engine() const;

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

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterHostWindowController);
};

}  // namespace flutter

extern "C" {

FLUTTER_EXPORT
void FlutterWindowingInitialize(int64_t engine_id,
                                const flutter::WindowingInitRequest* request);

FLUTTER_EXPORT
bool FlutterWindowingHasTopLevelWindows(int64_t engine_id);

FLUTTER_EXPORT
int64_t FlutterCreateRegularWindow(
    int64_t engine_id,
    const flutter::WindowCreationRequest* request);

FLUTTER_EXPORT
HWND FlutterGetWindowHandle(int64_t engine_id, FlutterViewId view_id);

struct FlutterWindowSize {
  double width;
  double height;
};

FLUTTER_EXPORT
FlutterWindowSize FlutterGetWindowContentSize(HWND hwnd);

FLUTTER_EXPORT
int64_t FlutterGetWindowState(HWND hwnd);

FLUTTER_EXPORT
void FlutterSetWindowState(HWND hwnd, int64_t state);

FLUTTER_EXPORT
void FlutterSetWindowContentSize(HWND hwnd,
                                 const flutter::FlutterWindowSizing* size);
}

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_HOST_WINDOW_CONTROLLER_H_
