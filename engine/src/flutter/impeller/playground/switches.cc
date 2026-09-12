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
std::string FoldNames(const std::array<T, N>& option_list) {
  return std::accumulate(option_list.begin(), option_list.end(), std::string{},
                         [](const std::string& a, const T& b) {
                           return a.empty() ? b.name : a + ", " + b.name;
                         });
}

template <typename T, std::size_t N>
void SetAllFlags(std::array<T, N>& option_list, bool val) {
  for (T& option : option_list) {
    option.value = val;
  }
}

template <typename T, std::size_t N>
bool OrAllFlags(std::array<T, N>& option_list) {
  return std::accumulate(
      option_list.begin(), option_list.end(), bool{false},
      [](const bool& a, const T& b) { return a || b.value; });
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
  auto option_list = flags.GetOptions();
  bool success = true;
  SetAllFlags(option_list, false);
  for (std::string_view option : options) {
    bool val = true;
    if (option.starts_with("-")) {
      val = false;
      option = option.substr(1);
    }
    if (option == "all") {
      SetAllFlags(option_list, val);
      continue;
    }
    auto found_it =
        std::find_if(option_list.begin(), option_list.end(),
                     [&option](const impeller::PlaygroundSwitchOption& s) {
                       return s.name == option;
                     });
    if (found_it == option_list.end()) {
      std::cout << std::endl
                << "Unrecognized value for " << option_name  //
                << " (\"" << option << "\") must be one of ["
                << FoldNames(option_list) << "]." << std::endl;
      success = false;
    } else {
      found_it->value = val;
    }
  }
  if (!OrAllFlags(option_list)) {
    std::cout << std::endl
              << "No recognized options specified for " << option_name << "."
              << std::endl
              << "At least one of [" << FoldNames(option_list) << "] "
              << "should be specified." << std::endl;
    success = false;
  }
  return success;
}

void print_usage(const std::string& command_name,
                 const std::string& golden_option_name) {
  impeller::PlaygroundOutputs outputs;
  impeller::PlaygroundBackends backends;
  int command_name_len = command_name.length();
  std::string indent = std::format("{0:<{1}}", "", command_name_len + 12);
  std::string formatted_golden_option =
      std::format("{0:<25}", "--" + golden_option_name + "=<dir>");
  std::cout << std::endl
            << "usage:    " << command_name << "   --use_swiftshader"
            << " --use_angle" << " --enable_vulkan_validation"  //
            << std::endl
            << indent << " --playground_timeout_ms=<ms>"
            << " --" << golden_option_name << "=<golden_image_dir>"  //
            << std::endl
            << indent << " --playground_output=<list>"
            << " --playground_backend=<list>" << std::endl
            << std::endl
            << "Flags:" << std::endl
            << std::endl
            << "        --use_swiftshader              "
            << "use the SwiftShader library for rendering" << std::endl
            << std::endl
            << "        --use_angle                    "
            << "use the Angle library for GL rendering"
            << " (Required and default for MacOS)" << std::endl
            << std::endl
            << "        --enable_vulkan_validation     "
            << "enables Vulkan validations" << std::endl
            << std::endl
            << "        --playground_timeout_ms=<ms>   "
            << "sets the Playground Window timeout and enables playgrounds"
            << std::endl
            << std::endl
            << "        " << formatted_golden_option << "      "
            << "sets the directory where the golden images will be written"
            << std::endl
            << std::endl
            << "        --playground_output=<list>     "
            << "sets the list of output types to render each playground test"
            << std::endl
            << "                                       "
            << "the values are a comma separated list of output types"
            << std::endl
            << "                                       "
            << "[" << FoldNames(outputs.GetOptions()) << ", all]"
            << std::endl  //
            << "                                       "
            << "each may be preceded by '-' to disable the type and the value"
            << std::endl
            << "                                       "
            << "\"all\" indicates all options should be enabled (or disabled)"
            << std::endl
            << std::endl
            << "        --playground_backend=<list>    "
            << "sets the list of backend types to render each playground test"
            << std::endl
            << "                                       "
            << "the values are a comma separated list of backend types"
            << std::endl
            << "                                       "
            << "[" << FoldNames(backends.GetOptions()) << ", all]"
            << std::endl  //
            << "                                       "
            << "each may be preceded by '-' to disable the type and the value"
            << std::endl
            << "                                       "
            << "\"all\" indicates all options should be enabled (or disabled)"
            << std::endl
            << std::endl
            << std::endl;
}

}  // namespace

namespace impeller {

PlaygroundSwitches::PlaygroundSwitches() = default;

std::optional<PlaygroundSwitches> PlaygroundSwitches::command_line_switches_;

const PlaygroundSwitches& PlaygroundSwitches::CommandLineSwitches() {
  if (!command_line_switches_) {
    FML_LOG(WARNING) << "Command line Playground switches not initialized";
    command_line_switches_ = PlaygroundSwitches();
  }
  return command_line_switches_.value();
}

bool PlaygroundSwitches::InitCommandLineSwitches(
    const fml::CommandLine& args,
    const std::string& golden_option_name) {
  bool success = true;
  PlaygroundSwitches switches;
  {
    if (args.HasOption("help") || args.HasOption("usage")) {
      success = false;
    }
    if (args.HasOption("playground_output")) {
      if (args.HasOption("enable_playground")) {
        FML_LOG(WARNING) << "The enable_playground flag is ignored if "
                            "the playground_output flag is used.";
      }
      if (!ProcessFlagListArg(args, switches.outputs_enabled,
                              "playground_output")) {
        success = false;
      }
    } else if (args.HasOption("enable_playground")) {
      FML_LOG(WARNING) << "The enable_playground flag is deprecated in "
                          "favor of --playground_output=window.";
      auto option_list = switches.outputs_enabled.GetOptions();
      SetAllFlags(option_list, false);
      switches.outputs_enabled.window = true;
    }
  }
  if (!ProcessFlagListArg(args, switches.backends_enabled,
                          "playground_backend")) {
    success = false;
  }
  std::string golden_output_dir;
  if (args.GetOptionValue(golden_option_name, &golden_output_dir)) {
    switches.golden_output_dir = golden_output_dir;
    switches.outputs_enabled.golden = true;
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
  if (!success) {
    print_usage(args.argv0(), golden_option_name);
  }
  command_line_switches_ = switches;
  return success;
}

}  // namespace impeller
