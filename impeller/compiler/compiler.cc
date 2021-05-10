// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/compiler.h"

#include <memory>

namespace impeller {
namespace compiler {

class Includer final : public shaderc::CompileOptions::IncluderInterface {
 public:
  Includer() = default;

  // |shaderc::CompileOptions::IncluderInterface|
  ~Includer() override = default;

  // |shaderc::CompileOptions::IncluderInterface|
  shaderc_include_result* GetInclude(const char* requested_source,
                                     shaderc_include_type type,
                                     const char* requesting_source,
                                     size_t include_depth) override {
    return nullptr;
  }

  // |shaderc::CompileOptions::IncluderInterface|
  void ReleaseInclude(shaderc_include_result* data) override {}

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Includer);
};

static shaderc_shader_kind ToShaderCShaderKind(Compiler::SourceType type) {
  switch (type) {
    case Compiler::SourceType::kVertexShader:
      return shaderc_shader_kind::shaderc_vertex_shader;
    case Compiler::SourceType::kFragmentShader:
      return shaderc_shader_kind::shaderc_fragment_shader;
  }
  return shaderc_shader_kind::shaderc_vertex_shader;
}

Compiler::Compiler(const fml::Mapping& source_mapping,
                   SourceOptions source_options) {
  if (source_mapping.GetMapping() == nullptr) {
    return;
  }

  shaderc::CompileOptions options;
  options.SetGenerateDebugInfo();
  options.SetOptimizationLevel(
      shaderc_optimization_level::shaderc_optimization_level_size);
  options.SetSourceLanguage(
      shaderc_source_language::shaderc_source_language_glsl);
  options.SetTargetEnvironment(
      shaderc_target_env::shaderc_target_env_vulkan,
      shaderc_env_version::shaderc_env_version_opengl_4_5);
  options.SetTargetSpirv(shaderc_spirv_version::shaderc_spirv_version_1_3);
  options.SetAutoBindUniforms(true);
  options.SetAutoMapLocations(true);
  options.SetIncluder(std::make_unique<Includer>());

  shaderc::Compiler compiler;
  if (!compiler.IsValid()) {
    return;
  }

  result_ = compiler.CompileGlslToSpv(
      reinterpret_cast<const char*>(
          source_mapping.GetMapping()),          // source_text
      source_mapping.GetSize(),                  // source_text_size
      ToShaderCShaderKind(source_options.type),  // shader_kind
      source_options.file_name.c_str(),          // input_file_name
      source_options.entry_point_name.c_str(),   // entry_point_name
      options                                    // options
  );
  is_valid_ = true;
}

Compiler::~Compiler() = default;

}  // namespace compiler
}  // namespace impeller
