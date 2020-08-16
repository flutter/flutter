// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOW_STATE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOW_STATE_H_

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/plugin_registrar.h"
#include "flutter/shell/platform/common/cpp/incoming_message_dispatcher.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
struct FlutterWindowsEngine;
struct FlutterWindowsView;
}  // namespace flutter

// Struct for storing state within an instance of the windows native (HWND or
// CoreWindow) Window.
struct FlutterDesktopViewControllerState {
  // The view that backs this state object.
  std::unique_ptr<flutter::FlutterWindowsView> view;

  // The window handle given to API clients.
  std::unique_ptr<FlutterDesktopView> view_wrapper;
};

// Opaque reference for the native windows itself. This is separate from the
// controller so that it can be provided to plugins without giving them access
// to all of the controller-based functionality.
struct FlutterDesktopView {
  // The view that (indirectly) owns this state object.
  flutter::FlutterWindowsView* view = nullptr;
};

// State associated with the plugin registrar.
struct FlutterDesktopPluginRegistrar {
  // The plugin messenger handle given to API clients.
  std::unique_ptr<FlutterDesktopMessenger> messenger;

  // The handle for the view associated with this registrar.
  std::unique_ptr<FlutterDesktopView> view;

  // Callback to be called on registrar destruction.
  FlutterDesktopOnRegistrarDestroyed destruction_handler;
};

// State associated with the messenger used to communicate with the engine.
struct FlutterDesktopMessenger {
  // The Flutter engine this messenger sends outgoing messages to.
  FLUTTER_API_SYMBOL(FlutterEngine) engine;

  // The message dispatcher for handling incoming messages.
  flutter::IncomingMessageDispatcher* dispatcher;
};

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOW_STATE_H_
