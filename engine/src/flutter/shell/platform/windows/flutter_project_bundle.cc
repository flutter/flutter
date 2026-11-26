// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_project_bundle.h"

#include <charconv>
#include <cstdlib>
#include <filesystem>
#include <string_view>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/string_conversion.h"
#include "flutter/shell/platform/common/engine_switches.h"  // nogncheck
#include "flutter/shell/platform/common/path_utils.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"

namespace flutter {

namespace {

// Parses a feature level written as "<major>_<minor>", such as "10_0".
absl::StatusOr<egl::D3DFeatureLevel> ParseD3DFeatureLevel(
    std::string_view value) {
  const absl::Status invalid_status =
      absl::InvalidArgumentError("expected a feature level such as 10_0");
  const size_t separator = value.find('_');
  if (separator == std::string_view::npos) {
    return invalid_status;
  }
  const char* major_begin = value.data();
  const char* major_end = major_begin + separator;
  const char* minor_begin = major_end + 1;
  const char* minor_end = value.data() + value.size();

  int major = 0;
  int minor = 0;
  auto major_result = std::from_chars(major_begin, major_end, major);
  auto minor_result = std::from_chars(minor_begin, minor_end, minor);
  if (major_result.ec != std::errc() || major_result.ptr != major_end ||
      minor_result.ec != std::errc() || minor_result.ptr != minor_end) {
    return invalid_status;
  }
  return egl::D3DFeatureLevel{major, minor};
}

// Returns the D3D11 feature level cap from the environment, if set. The cap
// lets tests emulate older GPUs, where ANGLE may only create OpenGL ES 2.0
// contexts.
std::optional<egl::D3DFeatureLevel> GetMaxD3DFeatureLevelFromEnvironment() {
  // Like engine switches, only read the environment in debug and profile.
#ifndef FLUTTER_RELEASE
  constexpr char kKey[] = "FLUTTER_WINDOWS_MAX_D3D_FEATURE_LEVEL";
  const char* value = std::getenv(kKey);
  if (value == nullptr || value[0] == '\0') {
    return std::nullopt;
  }
  absl::StatusOr<egl::D3DFeatureLevel> level = ParseD3DFeatureLevel(value);
  if (!level.ok()) {
    FML_LOG(WARNING) << "Ignoring " << kKey << "=" << value << ": "
                     << level.status().message();
    return std::nullopt;
  }
  return level.value();
#else
  return std::nullopt;
#endif  // !FLUTTER_RELEASE
}

}  // namespace

FlutterProjectBundle::FlutterProjectBundle(
    const FlutterDesktopEngineProperties& properties)
    : assets_path_(properties.assets_path),
      icu_path_(properties.icu_data_path) {
  if (properties.aot_library_path != nullptr) {
    aot_library_path_ = std::filesystem::path(properties.aot_library_path);
  }

  if (properties.dart_entrypoint && properties.dart_entrypoint[0] != '\0') {
    dart_entrypoint_ = properties.dart_entrypoint;
  }

  for (int i = 0; i < properties.dart_entrypoint_argc; i++) {
    dart_entrypoint_arguments_.push_back(
        std::string(properties.dart_entrypoint_argv[i]));
  }

  gpu_preference_ =
      static_cast<FlutterGpuPreference>(properties.gpu_preference);

  ui_thread_policy_ =
      static_cast<FlutterUIThreadPolicy>(properties.ui_thread_policy);

  accessibility_mode_ =
      static_cast<FlutterAccessibilityMode>(properties.accessibility_mode);

  impeller_switch_ =
      static_cast<FlutterImpellerSwitch>(properties.impeller_switch);

  enable_flutter_gpu_ = properties.enable_flutter_gpu;

  max_d3d_feature_level_ = GetMaxD3DFeatureLevelFromEnvironment();

  // Resolve any relative paths.
  if (assets_path_.is_relative() || icu_path_.is_relative() ||
      (!aot_library_path_.empty() && aot_library_path_.is_relative())) {
    std::filesystem::path executable_location = GetExecutableDirectory();
    if (executable_location.empty()) {
      FML_LOG(ERROR)
          << "Unable to find executable location to resolve resource paths.";
      assets_path_ = std::filesystem::path();
      icu_path_ = std::filesystem::path();
    } else {
      assets_path_ = std::filesystem::path(executable_location) / assets_path_;
      icu_path_ = std::filesystem::path(executable_location) / icu_path_;
      if (!aot_library_path_.empty()) {
        aot_library_path_ =
            std::filesystem::path(executable_location) / aot_library_path_;
      }
    }
  }
}

bool FlutterProjectBundle::HasValidPaths() {
  return !assets_path_.empty() && !icu_path_.empty();
}

// Attempts to load AOT data from the given path, which must be absolute and
// non-empty. Logs and returns nullptr on failure.
UniqueAotDataPtr FlutterProjectBundle::LoadAotData(
    const FlutterEngineProcTable& engine_procs) {
  if (aot_library_path_.empty()) {
    FML_LOG(ERROR)
        << "Attempted to load AOT data, but no aot_library_path was provided.";
    return UniqueAotDataPtr(nullptr, nullptr);
  }
  if (!std::filesystem::exists(aot_library_path_)) {
    FML_LOG(ERROR) << "Can't load AOT data from " << aot_library_path_
                   << "; no such file.";
    return UniqueAotDataPtr(nullptr, nullptr);
  }
  std::string path_string = fml::PathToUtf8(aot_library_path_);
  FlutterEngineAOTDataSource source = {};
#if FML_ARCH_CPU_X86_64
  source.type = kFlutterEngineAOTDataSourceTypeDllPath;
  source.dll_path = path_string.c_str();
#else
  source.type = kFlutterEngineAOTDataSourceTypeElfPath;
  source.elf_path = path_string.c_str();
#endif
  FlutterEngineAOTData data = nullptr;
  auto result = engine_procs.CreateAOTData(&source, &data);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "Failed to load AOT data from: " << path_string;
    return UniqueAotDataPtr(nullptr, nullptr);
  }
  return UniqueAotDataPtr(data, engine_procs.CollectAOTData);
}

FlutterProjectBundle::~FlutterProjectBundle() {}

void FlutterProjectBundle::SetSwitches(
    const std::vector<std::string>& switches) {
  engine_switches_ = switches;
}

const std::vector<std::string> FlutterProjectBundle::GetSwitches() {
  if (engine_switches_.size() == 0) {
    return GetSwitchesFromEnvironment();
  }
  std::vector<std::string> switches;
  switches.insert(switches.end(), engine_switches_.begin(),
                  engine_switches_.end());

  auto env_switches = GetSwitchesFromEnvironment();
  switches.insert(switches.end(), env_switches.begin(), env_switches.end());

  return switches;
}

}  // namespace flutter
