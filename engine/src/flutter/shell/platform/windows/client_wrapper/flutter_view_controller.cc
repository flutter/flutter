// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/flutter/flutter_view_controller.h"

#include <algorithm>
#include <iostream>

namespace flutter {

FlutterViewController::FlutterViewController(int width,
                                             int height,
                                             const DartProject& project) {
  std::vector<const char*> switches;
  std::transform(
      project.engine_switches().begin(), project.engine_switches().end(),
      std::back_inserter(switches),
      [](const std::string& arg) -> const char* { return arg.c_str(); });
  size_t switch_count = switches.size();

  FlutterDesktopEngineProperties properties = {};
  properties.assets_path = project.assets_path().c_str();
  properties.icu_data_path = project.icu_data_path().c_str();
  properties.switches = switch_count > 0 ? switches.data() : nullptr;
  properties.switches_count = switch_count;
  controller_ = FlutterDesktopCreateViewController(width, height, properties);
  if (!controller_) {
    std::cerr << "Failed to create view controller." << std::endl;
    return;
  }
  view_ = std::make_unique<FlutterView>(FlutterDesktopGetView(controller_));
}

FlutterViewController::FlutterViewController(
    const std::string& icu_data_path,
    int width,
    int height,
    const std::string& assets_path,
    const std::vector<std::string>& arguments) {
  if (controller_) {
    std::cerr << "Only one Flutter view can exist at a time." << std::endl;
  }

  std::vector<const char*> engine_arguments;
  std::transform(
      arguments.begin(), arguments.end(), std::back_inserter(engine_arguments),
      [](const std::string& arg) -> const char* { return arg.c_str(); });
  size_t arg_count = engine_arguments.size();

  controller_ = FlutterDesktopCreateViewControllerLegacy(
      width, height, assets_path.c_str(), icu_data_path.c_str(),
      arg_count > 0 ? &engine_arguments[0] : nullptr, arg_count);
  if (!controller_) {
    std::cerr << "Failed to create view controller." << std::endl;
    return;
  }
  view_ = std::make_unique<FlutterView>(FlutterDesktopGetView(controller_));
}

FlutterViewController::~FlutterViewController() {
  if (controller_) {
    FlutterDesktopDestroyViewController(controller_);
  }
}

std::chrono::nanoseconds FlutterViewController::ProcessMessages() {
  return std::chrono::nanoseconds(FlutterDesktopProcessMessages(controller_));
}

FlutterDesktopPluginRegistrarRef FlutterViewController::GetRegistrarForPlugin(
    const std::string& plugin_name) {
  if (!controller_) {
    std::cerr << "Cannot get plugin registrar without a window; call "
                 "CreateWindow first."
              << std::endl;
    return nullptr;
  }
  return FlutterDesktopGetPluginRegistrar(controller_, plugin_name.c_str());
}

}  // namespace flutter
