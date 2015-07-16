// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

#include "gpu/command_buffer/service/context_group.h"
#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

#define SHADER(Src) #Src

namespace gpu {

class GLProgramTest : public testing::Test {
 protected:
  void SetUp() override { gl_.Initialize(GLManager::Options()); }

  void TearDown() override { gl_.Destroy(); }

  GLManager gl_;
};

TEST_F(GLProgramTest, GetSetUniform) {
  static const char* v_shader_str = SHADER(
      attribute vec4 a_vertex;
      attribute vec3 a_normal;

      uniform mat4 u_modelViewProjMatrix;

      struct MyStruct
      {
        int x;
        int y;
      };

      uniform MyStruct u_struct;
      uniform float u_array[4];

      varying vec3 v_normal;

      void main()
      {
          v_normal = a_normal;
          gl_Position = u_modelViewProjMatrix * a_vertex +
              vec4(u_struct.x, u_struct.y, 0, 1) +
              vec4(u_array[0], u_array[1], u_array[2], u_array[3]);
      }
  );
  static const char* f_shader_str = SHADER(
      varying mediump vec3 v_normal;

      void main()
      {
          gl_FragColor = vec4(v_normal/2.0+vec3(0.5), 1);
      }
  );

  // Load the program.
  GLuint program = GLTestHelper::LoadProgram(v_shader_str, f_shader_str);
  glUseProgram(program);
  // Relink program.
  glLinkProgram(program);

  // These tests will fail on NVidia if not worked around by
  // command buffer.
  GLint location_sx = glGetUniformLocation(program, "u_struct.x");
  GLint location_array_0 = glGetUniformLocation(program, "u_array[0]");

  glUniform1i(location_sx, 3);
  glUniform1f(location_array_0, 123);

  GLint int_value = 0;
  GLfloat float_value = 0;

  glGetUniformiv(program, location_sx, &int_value);
  EXPECT_EQ(3, int_value);
  glGetUniformfv(program, location_array_0, &float_value);
  EXPECT_EQ(123.0f, float_value);

  GLTestHelper::CheckGLError("no errors", __LINE__);
}

TEST_F(GLProgramTest, NewShaderInCurrentProgram) {
  static const char* v_shader_str = SHADER(
      attribute vec4 a_position;
      void main()
      {
         gl_Position = a_position;
      }
  );
  static const char* f_red_shader_str = SHADER(
      void main()
      {
          gl_FragColor = vec4(1, 0, 0, 1);
      }
  );
  static const char* f_blue_shader_str = SHADER(
      void main()
      {
          gl_FragColor = vec4(0, 0, 1, 1);
      }
  );

  // Load the program.
  GLuint vs = GLTestHelper::LoadShader(GL_VERTEX_SHADER, v_shader_str);
  GLuint fs = GLTestHelper::LoadShader(GL_FRAGMENT_SHADER, f_red_shader_str);
  GLuint program = GLTestHelper::SetupProgram(vs, fs);
  glUseProgram(program);
  glShaderSource(fs, 1, &f_blue_shader_str, NULL);
  glCompileShader(fs);
  glLinkProgram(program);
  // We specifically don't call UseProgram again.
  GLuint position_loc = glGetAttribLocation(program, "a_position");
  GLTestHelper::SetupUnitQuad(position_loc);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  uint8 expected_color[] = { 0, 0, 255, 255, };
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, 1, 1, 0, expected_color));
  GLTestHelper::CheckGLError("no errors", __LINE__);
}

TEST_F(GLProgramTest, ShaderLengthSpecified) {
  const std::string valid_shader_str = SHADER(
      attribute vec4 a_position;
      void main()
      {
         gl_Position = a_position;
      }
  );

  const std::string invalid_shader = valid_shader_str + "invalid suffix";

  // Compiling invalid program should fail.
  const char* invalid_shader_strings[] = { invalid_shader.c_str() };
  GLuint vs = glCreateShader(GL_VERTEX_SHADER);
  glShaderSource(vs, 1, invalid_shader_strings, NULL);
  glCompileShader(vs);

  GLint compile_state = 0;
  glGetShaderiv(vs, GL_COMPILE_STATUS, &compile_state);
  EXPECT_EQ(GL_FALSE, compile_state);

  // Compiling program cutting off invalid parts should succeed.
  const GLint lengths[] = { valid_shader_str.length() };
  glShaderSource(vs, 1, invalid_shader_strings, lengths);
  glCompileShader(vs);
  glGetShaderiv(vs, GL_COMPILE_STATUS, &compile_state);
  EXPECT_EQ(GL_TRUE, compile_state);
}

