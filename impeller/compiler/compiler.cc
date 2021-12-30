// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/compiler.h"

#include <filesystem>
#include <memory>
#include <sstream>

#include "flutter/fml/paths.h"
#include "flutter/impeller/compiler/logger.h"

namespace impeller {
namespace compiler {

#define COMPILER_ERROR \
  ::impeller::compiler::AutoLogger(error_stream_) << GetSourcePrefix()

#define COMPILER_ERROR_NO_PREFIX ::impeller::compiler::AutoLogger(error_stream_)

struct IncluderData {
  std::string file_name;
  std::unique_ptr<fml::Mapping> mapping;

  IncluderData(std::string p_file_name, std::unique_ptr<fml::Mapping> p_mapping)
      : file_name(std::move(p_file_name)), mapping(std::move(p_mapping)) {}
};

class Includer final : public shaderc::CompileOptions::IncluderInterface {
 public:
  Includer(std::shared_ptr<fml::UniqueFD> working_directory,
           std::vector<IncludeDir> include_dirs,
           std::function<void(std::string)> on_file_included)
      : working_directory_(std::move(working_directory)),
        include_dirs_(std::move(include_dirs)),
        on_file_included_(std::move(on_file_included)) {}

  // |shaderc::CompileOptions::IncluderInterface|
  ~Includer() override = default;

  std::unique_ptr<fml::FileMapping> TryOpenMapping(
      const IncludeDir& dir,
      const char* requested_source) {
    if (!dir.dir || !dir.dir->is_valid()) {
      return nullptr;
    }

    if (requested_source == nullptr) {
      return nullptr;
    }

    std::string source(requested_source);
    if (source.empty()) {
      return nullptr;
    }

    auto mapping = fml::FileMapping::CreateReadOnly(*dir.dir, requested_source);
    if (!mapping || !mapping->IsValid()) {
      return nullptr;
    }

    on_file_included_(fml::paths::JoinPaths({dir.name, requested_source}));

    return mapping;
  }

  std::unique_ptr<fml::FileMapping> FindFirstMapping(
      const char* requested_source) {
    // Always try the working directory first no matter what the include
    // directories are.
    {
      IncludeDir dir;
      dir.name = ".";
      dir.dir = working_directory_;
      if (auto mapping = TryOpenMapping(dir, requested_source)) {
        return mapping;
      }
    }

    for (const auto& include_dir : include_dirs_) {
      if (auto mapping = TryOpenMapping(include_dir, requested_source)) {
        return mapping;
      }
    }
    return nullptr;
  }

  // |shaderc::CompileOptions::IncluderInterface|
  shaderc_include_result* GetInclude(const char* requested_source,
                                     shaderc_include_type type,
                                     const char* requesting_source,
                                     size_t include_depth) override {
    auto result = std::make_unique<shaderc_include_result>();

    // Default initialize to failed inclusion.
    result->source_name = "";
    result->source_name_length = 0;

    constexpr const char* kFileNotFoundMessage = "Included file not found.";
    result->content = kFileNotFoundMessage;
    result->content_length = ::strlen(kFileNotFoundMessage);
    result->user_data = nullptr;

    if (!working_directory_ || !working_directory_->is_valid()) {
      return result.release();
    }

    if (requested_source == nullptr) {
      return result.release();
    }

    auto file = FindFirstMapping(requested_source);

    if (!file || file->GetMapping() == nullptr) {
      return result.release();
    }

    auto includer_data =
        std::make_unique<IncluderData>(requested_source, std::move(file));

    result->source_name = includer_data->file_name.c_str();
    result->source_name_length = includer_data->file_name.length();
    result->content = reinterpret_cast<decltype(result->content)>(
        includer_data->mapping->GetMapping());
    result->content_length = includer_data->mapping->GetSize();
    result->user_data = includer_data.release();

    return result.release();
  }

  // |shaderc::CompileOptions::IncluderInterface|
  void ReleaseInclude(shaderc_include_result* data) override {
    delete reinterpret_cast<IncluderData*>(data->user_data);
    delete data;
  }

 private:
  std::shared_ptr<fml::UniqueFD> working_directory_;
  std::vector<IncludeDir> include_dirs_;
  std::function<void(std::string)> on_file_included_;

