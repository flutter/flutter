// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"


#define SHADER(Src) #Src

namespace gpu {

class GLStreamDrawTest : public testing::Test {
 protected:
  static const int kSize = 4;

  void SetUp() override {
    GLManager::Options options;
    options.size = gfx::Size(kSize, kSize);
    gl_.Initialize(options);
  }

  void TearDown() override { gl_.Destroy(); }

  GLManager gl_;
};

namespace {

GLuint SetupProgram() {
  static const char* v_shader_str = SHADER(
      attribute vec4 a_position;
      attribute vec4 a_color;
      varying vec4 v_color;
      void main()
      {
         gl_Position = a_position;
         v_color = a_color;
      }
   );

  static const char* f_shader_str = SHADER(
      precision mediump float;
      varying vec4 v_color;
      void main()
      {
        gl_FragColor = v_color;
      }
  );

  GLuint program = GLTestHelper::LoadProgram(v_shader_str, f_shader_str);
  glUseProgram(program);
  return program;
}

}  // anonymous namespace.

TEST_F(GLStreamDrawTest, Basic) {
  static GLfloat float_red[4] = { 1.0f, 0.0f, 0.0f, 1.0f, };
  static GLfloat float_green[4] = { 0.0f, 1.0f, 0.0f, 1.0f, };
  static uint8 expected_red[4] =  {255, 0, 0, 255, };
  static uint8 expected_green[4] =  {0, 255, 0, 255, };

  GLuint program = SetupProgram();
  GLuint position_loc = glGetAttribLocation(program, "a_position");
  GLuint color_loc = glGetAttribLocation(program, "a_color");
  GLTestHelper::SetupUnitQuad(position_loc);
  GLTestHelper::SetupColorsForUnitQuad(color_loc, float_red, GL_STREAM_DRAW);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, kSize, kSize, 0, expected_red));
  GLTestHelper::SetupColorsForUnitQuad(color_loc, float_green, GL_STATIC_DRAW);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, kSize, kSize, 0, expected_green));

  GLTestHelper::CheckGLError("no errors", __LINE__);
}

// http://crbug.com/281565
#if !defined(OS_ANDROID)
TEST_F(GLStreamDrawTest, DrawElements) {
  static GLfloat float_red[4] = { 1.0f, 0.0f, 0.0f, 1.0f, };
  static GLfloat float_green[4] = { 0.0f, 1.0f, 0.0f, 1.0f, };
  static uint8 expected_red[4] =  {255, 0, 0, 255, };
  static uint8 expected_green[4] =  {0, 255, 0, 255, };

  GLuint program = SetupProgram();
  GLuint position_loc = glGetAttribLocation(program, "a_position");
  GLuint color_loc = glGetAttribLocation(program, "a_color");
  GLTestHelper::SetupUnitQuad(position_loc);
  GLTestHelper::SetupColorsForUnitQuad(color_loc, float_red, GL_STREAM_DRAW);

  GLuint index_buffer = 0;
  glGenBuffers(1, &index_buffer);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer);
  static GLubyte indices[] = { 0, 1, 2, 3, 4, 5, };
  glBufferData(
      GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STREAM_DRAW);
  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, NULL);
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, kSize, kSize, 0, expected_red));
  GLTestHelper::SetupColorsForUnitQuad(color_loc, float_green, GL_STATIC_DRAW);

  glBufferData(
      GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, NULL);
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, kSize, kSize, 0, expected_green));

  GLTestHelper::CheckGLError("no errors", __LINE__);
}
#endif

TEST_F(GLStreamDrawTest, VertexArrayObjects) {
  if (!GLTestHelper::HasExtension("GL_OES_vertex_array_object")) {
    return;
  }

  static GLfloat float_red[4] = { 1.0f, 0.0f, 0.0f, 1.0f, };
  static GLfloat float_green[4] = { 0.0f, 1.0f, 0.0f, 1.0f, };
  static uint8 expected_red[4] =  {255, 0, 0, 255, };
  static uint8 expected_green[4] =  {0, 255, 0, 255, };

  GLuint program = SetupProgram();
  GLuint position_loc = glGetAttribLocation(program, "a_position");
  GLuint color_loc = glGetAttribLocation(program, "a_color");

  GLuint vaos[2];
  glGenVertexArraysOES(2, vaos);

  glBindVertexArrayOES(vaos[0]);
  GLuint position_buffer = GLTestHelper::SetupUnitQuad(position_loc);
  GLTestHelper::SetupColorsForUnitQuad(color_loc, float_red, GL_STREAM_DRAW);

  glBindVertexArrayOES(vaos[1]);
  glBindBuffer(GL_ARRAY_BUFFER, position_buffer);
  glEnableVertexAttribArray(position_loc);
  glVertexAttribPointer(position_loc, 2, GL_FLOAT, GL_FALSE, 0, 0);
  GLTestHelper::SetupColorsForUnitQuad(color_loc, float_green, GL_STATIC_DRAW);

  for (int ii = 0; ii < 2; ++ii) {
    glBindVertexArrayOES(vaos[0]);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, kSize, kSize, 0, expected_red));

    glBindVertexArrayOES(vaos[1]);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    EXPECT_TRUE(
        GLTestHelper::CheckPixels(0, 0, kSize, kSize, 0, expected_green));
  }

  GLTestHelper::CheckGLError("no errors", __LINE__);
}

}  // namespace gpu

