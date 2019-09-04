// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/public/flutter_windows.h"

#include <assert.h>

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <iostream>
#include <vector>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/plugin_registrar.h"
#include "flutter/shell/platform/common/cpp/incoming_message_dispatcher.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/key_event_handler.h"
#include "flutter/shell/platform/windows/keyboard_hook_handler.h"
#include "flutter/shell/platform/windows/platform_handler.h"
#include "flutter/shell/platform/windows/text_input_plugin.h"
#include "flutter/shell/platform/windows/win32_flutter_window.h"
#include "flutter/shell/platform/windows/window_state.h"

static_assert(FLUTTER_ENGINE_VERSION == 1, "");

// Spins up an instance of the Flutter Engine.
//
// This function launches the Flutter Engine in a background thread, supplying
// the necessary callbacks for rendering within a win32window (if one is
// provided).
//
// Returns a caller-owned pointer to the engine.
static FLUTTER_API_SYMBOL(FlutterEngine)
    RunFlutterEngine(flutter::Win32FlutterWindow* window,
                     const char* assets_path,
                     const char* icu_data_path,
                     const char** arguments,
                     size_t arguments_count) {
  // FlutterProjectArgs is expecting a full argv, so when processing it for
  // flags the first item is treated as the executable and ignored. Add a dummy
  // value so that all provided arguments are used.
  std::vector<const char*> argv = {"placeholder"};
  if (arguments_count > 0) {
    argv.insert(argv.end(), &arguments[0], &arguments[arguments_count]);
  }

  window->CreateRenderSurface();

  FlutterRendererConfig config = {};

  // Provide the necessary callbacks for rendering within a win32 child window.
  config.type = kOpenGL;
  config.open_gl.struct_size = sizeof(config.open_gl);
  config.open_gl.make_current = [](void* user_data) -> bool {
    auto host = static_cast<flutter::Win32FlutterWindow*>(user_data);
    return host->MakeCurrent();
  };
  config.open_gl.clear_current = [](void* user_data) -> bool {
    auto host = static_cast<flutter::Win32FlutterWindow*>(user_data);
    return host->ClearContext();
  };
  config.open_gl.present = [](void* user_data) -> bool {
    auto host = static_cast<flutter::Win32FlutterWindow*>(user_data);
    return host->SwapBuffers();
  };
  config.open_gl.fbo_callback = [](void* user_data) -> uint32_t { return 0; };
  config.open_gl.gl_proc_resolver = [](void* user_data,
                                       const char* what) -> void* {
    return eglGetProcAddress(what);
  };
  config.open_gl.make_resource_current = [](void* user_data) -> bool {
    auto host = static_cast<flutter::Win32FlutterWindow*>(user_data);
    return host->MakeResourceCurrent();
  };

  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = assets_path;
  args.icu_data_path = icu_data_path;
  args.command_line_argc = static_cast<int>(argv.size());
  args.command_line_argv = &argv[0];
  args.platform_message_callback =
      [](const FlutterPlatformMessage* engine_message,
         void* user_data) -> void {
    auto window = reinterpret_cast<flutter::Win32FlutterWindow*>(user_data);
    return window->HandlePlatformMessage(engine_message);
  };

  // args.custom_task_runners = custom_task_runners; TODO

  FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
  auto result =
      FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config, &args, window, &engine);
  if (result != kSuccess || engine == nullptr) {
    std::cerr << "Failed to start Flutter engine: error " << result
              << std::endl;
    return nullptr;
  }

  return engine;
}

FlutterDesktopViewControllerRef FlutterDesktopCreateViewController(
    int initial_width,
    int initial_height,
    const char* assets_path,
    const char* icu_data_path,
    const char** arguments,
    size_t argument_count) {
  FlutterDesktopViewControllerRef state =
      flutter::Win32FlutterWindow::CreateWin32FlutterWindow(initial_width,
                                                            initial_height);

  auto engine = RunFlutterEngine(state->view.get(), assets_path, icu_data_path,
                                 arguments, argument_count);

  if (engine == nullptr) {
    return nullptr;
  }

  state->view->SetState(engine);
  state->engine = engine;

  return state;
}

