// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/compiler.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

namespace impeller {
namespace compiler {
namespace testing {

TEST(CompilerTest, ShaderKindMatchingIsSuccessful) {
  ASSERT_EQ(Compiler::SourceTypeFromFileName("hello.vert"),
            Compiler::SourceType::kVertexShader);
  ASSERT_EQ(Compiler::SourceTypeFromFileName("hello.frag"),
            Compiler::SourceType::kFragmentShader);
  ASSERT_EQ(Compiler::SourceTypeFromFileName("hello.msl"),
            Compiler::SourceType::kUnknown);
  ASSERT_EQ(Compiler::SourceTypeFromFileName("hello.glsl"),
            Compiler::SourceType::kUnknown);
}

TEST(CompilerTest, CanCompileSample) {
  auto fixture = flutter::testing::OpenFixtureAsMapping("sample.frag");
  ASSERT_NE(fixture->GetMapping(), nullptr);
  Compiler::SourceOptions options("sample.frag");
  options.working_directory = std::make_shared<fml::UniqueFD>(
      flutter::testing::OpenFixturesDirectory());
  Compiler compiler(*fixture.get(), options);
  ASSERT_TRUE(compiler.IsValid());

  auto desktop = fml::OpenDirectory("/Users/chinmaygarde/Desktop", false,
                                    fml::FilePermission::kRead);
  fml::WriteAtomically(desktop, "sample.frag.spirv",
                       *compiler.GetSPIRVAssembly());
  fml::WriteAtomically(desktop, "sample.frag.metal",
                       *compiler.GetMSLShaderSource());
}

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
