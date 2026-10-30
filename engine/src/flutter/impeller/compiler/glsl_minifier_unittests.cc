// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/glsl_minifier.h"

#include <limits>
#include <memory>
#include <string>

#include "flutter/fml/file.h"
#include "flutter/fml/mapping.h"
#include "flutter/testing/testing.h"
#include "impeller/compiler/compiler.h"
#include "impeller/compiler/reflector.h"
#include "impeller/compiler/source_options.h"
#include "impeller/compiler/types.h"

namespace impeller {
namespace compiler {
namespace testing {

TEST(GLSLMinifierTest, StripGLSLComments) {
  EXPECT_EQ(StripGLSLComments(""), "");
  EXPECT_EQ(StripGLSLComments("void main() {}"), "void main() {}");
  EXPECT_EQ(StripGLSLComments("// trailing without newline"), "");
  EXPECT_EQ(StripGLSLComments("int a; // single-line\nint b;"),
            "int a; \nint b;");
  EXPECT_EQ(StripGLSLComments("int /* inline */ a;\n/* multi\nline */int b;"),
            "int  a;\nint b;");
}

TEST(GLSLMinifierTest, FormatFloatAndDouble) {
  // Integer-valued floats get ".0" appended so they remain valid GLSL float
  // literals.
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(0.0f), "0.0");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(1.0f), "1.0");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(42.0f), "42.0");

  // Floats that SPIRV-Cross's default "%.32g" expands to 25+ characters are
  // formatted to their shortest exact round-trip representation.
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(0.3f), "0.3");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(0.11f), "0.11");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(0.59f), "0.59");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(-0.475f), "-0.475");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(1e20f), "1e+20");

  // Non-finite values are preserved.
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(
                std::numeric_limits<float>::infinity()),
            "inf");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(
                -std::numeric_limits<float>::infinity()),
            "-inf");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatFloat(
                std::numeric_limits<float>::quiet_NaN()),
            "nan");

  // Doubles are formatted with the same round-trip and ".0" guarantees.
  EXPECT_EQ(MinifyingCompilerGLSL::FormatDouble(1.0), "1.0");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatDouble(0.3), "0.3");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatDouble(
                std::numeric_limits<double>::infinity()),
            "inf");
  EXPECT_EQ(MinifyingCompilerGLSL::FormatDouble(
                -std::numeric_limits<double>::infinity()),
            "-inf");
}

TEST(GLSLMinifierTest, TrimsAndCollapsesLineWhitespace) {
  EXPECT_EQ(MinifyGLSL("   \t\r  "), "");
  EXPECT_EQ(MinifyGLSL(" \t float  \t x  = \t 1.0 ; \t\r\n"), "float x=1.0;\n");
  EXPECT_EQ(MinifyGLSL(" \t #define \t  FOO \t\t 1.0 \t\r\n"),
            "#define FOO 1.0\n");
}

TEST(GLSLMinifierTest, StripsSingleLineAndMultiLineComments) {
  const std::string source = R"(#version 100
// Single-line comment
/* Multi-line
   comment */
void main() {
  gl_FragColor = vec4(1.0); // Trailing comment
}
)";
  EXPECT_EQ(MinifyGLSL(source),
            "#version 100\nvoid main(){gl_FragColor=vec4(1.0);}\n");
}

TEST(GLSLMinifierTest, PreservesPreprocessorDirectivesOnOwnLines) {
  const std::string source = R"(#version 100
#extension   GL_OES_standard_derivatives : require
precision mediump float;
#ifndef SPIRV_CROSS_CONSTANT_ID_0
#define   SPIRV_CROSS_CONSTANT_ID_0   1.0
#endif
void main() {
  gl_FragColor = vec4(SPIRV_CROSS_CONSTANT_ID_0);
}
)";
  EXPECT_EQ(MinifyGLSL(source),
            "#version 100\n"
            "#extension GL_OES_standard_derivatives : require\n"
            "precision mediump float;\n"
            "#ifndef SPIRV_CROSS_CONSTANT_ID_0\n"
            "#define SPIRV_CROSS_CONSTANT_ID_0 1.0\n"
            "#endif\n"
            "void main(){gl_FragColor=vec4(SPIRV_CROSS_CONSTANT_ID_0);}\n");
}

