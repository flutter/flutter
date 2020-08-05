// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_windows_engine.h"

#include <filesystem>
#include <iostream>

#include "flutter/shell/platform/common/cpp/path_utils.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"

namespace flutter {

namespace {

// Creates and returns a FlutterRendererConfig that renders to the view (if any)
// of a FlutterWindowsEngine, which should be the user_data received by the
// render callbacks.
FlutterRendererConfig GetRendererConfig() {
  FlutterRendererConfig config = {};
  config.type = kOpenGL;
  config.open_gl.struct_size = sizeof(config.open_gl);
  config.open_gl.make_current = [](void* user_data) -> bool {
    auto host = static_cast<FlutterWindowsEngine*>(user_data);
    if (!host->view()) {
      return false;
    }
    return host->view()->MakeCurrent();
  };
  config.open_gl.clear_current = [](void* user_data) -> bool {
    auto host = static_cast<FlutterWindowsEngine*>(user_data);
    if (!host->view()) {
      return false;
    }
    return host->view()->ClearContext();
  };
  config.open_gl.present = [](void* user_data) -> bool {
    auto host = static_cast<FlutterWindowsEngine*>(user_data);
    if (!host->view()) {
      return false;
    }
    return host->view()->SwapBuffers();
  };
  config.open_gl.fbo_callback = [](void* user_data) -> uint32_t { return 0; };
  config.open_gl.gl_proc_resolver = [](void* user_data,
                                       const char* what) -> void* {
    return reinterpret_cast<void*>(eglGetProcAddress(what));
  };
  config.open_gl.make_resource_current = [](void* user_data) -> bool {
    auto host = static_cast<FlutterWindowsEngine*>(user_data);
    if (!host->view()) {
      return false;
    }
    return host->view()->MakeResourceCurrent();
  };
  return config;
}

// Converts a FlutterPlatformMessage to an equivalent FlutterDesktopMessage.
static FlutterDesktopMessage ConvertToDesktopMessage(
    const FlutterPlatformMessage& engine_message) {
  FlutterDesktopMessage message = {};
  message.struct_size = sizeof(message);
  message.channel = engine_message.channel;
  message.message = engine_message.message;
  message.message_size = engine_message.message_size;
  message.response_handle = engine_message.response_handle;
  return message;
}

}  // namespace

FlutterWindowsEngine::FlutterWindowsEngine(const FlutterProjectBundle& project)
    : project_(std::make_unique<FlutterProjectBundle>(project)) {
  task_runner_ = std::make_unique<Win32TaskRunner>(
      GetCurrentThreadId(), [this](const auto* task) {
        if (!engine_) {
          std::cerr << "Cannot post an engine task when engine is not running."
                    << std::endl;
          return;
        }
        if (FlutterEngineRunTask(engine_, task) != kSuccess) {
          std::cerr << "Failed to post an engine task." << std::endl;
        }
      });

  // Set up the structure of the state/handle objects; engine and view paramater
  // will be filled in late.
  auto messenger = std::make_unique<FlutterDesktopMessenger>();
  message_dispatcher_ =
      std::make_unique<IncomingMessageDispatcher>(messenger.get());
  messenger->dispatcher = message_dispatcher_.get();

  plugin_registrar_ = std::make_unique<FlutterDesktopPluginRegistrar>();
  plugin_registrar_->messenger = std::move(messenger);
  plugin_registrar_->view = std::make_unique<FlutterDesktopView>();
}

FlutterWindowsEngine::~FlutterWindowsEngine() {
  Stop();
}

bool FlutterWindowsEngine::RunWithEntrypoint(const char* entrypoint) {
  if (!project_->HasValidPaths()) {
    std::cerr << "Missing or unresolvable paths to assets." << std::endl;
    return false;
  }
  std::string assets_path_string = project_->assets_path().u8string();
  std::string icu_path_string = project_->icu_path().u8string();
  if (FlutterEngineRunsAOTCompiledDartCode()) {
    aot_data_ = project_->LoadAotData();
    if (!aot_data_) {
      std::cerr << "Unable to start engine without AOT data." << std::endl;
      return false;
    }
  }

  // FlutterProjectArgs is expecting a full argv, so when processing it for
  // flags the first item is treated as the executable and ignored. Add a dummy
  // value so that all provided arguments are used.
  std::vector<const char*> argv = {"placeholder"};
  std::transform(
      project_->switches().begin(), project_->switches().end(),
      std::back_inserter(argv),
      [](const std::string& arg) -> const char* { return arg.c_str(); });

  // Configure task runners.
  FlutterTaskRunnerDescription platform_task_runner = {};
  platform_task_runner.struct_size = sizeof(FlutterTaskRunnerDescription);
  platform_task_runner.user_data = task_runner_.get();
  platform_task_runner.runs_task_on_current_thread_callback =
      [](void* user_data) -> bool {
    return static_cast<Win32TaskRunner*>(user_data)->RunsTasksOnCurrentThread();
  };
  platform_task_runner.post_task_callback = [](FlutterTask task,
                                               uint64_t target_time_nanos,
                                               void* user_data) -> void {
    static_cast<Win32TaskRunner*>(user_data)->PostTask(task, target_time_nanos);
  };
  FlutterCustomTaskRunners custom_task_runners = {};
  custom_task_runners.struct_size = sizeof(FlutterCustomTaskRunners);
  custom_task_runners.platform_task_runner = &platform_task_runner;

  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = assets_path_string.c_str();
  args.icu_data_path = icu_path_string.c_str();
  args.command_line_argc = static_cast<int>(argv.size());
  args.command_line_argv = argv.size() > 0 ? argv.data() : nullptr;
  args.platform_message_callback =
      [](const FlutterPlatformMessage* engine_message,
         void* user_data) -> void {
    auto host = static_cast<FlutterWindowsEngine*>(user_data);
    return host->HandlePlatformMessage(engine_message);
  };
  args.custom_task_runners = &custom_task_runners;
  if (aot_data_) {
    args.aot_data = aot_data_.get();
  }
  if (entrypoint) {
    args.custom_dart_entrypoint = entrypoint;
  }

  FlutterRendererConfig renderer_config = GetRendererConfig();

  auto result = FlutterEngineRun(FLUTTER_ENGINE_VERSION, &renderer_config,
                                 &args, this, &engine_);
  if (result != kSuccess || engine_ == nullptr) {
    std::cerr << "Failed to start Flutter engine: error " << result
              << std::endl;
    return false;
  }

  plugin_registrar_->messenger->engine = engine_;
  return true;
}

bool FlutterWindowsEngine::Stop() {
  if (engine_) {
    if (plugin_registrar_ && plugin_registrar_->destruction_handler) {
      plugin_registrar_->destruction_handler(plugin_registrar_.get());
    }
    FlutterEngineResult result = FlutterEngineShutdown(engine_);
    engine_ = nullptr;
    return (result == kSuccess);
  }
  return false;
}

void FlutterWindowsEngine::SetView(FlutterWindowsView* view) {
  view_ = view;
  plugin_registrar_->view->view = view;
}

// Returns the currently configured Plugin Registrar.
FlutterDesktopPluginRegistrarRef FlutterWindowsEngine::GetRegistrar() {
  return plugin_registrar_.get();
}

void FlutterWindowsEngine::HandlePlatformMessage(
    const FlutterPlatformMessage* engine_message) {
  if (engine_message->struct_size != sizeof(FlutterPlatformMessage)) {
    std::cerr << "Invalid message size received. Expected: "
              << sizeof(FlutterPlatformMessage) << " but received "
              << engine_message->struct_size << std::endl;
    return;
  }

  auto message = ConvertToDesktopMessage(*engine_message);

  message_dispatcher_->HandleMessage(
      message, [this] {}, [this] {});
}

}  // namespace flutter
