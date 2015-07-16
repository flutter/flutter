// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>

#include "gpu/command_buffer/service/shader_translator.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {
namespace gles2 {

class ShaderTranslatorTest : public testing::Test {
 public:
  ShaderTranslatorTest() {
  }

  ~ShaderTranslatorTest() override {}

 protected:
  void SetUp() override {
    ShBuiltInResources resources;
    ShInitBuiltInResources(&resources);
    resources.MaxExpressionComplexity = 32;
    resources.MaxCallStackDepth = 32;

    vertex_translator_ = new ShaderTranslator();
    fragment_translator_ = new ShaderTranslator();

    ASSERT_TRUE(vertex_translator_->Init(
        GL_VERTEX_SHADER, SH_GLES2_SPEC, &resources,
        ShaderTranslatorInterface::kGlsl,
        SH_EMULATE_BUILT_IN_FUNCTIONS));
    ASSERT_TRUE(fragment_translator_->Init(
        GL_FRAGMENT_SHADER, SH_GLES2_SPEC, &resources,
        ShaderTranslatorInterface::kGlsl,
        static_cast<ShCompileOptions>(0)));
  }
  void TearDown() override {
    vertex_translator_ = NULL;
    fragment_translator_ = NULL;
  }

  scoped_refptr<ShaderTranslator> vertex_translator_;
  scoped_refptr<ShaderTranslator> fragment_translator_;
};

TEST_F(ShaderTranslatorTest, ValidVertexShader) {
  const char* shader =
      "void main() {\n"
      "  gl_Position = vec4(1.0);\n"
      "}";

  // A valid shader should be successfully translated.
  std::string info_log, translated_source;
  AttributeMap attrib_map;
  UniformMap uniform_map;
  VaryingMap varying_map;
  NameMap name_map;
  EXPECT_TRUE(vertex_translator_->Translate(shader,
                                            &info_log,
                                            &translated_source,
                                            &attrib_map,
                                            &uniform_map,
                                            &varying_map,
                                            &name_map));
  // Info log must be NULL.
  EXPECT_TRUE(info_log.empty());
  // Translated shader must be valid and non-empty.
  ASSERT_FALSE(translated_source.empty());
  // There should be no attributes, uniforms, and only one built-in
  // varying: gl_Position.
  EXPECT_TRUE(attrib_map.empty());
  EXPECT_TRUE(uniform_map.empty());
  EXPECT_EQ(1u, varying_map.size());
  // There should be no name mapping.
  EXPECT_TRUE(name_map.empty());
}

TEST_F(ShaderTranslatorTest, InvalidVertexShader) {
  const char* bad_shader = "foo-bar";
  const char* good_shader =
      "void main() {\n"
      "  gl_Position = vec4(1.0);\n"
      "}";

  // An invalid shader should fail.
  std::string info_log, translated_source;
  AttributeMap attrib_map;
  UniformMap uniform_map;
  VaryingMap varying_map;
  NameMap name_map;
  EXPECT_FALSE(vertex_translator_->Translate(bad_shader,
                                             &info_log,
                                             &translated_source,
                                             &attrib_map,
                                             &uniform_map,
                                             &varying_map,
                                             &name_map));
  // Info log must be valid and non-empty.
  ASSERT_FALSE(info_log.empty());
  // Translated shader must be NULL.
  EXPECT_TRUE(translated_source.empty());
  // There should be no attributes, uniforms, varyings, or name mapping.
  EXPECT_TRUE(attrib_map.empty());
  EXPECT_TRUE(uniform_map.empty());
  EXPECT_TRUE(varying_map.empty());
  EXPECT_TRUE(name_map.empty());

  // Try a good shader after bad.
  info_log.clear();
  EXPECT_TRUE(vertex_translator_->Translate(good_shader,
                                            &info_log,
                                            &translated_source,
                                            &attrib_map,
                                            &uniform_map,
                                            &varying_map,
                                            &name_map));
  EXPECT_TRUE(info_log.empty());
  EXPECT_FALSE(translated_source.empty());
}

TEST_F(ShaderTranslatorTest, ValidFragmentShader) {
  const char* shader =
      "void main() {\n"
      "  gl_FragColor = vec4(1.0);\n"
      "}";

  // A valid shader should be successfully translated.
  std::string info_log, translated_source;
  AttributeMap attrib_map;
  UniformMap uniform_map;
  VaryingMap varying_map;
  NameMap name_map;
  EXPECT_TRUE(fragment_translator_->Translate(shader,
                                              &info_log,
                                              &translated_source,
                                              &attrib_map,
                                              &uniform_map,
                                              &varying_map,
                                              &name_map));
  // Info log must be NULL.
  EXPECT_TRUE(info_log.empty());
  // Translated shader must be valid and non-empty.
  ASSERT_FALSE(translated_source.empty());
  // There should be no attributes, uniforms, varyings, or name mapping.
  EXPECT_TRUE(attrib_map.empty());
  EXPECT_TRUE(uniform_map.empty());
  EXPECT_TRUE(varying_map.empty());
  EXPECT_TRUE(name_map.empty());
}

TEST_F(ShaderTranslatorTest, InvalidFragmentShader) {
  const char* shader = "foo-bar";

  std::string info_log, translated_source;
  AttributeMap attrib_map;
  UniformMap uniform_map;
  VaryingMap varying_map;
  NameMap name_map;
  // An invalid shader should fail.
  EXPECT_FALSE(fragment_translator_->Translate(shader,
                                               &info_log,
                                               &translated_source,
                                               &attrib_map,
                                               &uniform_map,
                                               &varying_map,
                                               &name_map));
  // Info log must be valid and non-empty.
  EXPECT_FALSE(info_log.empty());
  // Translated shader must be NULL.
  EXPECT_TRUE(translated_source.empty());
  // There should be no attributes or uniforms.
  EXPECT_TRUE(attrib_map.empty());
  EXPECT_TRUE(uniform_map.empty());
  EXPECT_TRUE(varying_map.empty());
  EXPECT_TRUE(name_map.empty());
}

TEST_F(ShaderTranslatorTest, GetAttributes) {
  const char* shader =
      "attribute vec4 vPosition;\n"
      "void main() {\n"
      "  gl_Position = vPosition;\n"
      "}";

  std::string info_log, translated_source;
  AttributeMap attrib_map;
  UniformMap uniform_map;
  VaryingMap varying_map;
  NameMap name_map;
  EXPECT_TRUE(vertex_translator_->Translate(shader,
                                            &info_log,
                                            &translated_source,
                                            &attrib_map,
                                            &uniform_map,
                                            &varying_map,
                                            &name_map));
  // Info log must be NULL.
  EXPECT_TRUE(info_log.empty());
  // Translated shader must be valid and non-empty.
  EXPECT_FALSE(translated_source.empty());
  // There should be no uniforms.
  EXPECT_TRUE(uniform_map.empty());
  // There should be one attribute with following characteristics:
  // name:vPosition type:GL_FLOAT_VEC4 size:0.
  EXPECT_EQ(1u, attrib_map.size());
  AttributeMap::const_iterator iter = attrib_map.find("vPosition");
  EXPECT_TRUE(iter != attrib_map.end());
  EXPECT_EQ(static_cast<GLenum>(GL_FLOAT_VEC4), iter->second.type);
  EXPECT_EQ(0u, iter->second.arraySize);
  EXPECT_EQ("vPosition", iter->second.name);
}

TEST_F(ShaderTranslatorTest, GetUniforms) {
  const char* shader =
      "precision mediump float;\n"
      "struct Foo {\n"
      "  vec4 color[1];\n"
      "};\n"
      "struct Bar {\n"
      "  Foo foo;\n"
      "};\n"
      "uniform Bar bar[2];\n"
      "void main() {\n"
      "  gl_FragColor = bar[0].foo.color[0] + bar[1].foo.color[0];\n"
      "}";

  std::string info_log, translated_source;
  AttributeMap attrib_map;
  UniformMap uniform_map;
  VaryingMap varying_map;
  NameMap name_map;
  EXPECT_TRUE(fragment_translator_->Translate(shader,
                                              &info_log,
                                              &translated_source,
                                              &attrib_map,
                                              &uniform_map,
                                              &varying_map,
                                              &name_map));
  // Info log must be NULL.
  EXPECT_TRUE(info_log.empty());
  // Translated shader must be valid and non-empty.
  EXPECT_FALSE(translated_source.empty());
  // There should be no attributes.
  EXPECT_TRUE(attrib_map.empty());
  // There should be two uniforms with following characteristics:
  // 1. name:bar[0].foo.color[0] type:GL_FLOAT_VEC4 size:1
  // 2. name:bar[1].foo.color[0] type:GL_FLOAT_VEC4 size:1
  // However, there will be only one entry "bar" in the map.
  EXPECT_EQ(1u, uniform_map.size());
  UniformMap::const_iterator iter = uniform_map.find("bar");
  EXPECT_TRUE(iter != uniform_map.end());
  // First uniform.
  const sh::ShaderVariable* info;
  std::string original_name;
  EXPECT_TRUE(iter->second.findInfoByMappedName(
      "bar[0].foo.color[0]", &info, &original_name));
  EXPECT_EQ(static_cast<GLenum>(GL_FLOAT_VEC4), info->type);
  EXPECT_EQ(1u, info->arraySize);
  EXPECT_STREQ("color", info->name.c_str());
  EXPECT_STREQ("bar[0].foo.color[0]", original_name.c_str());
  // Second uniform.
  EXPECT_TRUE(iter->second.findInfoByMappedName(
      "bar[1].foo.color[0]", &info, &original_name));
  EXPECT_EQ(static_cast<GLenum>(GL_FLOAT_VEC4), info->type);
  EXPECT_EQ(1u, info->arraySize);
  EXPECT_STREQ("color", info->name.c_str());
  EXPECT_STREQ("bar[1].foo.color[0]", original_name.c_str());
}

#if defined(OS_MACOSX)
TEST_F(ShaderTranslatorTest, BuiltInFunctionEmulation) {
  // This test might become invalid in the future when ANGLE Translator is no
  // longer emulate dot(float, float) in Mac, or the emulated function name is
  // no longer webgl_dot_emu.
  const char* shader =
      "void main() {\n"
      "  gl_Position = vec4(dot(1.0, 1.0), 1.0, 1.0, 1.0);\n"
      "}";

  std::string info_log, translated_source;
  AttributeMap attrib_map;
  UniformMap uniform_map;
  VaryingMap varying_map;
  NameMap name_map;
  EXPECT_TRUE(vertex_translator_->Translate(shader,
                                            &info_log,
                                            &translated_source,
                                            &attrib_map,
                                            &uniform_map,
                                            &varying_map,
                                            &name_map));
  // Info log must be NULL.
  EXPECT_TRUE(info_log.empty());
  // Translated shader must be valid and non-empty.
  ASSERT_FALSE(translated_source.empty());
  EXPECT_TRUE(strstr(translated_source.c_str(),
                     "webgl_dot_emu") != NULL);
}
#endif

TEST_F(ShaderTranslatorTest, OptionsString) {
  scoped_refptr<ShaderTranslator> translator_1 = new ShaderTranslator();
  scoped_refptr<ShaderTranslator> translator_2 = new ShaderTranslator();
  scoped_refptr<ShaderTranslator> translator_3 = new ShaderTranslator();

  ShBuiltInResources resources;
  ShInitBuiltInResources(&resources);

  ASSERT_TRUE(translator_1->Init(
      GL_VERTEX_SHADER, SH_GLES2_SPEC, &resources,
      ShaderTranslatorInterface::kGlsl,
      SH_EMULATE_BUILT_IN_FUNCTIONS));
  ASSERT_TRUE(translator_2->Init(
      GL_FRAGMENT_SHADER, SH_GLES2_SPEC, &resources,
      ShaderTranslatorInterface::kGlsl,
      static_cast<ShCompileOptions>(0)));
  resources.EXT_draw_buffers = 1;
  ASSERT_TRUE(translator_3->Init(
      GL_VERTEX_SHADER, SH_GLES2_SPEC, &resources,
      ShaderTranslatorInterface::kGlsl,
      SH_EMULATE_BUILT_IN_FUNCTIONS));

  std::string options_1(
      translator_1->GetStringForOptionsThatWouldAffectCompilation());
  std::string options_2(
      translator_1->GetStringForOptionsThatWouldAffectCompilation());
  std::string options_3(
      translator_2->GetStringForOptionsThatWouldAffectCompilation());
  std::string options_4(
      translator_3->GetStringForOptionsThatWouldAffectCompilation());

  EXPECT_EQ(options_1, options_2);
  EXPECT_NE(options_1, options_3);
  EXPECT_NE(options_1, options_4);
  EXPECT_NE(options_3, options_4);
}

}  // namespace gles2
}  // namespace gpu

