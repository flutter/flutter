// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/importer/switches.h"

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <map>

#include "flutter/fml/file.h"
#include "impeller/compiler/utilities.h"
#include "impeller/scene/importer/types.h"

namespace impeller {
namespace scene {
namespace importer {

static const std::map<std::string, SourceType> kKnownSourceTypes = {
    {"gltf", SourceType::kGLTF},
};

void Switches::PrintHelp(std::ostream& stream) {
  stream << std::endl;
  stream << "SceneC is an offline 3D geometry file parser." << std::endl;
  stream << "---------------------------------------------------------------"
         << std::endl;
  stream << "Valid Argument are:" << std::endl;
  stream << "--input=<source_file>" << std::endl;
  stream << "[optional] --input-kind={";
  for (const auto& source_type : kKnownSourceTypes) {
    stream << source_type.first << ", ";
  }
  stream << "} (default: gltf)" << std::endl;
  stream << "--output=<output_file>" << std::endl;
}

Switches::Switches() = default;

Switches::~Switches() = default;

static SourceType SourceTypeFromCommandLine(
    const fml::CommandLine& command_line) {
  auto source_type_option =
      command_line.GetOptionValueWithDefault("input-type", "gltf");
  auto source_type_search = kKnownSourceTypes.find(source_type_option);
  if (source_type_search == kKnownSourceTypes.end()) {
    return SourceType::kUnknown;
  }
  return source_type_search->second;
}

Switches::Switches(const fml::CommandLine& command_line)
    : working_directory(std::make_shared<fml::UniqueFD>(fml::OpenDirectory(
          compiler::Utf8FromPath(std::filesystem::current_path()).c_str(),
          false,  // create if necessary,
          fml::FilePermission::kRead))),
      source_file_name(command_line.GetOptionValueWithDefault("input", "")),
      input_type(SourceTypeFromCommandLine(command_line)),
      output_file_name(command_line.GetOptionValueWithDefault("output", "")) {
  if (!working_directory || !working_directory->is_valid()) {
    return;
  }
}

bool Switches::AreValid(std::ostream& explain) const {
  bool valid = true;

  if (input_type == SourceType::kUnknown) {
    explain << "Unknown input type." << std::endl;
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

  if (output_file_name.empty()) {
    explain << "Target output file name was empty." << std::endl;
    valid = false;
  }

  return valid;
}

}  // namespace importer
}  // namespace scene
}  // namespace impeller
