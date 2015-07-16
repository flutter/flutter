// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

#define SHADER(Src) #Src

namespace gpu {

class BindUniformLocationTest : public testing::Test {
 protected:
  static const GLsizei kResolution = 4;
  void SetUp() override {
    GLManager::Options options;
    options.size = gfx::Size(kResolution, kResolution);
    gl_.Initialize(options);
  }

  void TearDown() override { gl_.Destroy(); }

  GLManager gl_;
};

TEST_F(BindUniformLocationTest, Basic) {
  ASSERT_TRUE(
      GLTestHelper::HasExtension("GL_CHROMIUM_bind_uniform_location"));

  static const char* v_shader_str = SHADER(
      attribute vec4 a_position;
      void main()
      {
         gl_Position = a_position;
      }
  );
  static const char* f_shader_str = SHADER(
      precision mediump float;
      uniform vec4 u_colorC;
      uniform vec4 u_colorB[2];
      uniform vec4 u_colorA;
      void main()
      {
        gl_FragColor = u_colorA + u_colorB[0] + u_colorB[1] + u_colorC;
      }
  );

  GLint color_a_location = 3;
  GLint color_b_location = 10;
  GLint color_c_location = 5;

  GLuint vertex_shader = GLTestHelper::LoadShader(
      GL_VERTEX_SHADER, v_shader_str);
  GLuint fragment_shader = GLTestHelper::LoadShader(
      GL_FRAGMENT_SHADER, f_shader_str);

  GLuint program = glCreateProgram();

  glBindUniformLocationCHROMIUM(program, color_a_location, "u_colorA");
  glBindUniformLocationCHROMIUM(program, color_b_location, "u_colorB[0]");
  glBindUniformLocationCHROMIUM(program, color_c_location, "u_colorC");

  glAttachShader(program, vertex_shader);
  glAttachShader(program, fragment_shader);
  // Link the program
  glLinkProgram(program);
  // Check the link status
  GLint linked = 0;
  glGetProgramiv(program, GL_LINK_STATUS, &linked);
  EXPECT_EQ(1, linked);

  GLint position_loc = glGetAttribLocation(program, "a_position");

  GLTestHelper::SetupUnitQuad(position_loc);

  glUseProgram(program);

  static const float color_b[] = {
    0.0f, 0.50f, 0.0f, 0.0f,
    0.0f, 0.0f, 0.75f, 0.0f,
  };

  glUniform4f(color_a_location, 0.25f, 0.0f, 0.0f, 0.0f);
  glUniform4fv(color_b_location, 2, color_b);
  glUniform4f(color_c_location, 0.0f, 0.0f, 0.0f, 1.0f);

  glDrawArrays(GL_TRIANGLES, 0, 6);

  static const uint8 expected[] = { 64, 128, 192, 255 };
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, kResolution, kResolution, 1, expected));

  GLTestHelper::CheckGLError("no errors", __LINE__);
}

TEST_F(BindUniformLocationTest, Compositor) {
  ASSERT_TRUE(
      GLTestHelper::HasExtension("GL_CHROMIUM_bind_uniform_location"));

  static const char* v_shader_str = SHADER(
      attribute vec4 a_position;
      attribute vec2 a_texCoord;
      uniform mat4 matrix;
      uniform vec2 color_a[4];
      uniform vec4 color_b;
      varying vec4 v_color;
      void main()
      {
          v_color.xy = color_a[0] + color_a[1];
          v_color.zw = color_a[2] + color_a[3];
          v_color += color_b;
          gl_Position = matrix * a_position;
      }
  );

  static const char* f_shader_str =  SHADER(
      precision mediump float;
      varying vec4 v_color;
      uniform float alpha;
      uniform vec4 multiplier;
      uniform vec3 color_c[8];
      void main()
      {
          vec4 color_c_sum = vec4(0.0);
          color_c_sum.xyz += color_c[0];
          color_c_sum.xyz += color_c[1];
          color_c_sum.xyz += color_c[2];
          color_c_sum.xyz += color_c[3];
          color_c_sum.xyz += color_c[4];
          color_c_sum.xyz += color_c[5];
          color_c_sum.xyz += color_c[6];
          color_c_sum.xyz += color_c[7];
          color_c_sum.w = alpha;
          color_c_sum *= multiplier;
          gl_FragColor = v_color + color_c_sum;
      }
  );

  int counter = 0;
  int matrix_location = counter++;
  int color_a_location = counter++;
  int color_b_location = counter++;
  int alpha_location = counter++;
  int multiplier_location = counter++;
  int color_c_location = counter++;

  GLuint vertex_shader = GLTestHelper::LoadShader(
      GL_VERTEX_SHADER, v_shader_str);
  GLuint fragment_shader = GLTestHelper::LoadShader(
      GL_FRAGMENT_SHADER, f_shader_str);

  GLuint program = glCreateProgram();

  glBindUniformLocationCHROMIUM(program, matrix_location, "matrix");
  glBindUniformLocationCHROMIUM(program, color_a_location, "color_a");
  glBindUniformLocationCHROMIUM(program, color_b_location, "color_b");
  glBindUniformLocationCHROMIUM(program, alpha_location, "alpha");
  glBindUniformLocationCHROMIUM(program, multiplier_location, "multiplier");
  glBindUniformLocationCHROMIUM(program, color_c_location, "color_c");

  glAttachShader(program, vertex_shader);
  glAttachShader(program, fragment_shader);
  // Link the program
  glLinkProgram(program);
  // Check the link status
  GLint linked = 0;
  glGetProgramiv(program, GL_LINK_STATUS, &linked);
  EXPECT_EQ(1, linked);

  GLint position_loc = glGetAttribLocation(program, "a_position");

  GLTestHelper::SetupUnitQuad(position_loc);

  glUseProgram(program);

  static const float color_a[] = {
    0.1f, 0.1f, 0.1f, 0.1f,
    0.1f, 0.1f, 0.1f, 0.1f,
  };

  static const float color_c[] = {
    0.1f, 0.1f, 0.1f,
    0.1f, 0.1f, 0.1f,
    0.1f, 0.1f, 0.1f,
    0.1f, 0.1f, 0.1f,
    0.1f, 0.1f, 0.1f,
    0.1f, 0.1f, 0.1f,
    0.1f, 0.1f, 0.1f,
    0.1f, 0.1f, 0.1f,
  };

  static const float identity[] = {
    1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1,
  };

  glUniformMatrix4fv(matrix_location, 1, false, identity);
  glUniform2fv(color_a_location, 4, color_a);
  glUniform4f(color_b_location, 0.2f, 0.2f, 0.2f, 0.2f);
  glUniform1f(alpha_location, 0.8f);
  glUniform4f(multiplier_location, 0.5f, 0.5f, 0.5f, 0.5f);
  glUniform3fv(color_c_location, 8, color_c);

  glDrawArrays(GL_TRIANGLES, 0, 6);

  static const uint8 expected[] = { 204, 204, 204, 204 };
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, kResolution, kResolution, 1, expected));

  GLTestHelper::CheckGLError("no errors", __LINE__);

}

}  // namespace gpu



