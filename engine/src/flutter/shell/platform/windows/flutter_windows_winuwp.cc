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
#include <sstream>
#include <vector>

#include <winrt/Windows.ApplicationModel.Activation.h>
#include "winrt/Windows.ApplicationModel.Core.h"

#include "flutter/shell/platform/common/client_wrapper/include/flutter/plugin_registrar.h"
#include "flutter/shell/platform/common/incoming_message_dispatcher.h"
#include "flutter/shell/platform/windows/flutter_window_winuwp.h"  // nogncheck

// Returns the engine corresponding to the given opaque API handle.
static flutter::FlutterWindowsEngine* EngineFromHandle(
    FlutterDesktopEngineRef ref) {
  return reinterpret_cast<flutter::FlutterWindowsEngine*>(ref);
}

// Returns a list of discrete arguments splitting the input using a ",".
std::vector<std::string> SplitCommaSeparatedString(const std::string& s) {
  std::vector<std::string> components;
  std::istringstream stream(s);
  std::string component;
  while (getline(stream, component, ',')) {
    components.push_back(component);
  }
  return (components);
}

FlutterDesktopViewControllerRef
FlutterDesktopViewControllerCreateFromCoreApplicationView(
    ABI::Windows::ApplicationModel::Core::CoreApplicationView* application_view,
    ABI::Windows::ApplicationModel::Activation::IActivatedEventArgs* args,
    FlutterDesktopEngineRef engine) {
  std::unique_ptr<flutter::WindowBindingHandler> window_wrapper =
      std::make_unique<flutter::FlutterWindowWinUWP>(application_view);

  auto state = std::make_unique<FlutterDesktopViewControllerState>();
  state->view =
      std::make_unique<flutter::FlutterWindowsView>(std::move(window_wrapper));
  // Take ownership of the engine, starting it if necessary.
  state->view->SetEngine(
      std::unique_ptr<flutter::FlutterWindowsEngine>(EngineFromHandle(engine)));
  state->view->CreateRenderSurface();

  winrt::Windows::ApplicationModel::Activation::IActivatedEventArgs
      arg_interface{nullptr};
  winrt::copy_from_abi(arg_interface, args);

  std::vector<std::string> engine_switches;
  winrt::Windows::ApplicationModel::Activation::LaunchActivatedEventArgs launch{
      nullptr};
  if (arg_interface.Kind() ==
      winrt::Windows::ApplicationModel::Activation::ActivationKind::Launch) {
    launch = arg_interface.as<winrt::Windows::ApplicationModel::Activation::
                                  LaunchActivatedEventArgs>();
    if (launch != nullptr) {
      std::string launchargs = winrt::to_string(launch.Arguments());
      if (!launchargs.empty()) {
        engine_switches = SplitCommaSeparatedString(launchargs);
      }
    }
  }

  state->view->GetEngine()->SetSwitches(engine_switches);

  if (!state->view->GetEngine()->running()) {
    if (!state->view->GetEngine()->RunWithEntrypoint(nullptr)) {
      return nullptr;
    }
  }

  // Must happen after engine is running.
  state->view->SendInitialBounds();
  return state.release();
}
