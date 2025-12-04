// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstring>
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/base/validation.h"
#include "impeller/compiler/compiler.h"
#include "impeller/compiler/compiler_test.h"
#include "impeller/compiler/source_options.h"
#include "impeller/compiler/types.h"

namespace impeller {
namespace compiler {
namespace testing {

TEST(CompilerTest, Defines) {
  std::shared_ptr<const fml::Mapping> fixture =
      flutter::testing::OpenFixtureAsMapping("check_gles_definition.frag");

  SourceOptions options;
  options.source_language = SourceLanguage::kGLSL;
  options.target_platform = TargetPlatform::kRuntimeStageGLES;
  options.entry_point_name = "main";
  options.type = SourceType::kFragmentShader;

  Reflector::Options reflector_options;
  reflector_options.target_platform = TargetPlatform::kRuntimeStageGLES;
  Compiler compiler = Compiler(fixture, options, reflector_options);

  // Should fail as the shader has a compilation error in it.
  EXPECT_EQ(compiler.GetSPIRVAssembly(), nullptr);

  // Should succeed as the compilation error is ifdef'd out.
  options.target_platform = TargetPlatform::kRuntimeStageVulkan;
  reflector_options.target_platform = TargetPlatform::kRuntimeStageVulkan;
  Compiler compiler_2 = Compiler(fixture, options, reflector_options);
  EXPECT_NE(compiler_2.GetSPIRVAssembly(), nullptr);
}

TEST(CompilerTest, ShaderKindMatchingIsSuccessful) {
  ASSERT_EQ(SourceTypeFromFileName("hello.vert"), SourceType::kVertexShader);
  ASSERT_EQ(SourceTypeFromFileName("hello.frag"), SourceType::kFragmentShader);
  ASSERT_EQ(SourceTypeFromFileName("hello.comp"), SourceType::kComputeShader);
  ASSERT_EQ(SourceTypeFromFileName("hello.msl"), SourceType::kUnknown);
  ASSERT_EQ(SourceTypeFromFileName("hello.glsl"), SourceType::kUnknown);
}

TEST_P(CompilerTest, CanCompile) {
  if (GetParam() == TargetPlatform::kSkSL) {
    GTEST_SKIP() << "Not supported with SkSL";
  }
  ASSERT_TRUE(CanCompileAndReflect("sample.vert"));
  ASSERT_TRUE(CanCompileAndReflect("sample.vert", SourceType::kVertexShader));
  ASSERT_TRUE(CanCompileAndReflect("sample.vert", SourceType::kVertexShader,
                                   SourceLanguage::kGLSL));
}

TEST_P(CompilerTest, CanCompileHLSL) {
  if (GetParam() == TargetPlatform::kSkSL) {
    GTEST_SKIP() << "Not supported with SkSL";
  }
  ASSERT_TRUE(CanCompileAndReflect(
      "simple.vert.hlsl", SourceType::kVertexShader, SourceLanguage::kHLSL));
}

TEST_P(CompilerTest, CanCompileHLSLWithMultipleStages) {
  if (GetParam() == TargetPlatform::kSkSL) {
    GTEST_SKIP() << "Not supported with SkSL";
  }
  ASSERT_TRUE(CanCompileAndReflect("multiple_stages.hlsl",
                                   SourceType::kVertexShader,
                                   SourceLanguage::kHLSL, "VertexShader"));
  ASSERT_TRUE(CanCompileAndReflect("multiple_stages.hlsl",
                                   SourceType::kFragmentShader,
                                   SourceLanguage::kHLSL, "FragmentShader"));
}

TEST_P(CompilerTest, CanCompileComputeShader) {
  if (!TargetPlatformIsMetal(GetParam())) {
    GTEST_SKIP()
        << "Only enabled on Metal backends till ES 3.2 support is added.";
  }
  ASSERT_TRUE(CanCompileAndReflect("sample.comp"));
  ASSERT_TRUE(CanCompileAndReflect("sample.comp", SourceType::kComputeShader));
}

TEST_P(CompilerTest, MustFailDueToExceedingResourcesLimit) {
  if (GetParam() == TargetPlatform::kSkSL) {
    GTEST_SKIP() << "Not supported with SkSL";
  }
  ScopedValidationDisable disable_validation;
  ASSERT_FALSE(
      CanCompileAndReflect("resources_limit.vert", SourceType::kVertexShader));
}

TEST_P(CompilerTest, MustFailDueToMultipleLocationPerStructMember) {
  if (GetParam() == TargetPlatform::kSkSL) {
    GTEST_SKIP() << "Not supported with SkSL";
  }
  ScopedValidationDisable disable_validation;
  ASSERT_FALSE(CanCompileAndReflect("struct_def_bug.vert"));
}

TEST_P(CompilerTest, BindingBaseForFragShader) {
  if (!TargetPlatformIsVulkan(GetParam())) {
    GTEST_SKIP();
  }

  ASSERT_TRUE(CanCompileAndReflect("sample.vert", SourceType::kVertexShader));
  ASSERT_TRUE(CanCompileAndReflect("sample.frag", SourceType::kFragmentShader));

  auto get_binding = [&](const char* fixture) -> uint32_t {
    auto json_fd = GetReflectionJson(fixture);
    nlohmann::json shader_json = nlohmann::json::parse(json_fd->GetMapping());
    return shader_json["buffers"][0]["binding"].get<uint32_t>();
  };

  auto vert_uniform_binding = get_binding("sample.vert");
  auto frag_uniform_binding = get_binding("sample.frag");

  ASSERT_GT(frag_uniform_binding, vert_uniform_binding);
}

namespace {
struct UniformInfo {
  static UniformInfo fromJson(nlohmann::json& json) {
    return {
        .uniform_name = json["name"].get<std::string>(),
        .location = json["location"].get<uint32_t>(),
        .type_name = json["type"]["type_name"].get<std::string>(),
        .columns = json["type"]["columns"].get<uint32_t>(),
        .vec_size = json["type"]["vec_size"].get<uint32_t>(),
    };
  }
  std::string uniform_name;
  uint32_t location;
  std::string type_name;
  uint32_t columns;
  uint32_t vec_size;

