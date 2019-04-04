// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/flutter/flutter_window_controller.h"

#include <algorithm>
#include <iostream>

namespace flutter {

FlutterWindowController::FlutterWindowController(
    const std::string& icu_data_path)
    : icu_data_path_(icu_data_path) {
  init_succeeded_ = FlutterDesktopInit();
}

FlutterWindowController::~FlutterWindowController() {
  if (init_succeeded_) {
    FlutterDesktopTerminate();
  }
}

bool FlutterWindowController::CreateWindow(
    int width,
    int height,
    const std::string& title,
    const std::string& assets_path,
    const std::vector<std::string>& arguments) {
  if (!init_succeeded_) {
    std::cerr << "Could not create window; FlutterDesktopInit failed."
              << std::endl;
    return false;
  }

  if (window_) {
    std::cerr << "Only one Flutter window can exist at a time." << std::endl;
    return false;
  }

  std::vector<const char*> engine_arguments;
  std::transform(
      arguments.begin(), arguments.end(), std::back_inserter(engine_arguments),
      [](const std::string& arg) -> const char* { return arg.c_str(); });
  size_t arg_count = engine_arguments.size();

  window_ = FlutterDesktopCreateWindow(
      width, height, title.c_str(), assets_path.c_str(), icu_data_path_.c_str(),
      arg_count > 0 ? &engine_arguments[0] : nullptr, arg_count);
  if (!window_) {
    std::cerr << "Failed to create window." << std::endl;
    return false;
  }
  return true;
}

FlutterDesktopPluginRegistrarRef FlutterWindowController::GetRegistrarForPlugin(
    const std::string& plugin_name) {
  if (!window_) {
    std::cerr << "Cannot get plugin registrar without a window; call "
                 "CreateWindow first."
              << std::endl;
    return nullptr;
  }
  return FlutterDesktopGetPluginRegistrar(window_, plugin_name.c_str());
}

void FlutterWindowController::SetHoverEnabled(bool enabled) {
  FlutterDesktopSetHoverEnabled(window_, enabled);
}

void FlutterWindowController::SetTitle(const std::string& title) {
  FlutterDesktopSetWindowTitle(window_, title.c_str());
}

void FlutterWindowController::SetIcon(uint8_t* pixel_data,
                                      int width,
                                      int height) {
  FlutterDesktopSetWindowIcon(window_, pixel_data, width, height);
}

void FlutterWindowController::RunEventLoop() {
  if (window_) {
    FlutterDesktopRunWindowLoop(window_);
  }
}

}  // namespace flutter
