// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_project_bundle.h"

#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <sstream>

#include "flutter/shell/platform/common/cpp/path_utils.h"

namespace flutter {

FlutterProjectBundle::FlutterProjectBundle(
    const FlutterDesktopEngineProperties& properties)
    : assets_path_(properties.assets_path),
      icu_path_(properties.icu_data_path) {
  if (properties.aot_library_path != nullptr) {
    aot_library_path_ = std::filesystem::path(properties.aot_library_path);
  }

  // Resolve any relative paths.
  if (assets_path_.is_relative() || icu_path_.is_relative() ||
      (!aot_library_path_.empty() && aot_library_path_.is_relative())) {
    std::filesystem::path executable_location = GetExecutableDirectory();
    if (executable_location.empty()) {
      std::cerr
          << "Unable to find executable location to resolve resource paths."
          << std::endl;
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
UniqueAotDataPtr FlutterProjectBundle::LoadAotData() {
  if (aot_library_path_.empty()) {
    std::cerr
        << "Attempted to load AOT data, but no aot_library_path was provided."
        << std::endl;
    return nullptr;
  }
  if (!std::filesystem::exists(aot_library_path_)) {
    std::cerr << "Can't load AOT data from " << aot_library_path_.u8string()
              << "; no such file." << std::endl;
    return nullptr;
  }
  std::string path_string = aot_library_path_.u8string();
  FlutterEngineAOTDataSource source = {};
  source.type = kFlutterEngineAOTDataSourceTypeElfPath;
  source.elf_path = path_string.c_str();
  FlutterEngineAOTData data = nullptr;
  auto result = FlutterEngineCreateAOTData(&source, &data);
  if (result != kSuccess) {
    std::cerr << "Failed to load AOT data from: " << path_string << std::endl;
    return nullptr;
  }
  return UniqueAotDataPtr(data);
}

FlutterProjectBundle::~FlutterProjectBundle() {}

const std::vector<std::string> FlutterProjectBundle::GetSwitches() {
  std::vector<std::string> switches;
  // Read engine switches from the environment in debug/profile.
#ifndef FLUTTER_RELEASE
  const char* switch_count_key = "FLUTTER_ENGINE_SWITCHES";
  const int kMaxSwitchCount = 50;
  const char* switch_count_string = std::getenv(switch_count_key);
  int switch_count = std::min(
      kMaxSwitchCount, switch_count_string ? atoi(switch_count_string) : 0);
  for (int i = 1; i <= switch_count; ++i) {
    std::ostringstream switch_key;
    switch_key << "FLUTTER_ENGINE_SWITCH_" << i;
    const char* switch_value = std::getenv(switch_key.str().c_str());
    if (switch_value) {
      std::ostringstream switch_value_as_flag;
      switch_value_as_flag << "--" << switch_value;
      switches.push_back(switch_value_as_flag.str());
    } else {
      std::cerr << switch_count << " keys expected from " << switch_count_key
                << ", but " << switch_key.str() << " is missing." << std::endl;
    }
  }
#endif  // !FLUTTER_RELEASE
  return switches;
}

}  // namespace flutter