TEST(GLSLMinifierTest, PreservesRequiredSpacesBetweenIdentifiersAndOperators) {
  const std::string source = R"(
    precision highp
    float;
    uniform float _a9;
    uniform float B_0;
    float helper(float x) {
      return x - -1.0 + +B_0 + -_a9 - +x;
    }
  )";
  EXPECT_EQ(MinifyGLSL(source),
            "precision highp float;uniform float _a9;uniform float B_0;"
            "float helper(float x){return x- -1.0+ +B_0+-_a9-+x;}\n");
}

TEST(GLSLMinifierTest, HandlesEmptyAndTrailingPreprocessorSources) {
  EXPECT_EQ(MinifyGLSL(""), "");
  EXPECT_EQ(MinifyGLSL("  // comment only\n  /* block */  \n"), "");
  EXPECT_EQ(MinifyGLSL("precision mediump float;\n#endif\n"),
            "precision mediump float;\n#endif\n");
}

TEST(GLSLMinifierTest, CompilerMinifiesGLESShadersWhenEnabled) {
  const std::string shader_source = R"(
    #version 460 core
    out vec4 fragColor;
    void main() {
      // Single-line comment
      float w = 0.300000011920928955078125;
      fragColor = vec4(w, 0.11, 0.59, 1.0);
    }
  )";
  auto mapping = std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(shader_source.data()),
      shader_source.size(), [](auto, auto) {});

  SourceOptions options;
  options.source_language = SourceLanguage::kGLSL;
  options.target_platform = TargetPlatform::kOpenGLES;
  options.type = SourceType::kFragmentShader;
  options.file_name = "minify_test.frag";
  options.entry_point_name = "main";
  options.working_directory = std::make_shared<fml::UniqueFD>(
      flutter::testing::OpenFixturesDirectory());

  Reflector::Options reflector_options;
  reflector_options.target_platform = TargetPlatform::kOpenGLES;

  // By default, minify is false.
  {
    Compiler compiler(mapping, options, reflector_options);
    ASSERT_TRUE(compiler.IsValid()) << compiler.GetErrorMessages();
    auto sl = compiler.GetSLShaderSource();
    ASSERT_TRUE(sl && sl->GetMapping());
    const std::string gl_frag(reinterpret_cast<const char*>(sl->GetMapping()),
                              sl->GetSize());
    EXPECT_NE(gl_frag.find("    "), std::string::npos) << gl_frag;
    EXPECT_NE(gl_frag.find("0.300000011920928955078125"), std::string::npos)
        << gl_frag;
  }

  // When minify is true, comments/whitespace and verbose floats are minified.
  options.minify = true;
  {
    Compiler compiler(mapping, options, reflector_options);
    ASSERT_TRUE(compiler.IsValid()) << compiler.GetErrorMessages();
    auto sl = compiler.GetSLShaderSource();
    ASSERT_TRUE(sl && sl->GetMapping());
    const std::string gl_frag(reinterpret_cast<const char*>(sl->GetMapping()),
                              sl->GetSize());

    // Starts with #version on its own line so ComputeShaderWithDefines can
    // insert specialization constant #defines after the first newline.
    EXPECT_EQ(gl_frag.find("#version 100\n"), 0u) << gl_frag;
    // Indentation and verbose 24-digit float expansion are stripped.
    EXPECT_EQ(gl_frag.find("    "), std::string::npos) << gl_frag;
    EXPECT_EQ(gl_frag.find("0.300000011920928955078125"), std::string::npos)
        << gl_frag;
    EXPECT_NE(gl_frag.find("0.3"), std::string::npos) << gl_frag;
    EXPECT_NE(gl_frag.find("0.11"), std::string::npos) << gl_frag;
  }
}

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
