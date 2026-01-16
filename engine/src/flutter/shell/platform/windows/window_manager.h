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

// Specifies a preferred content size for the window.
struct WindowSizeRequest {
  bool has_preferred_view_size = false;
  double preferred_view_width;
  double preferred_view_height;
};

// Specifies a preferred constraint on the window.
struct WindowConstraints {
  bool has_view_constraints = false;
  double view_min_width;
  double view_min_height;
  double view_max_width;
  double view_max_height;
};

// Coordinates are in physical pixels.
struct WindowRect {
  int32_t left;
  int32_t top;
  int32_t width;
  int32_t height;
};

// Sizes are in physical pixels.
struct WindowSize {
  int32_t width;
  int32_t height;
};

// Sent by the framework to request a new window be created.
struct RegularWindowCreationRequest {
  WindowSizeRequest preferred_size;
  WindowConstraints preferred_constraints;
  LPCWSTR title;
};

struct DialogWindowCreationRequest {
  WindowSizeRequest preferred_size;
  WindowConstraints preferred_constraints;
  LPCWSTR title;
  HWND parent_or_null;
};

typedef WindowRect* (*GetWindowPositionCallback)(const WindowSize& child_size,
                                                 const WindowRect& parent_rect,
                                                 const WindowRect& output_rect);

struct TooltipWindowCreationRequest {
  WindowConstraints preferred_constraints;
  bool is_sized_to_content;
  HWND parent;
  GetWindowPositionCallback get_position_callback;
};

struct WindowsMessage {
  FlutterViewId view_id;
  HWND hwnd;
  UINT message;
  WPARAM wParam;
  LPARAM lParam;
  LRESULT result;
  bool handled;
};

struct WindowingInitRequest {
  void (*on_message)(WindowsMessage*);
};

// Returned from |InternalFlutterWindows_WindowManager_GetWindowContentSize|.
// This represents the current content size of the window.
struct ActualWindowSize {
  double width;
  double height;
};

struct FullscreenRequest {
  bool fullscreen;
  bool has_display_id;
  FlutterEngineDisplayId display_id;
};

// A manager class for managing |HostWindow| instances.
// A unique instance of this class is owned by |FlutterWindowsEngine|.
class WindowManager {
 public:
  explicit WindowManager(FlutterWindowsEngine* engine);
  virtual ~WindowManager() = default;

  void Initialize(const WindowingInitRequest* request);

  FlutterViewId CreateRegularWindow(
      const RegularWindowCreationRequest* request);

  FlutterViewId CreateDialogWindow(const DialogWindowCreationRequest* request);

  FlutterViewId CreateTooltipWindow(
      const TooltipWindowCreationRequest* request);

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
FlutterViewId InternalFlutterWindows_WindowManager_CreateRegularWindow(
    int64_t engine_id,
    const flutter::RegularWindowCreationRequest* request);

FLUTTER_EXPORT
FlutterViewId InternalFlutterWindows_WindowManager_CreateDialogWindow(
    int64_t engine_id,
    const flutter::DialogWindowCreationRequest* request);

FLUTTER_EXPORT
FlutterViewId InternalFlutterWindows_WindowManager_CreateTooltipWindow(
    int64_t engine_id,
    const flutter::TooltipWindowCreationRequest* request);

// Retrives the HWND associated with this |engine_id| and |view_id|. Returns
// NULL if the HWND cannot be found
FLUTTER_EXPORT
HWND InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
    int64_t engine_id,
    FlutterViewId view_id);

FLUTTER_EXPORT
flutter::ActualWindowSize
InternalFlutterWindows_WindowManager_GetWindowContentSize(HWND hwnd);

FLUTTER_EXPORT
void InternalFlutterWindows_WindowManager_SetWindowSize(
    HWND hwnd,
    const flutter::WindowSizeRequest* size);

FLUTTER_EXPORT
void InternalFlutterWindows_WindowManager_SetWindowConstraints(
    HWND hwnd,
    const flutter::WindowConstraints* constraints);

FLUTTER_EXPORT
void InternalFlutterWindows_WindowManager_SetFullscreen(
    HWND hwnd,
    const flutter::FullscreenRequest* request);

// Invoked by the framework when the host window receives WM_DESTROY.
FLUTTER_EXPORT
void InternalFlutterWindows_WindowManager_OnDestroyWindow(HWND hwnd);

FLUTTER_EXPORT
bool InternalFlutterWindows_WindowManager_GetFullscreen(HWND hwnd);

FLUTTER_EXPORT
void InternalFlutterWindows_WindowManager_UpdateTooltipPosition(HWND hwnd);
}

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_MANAGER_H_
