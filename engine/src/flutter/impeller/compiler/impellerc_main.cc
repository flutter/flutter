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

namespace {

Reflector::Options CreateReflectorOptions(const SourceOptions& options,
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

std::shared_ptr<Compiler> CreateCompiler(
    TargetPlatform platform,
    const std::shared_ptr<const fml::Mapping>& source_file_mapping,
    const Switches& switches) {
  SourceOptions options = switches.CreateSourceOptions();
  options.target_platform = platform;
  Reflector::Options reflector_options =
      CreateReflectorOptions(options, switches);
  return std::make_shared<Compiler>(source_file_mapping, options,
                                    reflector_options);
}

void OutputVerboseErrorFile(const std::string& verbose_error_messages,
                            const Switches& switches) {
  auto error_mapping = std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(verbose_error_messages.data()),
      verbose_error_messages.size(), [](auto, auto) {});
  std::filesystem::path output_path =
      std::filesystem::path(fml::CreateTemporaryDirectory()) /
      "impellerc_verbose_error.txt";

  if (fml::WriteAtomically(*switches.working_directory,
                           Utf8FromPath(output_path).c_str(), *error_mapping)) {
    std::cerr << "Full \"" << InferShaderNameFromPath(switches.source_file_name)
              << "\" error output written to " << output_path << std::endl;
  } else {
    std::cerr << "Failed to write full \""
              << InferShaderNameFromPath(switches.source_file_name)
              << "\" error output to " << output_path << std::endl;
  }
}

bool OutputIPLR(const std::vector<std::shared_ptr<Compiler>>& compilers,
                const Switches& switches) {
  FML_DCHECK(switches.iplr);

  RuntimeStageData stages;
  for (const auto& compiler : compilers) {
    std::shared_ptr<RuntimeStageData::Shader> stage_data =
        compiler->GetReflector()->GetRuntimeStageShaderData();
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

bool OutputSLFile(const Compiler& compiler, const Switches& switches) {
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

bool OutputSPIRV(const Compiler& compiler, const Switches& switches) {
  auto spriv_file_name = std::filesystem::absolute(
      std::filesystem::current_path() / switches.spirv_file_name);
  if (!fml::WriteAtomically(*switches.working_directory,
                            Utf8FromPath(spriv_file_name).c_str(),
                            *compiler.GetSPIRVAssembly())) {
    std::cerr << "Could not write file to " << switches.spirv_file_name
              << std::endl;
    return false;
  }
  return true;
}

bool ShouldOutputReflectionData(const Switches& switches) {
  return !switches.reflection_json_name.empty() ||
         !switches.reflection_header_name.empty() ||
         !switches.reflection_cc_name.empty();
}

bool OutputReflectionData(const Compiler& compiler, const Switches& switches) {
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

bool OutputDepfile(const Compiler& compiler, const Switches& switches) {
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

}  // namespace

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

  std::vector<std::shared_ptr<Compiler>> compilers;
  compilers.reserve(switches.PlatformsToCompile().size());
  for (const auto& platform : switches.PlatformsToCompile()) {
    std::shared_ptr<Compiler> compiler =
        CreateCompiler(platform, source_file_mapping, switches);
    if (compiler->IsValid()) {
      compilers.push_back(compiler);
    } else {
      std::cerr << "Compilation failed for target: "
                << TargetPlatformToString(platform) << std::endl;

      std::string verbose_error_messages = compiler->GetVerboseErrorMessages();
      if (verbose_error_messages.empty()) {
        // No verbose error messages. Output the regular error messages.
        std::cerr << compiler->GetErrorMessages();
      } else {
        if (switches.verbose) {
          // Verbose messages are available and the --verbose flag was set.
          // Directly output the verbose error messages.
          std::cerr << verbose_error_messages;
        } else {
          // Verbose messages are available and the --verbose flag was not set.
          // Output the regular error messages and write the verbose error
          // messages to a file.
          std::cerr << compiler->GetErrorMessages();
          OutputVerboseErrorFile(verbose_error_messages, switches);
        }
      }

      return false;
    }
  }

  // --------------------------------------------------------------------------
  /// 1. Output the source file. When in IPLR/RuntimeStage mode, output the
  ///    serialized IPLR flatbuffer. Otherwise output the shader source in the
  ///    target shading language.
  ///

  if (switches.iplr) {
    if (!OutputIPLR(compilers, switches)) {
      return false;
    }
  } else {
    // Non-IPLR mode is supported only for single platform targets. There is
    // exactly 1 created compiler for this case.
    FML_DCHECK(compilers.size() == 1);
    if (!OutputSLFile(*compilers.front(), switches)) {
      return false;
    }
  }

  // Use the first compiler for outputting the SPIRV file, reflection data, and
  // the depfile. The SPIRV and depfile outputs do not depend on the target
  // platform, so any valid compiler can be used. Reflection data output is only
  // supported for single platform targets, so it uses the first (only) valid
  // compiler as well.
  auto first_valid_compiler = compilers.front();

  // --------------------------------------------------------------------------
  /// 2. Output SPIRV file.
  ///

  if (!OutputSPIRV(*first_valid_compiler, switches)) {
    return false;
  }

  // --------------------------------------------------------------------------
  /// 3. Output shader reflection data.
  ///    May include a JSON file, a C++ header, and/or a C++ TU.
  ///

  if (ShouldOutputReflectionData(switches)) {
    // Outputting reflection data is supported only for single platform targets.
    FML_DCHECK(compilers.size() == 1);
    if (!OutputReflectionData(*first_valid_compiler, switches)) {
      return false;
    }
  }

  // --------------------------------------------------------------------------
  /// 4. Output a depfile.
  ///

  // Dep file output does not depend on the target platform. Any valid compiler
  // can be used to output it. Arbitrarily pick the first valid compiler.
  if (!OutputDepfile(*first_valid_compiler, switches)) {
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
