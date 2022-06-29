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

TEST_P(CompilerTest, MustFailDueToMultipleLocationPerStructMember) {
  if (GetParam() == TargetPlatform::kFlutterSPIRV) {
    // This is a failure of reflection which this target doesn't perform.
    GTEST_SKIP();
  }
  ScopedValidationDisable disable_validation;
  ASSERT_FALSE(CanCompileAndReflect("struct_def_bug.vert"));
}

#define INSTANTIATE_TARGET_PLATFORM_TEST_SUITE_P(suite_name)              \
  INSTANTIATE_TEST_SUITE_P(                                               \
      suite_name, CompilerTest,                                           \
      ::testing::Values(                                                  \
          TargetPlatform::kOpenGLES, TargetPlatform::kOpenGLDesktop,      \
          TargetPlatform::kMetalDesktop, TargetPlatform::kMetalIOS,       \
          TargetPlatform::kFlutterSPIRV),                                 \
      [](const ::testing::TestParamInfo<CompilerTest::ParamType>& info) { \
        return TargetPlatformToString(info.param);                        \
      });

INSTANTIATE_TARGET_PLATFORM_TEST_SUITE_P(CompilerSuite);

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