  FML_DISALLOW_COPY_AND_ASSIGN(Includer);
};

static std::string ShaderCErrorToString(shaderc_compilation_status status) {
  switch (status) {
    case shaderc_compilation_status::shaderc_compilation_status_success:
      return "Success";
    case shaderc_compilation_status::shaderc_compilation_status_invalid_stage:
      return "Invalid Shader Stage Specified";
    case shaderc_compilation_status::
        shaderc_compilation_status_compilation_error:
      return "Compilation Error";
    case shaderc_compilation_status::shaderc_compilation_status_internal_error:
      return "Internal Error";
    case shaderc_compilation_status::
        shaderc_compilation_status_null_result_object:
      return "Internal error. Null Result Object";
    case shaderc_compilation_status::
        shaderc_compilation_status_invalid_assembly:
      return "Invalid Assembly";
    case shaderc_compilation_status::
        shaderc_compilation_status_validation_error:
      return "Validation Error";
    case shaderc_compilation_status::
        shaderc_compilation_status_transformation_error:
      return "Transformation Error";
    case shaderc_compilation_status::
        shaderc_compilation_status_configuration_error:
      return "Configuration Error";
  }
  return "Unknown Internal Error";
}

static shaderc_shader_kind ToShaderCShaderKind(Compiler::SourceType type) {
  switch (type) {
    case Compiler::SourceType::kVertexShader:
      return shaderc_shader_kind::shaderc_vertex_shader;
    case Compiler::SourceType::kFragmentShader:
      return shaderc_shader_kind::shaderc_fragment_shader;
    case Compiler::SourceType::kUnknown:
      break;
  }
  return shaderc_shader_kind::shaderc_glsl_infer_from_source;
}

static spv::ExecutionModel ToExecutionModel(Compiler::SourceType type) {
  switch (type) {
    case Compiler::SourceType::kVertexShader:
      return spv::ExecutionModel::ExecutionModelVertex;
    case Compiler::SourceType::kFragmentShader:
      return spv::ExecutionModel::ExecutionModelFragment;
    case Compiler::SourceType::kUnknown:
      break;
  }
  return spv::ExecutionModel::ExecutionModelMax;
  ;
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

  auto shader_kind = ToShaderCShaderKind(source_options.type);

  if (shader_kind == shaderc_shader_kind::shaderc_glsl_infer_from_source) {
    COMPILER_ERROR << "Could not figure out shader stage.";
    return;
  }

  shaderc::CompileOptions options;

  // Make sure reflection is as effective as possible. The generated shaders
  // will be processed later by backend specific compilers. So optimizations
  // here are irrelevant and get in the way of generating reflection code.
  options.SetGenerateDebugInfo();
  options.SetOptimizationLevel(
      shaderc_optimization_level::shaderc_optimization_level_zero);

  // Expects GLSL 4.60 (Core Profile).
  // https://www.khronos.org/registry/OpenGL/specs/gl/GLSLangSpec.4.60.pdf
  options.SetSourceLanguage(
      shaderc_source_language::shaderc_source_language_glsl);
  options.SetForcedVersionProfile(460, shaderc_profile::shaderc_profile_core);
  options.SetTargetEnvironment(
      shaderc_target_env::shaderc_target_env_vulkan,
      shaderc_env_version::shaderc_env_version_vulkan_1_1);
  options.SetTargetSpirv(shaderc_spirv_version::shaderc_spirv_version_1_3);

  options.SetAutoBindUniforms(true);
  options.SetAutoMapLocations(true);

  options.AddMacroDefinition("IMPELLER_DEVICE");

  std::vector<std::string> included_file_names;
  options.SetIncluder(std::make_unique<Includer>(
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
          options                                   // options
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

  // MSL Generation.
  spirv_cross::Parser parser(spv_result_->cbegin(),
                             spv_result_->cend() - spv_result_->cbegin());
  // The parser and compiler must be run separately because the parser contains
  // meta information (like type member names) that are useful for reflection.
  parser.parse();

  const auto parsed_ir =
      std::make_shared<spirv_cross::ParsedIR>(parser.get_parsed_ir());

  const auto msl_compiler =
      std::make_shared<spirv_cross::CompilerMSL>(*parsed_ir);

  {
    msl_compiler->rename_entry_point("main", options_.entry_point_name,
                                     ToExecutionModel(options_.type));
  }

  {
    spirv_cross::CompilerMSL::Options msl_options;
    msl_options.platform = spirv_cross::CompilerMSL::Options::Platform::macOS;
    // If this version specification changes, the GN rules that process the
    // Metal to AIR must be updated as well.
    msl_options.msl_version =
        spirv_cross::CompilerMSL::Options::make_msl_version(1, 2);
    msl_compiler->set_msl_options(msl_options);
  }

  msl_string_ = std::make_shared<std::string>(msl_compiler->compile());

  if (!msl_string_) {
    COMPILER_ERROR << "Could not generate MSL from SPIRV";
    return;
  }

  reflector_ = std::make_unique<Reflector>(std::move(reflector_options),
                                           parsed_ir, msl_compiler);

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

std::unique_ptr<fml::Mapping> Compiler::GetMSLShaderSource() const {
  if (!msl_string_) {
    return nullptr;
  }

  return std::make_unique<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(msl_string_->c_str()),
      msl_string_->length(),
      [string = msl_string_](auto, auto) mutable { string.reset(); });
}

bool Compiler::IsValid() const {
  return is_valid_;
}

static bool StringEndWith(const std::string& string,
                          const std::string& suffix) {
  if (suffix.size() > string.size()) {
    return false;
  }

  if (suffix.empty() || suffix.empty()) {
    return false;
  }

  return string.rfind(suffix) == (string.size() - suffix.size());
}

Compiler::SourceType Compiler::SourceTypeFromFileName(
    const std::string& file_name) {
  if (StringEndWith(file_name, ".vert")) {
    return Compiler::SourceType::kVertexShader;
  }

  if (StringEndWith(file_name, ".frag")) {
    return Compiler::SourceType::kFragmentShader;
  }

  return Compiler::SourceType::kUnknown;
}

std::string Compiler::EntryPointFromSourceName(const std::string& file_name,
                                               SourceType type) {
  std::stringstream stream;
  std::filesystem::path file_path(file_name);
  stream << file_path.stem().native() << "_";
  switch (type) {
    case SourceType::kUnknown:
      stream << "unknown";
      break;
    case SourceType::kVertexShader:
      stream << "vertex";
      break;
    case SourceType::kFragmentShader:
      stream << "fragment";
      break;
  }
  stream << "_main";
  return stream.str();
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
  stream << targets << ":\n\t" << dependencies << "\n";

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
