// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/flutter/flutter_engine.h"

#include <algorithm>
#include <iostream>

namespace flutter {

FlutterEngine::FlutterEngine(const DartProject& project)
    : project_(std::make_unique<DartProject>(project)) {}

FlutterEngine::~FlutterEngine() {
  ShutDown();
}

bool FlutterEngine::Run(const char* entry_point) {
  if (engine_) {
    std::cerr << "Cannot run an already running engine. Create a new instance "
                 "or call ShutDown first."
              << std::endl;
    return false;
  }

  FlutterDesktopEngineProperties c_engine_properties = {};
  c_engine_properties.assets_path = project_->assets_path().c_str();
  c_engine_properties.icu_data_path = project_->icu_data_path().c_str();
  c_engine_properties.aot_library_path = project_->aot_library_path().c_str();
  c_engine_properties.entry_point = entry_point;
  std::vector<const char*> engine_switches;
  std::transform(
      project_->engine_switches().begin(), project_->engine_switches().end(),
      std::back_inserter(engine_switches),
      [](const std::string& arg) -> const char* { return arg.c_str(); });
  if (engine_switches.size() > 0) {
    c_engine_properties.switches = &engine_switches[0];
    c_engine_properties.switches_count = engine_switches.size();
  }

  engine_ = UniqueEnginePtr(FlutterDesktopRunEngine(c_engine_properties),
                            FlutterDesktopShutDownEngine);
  if (!engine_) {
    std::cerr << "Failed to start engine." << std::endl;
    return false;
  }
  return true;
}

void FlutterEngine::ShutDown() {
  engine_ = nullptr;
}

std::chrono::nanoseconds FlutterEngine::ProcessMessages() {
  return std::chrono::nanoseconds(FlutterDesktopProcessMessages(engine_.get()));
}

FlutterDesktopPluginRegistrarRef FlutterEngine::GetRegistrarForPlugin(
    const std::string& plugin_name) {
  if (!engine_) {
    std::cerr << "Cannot get plugin registrar on an engine that isn't running; "
                 "call Run first."
              << std::endl;
    return nullptr;
  }
  return FlutterDesktopGetPluginRegistrar(engine_.get(), plugin_name.c_str());
}

}  // namespace flutter
