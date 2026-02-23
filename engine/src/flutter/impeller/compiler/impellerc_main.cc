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

constexpr int kVerboseErrorLineThreshold = 20;
constexpr int kTruncatedErrorShowLines = 5;

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

static std::shared_ptr<Compiler> CreateCompiler(
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

static void OutputCompilationError(const Compiler& compiler,
                                   TargetPlatform platform,
                                   const Switches& switches) {
  std::cerr << "impellerc failed to compile " << switches.source_file_name
            << " to target: " << TargetPlatformToString(platform) << std::endl;
  auto error = compiler.GetErrorMessages();

  // No need to write to a file if no error output filename was provided or the
  // error is short. Output the error directly to cerr.
  auto line_count = std::count(error.begin(), error.end(), '\n');
  if (switches.verbose_error_output.empty() ||
      line_count <= kVerboseErrorLineThreshold) {
    std::cerr << error << std::endl;
    return;
  }

  // Output truncated error to cerr.
  auto prefix = InferShaderNameFromPath(switches.source_file_name) + ": ";
  std::vector<std::string> first_lines;
  std::vector<std::string> last_lines;
  std::stringstream error_stream(error);
  std::string line;
  for (int line_index = 0; std::getline(error_stream, line); line_index++) {
    if (line_index < kTruncatedErrorShowLines) {
      first_lines.push_back(line);
    } else if (line_index > line_count - kTruncatedErrorShowLines) {
      last_lines.push_back(line);
    }
  }
  for (size_t i = 0; i < kTruncatedErrorShowLines; ++i) {
    std::cerr << prefix << first_lines[i] << std::endl;
  }
  std::cerr << prefix << ">>>> TRUNCATED "
            << line_count - 2 * kTruncatedErrorShowLines << " LINES <<<<"
            << std::endl;
  for (size_t i = 0; i < kTruncatedErrorShowLines; ++i) {
    std::cerr << prefix << last_lines[i] << std::endl;
  }

  // Write full error to file.
  auto error_mapping = std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(error.data()), error.size(),
      [](auto, auto) {});
  auto output_path = std::filesystem::absolute(std::filesystem::current_path() /
                                               switches.verbose_error_output);
  if (fml::WriteAtomically(*switches.working_directory,
                           Utf8FromPath(output_path).c_str(), *error_mapping)) {
    std::cerr << prefix
              << "Error output was truncated. Full error output written to "
              << switches.verbose_error_output << std::endl;
  } else {
    std::cerr
        << prefix
        << "Error output was truncated. Failed to write full error output to "
        << switches.verbose_error_output << std::endl;
  }
}

static bool OutputIPLR(const std::vector<std::shared_ptr<Compiler>>& compilers,
                       const Switches& switches) {
  FML_DCHECK(switches.iplr);

  RuntimeStageData stages;
  for (const auto& compiler : compilers) {
    stages.AddShader(compiler->GetReflector()->GetRuntimeStageShaderData());
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

static bool OutputSPIRV(const Compiler& compiler, const Switches& switches) {
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

static bool ShouldOutputReflectionData(const Switches& switches) {
  return !switches.reflection_json_name.empty() ||
         !switches.reflection_header_name.empty() ||
         !switches.reflection_cc_name.empty();
}

static bool OutputReflectionData(const Compiler& compiler,
                                 const Switches& switches) {
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

  std::vector<std::shared_ptr<Compiler>> compilers;
  for (const auto& platform : switches.PlatformsToCompile()) {
    auto compiler = CreateCompiler(platform, source_file_mapping, switches);
    if (compiler->IsValid()) {
      compilers.push_back(compiler);
    } else {
      OutputCompilationError(*compiler, platform, switches);
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
