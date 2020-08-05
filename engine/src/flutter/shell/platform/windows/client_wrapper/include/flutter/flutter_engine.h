// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_ENGINE_H_

#define NOMINMAX
#include <flutter_windows.h>

#include <chrono>
#include <memory>
#include <string>

#include "dart_project.h"
#include "plugin_registrar.h"
#include "plugin_registry.h"

namespace flutter {

// An instance of a Flutter engine.
//
// In the future, this will be the API surface used for all interactions with
// the engine, rather than having them duplicated on FlutterViewController.
// For now it is only used in the rare where you need a headless Flutter engine.
class FlutterEngine : public PluginRegistry {
 public:
  // Creates a new engine for running the given project.
  explicit FlutterEngine(const DartProject& project);

  virtual ~FlutterEngine();

  // Prevent copying.
  FlutterEngine(FlutterEngine const&) = delete;
  FlutterEngine& operator=(FlutterEngine const&) = delete;

  // Starts running the engine.
  //
  // If the optional entry point is not provided, defaults to main().
  bool Run(const char* entry_point = nullptr);

  // Terminates the running engine.
  void ShutDown();

  // Processes any pending events in the Flutter engine, and returns the
  // nanosecond delay until the next scheduled event (or  max, if none).
  //
  // This should be called on every run of the application-level runloop, and
  // a wait for native events in the runloop should never be longer than the
  // last return value from this function.
  std::chrono::nanoseconds ProcessMessages();

  // flutter::PluginRegistry:
  FlutterDesktopPluginRegistrarRef GetRegistrarForPlugin(
      const std::string& plugin_name) override;

 private:
  using UniqueEnginePtr =
      std::unique_ptr<FlutterDesktopEngine, bool (*)(FlutterDesktopEngine*)>;

  // Handle for interacting with the C API's engine reference.
  UniqueEnginePtr engine_ =
      UniqueEnginePtr(nullptr, FlutterDesktopShutDownEngine);

  std::unique_ptr<DartProject> project_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_ENGINE_H_
