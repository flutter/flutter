// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/base/validation.h"
#include "impeller/compiler/compiler.h"

namespace impeller {
namespace compiler {
namespace testing {

class CompilerTest : public ::testing::Test {
 public:
  CompilerTest()
      : intermediates_directory_(
            fml::OpenDirectory(flutter::testing::GetFixturesPath(),
                               false,
                               fml::FilePermission::kRead)) {
    FML_CHECK(intermediates_directory_.is_valid());
  }

  ~CompilerTest() = default;

  bool CanCompileFixture(const char* fixture_name,
                         Compiler::TargetPlatform target_platform) const {
    auto fixture = flutter::testing::OpenFixtureAsMapping(fixture_name);
    if (!fixture->GetMapping()) {
      VALIDATION_LOG << "Could not find shader in fixtures: " << fixture_name;
      return false;
    }
    Compiler::SourceOptions compiler_options(fixture_name);
    compiler_options.target_platform = target_platform;
    compiler_options.working_directory = std::make_shared<fml::UniqueFD>(
        flutter::testing::OpenFixturesDirectory());
    Reflector::Options reflector_options;
    Compiler compiler(*fixture.get(), compiler_options, reflector_options);
    if (!compiler.IsValid()) {
      VALIDATION_LOG << "Compilation failed: " << compiler.GetErrorMessages();
      return false;
    }
    return true;
  }

 private:
  fml::UniqueFD intermediates_directory_;

  FML_DISALLOW_COPY_AND_ASSIGN(CompilerTest);
};

TEST_F(CompilerTest, ShaderKindMatchingIsSuccessful) {
  ASSERT_EQ(Compiler::SourceTypeFromFileName("hello.vert"),
            Compiler::SourceType::kVertexShader);
  ASSERT_EQ(Compiler::SourceTypeFromFileName("hello.frag"),
            Compiler::SourceType::kFragmentShader);
  ASSERT_EQ(Compiler::SourceTypeFromFileName("hello.msl"),
            Compiler::SourceType::kUnknown);
  ASSERT_EQ(Compiler::SourceTypeFromFileName("hello.glsl"),
            Compiler::SourceType::kUnknown);
}

TEST_F(CompilerTest, CanCompileSample) {
  ASSERT_TRUE(CanCompileFixture(
      "sample.vert", Compiler::TargetPlatform::kMacOS));
}

TEST_F(CompilerTest, CanTargetFlutterSPIRV) {
  ASSERT_TRUE(CanCompileFixture(
    "test_texture.frag", Compiler::TargetPlatform::kFlutterSPIRV));
}

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
