// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/switches.h"

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <map>

#include "flutter/fml/file.h"
#include "impeller/compiler/types.h"
#include "impeller/compiler/utilities.h"

namespace impeller {
namespace compiler {

static const std::map<std::string, TargetPlatform> kKnownPlatforms = {
    {"metal-desktop", TargetPlatform::kMetalDesktop},
    {"metal-ios", TargetPlatform::kMetalIOS},
    {"vulkan", TargetPlatform::kVulkan},
    {"opengl-es", TargetPlatform::kOpenGLES},
    {"opengl-desktop", TargetPlatform::kOpenGLDesktop},
    {"sksl", TargetPlatform::kSkSL},
    {"runtime-stage-metal", TargetPlatform::kRuntimeStageMetal},
    {"runtime-stage-gles", TargetPlatform::kRuntimeStageGLES},
    {"runtime-stage-vulkan", TargetPlatform::kRuntimeStageVulkan},
};

static const std::map<std::string, SourceType> kKnownSourceTypes = {
    {"vert", SourceType::kVertexShader},
    {"frag", SourceType::kFragmentShader},
    {"tesc", SourceType::kTessellationControlShader},
    {"tese", SourceType::kTessellationEvaluationShader},
    {"comp", SourceType::kComputeShader},
};

void Switches::PrintHelp(std::ostream& stream) {
  stream << std::endl;
  stream << "ImpellerC is an offline shader processor and reflection engine."
         << std::endl;
  stream << "---------------------------------------------------------------"
         << std::endl;
  stream << "Valid Argument are:" << std::endl;
  stream << "One of [";
  for (const auto& platform : kKnownPlatforms) {
    stream << " --" << platform.first;
  }
  stream << " ]" << std::endl;
  stream << "--input=<source_file>" << std::endl;
  stream << "[optional] --input-type={";
  for (const auto& source_type : kKnownSourceTypes) {
    stream << source_type.first << ", ";
  }
  stream << "}" << std::endl;
  stream << "--sl=<sl_output_file>" << std::endl;
  stream << "--spirv=<spirv_output_file>" << std::endl;
  stream << "[optional] --source-language=glsl|hlsl (default: glsl)"
         << std::endl;
  stream << "[optional] --entry-point=<entry_point_name> (default: main; "
            "ignored for glsl)"
         << std::endl;
  stream << "[optional] --iplr (causes --sl file to be emitted in iplr format)"
         << std::endl;
  stream << "[optional] --reflection-json=<reflection_json_file>" << std::endl;
  stream << "[optional] --reflection-header=<reflection_header_file>"
         << std::endl;
  stream << "[optional] --reflection-cc=<reflection_cc_file>" << std::endl;
  stream << "[optional,multiple] --include=<include_directory>" << std::endl;
  stream << "[optional,multiple] --define=<define>" << std::endl;
  stream << "[optional] --depfile=<depfile_path>" << std::endl;
  stream << "[optional] --gles-language-version=<number>" << std::endl;
  stream << "[optional] --json" << std::endl;
  stream << "[optional] --use-half-textures (force openGL semantics when "
            "targeting metal)"
         << std::endl;
}

Switches::Switches() = default;

Switches::~Switches() = default;

static TargetPlatform TargetPlatformFromCommandLine(
    const fml::CommandLine& command_line) {
  auto target = TargetPlatform::kUnknown;
  for (const auto& platform : kKnownPlatforms) {
    if (command_line.HasOption(platform.first)) {
      // If the platform has already been determined, the caller may have
      // specified multiple platforms. This is an error and only one must be
      // selected.
      if (target != TargetPlatform::kUnknown) {
        return TargetPlatform::kUnknown;
      }
      target = platform.second;
      // Keep going to detect duplicates.
    }
  }
  return target;
}

static SourceType SourceTypeFromCommandLine(
    const fml::CommandLine& command_line) {
  auto source_type_option =
      command_line.GetOptionValueWithDefault("input-type", "");
  auto source_type_search = kKnownSourceTypes.find(source_type_option);
  if (source_type_search == kKnownSourceTypes.end()) {
    return SourceType::kUnknown;
  }
  return source_type_search->second;
}

Switches::Switches(const fml::CommandLine& command_line)
    : target_platform(TargetPlatformFromCommandLine(command_line)),
      working_directory(std::make_shared<fml::UniqueFD>(fml::OpenDirectory(
          Utf8FromPath(std::filesystem::current_path()).c_str(),
          false,  // create if necessary,
          fml::FilePermission::kRead))),
      source_file_name(command_line.GetOptionValueWithDefault("input", "")),
      input_type(SourceTypeFromCommandLine(command_line)),
      sl_file_name(command_line.GetOptionValueWithDefault("sl", "")),
      iplr(command_line.HasOption("iplr")),
      spirv_file_name(command_line.GetOptionValueWithDefault("spirv", "")),
      reflection_json_name(
          command_line.GetOptionValueWithDefault("reflection-json", "")),
      reflection_header_name(
          command_line.GetOptionValueWithDefault("reflection-header", "")),
      reflection_cc_name(
          command_line.GetOptionValueWithDefault("reflection-cc", "")),
      depfile_path(command_line.GetOptionValueWithDefault("depfile", "")),
      json_format(command_line.HasOption("json")),
      gles_language_version(
          stoi(command_line.GetOptionValueWithDefault("gles-language-version",
                                                      "0"))),
      metal_version(
          command_line.GetOptionValueWithDefault("metal-version", "1.2")),
      entry_point(
          command_line.GetOptionValueWithDefault("entry-point", "main")),
      use_half_textures(command_line.HasOption("use-half-textures")) {
  auto language =
      command_line.GetOptionValueWithDefault("source-language", "glsl");
  std::transform(language.begin(), language.end(), language.begin(),
                 [](char x) { return std::tolower(x); });
  if (language == "glsl") {
    source_language = SourceLanguage::kGLSL;
  } else if (language == "hlsl") {
    source_language = SourceLanguage::kHLSL;
  }

  if (!working_directory || !working_directory->is_valid()) {
    return;
  }

  for (const auto& include_dir_path : command_line.GetOptionValues("include")) {
    if (!include_dir_path.data()) {
      continue;
    }

    // fml::OpenDirectoryReadOnly for Windows doesn't handle relative paths
    // beginning with `../` well, so we build an absolute path.

    // Get the current working directory as a utf8 encoded string.
    // Note that the `include_dir_path` is already utf8 encoded, and so we
    // mustn't attempt to double-convert it to utf8 lest multi-byte characters
    // will become mangled.
    std::filesystem::path include_dir_absolute;
    if (std::filesystem::path(include_dir_path).is_absolute()) {
      include_dir_absolute = std::filesystem::path(include_dir_path);
    } else {
      auto cwd = Utf8FromPath(std::filesystem::current_path());
      include_dir_absolute = std::filesystem::absolute(
          std::filesystem::path(cwd) / include_dir_path);
    }

    auto dir = std::make_shared<fml::UniqueFD>(fml::OpenDirectoryReadOnly(
        *working_directory, include_dir_absolute.string().c_str()));
    if (!dir || !dir->is_valid()) {
      continue;
    }

    IncludeDir dir_entry;
    dir_entry.name = include_dir_path;
    dir_entry.dir = std::move(dir);

    include_directories.emplace_back(std::move(dir_entry));
  }

  for (const auto& define : command_line.GetOptionValues("define")) {
    defines.emplace_back(define);
  }
}

bool Switches::AreValid(std::ostream& explain) const {
  bool valid = true;
  if (target_platform == TargetPlatform::kUnknown) {
    explain << "The target platform (only one) was not specified." << std::endl;
    valid = false;
  }

  if (source_language == SourceLanguage::kUnknown) {
    explain << "Invalid source language type." << std::endl;
    valid = false;
  }

  if (!working_directory || !working_directory->is_valid()) {
    explain << "Could not open the working directory: \""
            << Utf8FromPath(std::filesystem::current_path()).c_str() << "\""
            << std::endl;
    valid = false;
  }

  if (source_file_name.empty()) {
    explain << "Input file name was empty." << std::endl;
    valid = false;
  }

  if (sl_file_name.empty()) {
    explain << "Target shading language file name was empty." << std::endl;
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
