// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/compiler.h"

#include <filesystem>
#include <memory>
#include <sstream>

#include "flutter/fml/paths.h"
#include "impeller/compiler/compiler_backend.h"
#include "impeller/compiler/includer.h"
#include "impeller/compiler/logger.h"

namespace impeller {
namespace compiler {

static CompilerBackend CreateMSLCompiler(const spirv_cross::ParsedIR& ir,
                                         const SourceOptions& source_options) {
  auto sl_compiler = std::make_shared<spirv_cross::CompilerMSL>(ir);
  spirv_cross::CompilerMSL::Options sl_options;
  sl_options.platform =
      TargetPlatformToMSLPlatform(source_options.target_platform);
  // If this version specification changes, the GN rules that process the
  // Metal to AIR must be updated as well.
  sl_options.msl_version =
      spirv_cross::CompilerMSL::Options::make_msl_version(1, 2);
  sl_compiler->set_msl_options(sl_options);
  return sl_compiler;
}

static CompilerBackend CreateGLSLCompiler(const spirv_cross::ParsedIR& ir,
                                          const SourceOptions& source_options) {
  auto gl_compiler = std::make_shared<spirv_cross::CompilerGLSL>(ir);
  spirv_cross::CompilerGLSL::Options sl_options;
  sl_options.force_zero_initialized_variables = true;
  sl_options.vertex.fixup_clipspace = true;
  if (source_options.target_platform == TargetPlatform::kOpenGLES) {
    sl_options.version = 100;
    sl_options.es = true;
  } else {
    sl_options.version = 120;
    sl_options.es = false;
  }
  gl_compiler->set_common_options(sl_options);
  return gl_compiler;
}

static bool EntryPointMustBeNamedMain(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform::kUnknown:
      FML_UNREACHABLE();
    case TargetPlatform::kMetalDesktop:
    case TargetPlatform::kMetalIOS:
    case TargetPlatform::kRuntimeStageMetal:
      return false;
    case TargetPlatform::kFlutterSPIRV:
    case TargetPlatform::kOpenGLES:
    case TargetPlatform::kOpenGLDesktop:
    case TargetPlatform::kRuntimeStageGLES:
      return true;
  }
  FML_UNREACHABLE();
}

static CompilerBackend CreateCompiler(const spirv_cross::ParsedIR& ir,
                                      const SourceOptions& source_options) {
  CompilerBackend compiler;
  switch (source_options.target_platform) {
    case TargetPlatform::kMetalDesktop:
    case TargetPlatform::kMetalIOS:
    case TargetPlatform::kRuntimeStageMetal:
    case TargetPlatform::kRuntimeStageGLES:
      compiler = CreateMSLCompiler(ir, source_options);
      break;
    case TargetPlatform::kUnknown:
    case TargetPlatform::kFlutterSPIRV:
    case TargetPlatform::kOpenGLES:
    case TargetPlatform::kOpenGLDesktop:
      compiler = CreateGLSLCompiler(ir, source_options);
      break;
  }
  if (!compiler) {
    return {};
  }
  auto* backend = compiler.GetCompiler();
  if (!EntryPointMustBeNamedMain(source_options.target_platform)) {
    backend->rename_entry_point("main", source_options.entry_point_name,
                                ToExecutionModel(source_options.type));
  }
  return compiler;
}

Compiler::Compiler(const fml::Mapping& source_mapping,
                   SourceOptions source_options,
                   Reflector::Options reflector_options)
    : options_(source_options) {
  if (source_mapping.GetMapping() == nullptr) {
    COMPILER_ERROR
        << "Could not read shader source or shader source was empty.";
    return;
  }

  if (source_options.target_platform == TargetPlatform::kUnknown) {
    COMPILER_ERROR << "Target platform not specified.";
    return;
  }

  auto shader_kind = ToShaderCShaderKind(source_options.type);

  if (shader_kind == shaderc_shader_kind::shaderc_glsl_infer_from_source) {
    COMPILER_ERROR << "Could not figure out shader stage.";
    return;
  }

  shaderc::CompileOptions spirv_options;

  // Make sure reflection is as effective as possible. The generated shaders
  // will be processed later by backend specific compilers. So optimizations
  // here are irrelevant and get in the way of generating reflection code.
  spirv_options.SetGenerateDebugInfo();

  // Expects GLSL 4.60 (Core Profile).
  // https://www.khronos.org/registry/OpenGL/specs/gl/GLSLangSpec.4.60.pdf
  spirv_options.SetSourceLanguage(
      shaderc_source_language::shaderc_source_language_glsl);
  spirv_options.SetForcedVersionProfile(460,
                                        shaderc_profile::shaderc_profile_core);
  switch (source_options.target_platform) {
    case TargetPlatform::kMetalDesktop:
    case TargetPlatform::kMetalIOS:
    case TargetPlatform::kOpenGLES:
    case TargetPlatform::kOpenGLDesktop:
      spirv_options.SetOptimizationLevel(
          shaderc_optimization_level::shaderc_optimization_level_performance);
      spirv_options.SetTargetEnvironment(
          shaderc_target_env::shaderc_target_env_vulkan,
          shaderc_env_version::shaderc_env_version_vulkan_1_1);
      spirv_options.SetTargetSpirv(
          shaderc_spirv_version::shaderc_spirv_version_1_3);
      break;
    case TargetPlatform::kRuntimeStageMetal:
    case TargetPlatform::kRuntimeStageGLES:
      spirv_options.SetOptimizationLevel(
          shaderc_optimization_level::shaderc_optimization_level_performance);
      spirv_options.SetTargetEnvironment(
          shaderc_target_env::shaderc_target_env_opengl,
          shaderc_env_version::shaderc_env_version_opengl_4_5);
      spirv_options.SetTargetSpirv(
          shaderc_spirv_version::shaderc_spirv_version_1_0);
      break;
    case TargetPlatform::kFlutterSPIRV:
      // With any optimization level above 'zero' enabled, shaderc will emit
      // ops that are not supported by the Engine's SPIR-V -> SkSL transpiler.
      // In particular, with 'shaderc_optimization_level_size' enabled, it will
      // generate OpPhi (opcode 245) for test 246_OpLoopMerge.frag instead of
      // the OpLoopMerge op expected by that test.
      // See: https://github.com/flutter/flutter/issues/105396.
      spirv_options.SetOptimizationLevel(
          shaderc_optimization_level::shaderc_optimization_level_zero);
      spirv_options.SetTargetEnvironment(
          shaderc_target_env::shaderc_target_env_opengl,
          shaderc_env_version::shaderc_env_version_opengl_4_5);
      spirv_options.SetTargetSpirv(
          shaderc_spirv_version::shaderc_spirv_version_1_0);
      break;
    case TargetPlatform::kUnknown:
      COMPILER_ERROR << "Target platform invalid.";
      return;
  }

  // Implicit definition that indicates that this compilation is for the device
  // (instead of the host).
  spirv_options.AddMacroDefinition("IMPELLER_DEVICE");
  for (const auto& define : source_options.defines) {
    spirv_options.AddMacroDefinition(define);
  }

  spirv_options.SetAutoBindUniforms(true);
  spirv_options.SetAutoMapLocations(true);

  std::vector<std::string> included_file_names;
  spirv_options.SetIncluder(std::make_unique<Includer>(
      options_.working_directory, options_.include_dirs,
      [&included_file_names](auto included_name) {
        included_file_names.emplace_back(std::move(included_name));
      }));

  shaderc::Compiler spv_compiler;
  if (!spv_compiler.IsValid()) {
    COMPILER_ERROR << "Could not initialize the GLSL to SPIRV compiler.";
    return;
  }

  // SPIRV Generation.
  spv_result_ = std::make_shared<shaderc::SpvCompilationResult>(
      spv_compiler.CompileGlslToSpv(
          reinterpret_cast<const char*>(
              source_mapping.GetMapping()),         // source_text
          source_mapping.GetSize(),                 // source_text_size
          shader_kind,                              // shader_kind
          source_options.file_name.c_str(),         // input_file_name
          source_options.entry_point_name.c_str(),  // entry_point_name
          spirv_options                             // options
          ));
  if (spv_result_->GetCompilationStatus() !=
      shaderc_compilation_status::shaderc_compilation_status_success) {
    COMPILER_ERROR << "GLSL to SPIRV failed; "
                   << ShaderCErrorToString(spv_result_->GetCompilationStatus())
                   << ". " << spv_result_->GetNumErrors() << " error(s) and "
                   << spv_result_->GetNumWarnings() << " warning(s).";
    if (spv_result_->GetNumErrors() > 0 || spv_result_->GetNumWarnings() > 0) {
      COMPILER_ERROR_NO_PREFIX << spv_result_->GetErrorMessage();
    }
    return;
  } else {
    included_file_names_ = std::move(included_file_names);
  }

  if (!TargetPlatformNeedsSL(source_options.target_platform)) {
    is_valid_ = true;
    return;
  }

  // SL Generation.
  spirv_cross::Parser parser(spv_result_->cbegin(),
                             spv_result_->cend() - spv_result_->cbegin());
  // The parser and compiler must be run separately because the parser contains
  // meta information (like type member names) that are useful for reflection.
  parser.parse();

  const auto parsed_ir =
      std::make_shared<spirv_cross::ParsedIR>(parser.get_parsed_ir());

  auto sl_compiler = CreateCompiler(*parsed_ir, options_);

  if (!sl_compiler) {
    COMPILER_ERROR << "Could not create compiler for target platform.";
    return;
  }

  sl_string_ =
      std::make_shared<std::string>(sl_compiler.GetCompiler()->compile());

  if (!sl_string_) {
    COMPILER_ERROR << "Could not generate SL from SPIRV";
    return;
  }

  reflector_ = std::make_unique<Reflector>(std::move(reflector_options),  //
                                           parsed_ir,                     //
                                           GetSLShaderSource(),           //
                                           sl_compiler                    //
  );

  if (!reflector_->IsValid()) {
    COMPILER_ERROR << "Could not complete reflection on generated shader.";
    return;
  }

  is_valid_ = true;
}

Compiler::~Compiler() = default;

std::unique_ptr<fml::Mapping> Compiler::GetSPIRVAssembly() const {
  if (!spv_result_) {
    return nullptr;
  }
  const auto data_length =
      (spv_result_->cend() - spv_result_->cbegin()) *
      sizeof(decltype(spv_result_)::element_type::element_type);

  return std::make_unique<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(spv_result_->cbegin()), data_length,
      [result = spv_result_](auto, auto) mutable { result.reset(); });
}

