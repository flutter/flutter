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

TEST(GLSLMinifierTest, IsGLSLIdentStartCharAndIdentChar) {
  EXPECT_TRUE(IsGLSLIdentStartChar('a'));
  EXPECT_TRUE(IsGLSLIdentStartChar('z'));
  EXPECT_TRUE(IsGLSLIdentStartChar('A'));
  EXPECT_TRUE(IsGLSLIdentStartChar('Z'));
  EXPECT_TRUE(IsGLSLIdentStartChar('_'));
  EXPECT_FALSE(IsGLSLIdentStartChar('0'));
  EXPECT_FALSE(IsGLSLIdentStartChar('.'));
  EXPECT_FALSE(IsGLSLIdentStartChar('+'));

  EXPECT_TRUE(IsGLSLIdentChar('a'));
  EXPECT_TRUE(IsGLSLIdentChar('Z'));
  EXPECT_TRUE(IsGLSLIdentChar('_'));
  EXPECT_TRUE(IsGLSLIdentChar('0'));
  EXPECT_TRUE(IsGLSLIdentChar('9'));
  EXPECT_FALSE(IsGLSLIdentChar('.'));
  EXPECT_FALSE(IsGLSLIdentChar(' '));
}

TEST(GLSLMinifierTest, IsGLSLIdentOrNumChar) {
  EXPECT_TRUE(IsGLSLIdentOrNumChar('a'));
  EXPECT_TRUE(IsGLSLIdentOrNumChar('z'));
  EXPECT_TRUE(IsGLSLIdentOrNumChar('A'));
  EXPECT_TRUE(IsGLSLIdentOrNumChar('Z'));
  EXPECT_TRUE(IsGLSLIdentOrNumChar('0'));
  EXPECT_TRUE(IsGLSLIdentOrNumChar('9'));
  EXPECT_TRUE(IsGLSLIdentOrNumChar('_'));
  EXPECT_TRUE(IsGLSLIdentOrNumChar('.'));

  EXPECT_FALSE(IsGLSLIdentOrNumChar('+'));
  EXPECT_FALSE(IsGLSLIdentOrNumChar('-'));
  EXPECT_FALSE(IsGLSLIdentOrNumChar(' '));
  EXPECT_FALSE(IsGLSLIdentOrNumChar(';'));
  EXPECT_FALSE(IsGLSLIdentOrNumChar('\0'));
}

TEST(GLSLMinifierTest, NeedsGLSLSpaceBetween) {
  // Both characters are identifier/number/dot characters.
  EXPECT_TRUE(NeedsGLSLSpaceBetween('t', 'x'));
  EXPECT_TRUE(NeedsGLSLSpaceBetween('0', 'f'));
  EXPECT_TRUE(NeedsGLSLSpaceBetween('_', '.'));

  // Only one character is an identifier/number/dot character.
  EXPECT_FALSE(NeedsGLSLSpaceBetween('x', '+'));
  EXPECT_FALSE(NeedsGLSLSpaceBetween('+', 'x'));

  // Adjacent '+' or '-' characters must remain separated to avoid '++' / '--'.
  EXPECT_TRUE(NeedsGLSLSpaceBetween('+', '+'));
  EXPECT_FALSE(NeedsGLSLSpaceBetween('+', '-'));
  EXPECT_TRUE(NeedsGLSLSpaceBetween('-', '-'));
  EXPECT_FALSE(NeedsGLSLSpaceBetween('-', '+'));

  // Other adjacent operators/delimiters do not need separating spaces.
  EXPECT_FALSE(NeedsGLSLSpaceBetween('=', '-'));
  EXPECT_FALSE(NeedsGLSLSpaceBetween(';', '}'));
}

