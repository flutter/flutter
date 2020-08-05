// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/public/flutter_windows.h"

#include <assert.h>
#include <io.h>

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <memory>
#include <vector>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/plugin_registrar.h"
#include "flutter/shell/platform/common/cpp/incoming_message_dispatcher.h"
#include "flutter/shell/platform/common/cpp/path_utils.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/flutter_project_bundle.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/win32_dpi_utils.h"
#include "flutter/shell/platform/windows/win32_flutter_window.h"
#include "flutter/shell/platform/windows/win32_platform_handler.h"
#include "flutter/shell/platform/windows/win32_task_runner.h"
#include "flutter/shell/platform/windows/window_binding_handler.h"
#include "flutter/shell/platform/windows/window_state.h"

static_assert(FLUTTER_ENGINE_VERSION == 1, "");

// Returns the engine corresponding to the given opaque API handle.
static flutter::FlutterWindowsEngine* EngineFromHandle(
    FlutterDesktopEngineRef ref) {
  return reinterpret_cast<flutter::FlutterWindowsEngine*>(ref);
}

// Returns opaque API handle for the given engine instance.
static FlutterDesktopEngineRef HandleForEngine(
    flutter::FlutterWindowsEngine* engine) {
  return reinterpret_cast<FlutterDesktopEngineRef>(engine);
}

FlutterDesktopViewControllerRef FlutterDesktopCreateViewController(
    int width,
    int height,
    const FlutterDesktopEngineProperties& engine_properties) {
  std::unique_ptr<flutter::WindowBindingHandler> window_wrapper =
      std::make_unique<flutter::Win32FlutterWindow>(width, height);

  auto state = std::make_unique<FlutterDesktopViewControllerState>();
  state->view =
      std::make_unique<flutter::FlutterWindowsView>(std::move(window_wrapper));
  state->view->CreateRenderSurface();
  state->view_wrapper = std::make_unique<FlutterDesktopView>();
  state->view_wrapper->view = state->view.get();

  flutter::FlutterProjectBundle project(engine_properties);
  auto engine = std::make_unique<flutter::FlutterWindowsEngine>(project);
  if (!engine) {
    return nullptr;
  }
  state->view->SetEngine(std::move(engine));
  if (!state->view->GetEngine()->RunWithEntrypoint(
          engine_properties.entry_point)) {
    return nullptr;
  }
  return state.release();
}

uint64_t FlutterDesktopProcessMessages(FlutterDesktopEngineRef engine) {
  return EngineFromHandle(engine)->task_runner()->ProcessTasks().count();
}

void FlutterDesktopDestroyViewController(
    FlutterDesktopViewControllerRef controller) {
  delete controller;
}

FlutterDesktopEngineRef FlutterDesktopGetEngine(
    FlutterDesktopViewControllerRef controller) {
  return HandleForEngine(controller->view->GetEngine());
}

FlutterDesktopPluginRegistrarRef FlutterDesktopGetPluginRegistrar(
    FlutterDesktopEngineRef engine,
    const char* plugin_name) {
  // Currently, one registrar acts as the registrar for all plugins, so the
  // name is ignored. It is part of the API to reduce churn in the future when
  // aligning more closely with the Flutter registrar system.

  return EngineFromHandle(engine)->GetRegistrar();
}

FlutterDesktopViewRef FlutterDesktopGetView(
    FlutterDesktopViewControllerRef controller) {
  return controller->view_wrapper.get();
}

HWND FlutterDesktopViewGetHWND(FlutterDesktopViewRef view_ref) {
  return std::get<HWND>(*view_ref->view->GetRenderTarget());
}

UINT FlutterDesktopGetDpiForHWND(HWND hwnd) {
  return flutter::GetDpiForHWND(hwnd);
}

UINT FlutterDesktopGetDpiForMonitor(HMONITOR monitor) {
  return flutter::GetDpiForMonitor(monitor);
}

void FlutterDesktopResyncOutputStreams() {
  FILE* unused;
  if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
    _dup2(_fileno(stdout), 1);
  }
  if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
    _dup2(_fileno(stdout), 2);
  }
  std::ios::sync_with_stdio();
}

FlutterDesktopEngineRef FlutterDesktopRunEngine(
    const FlutterDesktopEngineProperties& engine_properties) {
  flutter::FlutterProjectBundle project(engine_properties);
  auto engine = std::make_unique<flutter::FlutterWindowsEngine>(project);
  if (!engine->RunWithEntrypoint(engine_properties.entry_point)) {
    return nullptr;
  }
  return HandleForEngine(engine.release());
}

bool FlutterDesktopShutDownEngine(FlutterDesktopEngineRef engine_ref) {
  std::cout << "Shutting down flutter engine process." << std::endl;
  flutter::FlutterWindowsEngine* engine = EngineFromHandle(engine_ref);
  bool result = engine->Stop();
  delete engine;
  return result;
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

void FlutterDesktopRegistrarSetDestructionHandler(
    FlutterDesktopPluginRegistrarRef registrar,
    FlutterDesktopOnRegistrarDestroyed callback) {
  registrar->destruction_handler = callback;
}

FlutterDesktopViewRef FlutterDesktopRegistrarGetView(
    FlutterDesktopPluginRegistrarRef registrar) {
  return registrar->view.get();
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
