// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/switches.h"

#include <filesystem>

#include "flutter/fml/file.h"

namespace impeller {
namespace compiler {

void Switches::PrintHelp(std::ostream& stream) {
  stream << std::endl << "Valid Argument are:" << std::endl;
  stream << "--input=<glsl_file>" << std::endl;
  stream << "--metal=<metal_output_file>" << std::endl;
  stream << "--spirv=<spirv_output_file>" << std::endl;
  stream << "[Multiple] --include=<include_directory>" << std::endl;
}

Switches::Switches() = default;

Switches::~Switches() = default;

Switches::Switches(const fml::CommandLine& command_line)
    : working_directory(std::make_shared<fml::UniqueFD>(
          fml::OpenDirectory(std::filesystem::current_path().native().c_str(),
                             false,  // create if necessary,
                             fml::FilePermission::kRead))),
      source_file_name(command_line.GetOptionValueWithDefault("input", "")),
      metal_file_name(command_line.GetOptionValueWithDefault("metal", "")),
      spirv_file_name(command_line.GetOptionValueWithDefault("spirv", "")) {
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
    include_directories.emplace_back(std::move(dir));
  }
}

bool Switches::AreValid(std::ostream& explain) const {
  bool valid = true;
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