TEST_F(GLProgramTest, UniformsInCurrentProgram) {
  static const char* v_shader_str = SHADER(
      attribute vec4 a_position;
      void main()
      {
         gl_Position = a_position;
      }
  );
  static const char* f_shader_str = SHADER(
      precision mediump float;
      uniform vec4 u_color;
      void main()
      {
          gl_FragColor = u_color;;
      }
  );

  // Load the program.
  GLuint program = GLTestHelper::LoadProgram(v_shader_str, f_shader_str);
  glUseProgram(program);

  // Relink.
  glLinkProgram(program);

  // This test will fail on NVidia Linux if not worked around.
  GLint color_location = glGetUniformLocation(program, "u_color");
  glUniform4f(color_location, 0.0f, 0.0f, 1.0f, 1.0f);

  // We specifically don't call UseProgram again.
  GLuint position_loc = glGetAttribLocation(program, "a_position");
  GLTestHelper::SetupUnitQuad(position_loc);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  uint8 expected_color[] = { 0, 0, 255, 255, };
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, 1, 1, 0, expected_color));
  GLTestHelper::CheckGLError("no errors", __LINE__);
}

TEST_F(GLProgramTest, DeferCompileWithExt) {
  // This test must have extensions enabled.
  gles2::ContextGroup* context_group = gl_.decoder()->GetContextGroup();
  gles2::FeatureInfo* feature_info = context_group->feature_info();
  const gles2::FeatureInfo::FeatureFlags& flags = feature_info->feature_flags();
  if (!flags.ext_frag_depth)
    return;

  static const char* v_shdr_str = R"(
      attribute vec4 vPosition;
      void main()
      {
        gl_Position = vPosition;
      }
  )";
  static const char* f_shdr_str = R"(
      #extension GL_EXT_frag_depth : enable
      void main()
      {
        gl_FragDepthEXT = 1.0;
      }
  )";

  // First compile and link to be shader compiles.
  GLuint vs_good = GLTestHelper::CompileShader(GL_VERTEX_SHADER, v_shdr_str);
  GLuint fs_good = GLTestHelper::CompileShader(GL_FRAGMENT_SHADER, f_shdr_str);
  GLuint program_good = GLTestHelper::LinkProgram(vs_good, fs_good);
  GLint linked_good = 0;
  glGetProgramiv(program_good, GL_LINK_STATUS, &linked_good);
  EXPECT_NE(0, linked_good);

  // Disable extension and be sure shader no longer compiles.
  ASSERT_TRUE(glEnableFeatureCHROMIUM("webgl_enable_glsl_webgl_validation"));
  GLuint vs_bad = GLTestHelper::CompileShader(GL_VERTEX_SHADER, v_shdr_str);
  GLuint fs_bad = GLTestHelper::CompileShader(GL_FRAGMENT_SHADER, f_shdr_str);
  GLuint program_bad = GLTestHelper::LinkProgram(vs_bad, fs_bad);
  GLint linked_bad = 0;
  glGetProgramiv(program_bad, GL_LINK_STATUS, &linked_bad);
  EXPECT_EQ(0, linked_bad);

  // Relinking good compilations without extension disabled should still link.
  GLuint program_defer_good = GLTestHelper::LinkProgram(vs_good, fs_good);
  GLint linked_defer_good = 0;
  glGetProgramiv(program_defer_good, GL_LINK_STATUS, &linked_defer_good);
  EXPECT_NE(0, linked_defer_good);

  // linking bad compilations with extension enabled should still not link.
  GLuint vs_bad2 = GLTestHelper::CompileShader(GL_VERTEX_SHADER, v_shdr_str);
  GLuint fs_bad2 = GLTestHelper::CompileShader(GL_FRAGMENT_SHADER, f_shdr_str);
  glRequestExtensionCHROMIUM("GL_EXT_frag_depth");
  GLuint program_bad2 = GLTestHelper::LinkProgram(vs_bad2, fs_bad2);
  GLint linked_bad2 = 0;
  glGetProgramiv(program_bad2, GL_LINK_STATUS, &linked_bad2);
  EXPECT_EQ(0, linked_bad2);

  // Be sure extension was actually turned on by recompiling.
  GLuint vs_good2 = GLTestHelper::LoadShader(GL_VERTEX_SHADER, v_shdr_str);
  GLuint fs_good2 = GLTestHelper::LoadShader(GL_FRAGMENT_SHADER, f_shdr_str);
  GLuint program_good2 = GLTestHelper::SetupProgram(vs_good2, fs_good2);
  EXPECT_NE(0u, program_good2);
}

TEST_F(GLProgramTest, DeleteAttachedShaderLinks) {
  static const char* v_shdr_str = R"(
      attribute vec4 vPosition;
      void main()
      {
        gl_Position = vPosition;
      }
  )";
  static const char* f_shdr_str = R"(
      void main()
      {
        gl_FragColor = vec4(1, 1, 1, 1);
      }
  )";

  // Compiling the shaders, attaching, then deleting before linking should work.
  GLuint vs = GLTestHelper::CompileShader(GL_VERTEX_SHADER, v_shdr_str);
  GLuint fs = GLTestHelper::CompileShader(GL_FRAGMENT_SHADER, f_shdr_str);

  GLuint program = glCreateProgram();
  glAttachShader(program, vs);
  glAttachShader(program, fs);

  glDeleteShader(vs);
  glDeleteShader(fs);

  glLinkProgram(program);

  GLint linked = 0;
  glGetProgramiv(program, GL_LINK_STATUS, &linked);
  EXPECT_NE(0, linked);
}

}  // namespace gpu

