// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_DART_PROJECT_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_DART_PROJECT_H_

#include <string>
#include <vector>

namespace flutter {

// Configures how the Flutter engine selects a GPU.
enum class GpuPreference {
  // No preference.
  NoPreference,
  // Prefer energy efficiency over performance, such as an integrated GPU.
  // This falls back to a high performance GPU if no low power GPU is
  // available.
  LowPowerPreference,
};

// Configures the thread policy for running the UI isolate.
enum class UIThreadPolicy {
  // Default value. Currently will run the UI isolate on separate thread,
  // later will be changed to running the UI isolate on platform thread.
  Default,
  // Run the UI isolate on platform thread.
  RunOnPlatformThread,
  // Run the UI isolate on a separate thread.
  RunOnSeparateThread,
};

// A set of Flutter and Dart assets used to initialize a Flutter engine.
class DartProject {
 public:
  // Creates a DartProject from a series of absolute paths.
  // The three paths are:
  // - assets_path: Path to the assets directory as built by the Flutter tool.
  // - icu_data_path: Path to the icudtl.dat file.
  // - aot_library_path: Path to the AOT snapshot file.
  //
  // The paths may either be absolute or relative to the directory containing
  // the running executable.
  explicit DartProject(const std::wstring& assets_path,
                       const std::wstring& icu_data_path,
                       const std::wstring& aot_library_path) {
    assets_path_ = assets_path;
    icu_data_path_ = icu_data_path;
    aot_library_path_ = aot_library_path;
  }

  // Creates a DartProject from a directory path. The directory should contain
  // the following top-level items:
  // - icudtl.dat (provided as a resource by the Flutter tool)
  // - flutter_assets (as built by the Flutter tool)
  // - app.so, for an AOT build (as built by the Flutter tool)
  //
  // The path can either be absolute, or relative to the directory containing
  // the running executable.
  explicit DartProject(const std::wstring& path) {
    assets_path_ = path + L"\\flutter_assets";
    icu_data_path_ = path + L"\\icudtl.dat";
    aot_library_path_ = path + L"\\app.so";
  }

  ~DartProject() = default;

  // Sets the Dart entrypoint to the specified value.
  //
  // If not set, the default entrypoint (main) is used. Custom Dart entrypoints
  // must be decorated with `@pragma('vm:entry-point')`.
  void set_dart_entrypoint(const std::string& entrypoint) {
    if (entrypoint.empty()) {
      return;
    }
    dart_entrypoint_ = entrypoint;
  }

  // Returns the Dart entrypoint.
  const std::string& dart_entrypoint() const { return dart_entrypoint_; }

  // Sets the command line arguments that should be passed to the Dart
  // entrypoint.
  void set_dart_entrypoint_arguments(std::vector<std::string> arguments) {
    dart_entrypoint_arguments_ = std::move(arguments);
  }

  // Returns any command line arguments that should be passed to the Dart
  // entrypoint.
  const std::vector<std::string>& dart_entrypoint_arguments() const {
    return dart_entrypoint_arguments_;
  }

  // Sets the GPU usage preference for flutter engine.
  void set_gpu_preference(GpuPreference gpu_preference) {
    gpu_preference_ = gpu_preference;
  }

  // Returns the project's GPU preference.
  // Defaults to NoPreference.
  GpuPreference gpu_preference() const { return gpu_preference_; }

  // Sets the thread policy for UI isolate.
  void set_ui_thread_policy(UIThreadPolicy policy) {
    ui_thread_policy_ = policy;
  }

  // Returns the policy for UI isolate.
  // Defaults to UIThreadPolicy::Default.
  UIThreadPolicy ui_thread_policy() const { return ui_thread_policy_; }

 private:
  // Accessors for internals are private, so that they can be changed if more
  // flexible options for project structures are needed later without it
  // being a breaking change. Provide access to internal classes that need
  // them.
  friend class FlutterEngine;
  friend class FlutterViewController;
  friend class DartProjectTest;

  const std::wstring& assets_path() const { return assets_path_; }
  const std::wstring& icu_data_path() const { return icu_data_path_; }
  const std::wstring& aot_library_path() const { return aot_library_path_; }

  // The path to the assets directory.
  std::wstring assets_path_;
  // The path to the ICU data.
  std::wstring icu_data_path_;
  // The path to the AOT library. This will always return a path, but non-AOT
  // builds will not be expected to actually have a library at that path.
  std::wstring aot_library_path_;
  // The Dart entrypoint to launch.
  std::string dart_entrypoint_;
  // The list of arguments to pass through to the Dart entrypoint.
  std::vector<std::string> dart_entrypoint_arguments_;
  // The preference for GPU to be used by flutter engine.
  GpuPreference gpu_preference_ = GpuPreference::NoPreference;
  // Thread policy for UI isolate.
  UIThreadPolicy ui_thread_policy_ = UIThreadPolicy::Default;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_DART_PROJECT_H_
