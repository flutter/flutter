// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_ENGINE_H_

#include <memory>
#include <vector>

#include "flutter/shell/platform/common/cpp/incoming_message_dispatcher.h"
#include "flutter/shell/platform/windows/flutter_project_bundle.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "flutter/shell/platform/windows/win32_task_runner.h"
#include "flutter/shell/platform/windows/window_state.h"

namespace flutter {

class FlutterWindowsView;

// Manages state associated with the underlying FlutterEngine that isn't
// related to its display.
//
// In most cases this will be associated with a FlutterView, but if not will
// run in headless mode.
class FlutterWindowsEngine {
 public:
  // Creates a new Flutter engine object configured to run |project|.
  explicit FlutterWindowsEngine(const FlutterProjectBundle& project);

  virtual ~FlutterWindowsEngine();

  // Prevent copying.
  FlutterWindowsEngine(FlutterWindowsEngine const&) = delete;
  FlutterWindowsEngine& operator=(FlutterWindowsEngine const&) = delete;

  // Starts running the engine with the given entrypoint. If null, defaults to
  // main().
  //
  // Returns false if the engine couldn't be started.
  bool RunWithEntrypoint(const char* entrypoint);

  // Returns true if the engine is currently running.
  bool running() { return engine_ != nullptr; }

  // Stops the engine. This invalidates the pointer returned by engine().
  //
  // Returns false if stopping the engine fails, or if it was not running.
  bool Stop();

  // Sets the view that is displaying this engine's content.
  void SetView(FlutterWindowsView* view);

  // The view displaying this engine's content, if any. This will be null for
  // headless engines.
  FlutterWindowsView* view() { return view_; }

  // Returns the currently configured Plugin Registrar.
  FlutterDesktopPluginRegistrarRef GetRegistrar();

  FLUTTER_API_SYMBOL(FlutterEngine) engine() { return engine_; }

  Win32TaskRunner* task_runner() { return task_runner_.get(); }

  // Callback passed to Flutter engine for notifying window of platform
  // messages.
  void HandlePlatformMessage(const FlutterPlatformMessage*);

 private:
  // The handle to the embedder.h engine instance.
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;

  std::unique_ptr<FlutterProjectBundle> project_;

  // AOT data, if any.
  UniqueAotDataPtr aot_data_;

  // The view displaying the content running in this engine, if any.
  FlutterWindowsView* view_ = nullptr;

  // Task runner for tasks posted from the engine.
  std::unique_ptr<Win32TaskRunner> task_runner_;

  // Message dispatch manager for messages from engine_.
  std::unique_ptr<IncomingMessageDispatcher> message_dispatcher_;

  // The plugin registrar handle given to API clients.
  std::unique_ptr<FlutterDesktopPluginRegistrar> plugin_registrar_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_ENGINE_H_