TEST(GLSLMinifierTest, ShortenGLSLFloatLiteral) {
  // Tokens with <= 9 characters are returned unchanged.
  EXPECT_EQ(ShortenGLSLFloatLiteral("0.5", 0.5f), "0.5");
  EXPECT_EQ(ShortenGLSLFloatLiteral("1234567.0", 1234567.0f), "1234567.0");

  // Integer tokens (> 9 characters without '.', 'e', or 'E') are unchanged.
  EXPECT_EQ(ShortenGLSLFloatLiteral("1000000000", 1000000000.0f), "1000000000");

  // Non-finite float values are returned unchanged.
  EXPECT_EQ(ShortenGLSLFloatLiteral("1e99999999",
                                    std::numeric_limits<float>::infinity()),
            "1e99999999");
  EXPECT_EQ(ShortenGLSLFloatLiteral("0.000000000",
                                    std::numeric_limits<float>::quiet_NaN()),
            "0.000000000");

  // Verbose float literals that round-trip to an integer value get ".0"
  // appended so they remain valid GLSL float tokens.
  EXPECT_EQ(ShortenGLSLFloatLiteral("1.0000000000", 1.0f), "1.0");
  EXPECT_EQ(ShortenGLSLFloatLiteral("42.000000000", 42.0f), "42.0");

  // Verbose SPIRV-Cross float literals (with or without `f`/`F` suffixes)
  // shorten to their exact decimal or scientific representation.
  EXPECT_EQ(ShortenGLSLFloatLiteral("0.300000011920928955078125", 0.3f), "0.3");
  EXPECT_EQ(ShortenGLSLFloatLiteral("0.300000011920928955078125f", 0.3f),
            "0.3");
  EXPECT_EQ(ShortenGLSLFloatLiteral("0.10999999940395355224609375", 0.11f),
            "0.11");
  EXPECT_EQ(ShortenGLSLFloatLiteral("0.589999973773956298828125F", 0.59f),
            "0.59");
  EXPECT_EQ(ShortenGLSLFloatLiteral("100000000000000000000.0", 1e20f), "1e+20");

  // Tokens whose shortest representation is not shorter than the original token
  // are returned unchanged.
  EXPECT_EQ(ShortenGLSLFloatLiteral("123456.125", 123456.125f), "123456.125");
}

TEST(GLSLMinifierTest, ShortenGLSLFloatLiteralsInLine) {
  EXPECT_EQ(ShortenGLSLFloatLiteralsInLine(""), "");

  // Literal at index 0 (start of line) and at end of line.
  EXPECT_EQ(ShortenGLSLFloatLiteralsInLine("0.300000011920928955078125"),
            "0.3");

  // Literals preceded by operators/punctuation and followed by delimiters or
  // end-of-line.
  EXPECT_EQ(ShortenGLSLFloatLiteralsInLine(
                "vec3 w = vec3(0.300000011920928955078125, "
                "-0.4749999940395355224609375, 0.5);"),
            "vec3 w = vec3(0.3, -0.475, 0.5);");

  // Digits inside identifiers are not treated as float literals.
  EXPECT_EQ(ShortenGLSLFloatLiteralsInLine("vec4 _123 = v0;"),
            "vec4 _123 = v0;");

  // Literals with `f`/`F` suffixes (emitted in GLSL ES 3.00 / desktop GLSL)
  // are recognized and shortened, while short suffixed literals and identifiers
  // starting with `f` after digits are preserved.
  EXPECT_EQ(ShortenGLSLFloatLiteralsInLine(
                "vec3 w = vec3(0.300000011920928955078125f, "
                "0.10999999940395355224609375F, 1.5f);"),
            "vec3 w = vec3(0.3, 0.11, 1.5f);");
  EXPECT_EQ(ShortenGLSLFloatLiteralsInLine("0.300000011920928955078125f"),
            "0.3");

  // Out-of-range float literals (where std::from_chars fails) and malformed
  // numeric prefixes followed by identifier/dot chars are left intact.
  EXPECT_EQ(ShortenGLSLFloatLiteralsInLine("float big = 1e9999999999;"),
            "float big = 1e9999999999;");
  EXPECT_EQ(
      ShortenGLSLFloatLiteralsInLine("int x = 123abc + 123f + 1.0foo + 1.0.2;"),
      "int x = 123abc + 123f + 1.0foo + 1.0.2;");
}

