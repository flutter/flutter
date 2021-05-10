// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/public/flutter_windows.h"

#include <io.h>

#include <algorithm>
#include <cassert>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <memory>
#include <vector>

#include "flutter/shell/platform/windows/dpi_utils_win32.h"
#include "flutter/shell/platform/windows/flutter_window_win32.h"

// Returns the engine corresponding to the given opaque API handle.
static flutter::FlutterWindowsEngine* EngineFromHandle(
    FlutterDesktopEngineRef ref) {
  return reinterpret_cast<flutter::FlutterWindowsEngine*>(ref);
}

FlutterDesktopViewControllerRef FlutterDesktopViewControllerCreate(
    int width,
    int height,
    FlutterDesktopEngineRef engine) {
  std::unique_ptr<flutter::WindowBindingHandler> window_wrapper =
      std::make_unique<flutter::FlutterWindowWin32>(width, height);

  auto state = std::make_unique<FlutterDesktopViewControllerState>();
  state->view =
      std::make_unique<flutter::FlutterWindowsView>(std::move(window_wrapper));
  // Take ownership of the engine, starting it if necessary.
  state->view->SetEngine(
      std::unique_ptr<flutter::FlutterWindowsEngine>(EngineFromHandle(engine)));
  state->view->CreateRenderSurface();
  if (!state->view->GetEngine()->running()) {
    if (!state->view->GetEngine()->RunWithEntrypoint(nullptr)) {
      return nullptr;
    }
  }

  // Must happen after engine is running.
  state->view->SendInitialBounds();
  return state.release();
}

bool FlutterDesktopViewControllerHandleTopLevelWindowProc(
    FlutterDesktopViewControllerRef controller,
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam,
    LRESULT* result) {
  std::optional<LRESULT> delegate_result =
      controller->view->GetEngine()
          ->window_proc_delegate_manager()
          ->OnTopLevelWindowProc(hwnd, message, wparam, lparam);
  if (delegate_result) {
    *result = *delegate_result;
  }
  return delegate_result.has_value();
}

uint64_t FlutterDesktopEngineProcessMessages(FlutterDesktopEngineRef engine) {
  return std::chrono::nanoseconds::max().count();
}

void FlutterDesktopPluginRegistrarRegisterTopLevelWindowProcDelegate(
    FlutterDesktopPluginRegistrarRef registrar,
    FlutterDesktopWindowProcCallback delegate,
    void* user_data) {
  registrar->engine->window_proc_delegate_manager()
      ->RegisterTopLevelWindowProcDelegate(delegate, user_data);
}

void FlutterDesktopPluginRegistrarUnregisterTopLevelWindowProcDelegate(
    FlutterDesktopPluginRegistrarRef registrar,
    FlutterDesktopWindowProcCallback delegate) {
  registrar->engine->window_proc_delegate_manager()
      ->UnregisterTopLevelWindowProcDelegate(delegate);
}

UINT FlutterDesktopGetDpiForHWND(HWND hwnd) {
  return flutter::GetDpiForHWND(hwnd);
}

UINT FlutterDesktopGetDpiForMonitor(HMONITOR monitor) {
  return flutter::GetDpiForMonitor(monitor);
}