std::unique_ptr<fml::Mapping> Compiler::GetSLShaderSource() const {
  if (!sl_string_) {
    return nullptr;
  }

  return std::make_unique<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(sl_string_->c_str()),
      sl_string_->length(),
      [string = sl_string_](auto, auto) mutable { string.reset(); });
}

bool Compiler::IsValid() const {
  return is_valid_;
}

std::string Compiler::GetSourcePrefix() const {
  std::stringstream stream;
  stream << options_.file_name << ": ";
  return stream.str();
}

std::string Compiler::GetErrorMessages() const {
  return error_stream_.str();
}

const std::vector<std::string>& Compiler::GetIncludedFileNames() const {
  return included_file_names_;
}

static std::string JoinStrings(std::vector<std::string> items,
                               std::string separator) {
  std::stringstream stream;
  for (size_t i = 0, count = items.size(); i < count; i++) {
    const auto is_last = (i == count - 1);

    stream << items[i];
    if (!is_last) {
      stream << separator;
    }
  }
  return stream.str();
}

std::string Compiler::GetDependencyNames(std::string separator) const {
  std::vector<std::string> dependencies = included_file_names_;
  dependencies.push_back(options_.file_name);
  return JoinStrings(dependencies, separator);
}

std::unique_ptr<fml::Mapping> Compiler::CreateDepfileContents(
    std::initializer_list<std::string> targets_names) const {
  const auto targets = JoinStrings(targets_names, " ");
  const auto dependencies = GetDependencyNames(" ");

  std::stringstream stream;
  stream << targets << ": " << dependencies << "\n";

  auto contents = std::make_shared<std::string>(stream.str());
  return std::make_unique<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(contents->data()), contents->size(),
      [contents](auto, auto) {});
}

const Reflector* Compiler::GetReflector() const {
  return reflector_.get();
}

}  // namespace compiler
}  // namespace impeller
