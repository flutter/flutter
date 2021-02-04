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

#include "flutter/shell/platform/common/client_wrapper/include/flutter/plugin_registrar.h"
#include "flutter/shell/platform/common/incoming_message_dispatcher.h"
#include "flutter/shell/platform/windows/flutter_window_winuwp.h"  // nogncheck

// Returns the engine corresponding to the given opaque API handle.
static flutter::FlutterWindowsEngine* EngineFromHandle(
    FlutterDesktopEngineRef ref) {
  return reinterpret_cast<flutter::FlutterWindowsEngine*>(ref);
}

FlutterDesktopViewControllerRef
FlutterDesktopViewControllerCreateFromCoreWindow(
    ABI::Windows::UI::Core::CoreWindow* window,
    FlutterDesktopEngineRef engine) {
  std::unique_ptr<flutter::WindowBindingHandler> window_wrapper =
      std::make_unique<flutter::FlutterWindowWinUWP>(window);

  auto state = std::make_unique<FlutterDesktopViewControllerState>();
  state->view =
      std::make_unique<flutter::FlutterWindowsView>(std::move(window_wrapper));
  state->view->CreateRenderSurface();

  // Take ownership of the engine, starting it if necessary.
  state->view->SetEngine(
      std::unique_ptr<flutter::FlutterWindowsEngine>(EngineFromHandle(engine)));
  if (!state->view->GetEngine()->running()) {
    if (!state->view->GetEngine()->RunWithEntrypoint(nullptr)) {
      return nullptr;
    }
  }

  // Must happen after engine is running.
  state->view->SendInitialBounds();
  return state.release();
}
