// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <filesystem>
#include <system_error>

#include "flutter/fml/backtrace.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/fml/mapping.h"
#include "impeller/compiler/compiler.h"
#include "impeller/compiler/runtime_stage_data.h"
#include "impeller/compiler/shader_bundle.h"
#include "impeller/compiler/source_options.h"
#include "impeller/compiler/switches.h"
#include "impeller/compiler/types.h"
#include "impeller/compiler/utilities.h"

namespace impeller {
namespace compiler {

static Reflector::Options CreateReflectorOptions(const SourceOptions& options,
                                                 const Switches& switches) {
  Reflector::Options reflector_options;
  reflector_options.target_platform = options.target_platform;
  reflector_options.entry_point_name = options.entry_point_name;
  reflector_options.shader_name =
      InferShaderNameFromPath(switches.source_file_name);
  reflector_options.header_file_name =
      Utf8FromPath(switches.reflection_header_name.filename());
  return reflector_options;
}

static bool OutputIPLR(
    const Switches& switches,
    const std::shared_ptr<fml::Mapping>& source_file_mapping) {
  FML_DCHECK(switches.iplr);

  RuntimeStageData stages;
  for (const auto& platform : switches.PlatformsToCompile()) {
    SourceOptions options = switches.CreateSourceOptions();
    options.target_platform = platform;

    // Invoke the compiler and generate reflection data for a single shader.

    Reflector::Options reflector_options =
        CreateReflectorOptions(options, switches);
    Compiler compiler(source_file_mapping, options, reflector_options);
    if (!compiler.IsValid()) {
      std::cerr << "Compilation failed for target: "
                << TargetPlatformToString(platform) << std::endl;
      std::cerr << compiler.GetErrorMessages() << std::endl;
      return false;
    }

    auto reflector = compiler.GetReflector();
    if (reflector == nullptr) {
      std::cerr << "Could not create reflector." << std::endl;
      return false;
    }

    auto stage_data = reflector->GetRuntimeStageShaderData();
    if (!stage_data) {
      std::cerr << "Runtime stage information was nil." << std::endl;
      return false;
    }

    stages.AddShader(stage_data);
  }

  auto stage_data_mapping = switches.json_format ? stages.CreateJsonMapping()
                                                 : stages.CreateMapping();
  if (!stage_data_mapping) {
    std::cerr << "Runtime stage data could not be created." << std::endl;
    return false;
  }
  if (!fml::WriteAtomically(*switches.working_directory,                  //
                            Utf8FromPath(switches.sl_file_name).c_str(),  //
                            *stage_data_mapping                           //
                            )) {
    std::cerr << "Could not write file to " << switches.sl_file_name
              << std::endl;
    return false;
  }
  // Tools that consume the runtime stage data expect the access mode to
  // be 0644.
  if (!SetPermissiveAccess(switches.sl_file_name)) {
    return false;
  }
  return true;
}

static bool OutputSLFile(const Compiler& compiler, const Switches& switches) {
  // --------------------------------------------------------------------------
  /// 2. Output the source file. When in IPLR/RuntimeStage mode, output the
  ///    serialized IPLR flatbuffer.
  ///

  auto sl_file_name = std::filesystem::absolute(
      std::filesystem::current_path() / switches.sl_file_name);
  if (!fml::WriteAtomically(*switches.working_directory,
                            Utf8FromPath(sl_file_name).c_str(),
                            *compiler.GetSLShaderSource())) {
    std::cerr << "Could not write file to " << switches.sl_file_name
              << std::endl;
    return false;
  }
  return true;
}

static bool OutputReflectionData(const Compiler& compiler,
                                 const Switches& switches,
                                 const SourceOptions& options) {
  // --------------------------------------------------------------------------
  /// 3. Output shader reflection data.
  ///    May include a JSON file, a C++ header, and/or a C++ TU.
  ///

  if (!switches.reflection_json_name.empty()) {
    auto reflection_json_name = std::filesystem::absolute(
        std::filesystem::current_path() / switches.reflection_json_name);
    if (!fml::WriteAtomically(*switches.working_directory,
                              Utf8FromPath(reflection_json_name).c_str(),
                              *compiler.GetReflector()->GetReflectionJSON())) {
      std::cerr << "Could not write reflection json to "
                << switches.reflection_json_name << std::endl;
      return false;
    }
  }

  if (!switches.reflection_header_name.empty()) {
    auto reflection_header_name = std::filesystem::absolute(
        std::filesystem::current_path() / switches.reflection_header_name);
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
    auto reflection_cc_name = std::filesystem::absolute(
        std::filesystem::current_path() / switches.reflection_cc_name);
    if (!fml::WriteAtomically(*switches.working_directory,
                              Utf8FromPath(reflection_cc_name).c_str(),
                              *compiler.GetReflector()->GetReflectionCC())) {
      std::cerr << "Could not write reflection CC to "
                << switches.reflection_cc_name << std::endl;
      return false;
    }
  }
  return true;
}

static bool OutputDepfile(const Compiler& compiler, const Switches& switches) {
  // --------------------------------------------------------------------------
  /// 4. Output a depfile.
  ///

  if (!switches.depfile_path.empty()) {
    std::string result_file = Utf8FromPath(switches.sl_file_name);
    auto depfile_path = std::filesystem::absolute(
        std::filesystem::current_path() / switches.depfile_path);
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

  if (!switches.shader_bundle.empty()) {
    // Invoke the compiler multiple times to build a shader bundle with the
    // given shader_bundle spec.
    return GenerateShaderBundle(switches);
  }

  std::shared_ptr<fml::FileMapping> source_file_mapping =
      fml::FileMapping::CreateReadOnly(Utf8FromPath(switches.source_file_name));
  if (!source_file_mapping) {
    std::cerr << "Could not open input file." << std::endl;
    return false;
  }

  if (switches.iplr && !OutputIPLR(switches, source_file_mapping)) {
    return false;
  }

  // Create at least one compiler to output the SL file, reflection data, and a
  // depfile.

  SourceOptions options = switches.CreateSourceOptions();
  // If there are multiple platform compile targets, the specific target
  // platform that is used does not matter because the output files won't depend
  // on the target platform. Arbitrarily choose the first one from
  // PlatformsToCompile().
  options.target_platform = switches.PlatformsToCompile().front();

  // Invoke the compiler and generate reflection data for a single shader.

  Reflector::Options reflector_options =
      CreateReflectorOptions(options, switches);

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

  if (!switches.iplr && !OutputSLFile(compiler, switches)) {
    return false;
  }

  if (!OutputReflectionData(compiler, switches, options)) {
    return false;
  }

  if (!OutputDepfile(compiler, switches)) {
    return false;
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
