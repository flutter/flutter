// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/switches.h"

#include <filesystem>
#include <map>

#include "flutter/fml/file.h"

namespace impeller {
namespace compiler {

static const std::map<std::string, Compiler::TargetPlatform> kKnownPlatforms = {
    {"macos", Compiler::TargetPlatform::kMacOS},
    {"ios", Compiler::TargetPlatform::kIPhoneOS},
};

void Switches::PrintHelp(std::ostream& stream) {
  stream << std::endl << "Valid Argument are:" << std::endl;
  stream << "One of [";
  for (const auto& platform : kKnownPlatforms) {
    stream << " --" << platform.first;
  }
  stream << " ]" << std::endl;
  stream << "--input=<glsl_file>" << std::endl;
  stream << "--metal=<metal_output_file>" << std::endl;
  stream << "--spirv=<spirv_output_file>" << std::endl;
  stream << "[optional] --reflection-json=<reflection_json_file>" << std::endl;
  stream << "[optional] --reflection-header=<reflection_header_file>"
         << std::endl;
  stream << "[optional] --reflection-cc=<reflection_cc_file>" << std::endl;
  stream << "[optional,multiple] --include=<include_directory>" << std::endl;
  stream << "[optional] --depfile=<depfile_path>" << std::endl;
}

Switches::Switches() = default;

Switches::~Switches() = default;

static Compiler::TargetPlatform TargetPlatformFromCommandLine(
    const fml::CommandLine& command_line) {
  auto target = Compiler::TargetPlatform::kUnknown;
  for (const auto& platform : kKnownPlatforms) {
    if (command_line.HasOption(platform.first)) {
      // If the platform has already been determined, the caller may have
      // specified multiple platforms. This is an error and only one must be
      // selected.
      if (target != Compiler::TargetPlatform::kUnknown) {
        return Compiler::TargetPlatform::kUnknown;
      }
      target = platform.second;
      // Keep going to detect duplicates.
    }
  }
  return target;
}

Switches::Switches(const fml::CommandLine& command_line)
    : target_platform(TargetPlatformFromCommandLine(command_line)),
      working_directory(std::make_shared<fml::UniqueFD>(
          fml::OpenDirectory(std::filesystem::current_path().native().c_str(),
                             false,  // create if necessary,
                             fml::FilePermission::kRead))),
      source_file_name(command_line.GetOptionValueWithDefault("input", "")),
      metal_file_name(command_line.GetOptionValueWithDefault("metal", "")),
      spirv_file_name(command_line.GetOptionValueWithDefault("spirv", "")),
      reflection_json_name(
          command_line.GetOptionValueWithDefault("reflection-json", "")),
      reflection_header_name(
          command_line.GetOptionValueWithDefault("reflection-header", "")),
      reflection_cc_name(
          command_line.GetOptionValueWithDefault("reflection-cc", "")),
      depfile_path(command_line.GetOptionValueWithDefault("depfile", "")) {
  if (!working_directory || !working_directory->is_valid()) {
    return;
  }

  for (const auto& include_dir_path : command_line.GetOptionValues("include")) {
    if (!include_dir_path.data()) {
      continue;
    }
    auto dir = std::make_shared<fml::UniqueFD>(fml::OpenDirectoryReadOnly(
        *working_directory, include_dir_path.data()));
    if (!dir || !dir->is_valid()) {
      continue;
    }

    IncludeDir dir_entry;
    dir_entry.name = include_dir_path;
    dir_entry.dir = std::move(dir);

    include_directories.emplace_back(std::move(dir_entry));
  }
}

bool Switches::AreValid(std::ostream& explain) const {
  bool valid = true;
  if (target_platform == Compiler::TargetPlatform::kUnknown) {
    explain << "The target platform (only one) was not specified." << std::endl;
    valid = false;
  }

  if (!working_directory || !working_directory->is_valid()) {
    explain << "Could not figure out working directory." << std::endl;
    valid = false;
  }

  if (source_file_name.empty()) {
    explain << "Input file name was empty." << std::endl;
    valid = false;
  }

  if (metal_file_name.empty()) {
    explain << "Metal file name was empty." << std::endl;
    valid = false;
  }

  if (spirv_file_name.empty()) {
    explain << "Spirv file name was empty." << std::endl;
    valid = false;
  }
  return valid;
}

}  // namespace compiler
}  // namespace impeller
