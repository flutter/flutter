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
  // It is harmless to pass this in non-AOT mode.
  properties.aot_library_path = project.aot_library_path().c_str();
  properties.switches = switch_count > 0 ? switches.data() : nullptr;
  properties.switches_count = switch_count;
  controller_ = FlutterDesktopCreateViewController(width, height, properties);
  if (!controller_) {
    std::cerr << "Failed to create view controller." << std::endl;
    return;
  }
  view_ = std::make_unique<FlutterView>(FlutterDesktopGetView(controller_));
  engine_ = FlutterDesktopGetEngine(controller_);
}

FlutterViewController::~FlutterViewController() {
  if (controller_) {
    FlutterDesktopDestroyViewController(controller_);
  }
}

std::chrono::nanoseconds FlutterViewController::ProcessMessages() {
  return std::chrono::nanoseconds(FlutterDesktopProcessMessages(engine_));
}

FlutterDesktopPluginRegistrarRef FlutterViewController::GetRegistrarForPlugin(
    const std::string& plugin_name) {
  if (!engine_) {
    std::cerr << "Cannot get plugin registrar without an engine." << std::endl;
    return nullptr;
  }
  return FlutterDesktopGetPluginRegistrar(engine_, plugin_name.c_str());
}

}  // namespace flutter
