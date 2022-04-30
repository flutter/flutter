// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_ENGINE_H_

#include <chrono>
#include <map>
#include <memory>
#include <optional>
#include <vector>

#include "flutter/shell/platform/common/accessibility_bridge.h"
#include "flutter/shell/platform/common/client_wrapper/binary_messenger_impl.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/basic_message_channel.h"
#include "flutter/shell/platform/common/incoming_message_dispatcher.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/angle_surface_manager.h"
#include "flutter/shell/platform/windows/flutter_project_bundle.h"
#include "flutter/shell/platform/windows/flutter_windows_texture_registrar.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "flutter/shell/platform/windows/settings_plugin.h"
#include "flutter/shell/platform/windows/task_runner.h"
#include "flutter/shell/platform/windows/window_proc_delegate_manager_win32.h"
#include "flutter/shell/platform/windows/window_state.h"
#include "third_party/rapidjson/include/rapidjson/document.h"

namespace flutter {

class FlutterWindowsView;

// Update the thread priority for the Windows engine.
static void WindowsPlatformThreadPrioritySetter(
    FlutterThreadPriority priority) {
  // TODO(99502): Add support for tracing to the windows embedding so we can
  // mark thread priorities and success/failure.
  switch (priority) {
    case FlutterThreadPriority::kBackground: {
      SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_BELOW_NORMAL);
      break;
    }
    case FlutterThreadPriority::kDisplay: {
      SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL);
      break;
    }
    case FlutterThreadPriority::kRaster: {
      SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL);
      break;
    }
    case FlutterThreadPriority::kNormal: {
      // For normal or default priority we do not need to set the priority
      // class.
      break;
    }
  }
}

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

  // Registers |callback| to be called when the plugin registrar is destroyed.
  void AddPluginRegistrarDestructionCallback(
      FlutterDesktopOnPluginRegistrarDestroyed callback,
      FlutterDesktopPluginRegistrarRef registrar);

  // Sets switches member to the given switches.
  void SetSwitches(const std::vector<std::string>& switches);

  FlutterDesktopMessengerRef messenger() { return messenger_.get(); }

  IncomingMessageDispatcher* message_dispatcher() {
    return message_dispatcher_.get();
  }

  TaskRunner* task_runner() { return task_runner_.get(); }

  FlutterWindowsTextureRegistrar* texture_registrar() {
    return texture_registrar_.get();
  }

  // The ANGLE surface manager object. If this is nullptr, then we are
  // rendering using software instead of OpenGL.
  AngleSurfaceManager* surface_manager() { return surface_manager_.get(); }

  std::weak_ptr<AccessibilityBridge> accessibility_bridge() {
    return accessibility_bridge_;
  }

  WindowProcDelegateManagerWin32* window_proc_delegate_manager() {
    return window_proc_delegate_manager_.get();
  }

  // Informs the engine that the window metrics have changed.
  void SendWindowMetricsEvent(const FlutterWindowMetricsEvent& event);

  // Informs the engine of an incoming pointer event.
  void SendPointerEvent(const FlutterPointerEvent& event);

  // Informs the engine of an incoming key event.
  void SendKeyEvent(const FlutterKeyEvent& event,
                    FlutterKeyEventCallback callback,
                    void* user_data);

  // Sends the given message to the engine, calling |reply| with |user_data|
  // when a response is received from the engine if they are non-null.
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

  // Attempts to register the texture with the given |texture_id|.
  bool RegisterExternalTexture(int64_t texture_id);

  // Attempts to unregister the texture with the given |texture_id|.
  bool UnregisterExternalTexture(int64_t texture_id);

  // Notifies the engine about a new frame being available for the
  // given |texture_id|.
  bool MarkExternalTextureFrameAvailable(int64_t texture_id);

  // Invoke on the embedder's vsync callback to schedule a frame.
  void OnVsync(intptr_t baton);

  // Dispatches a semantics action to the specified semantics node.
  bool DispatchSemanticsAction(uint64_t id,
                               FlutterSemanticsAction action,
                               fml::MallocMapping data);

  // Informs the engine that the semantics enabled state has changed.
  void UpdateSemanticsEnabled(bool enabled);

  // Returns true if the semantics tree is enabled.
  bool semantics_enabled() const { return semantics_enabled_; }

  // Returns the native accessibility node with the given id.
  gfx::NativeViewAccessible GetNativeAccessibleFromId(AccessibilityNodeId id);

 private:
  // Allows swapping out embedder_api_ calls in tests.
  friend class EngineModifier;

  // Sends system locales to the engine.
  //
  // Should be called just after the engine is run, and after any relevant
  // system changes.
  void SendSystemLocales();

  // The handle to the embedder.h engine instance.
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;

  FlutterEngineProcTable embedder_api_ = {};

  std::unique_ptr<FlutterProjectBundle> project_;

  // AOT data, if any.
  UniqueAotDataPtr aot_data_;

  // The view displaying the content running in this engine, if any.
  FlutterWindowsView* view_ = nullptr;

  // Task runner for tasks posted from the engine.
  std::unique_ptr<TaskRunner> task_runner_;

  // The plugin messenger handle given to API clients.
  std::unique_ptr<FlutterDesktopMessenger> messenger_;

  // A wrapper around messenger_ for interacting with client_wrapper-level APIs.
  std::unique_ptr<BinaryMessengerImpl> messenger_wrapper_;

  // Message dispatch manager for messages from engine_.
  std::unique_ptr<IncomingMessageDispatcher> message_dispatcher_;

  // The plugin registrar handle given to API clients.
  std::unique_ptr<FlutterDesktopPluginRegistrar> plugin_registrar_;

  // The texture registrar.
  std::unique_ptr<FlutterWindowsTextureRegistrar> texture_registrar_;

  // Resolved OpenGL functions used by external texture implementations.
  GlProcs gl_procs_ = {};

  // An object used for intializing Angle and creating / destroying render
  // surfaces. Surface creation functionality requires a valid render_target.
  // May be nullptr if ANGLE failed to initialize.
  std::unique_ptr<AngleSurfaceManager> surface_manager_;

  // The settings plugin.
  std::unique_ptr<SettingsPlugin> settings_plugin_;

  // Callbacks to be called when the engine (and thus the plugin registrar) is
  // being destroyed.
  std::map<FlutterDesktopOnPluginRegistrarDestroyed,
           FlutterDesktopPluginRegistrarRef>
      plugin_registrar_destruction_callbacks_;

  // The approximate time between vblank events.
  std::chrono::nanoseconds FrameInterval();

  // The start time used to align frames.
  std::chrono::nanoseconds start_time_ = std::chrono::nanoseconds::zero();

  // An override of the frame interval used by EngineModifier for testing.
  std::optional<std::chrono::nanoseconds> frame_interval_override_ =
      std::nullopt;

  bool semantics_enabled_ = false;

  std::shared_ptr<AccessibilityBridge> accessibility_bridge_;

  // The manager for WindowProc delegate registration and callbacks.
  std::unique_ptr<WindowProcDelegateManagerWin32> window_proc_delegate_manager_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_ENGINE_H_
