// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/base/validation.h"
#include "impeller/compiler/compiler.h"
#include "impeller/compiler/compiler_test.h"
#include "impeller/compiler/source_options.h"
#include "impeller/compiler/types.h"

namespace impeller {
namespace compiler {
namespace testing {

TEST(CompilerTest, ShaderKindMatchingIsSuccessful) {
  ASSERT_EQ(SourceTypeFromFileName("hello.vert"), SourceType::kVertexShader);
  ASSERT_EQ(SourceTypeFromFileName("hello.frag"), SourceType::kFragmentShader);
  ASSERT_EQ(SourceTypeFromFileName("hello.tesc"),
            SourceType::kTessellationControlShader);
  ASSERT_EQ(SourceTypeFromFileName("hello.tese"),
            SourceType::kTessellationEvaluationShader);
  ASSERT_EQ(SourceTypeFromFileName("hello.comp"), SourceType::kComputeShader);
  ASSERT_EQ(SourceTypeFromFileName("hello.msl"), SourceType::kUnknown);
  ASSERT_EQ(SourceTypeFromFileName("hello.glsl"), SourceType::kUnknown);
}

TEST_P(CompilerTest, CanCompile) {
  ASSERT_TRUE(CanCompileAndReflect("sample.vert"));
  ASSERT_TRUE(CanCompileAndReflect("sample.vert", SourceType::kVertexShader));
  ASSERT_TRUE(CanCompileAndReflect("sample.vert", SourceType::kVertexShader,
                                   SourceLanguage::kGLSL));
}

TEST_P(CompilerTest, CanCompileHLSL) {
  ASSERT_TRUE(CanCompileAndReflect(
      "simple.vert.hlsl", SourceType::kVertexShader, SourceLanguage::kHLSL));
}

TEST_P(CompilerTest, CanCompileHLSLWithMultipleStages) {
  ASSERT_TRUE(CanCompileAndReflect("multiple_stages.hlsl",
                                   SourceType::kVertexShader,
                                   SourceLanguage::kHLSL, "VertexShader"));
  ASSERT_TRUE(CanCompileAndReflect("multiple_stages.hlsl",
                                   SourceType::kFragmentShader,
                                   SourceLanguage::kHLSL, "FragmentShader"));
}

TEST_P(CompilerTest, CanCompileTessellationControlShader) {
  ASSERT_TRUE(CanCompileAndReflect("sample.tesc"));
  ASSERT_TRUE(CanCompileAndReflect("sample.tesc",
                                   SourceType::kTessellationControlShader));
}

TEST_P(CompilerTest, CanCompileTessellationEvaluationShader) {
  ASSERT_TRUE(CanCompileAndReflect("sample.tese"));
  ASSERT_TRUE(CanCompileAndReflect("sample.tese",
                                   SourceType::kTessellationEvaluationShader));
}

TEST_P(CompilerTest, CanCompileComputeShader) {
  if (!TargetPlatformIsMetal(GetParam())) {
    GTEST_SKIP_("Only enabled on Metal backends till ES 3.2 support is added.");
  }
  ASSERT_TRUE(CanCompileAndReflect("sample.comp"));
  ASSERT_TRUE(CanCompileAndReflect("sample.comp", SourceType::kComputeShader));
}

TEST_P(CompilerTest, MustFailDueToExceedingResourcesLimit) {
  ScopedValidationDisable disable_validation;
  ASSERT_FALSE(
      CanCompileAndReflect("resources_limit.vert", SourceType::kVertexShader));
}

TEST_P(CompilerTest, MustFailDueToMultipleLocationPerStructMember) {
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

TEST_P(CompilerTest, UniformsHaveBindingAndSet) {
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

#define INSTANTIATE_TARGET_PLATFORM_TEST_SUITE_P(suite_name)              \
  INSTANTIATE_TEST_SUITE_P(                                               \
      suite_name, CompilerTest,                                           \
      ::testing::Values(                                                  \
          TargetPlatform::kOpenGLES, TargetPlatform::kOpenGLDesktop,      \
          TargetPlatform::kMetalDesktop, TargetPlatform::kMetalIOS),      \
      [](const ::testing::TestParamInfo<CompilerTest::ParamType>& info) { \
        return TargetPlatformToString(info.param);                        \
      });

INSTANTIATE_TARGET_PLATFORM_TEST_SUITE_P(CompilerSuite);

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