  constexpr bool operator==(const UniformInfo& other) const {
    return (uniform_name == other.uniform_name &&  //
            location == other.location &&          //
            type_name == other.type_name &&        //
            columns == other.columns &&            //
            vec_size == other.vec_size);
  }
};

inline std::ostream& operator<<(std::ostream& out, const UniformInfo& info) {
  out << "UniformInfo {" << std::endl
      << "  uniform_name: " << info.uniform_name << std::endl
      << "  location: " << info.location << std::endl
      << "  type_name: " << info.type_name << std::endl
      << "  columns: " << info.columns << std::endl
      << "  vec_size: " << info.vec_size << std::endl
      << "}";
  return out;
}
}  // namespace

TEST_P(CompilerTestRuntime, UniformsAppearInJson) {
  ASSERT_TRUE(CanCompileAndReflect("sample_with_uniforms.frag",
                                   SourceType::kFragmentShader,
                                   SourceLanguage::kGLSL));

  auto json_fd = GetReflectionJson("sample_with_uniforms.frag");
  ASSERT_TRUE(json_fd);
  nlohmann::json shader_json = nlohmann::json::parse(json_fd->GetMapping());
  auto sampler_list = shader_json["sampled_images"];
  auto float_list = shader_json["uniforms"];
  ASSERT_EQ(sampler_list.size(), 2u);
  ASSERT_EQ(float_list.size(), 6u);

  {
    UniformInfo expected = UniformInfo{
        .uniform_name = "uFirstSampler",
        .location = 1u,
        .type_name = "ShaderType::kSampledImage",
        .columns = 1u,
        .vec_size = 1u,
    };
    EXPECT_EQ(UniformInfo::fromJson(sampler_list[0]), expected);
  }

  {
    UniformInfo expected = UniformInfo{
        .uniform_name = "uSampler",
        .location = 7u,
        .type_name = "ShaderType::kSampledImage",
        .columns = 1u,
        .vec_size = 1u,
    };
    EXPECT_EQ(UniformInfo::fromJson(sampler_list[1]), expected);
  }

  {
    UniformInfo expected = UniformInfo{
        .uniform_name = "uFirstFloat",
        .location = 0u,
        .type_name = "ShaderType::kFloat",
        .columns = 1u,
        .vec_size = 1u,
    };
    EXPECT_EQ(UniformInfo::fromJson(float_list[0]), expected);
  }

  {
    UniformInfo expected = UniformInfo{
        .uniform_name = "uFloat",
        .location = 2u,
        .type_name = "ShaderType::kFloat",
        .columns = 1u,
        .vec_size = 1u,
    };
    EXPECT_EQ(UniformInfo::fromJson(float_list[1]), expected);
  }

  {
    UniformInfo expected = UniformInfo{
        .uniform_name = "uVec2",
        .location = 3u,
        .type_name = "ShaderType::kFloat",
        .columns = 1u,
        .vec_size = 2u,
    };
    EXPECT_EQ(UniformInfo::fromJson(float_list[2]), expected);
  }

  {
    UniformInfo expected = UniformInfo{
        .uniform_name = "uVec3",
        .location = 4u,
        .type_name = "ShaderType::kFloat",
        .columns = 1u,
        .vec_size = 3u,
    };
    EXPECT_EQ(UniformInfo::fromJson(float_list[3]), expected);
  }

  {
    UniformInfo expected = UniformInfo{
        .uniform_name = "uVec4",
        .location = 5u,
        .type_name = "ShaderType::kFloat",
        .columns = 1u,
        .vec_size = 4u,
    };
    EXPECT_EQ(UniformInfo::fromJson(float_list[4]), expected);
  }

  {
    UniformInfo expected = UniformInfo{
        .uniform_name = "uMat4",
        .location = 6u,
        .type_name = "ShaderType::kFloat",
        .columns = 4u,
        .vec_size = 4u,
    };
    EXPECT_EQ(UniformInfo::fromJson(float_list[5]), expected);
  }
}

TEST_P(CompilerTest, UniformsHaveBindingAndSet) {
  if (GetParam() == TargetPlatform::kSkSL) {
    GTEST_SKIP() << "Not supported with SkSL";
  }
  ASSERT_TRUE(CanCompileAndReflect("sample_with_binding.vert",
                                   SourceType::kVertexShader));
  ASSERT_TRUE(CanCompileAndReflect("sample.frag", SourceType::kFragmentShader));

  struct binding_and_set {
    uint32_t binding;
    uint32_t set;
  };

  auto get_binding = [&](const char* fixture) -> binding_and_set {
    auto json_fd = GetReflectionJson(fixture);
    nlohmann::json shader_json = nlohmann::json::parse(json_fd->GetMapping());
    uint32_t binding = shader_json["buffers"][0]["binding"].get<uint32_t>();
    uint32_t set = shader_json["buffers"][0]["set"].get<uint32_t>();
    return {binding, set};
  };

  auto vert_uniform_binding = get_binding("sample_with_binding.vert");
  auto frag_uniform_binding = get_binding("sample.frag");

  ASSERT_EQ(frag_uniform_binding.set, 0u);
  ASSERT_EQ(vert_uniform_binding.set, 3u);
  ASSERT_EQ(vert_uniform_binding.binding, 17u);
}

TEST_P(CompilerTest, SkSLTextureLookUpOrderOfOperations) {
  if (GetParam() != TargetPlatform::kSkSL) {
    GTEST_SKIP() << "Only supported on SkSL";
  }
  ASSERT_TRUE(
      CanCompileAndReflect("texture_lookup.frag", SourceType::kFragmentShader));

  auto shader = GetShaderFile("texture_lookup.frag", GetParam());
  std::string_view shader_mapping(
      reinterpret_cast<const char*>(shader->GetMapping()), shader->GetSize());

  constexpr std::string_view expected =
      "textureA.eval(textureA_size * ( vec2(1.0) + flutter_FragCoord.xy));";

  EXPECT_NE(shader_mapping.find(expected), std::string::npos);
}

TEST_P(CompilerTest, CanCompileStructs) {
  if (GetParam() != TargetPlatform::kSkSL) {
    GTEST_SKIP() << "Only supported on SkSL";
  }
  ASSERT_TRUE(CanCompileAndReflect("struct_internal.frag",
                                   SourceType::kFragmentShader));
}

#define INSTANTIATE_TARGET_PLATFORM_TEST_SUITE_P(suite_name)               \
  INSTANTIATE_TEST_SUITE_P(                                                \
      suite_name, CompilerTest,                                            \
      ::testing::Values(TargetPlatform::kOpenGLES,                         \
                        TargetPlatform::kOpenGLDesktop,                    \
                        TargetPlatform::kMetalDesktop,                     \
                        TargetPlatform::kMetalIOS, TargetPlatform::kSkSL), \
      [](const ::testing::TestParamInfo<CompilerTest::ParamType>& info) {  \
        return TargetPlatformToString(info.param);                         \
      });

INSTANTIATE_TARGET_PLATFORM_TEST_SUITE_P(CompilerSuite);

#define INSTANTIATE_RUNTIME_TARGET_PLATFORM_TEST_SUITE_P(suite_name)      \
  INSTANTIATE_TEST_SUITE_P(                                               \
      suite_name, CompilerTestRuntime,                                    \
      ::testing::Values(TargetPlatform::kRuntimeStageMetal),              \
      [](const ::testing::TestParamInfo<CompilerTest::ParamType>& info) { \
        return TargetPlatformToString(info.param);                        \
      });

INSTANTIATE_RUNTIME_TARGET_PLATFORM_TEST_SUITE_P(CompilerSuite);

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
