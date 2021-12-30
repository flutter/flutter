// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <filesystem>

#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/impeller/compiler/compiler.h"
#include "flutter/impeller/compiler/switches.h"
#include "flutter/impeller/compiler/utilities.h"
#include "third_party/shaderc/libshaderc/include/shaderc/shaderc.hpp"

namespace impeller {
namespace compiler {

bool Main(const fml::CommandLine& command_line) {
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

  auto source_file_mapping = fml::FileMapping::CreateReadOnly(
      *switches.working_directory, switches.source_file_name);
  if (!source_file_mapping) {
    std::cerr << "Could not open input file." << std::endl;
    return false;
  }

  Compiler::SourceOptions options;
  options.target_platform = switches.target_platform;
  options.type = Compiler::SourceTypeFromFileName(switches.source_file_name);
  options.working_directory = switches.working_directory;
  options.file_name = switches.source_file_name;
  options.include_dirs = switches.include_directories;
  options.entry_point_name = Compiler::EntryPointFromSourceName(
      switches.source_file_name,
      Compiler::SourceTypeFromFileName(switches.source_file_name));

  Reflector::Options reflector_options;
  reflector_options.shader_name =
      InferShaderNameFromPath(switches.source_file_name);
  reflector_options.header_file_name =
      std::filesystem::path{switches.reflection_header_name}
          .filename()
          .native();

  Compiler compiler(*source_file_mapping, options, reflector_options);
  if (!compiler.IsValid()) {
    std::cerr << "Compilation failed." << std::endl;
    std::cerr << compiler.GetErrorMessages() << std::endl;
    return false;
  }

  if (!fml::WriteAtomically(*switches.working_directory,
                            switches.spirv_file_name.c_str(),
                            *compiler.GetSPIRVAssembly())) {
    std::cerr << "Could not write file to " << switches.spirv_file_name
              << std::endl;
    return false;
  }

  if (!fml::WriteAtomically(*switches.working_directory,
                            switches.metal_file_name.c_str(),
                            *compiler.GetMSLShaderSource())) {
    std::cerr << "Could not write file to " << switches.spirv_file_name
              << std::endl;
    return false;
  }

  if (!switches.reflection_json_name.empty()) {
    if (!fml::WriteAtomically(*switches.working_directory,
                              switches.reflection_json_name.c_str(),
                              *compiler.GetReflector()->GetReflectionJSON())) {
      std::cerr << "Could not write reflection json to "
                << switches.reflection_json_name << std::endl;
      return false;
    }
  }

  if (!switches.reflection_header_name.empty()) {
    if (!fml::WriteAtomically(
            *switches.working_directory,
            switches.reflection_header_name.c_str(),
            *compiler.GetReflector()->GetReflectionHeader())) {
      std::cerr << "Could not write reflection header to "
                << switches.reflection_header_name << std::endl;
      return false;
    }
  }

  if (!switches.reflection_cc_name.empty()) {
    if (!fml::WriteAtomically(*switches.working_directory,
                              switches.reflection_cc_name.c_str(),
                              *compiler.GetReflector()->GetReflectionCC())) {
      std::cerr << "Could not write reflection CC to "
                << switches.reflection_cc_name << std::endl;
      return false;
    }
  }

  if (!switches.depfile_path.empty()) {
    if (!fml::WriteAtomically(
            *switches.working_directory, switches.depfile_path.c_str(),
            *compiler.CreateDepfileContents({switches.metal_file_name}))) {
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
  return impeller::compiler::Main(fml::CommandLineFromArgcArgv(argc, argv))
             ? EXIT_SUCCESS
             : EXIT_FAILURE;
}