TEST(GLSLMinifierTest, TrimGLSLLineWhitespace) {
  EXPECT_EQ(TrimGLSLLineWhitespace(""), "");
  EXPECT_EQ(TrimGLSLLineWhitespace("   \t\r  "), "");
  EXPECT_EQ(TrimGLSLLineWhitespace("void main()"), "void main()");
  EXPECT_EQ(TrimGLSLLineWhitespace(" \t float x = 1.0; \t\r"),
            "float x = 1.0;");
}

TEST(GLSLMinifierTest, CollapseGLSLHorizontalWhitespace) {
  EXPECT_EQ(CollapseGLSLHorizontalWhitespace(""), "");
  EXPECT_EQ(CollapseGLSLHorizontalWhitespace("gl_FragColor=vec4(1.0);"),
            "gl_FragColor=vec4(1.0);");
  EXPECT_EQ(CollapseGLSLHorizontalWhitespace("#define \t  FOO \t\t 1.0"),
            "#define FOO 1.0");
}

TEST(GLSLMinifierTest, MinifyGLSLNonPreprocessorLine) {
  EXPECT_EQ(MinifyGLSLNonPreprocessorLine(""), "");
  EXPECT_EQ(MinifyGLSLNonPreprocessorLine("  \t\r "), "");
  EXPECT_EQ(
      MinifyGLSLNonPreprocessorLine("  highp   float  x = a -  -b +  +c ; \t "),
      "highp float x=a- -b+ +c;");
}

TEST(GLSLMinifierTest, IsSynthesizedGLSLIdentifier) {
  EXPECT_TRUE(IsSynthesizedGLSLIdentifier("_0"));
  EXPECT_TRUE(IsSynthesizedGLSLIdentifier("_2461"));
  EXPECT_TRUE(IsSynthesizedGLSLIdentifier("mp_copy_91"));
  EXPECT_TRUE(IsSynthesizedGLSLIdentifier("hp_copy_3405"));
  EXPECT_TRUE(IsSynthesizedGLSLIdentifier("spvDummy95"));

  EXPECT_FALSE(IsSynthesizedGLSLIdentifier(""));
  EXPECT_FALSE(IsSynthesizedGLSLIdentifier("_"));
  EXPECT_FALSE(IsSynthesizedGLSLIdentifier("_abc"));
  EXPECT_FALSE(IsSynthesizedGLSLIdentifier("mp_copy_"));
  EXPECT_FALSE(IsSynthesizedGLSLIdentifier("spvDummy"));
  EXPECT_FALSE(IsSynthesizedGLSLIdentifier("_impeller_user_main"));
  EXPECT_FALSE(IsSynthesizedGLSLIdentifier("frag_info"));
}

TEST(GLSLMinifierTest, NextShortGLSLIdentifier) {
  std::unordered_set<std::string_view> reserved = {"a", "do"};
  size_t cursor = 0;
  // Skips "a" because it is in `reserved` and returns "b".
  EXPECT_EQ(NextShortGLSLIdentifier(cursor, reserved), "b");
  EXPECT_EQ(cursor, 2u);

  // Jump to the last 1-character identifier ('Z' at index 51) and then the
  // first 2-character identifier ("aa" at index 52).
  cursor = 51;
  EXPECT_EQ(NextShortGLSLIdentifier(cursor, reserved), "Z");
  EXPECT_EQ(NextShortGLSLIdentifier(cursor, reserved), "aa");

  // Jump to a 3-character identifier (index 52 + 52 * 63 = 3328).
  cursor = 52 + 52 * 63;
  EXPECT_EQ(NextShortGLSLIdentifier(cursor, reserved), "aaa");
}

