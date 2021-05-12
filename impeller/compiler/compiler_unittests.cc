// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/compiler.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

namespace impeller {
namespace compiler {
namespace testing {

class CompilerTest : public ::testing::Test {
 public:
  CompilerTest()
      : directory_(fml::OpenDirectory("/Users/chinmaygarde/Desktop/shaders",
                                      false,
                                      fml::FilePermission::kRead)) {
    FML_CHECK(directory_.is_valid());
  }

  ~CompilerTest() {}

  void WriteCompilerIntermediates(const Compiler& compiler,
                                  const std::string& base_name) {
    ASSERT_TRUE(compiler.IsValid());
    fml::WriteAtomically(directory_,
                         std::string{base_name + std::string{".spirv"}}.c_str(),
                         *compiler.GetSPIRVAssembly());
    fml::WriteAtomically(directory_,
                         std::string{base_name + std::string{".metal"}}.c_str(),
                         *compiler.GetMSLShaderSource());
  }

 private:
  fml::UniqueFD directory_;

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
  constexpr const char* kShaderFixtureName = "sample.frag";
  auto fixture = flutter::testing::OpenFixtureAsMapping(kShaderFixtureName);
  ASSERT_NE(fixture->GetMapping(), nullptr);
  Compiler::SourceOptions options(kShaderFixtureName);
  options.working_directory = std::make_shared<fml::UniqueFD>(
      flutter::testing::OpenFixturesDirectory());
  Compiler compiler(*fixture.get(), options);
  ASSERT_TRUE(compiler.IsValid());
  WriteCompilerIntermediates(compiler, kShaderFixtureName);
}

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
