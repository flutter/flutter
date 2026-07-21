// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/switches.h"

#include <cstdlib>
#include <numeric>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"

namespace {

template <typename T, std::size_t N>
std::string FoldNames(const std::array<T, N>& array) {
  return std::accumulate(array.begin(), array.end(), std::string{},
                         [](const std::string& a, const T& b) {
                           return a.empty() ? b.name : a + "," + b.name;
                         });
}

template <typename T>
bool ProcessFlagListArg(const fml::CommandLine& args,
                        T& flags,
                        const std::string& option_name) {
  std::vector<std::string_view> options =
      args.GetOptionValues(option_name, ',');
  if (options.empty()) {
    return true;
  }
  bool success = true;
  flags.Clear();
  auto switches = flags.switches();
  for (std::string_view option : options) {
    auto found_it =
        std::find_if(switches.begin(), switches.end(),
                     [&option](const impeller::PlaygroundSwitchOption& s) {
                       return s.name == option;
                     });
    if (found_it == switches.end()) {
      FML_LOG(WARNING) << "Unrecognized value for " << option_name << " (\""
                       << option << "\") must be one of ["
                       << FoldNames(switches) << "].";
      success = false;
    } else {
      found_it->flag = true;
    }
  }
  if (!flags.Any()) {
    FML_LOG(WARNING) << "No options specified for " << option_name << ".";
    FML_LOG(WARNING) << "At least one of [" << FoldNames(switches) << "] "
                     << "should be specified.";
    success = false;
  }
  return success;
}

}  // namespace

namespace impeller {

PlaygroundSwitches::PlaygroundSwitches() = default;

absl::StatusOr<PlaygroundSwitches> PlaygroundSwitches::FromCommandLine(
    const fml::CommandLine& args) {
  PlaygroundSwitches switches;
  {
    if (args.HasOption("playground_output")) {
      if (args.HasOption("enable_playground")) {
        FML_LOG(WARNING) << "The enable_playground flag is ignored if "
                            "the playground_output flag is used.";
      }
      if (!ProcessFlagListArg(args, switches.outputs_enabled,
                              "playground_output")) {
        return absl::InvalidArgumentError("Unrecognized Playground output");
      }
    } else if (args.HasOption("enable_playground")) {
      FML_LOG(WARNING) << "The enable_playground flag is deprecated in "
                          "favor of --playground_output=window.";
      switches.outputs_enabled.Clear();
      switches.outputs_enabled.window = true;
    }
  }
  if (!ProcessFlagListArg(args, switches.backends_enabled,
                          "playground_backend")) {
    return absl::InvalidArgumentError("Unrecognized Playground backend");
  }
  std::string timeout_str;
  if (args.GetOptionValue("playground_timeout_ms", &timeout_str)) {
    switches.timeout = std::chrono::milliseconds(atoi(timeout_str.c_str()));
    // Specifying a playground timeout implies you want to enable
    // playground windows.
    switches.outputs_enabled.window = true;
  }
  switches.enable_vulkan_validation =
      args.HasOption("enable_vulkan_validation");
  switches.use_swiftshader = args.HasOption("use_swiftshader");
  switches.use_angle = args.HasOption("use_angle");
#if FML_OS_MACOSX
  // OpenGL on macOS is busted and deprecated. Use Angle there by default.
  switches.use_angle = true;
#endif  // FML_OS_MACOSX
  return switches;
}

}  // namespace impeller