TEST(GLSLMinifierTest, BuildGLSLIdentifierRenameMap) {
  // Empty or no-candidate sources produce an empty map.
  EXPECT_TRUE(BuildGLSLIdentifierRenameMap("").empty());
  EXPECT_TRUE(
      BuildGLSLIdentifierRenameMap("void main(){gl_FragColor=vec4(1.0);}")
          .empty());

  // Candidates are ordered by descending frequency (breaking ties
  // lexicographically) and skip identifiers already present in `source`.
  const std::string source =
      "void main(){"
      "float a=1.0;"
      "float _100=a;"
      "float mp_copy_100=_100+_100;"
      "float _20=mp_copy_100;"
      "float _30=mp_copy_100;"
      "for(int spvDummy1=0;spvDummy1<1;spvDummy1++){"
      "gl_FragColor=vec4(_20,_30,_100,a);"
      "}"
      "}";
  const auto rename_map = BuildGLSLIdentifierRenameMap(source);
  // `_100` appears 4 times -> gets `"b"` (since `"a"` is already in `source`).
  // `mp_copy_100` and `spvDummy1` each appear 3 times -> `"mp_copy_100" <
  // "spvDummy1"`, so `mp_copy_100` gets `"c"` and `spvDummy1` gets `"d"`.
  // `_20` and `_30` each appear 2 times -> `_20` gets `"e"`, `_30` gets `"f"`.
  ASSERT_EQ(rename_map.size(), 5u);
  EXPECT_EQ(rename_map.at("_100"), "b");
  EXPECT_EQ(rename_map.at("mp_copy_100"), "c");
  EXPECT_EQ(rename_map.at("spvDummy1"), "d");
  EXPECT_EQ(rename_map.at("_20"), "e");
  EXPECT_EQ(rename_map.at("_30"), "f");

  // When a 2-character candidate (`_0`) cannot be shortened because all 52
  // 1-character names are already present in the shader, it is omitted from
  // `rename_map`.
  const std::string all_single_chars_used =
      "void main(){float a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,"
      "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,_0;}";
  EXPECT_TRUE(BuildGLSLIdentifierRenameMap(all_single_chars_used).empty());
}

TEST(GLSLMinifierTest, ShortenGLSLInternalIdentifiers) {
  // Empty or no-candidate sources are returned unchanged.
  EXPECT_EQ(ShortenGLSLInternalIdentifiers(""), "");
  EXPECT_EQ(
      ShortenGLSLInternalIdentifiers("void main(){gl_FragColor=vec4(1.0);}"),
      "void main(){gl_FragColor=vec4(1.0);}");

  // Synthesized temporaries are rewritten to their short names while external
  // identifiers, keywords, and numeric literals remain untouched.
  const std::string source =
      "void main(){"
      "float a=1.0;"
      "float _100=a;"
      "float mp_copy_100=_100+_100;"
      "gl_FragColor=vec4(mp_copy_100);"
      "}\n";
  EXPECT_EQ(ShortenGLSLInternalIdentifiers(source),
            "void main(){"
            "float a=1.0;"
            "float b=a;"
            "float c=b+b;"
            "gl_FragColor=vec4(c);"
            "}\n");
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
    uniform float a;
    uniform float b;
    float helper(float x) {
      return x - -1.0 + +b;
    }
  )";
  EXPECT_EQ(MinifyGLSL(source),
            "precision highp float;uniform float a;uniform float b;"
            "float helper(float x){return x- -1.0+ +b;}\n");
}

TEST(GLSLMinifierTest, HandlesEmptyAndTrailingPreprocessorSources) {
  EXPECT_EQ(MinifyGLSL(""), "");
  EXPECT_EQ(MinifyGLSL("  // comment only\n  /* block */  \n"), "");
  EXPECT_EQ(MinifyGLSL("precision mediump float;\n#endif\n"),
            "precision mediump float;\n#endif\n");
}

TEST(GLSLMinifierTest, ShortensVerboseFloatLiterals) {
  const std::string source = R"(
    void main() {
      vec3 weights = vec3(
          0.300000011920928955078125,
          0.10999999940395355224609375,
          0.589999973773956298828125);
      float neg = -0.4749999940395355224609375;
      float exact = 0.5;
    }
  )";
  EXPECT_EQ(MinifyGLSL(source),
            "void main(){vec3 weights=vec3(0.3,0.11,0.59);"
            "float neg=-0.475;float exact=0.5;}\n");
}

TEST(GLSLMinifierTest, CompilerMinifiesGLESShaders) {
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
}

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
