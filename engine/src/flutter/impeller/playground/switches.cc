// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/switches.h"

#include <cstdlib>
#include <numeric>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"

namespace {

template <std::size_t N>
std::string FoldNames(const std::array<std::string, N>& array) {
  return std::accumulate(array.begin(), array.end(), std::string{},
                         [](const std::string& a, const std::string& b) {
                           return a.size() == 0 ? b : a + "," + b;
                         });
}

template <typename T>
bool ProcessFlagListArg(const fml::CommandLine& args,
                        T* flags_copy,
                        const std::string& option_name) {
  std::vector<std::string> options = args.GetOptionValues(option_name, ',');
  if (options.empty()) {
    return true;
  }
  bool success = true;
  bool* flags_bool = reinterpret_cast<bool*>(flags_copy);
  static_assert(sizeof(T) == sizeof(bool[T::kNames.size()]));
  flags_copy->Clear();
  for (std::string_view option : options) {
    auto found_it = std::find(T::kNames.begin(), T::kNames.end(), option);
    if (found_it == T::kNames.end()) {
      FML_LOG(WARNING) << "Unrecognized value for " << option_name << " ("
                       << option << ") must be one of [" << FoldNames(T::kNames)
                       << "].";
      success = false;
    } else {
      size_t index = std::distance(T::kNames.begin(), found_it);
      flags_bool[index] = true;
    }
  }
  if (!flags_copy->Any()) {
    FML_LOG(WARNING) << "No options specified for " << option_name << ".";
    FML_LOG(WARNING) << "At least one of [" << FoldNames(T::kNames) << "] "
                     << "should be specified.";
    success = false;
  }
  return success;
}

}  // namespace

namespace impeller {

PlaygroundSwitches::PlaygroundSwitches() = default;

PlaygroundSwitches::PlaygroundSwitches(const fml::CommandLine& args) {
  {
    if (args.HasOption("playground_output")) {
      if (args.HasOption("enable_playground")) {
        FML_LOG(WARNING) << "The enable_playground flag is ignored if "
                            "the playground_output flag is used.";
      }
      ProcessFlagListArg(args, &outputs_enabled, "playground_output");
    } else if (args.HasOption("enable_playground")) {
      FML_LOG(WARNING) << "The enable_playground flag is deprecated in "
                          "favor of --playground_output=window.";
      outputs_enabled.window = true;
    }
  }
  ProcessFlagListArg(args, &backends_enabled, "playground_backend");
  std::string timeout_str;
  if (args.GetOptionValue("playground_timeout_ms", &timeout_str)) {
    timeout = std::chrono::milliseconds(atoi(timeout_str.c_str()));
    // Specifying a playground timeout implies you want to enable
    // playground windows.
    outputs_enabled.window = true;
  }
  enable_vulkan_validation = args.HasOption("enable_vulkan_validation");
  use_swiftshader = args.HasOption("use_swiftshader");
  use_angle = args.HasOption("use_angle");
#if FML_OS_MACOSX
  // OpenGL on macOS is busted and deprecated. Use Angle there by default.
  use_angle = true;
#endif  // FML_OS_MACOSX
}

}  // namespace impeller
