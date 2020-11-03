// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_ENGINE_H_

#include <map>
#include <memory>
#include <optional>
#include <vector>

#include "flutter/shell/platform/common/cpp/incoming_message_dispatcher.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/flutter_project_bundle.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "flutter/shell/platform/windows/win32_task_runner.h"
#include "flutter/shell/platform/windows/win32_window_proc_delegate_manager.h"
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

  // Sets |callback| to be called when the plugin registrar is destroyed.
  void SetPluginRegistrarDestructionCallback(
      FlutterDesktopOnPluginRegistrarDestroyed callback);

  FlutterDesktopMessengerRef messenger() { return messenger_.get(); }

  IncomingMessageDispatcher* message_dispatcher() {
    return message_dispatcher_.get();
  }

  Win32TaskRunner* task_runner() { return task_runner_.get(); }

  Win32WindowProcDelegateManager* window_proc_delegate_manager() {
    return window_proc_delegate_manager_.get();
  }

  // Informs the engine that the window metrics have changed.
  void SendWindowMetricsEvent(const FlutterWindowMetricsEvent& event);

  // Informs the engine of an incoming pointer event.
  void SendPointerEvent(const FlutterPointerEvent& event);

  // Sends the given message to the engine, calling |reply| with |user_data|
  // when a reponse is received from the engine if they are non-null.
  bool SendPlatformMessage(const char* channel,
                           const uint8_t* message,
                           const size_t message_size,
                           const FlutterDesktopBinaryReply reply,
                           void* user_data);

  // Sends the given data as the response to an earlier platform message.
  void SendPlatformMessageResponse(
      const FlutterDesktopMessageResponseHandle* handle,
      const uint8_t* data,
      size_t data_length);

  // Callback passed to Flutter engine for notifying window of platform
  // messages.
  void HandlePlatformMessage(const FlutterPlatformMessage*);

  // Informs the engine that the system font list has changed.
  void ReloadSystemFonts();

 private:
  // Allows swapping out embedder_api_ calls in tests.
  friend class EngineEmbedderApiModifier;

  // Sends system settings (e.g., locale) to the engine.
  //
  // Should be called just after the engine is run, and after any relevant
  // system changes.
  void SendSystemSettings();

  // The handle to the embedder.h engine instance.
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;

  FlutterEngineProcTable embedder_api_ = {};

  std::unique_ptr<FlutterProjectBundle> project_;

  // AOT data, if any.
  UniqueAotDataPtr aot_data_;

  // The view displaying the content running in this engine, if any.
  FlutterWindowsView* view_ = nullptr;

  // Task runner for tasks posted from the engine.
  std::unique_ptr<Win32TaskRunner> task_runner_;

  // The plugin messenger handle given to API clients.
  std::unique_ptr<FlutterDesktopMessenger> messenger_;

  // Message dispatch manager for messages from engine_.
  std::unique_ptr<IncomingMessageDispatcher> message_dispatcher_;

  // The plugin registrar handle given to API clients.
  std::unique_ptr<FlutterDesktopPluginRegistrar> plugin_registrar_;

  // A callback to be called when the engine (and thus the plugin registrar)
  // is being destroyed.
  FlutterDesktopOnPluginRegistrarDestroyed
      plugin_registrar_destruction_callback_;

  // The manager for WindowProc delegate registration and callbacks.
  std::unique_ptr<Win32WindowProcDelegateManager> window_proc_delegate_manager_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_ENGINE_H_