void FlutterDesktopProcessMessages() {
  __FlutterEngineFlushPendingTasksNow();
}

HWND FlutterDesktopGetHWND(FlutterDesktopViewControllerRef controller) {
  return (controller)->view->GetWindowHandle();
}

void FlutterDesktopDestroyViewController(
    FlutterDesktopViewControllerRef controller) {
  FlutterEngineShutdown(controller->engine);
  delete controller;
}

FlutterDesktopPluginRegistrarRef FlutterDesktopGetPluginRegistrar(
    FlutterDesktopViewControllerRef controller,
    const char* plugin_name) {
  // Currently, one registrar acts as the registrar for all plugins, so the
  // name is ignored. It is part of the API to reduce churn in the future when
  // aligning more closely with the Flutter registrar system.

  return controller->view->GetRegistrar();
}

FlutterDesktopEngineRef FlutterDesktopRunEngine(const char* assets_path,
                                                const char* icu_data_path,
                                                const char** arguments,
                                                size_t argument_count) {
  auto engine = RunFlutterEngine(nullptr, assets_path, icu_data_path, arguments,
                                 argument_count);
  if (engine == nullptr) {
    return nullptr;
  }
  auto engine_state = new FlutterDesktopEngineState();
  engine_state->engine = engine;
  return engine_state;
}

bool FlutterDesktopShutDownEngine(FlutterDesktopEngineRef engine_ref) {
  std::cout << "Shutting down flutter engine process." << std::endl;
  auto result = FlutterEngineShutdown(engine_ref->engine);
  delete engine_ref;
  return (result == kSuccess);
}

void FlutterDesktopRegistrarEnableInputBlocking(
    FlutterDesktopPluginRegistrarRef registrar,
    const char* channel) {
  registrar->messenger->dispatcher->EnableInputBlockingForChannel(channel);
}

FlutterDesktopMessengerRef FlutterDesktopRegistrarGetMessenger(
    FlutterDesktopPluginRegistrarRef registrar) {
  return registrar->messenger.get();
}

bool FlutterDesktopMessengerSendWithReply(FlutterDesktopMessengerRef messenger,
                                          const char* channel,
                                          const uint8_t* message,
                                          const size_t message_size,
                                          const FlutterDesktopBinaryReply reply,
                                          void* user_data) {
  FlutterPlatformMessageResponseHandle* response_handle = nullptr;
  if (reply != nullptr && user_data != nullptr) {
    FlutterEngineResult result = FlutterPlatformMessageCreateResponseHandle(
        messenger->engine, reply, user_data, &response_handle);
    if (result != kSuccess) {
      std::cout << "Failed to create response handle\n";
      return false;
    }
  }

  FlutterPlatformMessage platform_message = {
      sizeof(FlutterPlatformMessage),
      channel,
      message,
      message_size,
      response_handle,
  };

  FlutterEngineResult message_result =
      FlutterEngineSendPlatformMessage(messenger->engine, &platform_message);

  if (response_handle != nullptr) {
    FlutterPlatformMessageReleaseResponseHandle(messenger->engine,
                                                response_handle);
  }

  return message_result == kSuccess;
}

bool FlutterDesktopMessengerSend(FlutterDesktopMessengerRef messenger,
                                 const char* channel,
                                 const uint8_t* message,
                                 const size_t message_size) {
  return FlutterDesktopMessengerSendWithReply(messenger, channel, message,
                                              message_size, nullptr, nullptr);
}

void FlutterDesktopMessengerSendResponse(
    FlutterDesktopMessengerRef messenger,
    const FlutterDesktopMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length) {
  FlutterEngineSendPlatformMessageResponse(messenger->engine, handle, data,
                                           data_length);
}

void FlutterDesktopMessengerSetCallback(FlutterDesktopMessengerRef messenger,
                                        const char* channel,
                                        FlutterDesktopMessageCallback callback,
                                        void* user_data) {
  messenger->dispatcher->SetMessageCallback(channel, callback, user_data);
}
