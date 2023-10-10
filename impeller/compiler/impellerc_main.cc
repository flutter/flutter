// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <filesystem>
#include <system_error>

#include "flutter/fml/backtrace.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/base/strings.h"
#include "impeller/compiler/compiler.h"
#include "impeller/compiler/source_options.h"
#include "impeller/compiler/switches.h"
#include "impeller/compiler/types.h"
#include "impeller/compiler/utilities.h"
#include "third_party/shaderc/libshaderc/include/shaderc/shaderc.hpp"

namespace impeller {
namespace compiler {

// Sets the file access mode of the file at path 'p' to 0644.
static bool SetPermissiveAccess(const std::filesystem::path& p) {
  auto permissions =
      std::filesystem::perms::owner_read | std::filesystem::perms::owner_write |
      std::filesystem::perms::group_read | std::filesystem::perms::others_read;
  std::error_code error;
  std::filesystem::permissions(p, permissions, error);
  if (error) {
    std::cerr << "Failed to set access on file '" << p
              << "': " << error.message() << std::endl;
    return false;
  }
  return true;
}

bool Main(const fml::CommandLine& command_line) {
  fml::InstallCrashHandler();
  if (command_line.HasOption("help")) {
    Switches::PrintHelp(std::cout);
    return true;
  }

  Switches switches(command_line);
  if (!switches.AreValid(std::cerr)) {
    std::cerr << "Invalid flags specified." << std::endl;
    Switches::PrintHelp(std::cerr);
    return false;
  }

  std::shared_ptr<fml::FileMapping> source_file_mapping =
      fml::FileMapping::CreateReadOnly(switches.source_file_name);
  if (!source_file_mapping) {
    std::cerr << "Could not open input file." << std::endl;
    return false;
  }

  SourceOptions options;
  options.target_platform = switches.target_platform;
  options.source_language = switches.source_language;
  if (switches.input_type == SourceType::kUnknown) {
    options.type = SourceTypeFromFileName(switches.source_file_name);
  } else {
    options.type = switches.input_type;
  }
  options.working_directory = switches.working_directory;
  options.file_name = switches.source_file_name;
  options.include_dirs = switches.include_directories;
  options.defines = switches.defines;
  options.entry_point_name = EntryPointFunctionNameFromSourceName(
      switches.source_file_name, options.type, options.source_language,
      switches.entry_point);
  options.json_format = switches.json_format;
  options.gles_language_version = switches.gles_language_version;
  options.metal_version = switches.metal_version;
  options.use_half_textures = switches.use_half_textures;
  options.require_framebuffer_fetch = switches.require_framebuffer_fetch;

  Reflector::Options reflector_options;
  reflector_options.target_platform = switches.target_platform;
  reflector_options.entry_point_name = options.entry_point_name;
  reflector_options.shader_name =
      InferShaderNameFromPath(switches.source_file_name);
  reflector_options.header_file_name = Utf8FromPath(
      std::filesystem::path{switches.reflection_header_name}.filename());

  // Generate SkSL if needed.
  std::shared_ptr<fml::Mapping> sksl_mapping;
  if (switches.iplr && TargetPlatformBundlesSkSL(switches.target_platform)) {
    SourceOptions sksl_options = options;
    sksl_options.target_platform = TargetPlatform::kSkSL;

    Reflector::Options sksl_reflector_options = reflector_options;
    sksl_reflector_options.target_platform = TargetPlatform::kSkSL;

    Compiler sksl_compiler =
        Compiler(source_file_mapping, sksl_options, sksl_reflector_options);
    if (!sksl_compiler.IsValid()) {
      std::cerr << "Compilation to SkSL failed." << std::endl;
      std::cerr << sksl_compiler.GetErrorMessages() << std::endl;
      return false;
    }
    sksl_mapping = sksl_compiler.GetSLShaderSource();
  }

  Compiler compiler(source_file_mapping, options, reflector_options);
  if (!compiler.IsValid()) {
    std::cerr << "Compilation failed." << std::endl;
    std::cerr << compiler.GetErrorMessages() << std::endl;
    return false;
  }

  auto spriv_file_name = std::filesystem::absolute(
      std::filesystem::current_path() / switches.spirv_file_name);
  if (!fml::WriteAtomically(*switches.working_directory,
                            Utf8FromPath(spriv_file_name).c_str(),
                            *compiler.GetSPIRVAssembly())) {
    std::cerr << "Could not write file to " << switches.spirv_file_name
              << std::endl;
    return false;
  }

  auto sl_file_name = std::filesystem::absolute(
      std::filesystem::current_path() / switches.sl_file_name);
  if (switches.iplr) {
    auto reflector = compiler.GetReflector();
    if (reflector == nullptr) {
      std::cerr << "Could not create reflector." << std::endl;
      return false;
    }
    auto stage_data = reflector->GetRuntimeStageData();
    if (!stage_data) {
      std::cerr << "Runtime stage information was nil." << std::endl;
      return false;
    }
    if (sksl_mapping) {
      stage_data->SetSkSLData(sksl_mapping);
    }
    auto stage_data_mapping = options.json_format
                                  ? stage_data->CreateJsonMapping()
                                  : stage_data->CreateMapping();
    if (!stage_data_mapping) {
      std::cerr << "Runtime stage data could not be created." << std::endl;
      return false;
    }
    if (!fml::WriteAtomically(*switches.working_directory,         //
                              Utf8FromPath(sl_file_name).c_str(),  //
                              *stage_data_mapping                  //
                              )) {
      std::cerr << "Could not write file to " << switches.sl_file_name
                << std::endl;
      return false;
    }
    // Tools that consume the runtime stage data expect the access mode to
    // be 0644.
    if (!SetPermissiveAccess(sl_file_name)) {
      return false;
    }
  } else {
    if (!fml::WriteAtomically(*switches.working_directory,
                              Utf8FromPath(sl_file_name).c_str(),
                              *compiler.GetSLShaderSource())) {
      std::cerr << "Could not write file to " << switches.sl_file_name
                << std::endl;
      return false;
    }
  }

  if (TargetPlatformNeedsReflection(options.target_platform)) {
    if (!switches.reflection_json_name.empty()) {
      auto reflection_json_name = std::filesystem::absolute(
          std::filesystem::current_path() / switches.reflection_json_name);
      if (!fml::WriteAtomically(
              *switches.working_directory,
              Utf8FromPath(reflection_json_name).c_str(),
              *compiler.GetReflector()->GetReflectionJSON())) {
        std::cerr << "Could not write reflection json to "
                  << switches.reflection_json_name << std::endl;
        return false;
      }
    }

    if (!switches.reflection_header_name.empty()) {
      auto reflection_header_name =
          std::filesystem::absolute(std::filesystem::current_path() /
                                    switches.reflection_header_name.c_str());
      if (!fml::WriteAtomically(
              *switches.working_directory,
              Utf8FromPath(reflection_header_name).c_str(),
              *compiler.GetReflector()->GetReflectionHeader())) {
        std::cerr << "Could not write reflection header to "
                  << switches.reflection_header_name << std::endl;
        return false;
      }
    }

    if (!switches.reflection_cc_name.empty()) {
      auto reflection_cc_name =
          std::filesystem::absolute(std::filesystem::current_path() /
                                    switches.reflection_cc_name.c_str());
      if (!fml::WriteAtomically(*switches.working_directory,
                                Utf8FromPath(reflection_cc_name).c_str(),
                                *compiler.GetReflector()->GetReflectionCC())) {
        std::cerr << "Could not write reflection CC to "
                  << switches.reflection_cc_name << std::endl;
        return false;
      }
    }
  }

  if (!switches.depfile_path.empty()) {
    std::string result_file;
    switch (switches.target_platform) {
      case TargetPlatform::kMetalDesktop:
      case TargetPlatform::kMetalIOS:
      case TargetPlatform::kOpenGLES:
      case TargetPlatform::kOpenGLDesktop:
      case TargetPlatform::kRuntimeStageMetal:
      case TargetPlatform::kRuntimeStageGLES:
      case TargetPlatform::kRuntimeStageVulkan:
      case TargetPlatform::kSkSL:
      case TargetPlatform::kVulkan:
        result_file = switches.sl_file_name;
        break;
      case TargetPlatform::kUnknown:
        result_file = switches.spirv_file_name;
        break;
    }
    auto depfile_path = std::filesystem::absolute(
        std::filesystem::current_path() / switches.depfile_path.c_str());
    if (!fml::WriteAtomically(*switches.working_directory,
                              Utf8FromPath(depfile_path).c_str(),
                              *compiler.CreateDepfileContents({result_file}))) {
      std::cerr << "Could not write depfile to " << switches.depfile_path
                << std::endl;
      return false;
    }
  }

  return true;
}

}  // namespace compiler
}  // namespace impeller

int main(int argc, char const* argv[]) {
  return impeller::compiler::Main(
             fml::CommandLineFromPlatformOrArgcArgv(argc, argv))
             ? EXIT_SUCCESS
             : EXIT_FAILURE;
}
