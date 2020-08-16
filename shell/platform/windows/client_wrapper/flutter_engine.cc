// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/flutter/flutter_engine.h"

#include <algorithm>
#include <iostream>

namespace flutter {

FlutterEngine::FlutterEngine(const DartProject& project) {
  FlutterDesktopEngineProperties c_engine_properties = {};
  c_engine_properties.assets_path = project.assets_path().c_str();
  c_engine_properties.icu_data_path = project.icu_data_path().c_str();
  c_engine_properties.aot_library_path = project.aot_library_path().c_str();
  std::vector<const char*> engine_switches;
  std::transform(
      project.engine_switches().begin(), project.engine_switches().end(),
      std::back_inserter(engine_switches),
      [](const std::string& arg) -> const char* { return arg.c_str(); });
  if (engine_switches.size() > 0) {
    c_engine_properties.switches = &engine_switches[0];
    c_engine_properties.switches_count = engine_switches.size();
  }

  engine_ = FlutterDesktopEngineCreate(c_engine_properties);
}

FlutterEngine::~FlutterEngine() {
  ShutDown();
}

bool FlutterEngine::Run(const char* entry_point) {
  if (!engine_) {
    std::cerr << "Cannot run an engine that failed creation." << std::endl;
    return false;
  }
  if (has_been_run_) {
    std::cerr << "Cannot run an engine more than once." << std::endl;
    return false;
  }
  bool run_succeeded = FlutterDesktopEngineRun(engine_, entry_point);
  if (!run_succeeded) {
    std::cerr << "Failed to start engine." << std::endl;
  }
  has_been_run_ = true;
  return run_succeeded;
}

void FlutterEngine::ShutDown() {
  if (engine_ && owns_engine_) {
    FlutterDesktopEngineDestroy(engine_);
  }
  engine_ = nullptr;
}

std::chrono::nanoseconds FlutterEngine::ProcessMessages() {
  return std::chrono::nanoseconds(FlutterDesktopEngineProcessMessages(engine_));
}

FlutterDesktopPluginRegistrarRef FlutterEngine::GetRegistrarForPlugin(
    const std::string& plugin_name) {
  if (!engine_) {
    std::cerr << "Cannot get plugin registrar on an engine that isn't running; "
                 "call Run first."
              << std::endl;
    return nullptr;
  }
  return FlutterDesktopEngineGetPluginRegistrar(engine_, plugin_name.c_str());
}

FlutterDesktopEngineRef FlutterEngine::RelinquishEngine() {
  owns_engine_ = false;
  return engine_;
}

}  // namespace flutter
