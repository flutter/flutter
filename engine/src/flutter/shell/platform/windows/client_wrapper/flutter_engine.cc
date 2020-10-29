// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/flutter/flutter_engine.h"

#include <algorithm>
#include <iostream>

#include "binary_messenger_impl.h"

namespace flutter {

FlutterEngine::FlutterEngine(const DartProject& project) {
  FlutterDesktopEngineProperties c_engine_properties = {};
  c_engine_properties.assets_path = project.assets_path().c_str();
  c_engine_properties.icu_data_path = project.icu_data_path().c_str();
  c_engine_properties.aot_library_path = project.aot_library_path().c_str();

  const std::vector<std::string>& entrypoint_args =
      project.dart_entrypoint_arguments();
  std::vector<const char*> entrypoint_argv;
  std::transform(
      entrypoint_args.begin(), entrypoint_args.end(),
      std::back_inserter(entrypoint_argv),
      [](const std::string& arg) -> const char* { return arg.c_str(); });

  c_engine_properties.dart_entrypoint_argc =
      static_cast<int>(entrypoint_argv.size());
  c_engine_properties.dart_entrypoint_argv =
      entrypoint_argv.size() > 0 ? entrypoint_argv.data() : nullptr;

  engine_ = FlutterDesktopEngineCreate(c_engine_properties);

  auto core_messenger = FlutterDesktopEngineGetMessenger(engine_);
  messenger_ = std::make_unique<BinaryMessengerImpl>(core_messenger);
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

void FlutterEngine::ReloadSystemFonts() {
  FlutterDesktopEngineReloadSystemFonts(engine_);
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
