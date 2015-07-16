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

class GLVirtualContextsTest : public testing::Test {
 protected:
  static const int kSize0 = 4;
  static const int kSize1 = 8;
  static const int kSize2 = 16;

  static const GLfloat kFloatRed[4];
  static const GLfloat kFloatGreen[4];
  static const uint8 kExpectedRed[4];
  static const uint8 kExpectedGreen[4];

  void SetUp() override {
    GLManager::Options options;
    options.size = gfx::Size(kSize0, kSize0);
    gl_real_.Initialize(options);
    gl_real_shared_.Initialize(options);
    options.virtual_manager = &gl_real_shared_;
    options.size = gfx::Size(kSize1, kSize1);
    gl1_.Initialize(options);
    options.size = gfx::Size(kSize2, kSize2);
    gl2_.Initialize(options);
  }

  void TearDown() override {
    gl1_.Destroy();
    gl2_.Destroy();
    gl_real_shared_.Destroy();
    gl_real_.Destroy();
  }

  GLuint SetupColoredVertexProgram() {
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

  void SetUpColoredUnitQuad(const GLfloat* color) {
    GLuint program1 = SetupColoredVertexProgram();
    GLuint position_loc1 = glGetAttribLocation(program1, "a_position");
    GLuint color_loc1 = glGetAttribLocation(program1, "a_color");
    GLTestHelper::SetupUnitQuad(position_loc1);
    GLTestHelper::SetupColorsForUnitQuad(color_loc1, color, GL_STATIC_DRAW);
  }

  GLManager gl_real_;
  GLManager gl_real_shared_;
  GLManager gl1_;
  GLManager gl2_;
};

const GLfloat GLVirtualContextsTest::kFloatRed[4] = {
    1.0f, 0.0f, 0.0f, 1.0f,
};
const GLfloat GLVirtualContextsTest::kFloatGreen[4] = {
    0.0f, 1.0f, 0.0f, 1.0f,
};
const uint8 GLVirtualContextsTest::kExpectedRed[4] = {
    255, 0, 0, 255,
};
const uint8 GLVirtualContextsTest::kExpectedGreen[4] = {
    0, 255, 0, 255,
};

namespace {

void SetupSimpleShader(const uint8* color) {
  static const char* v_shader_str = SHADER(
      attribute vec4 a_Position;
      void main()
      {
         gl_Position = a_Position;
      }
   );

  static const char* f_shader_str = SHADER(
      precision mediump float;
      uniform vec4 u_color;
      void main()
      {
        gl_FragColor = u_color;
      }
  );

  GLuint program = GLTestHelper::LoadProgram(v_shader_str, f_shader_str);
  glUseProgram(program);

  GLuint position_loc = glGetAttribLocation(program, "a_Position");

  GLTestHelper::SetupUnitQuad(position_loc);

  GLuint color_loc = glGetUniformLocation(program, "u_color");
  glUniform4f(
      color_loc,
      color[0] / 255.0f,
      color[1] / 255.0f,
      color[2] / 255.0f,
      color[3] / 255.0f);
}

void TestDraw(int size) {
  uint8 expected_clear[] = { 127, 0, 255, 0, };
  glClearColor(0.5f, 0.0f, 1.0f, 0.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, size, size, 1, expected_clear));
  glDrawArrays(GL_TRIANGLES, 0, 6);
}

}  // anonymous namespace

// http://crbug.com/281565
TEST_F(GLVirtualContextsTest, Basic) {
  struct TestInfo {
    int size;
    uint8 color[4];
    GLManager* manager;
  };
  const int kNumTests = 3;
  TestInfo tests[] = {
    { kSize0, { 255, 0, 0, 0, }, &gl_real_, },
    { kSize1, { 0, 255, 0, 0, }, &gl1_, },
    { kSize2, { 0, 0, 255, 0, }, &gl2_, },
  };

  for (int ii = 0; ii < kNumTests; ++ii) {
    const TestInfo& test = tests[ii];
    GLManager* gl_manager = test.manager;
    gl_manager->MakeCurrent();
    SetupSimpleShader(test.color);
  }

  for (int ii = 0; ii < kNumTests; ++ii) {
    const TestInfo& test = tests[ii];
    GLManager* gl_manager = test.manager;
    gl_manager->MakeCurrent();
    TestDraw(test.size);
  }

  for (int ii = 0; ii < kNumTests; ++ii) {
    const TestInfo& test = tests[ii];
    GLManager* gl_manager = test.manager;
    gl_manager->MakeCurrent();
    EXPECT_TRUE(GLTestHelper::CheckPixels(
        0, 0, test.size, test.size, 0, test.color));
  }

  for (int ii = 0; ii < kNumTests; ++ii) {
    const TestInfo& test = tests[ii];
    GLManager* gl_manager = test.manager;
    gl_manager->MakeCurrent();
    GLTestHelper::CheckGLError("no errors", __LINE__);
  }
}

// http://crbug.com/363407
TEST_F(GLVirtualContextsTest, VertexArrayObjectRestore) {
  GLuint vao1 = 0, vao2 = 0;

  gl1_.MakeCurrent();
  // Set up red quad in vao1.
  glGenVertexArraysOES(1, &vao1);
  glBindVertexArrayOES(vao1);
  SetUpColoredUnitQuad(kFloatRed);
  glFinish();

  gl2_.MakeCurrent();
  // Set up green quad in vao2.
  glGenVertexArraysOES(1, &vao2);
  glBindVertexArrayOES(vao2);
  SetUpColoredUnitQuad(kFloatGreen);
  glFinish();

  gl1_.MakeCurrent();
  // Test to ensure that vao1 is still the active VAO for this context.
  glDrawArrays(GL_TRIANGLES, 0, 6);
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, kSize1, kSize1, 0, kExpectedRed));
  glFinish();
  GLTestHelper::CheckGLError("no errors", __LINE__);

  gl2_.MakeCurrent();
  // Test to ensure that vao2 is still the active VAO for this context.
  glDrawArrays(GL_TRIANGLES, 0, 6);
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, kSize2, kSize2, 0, kExpectedGreen));
  glFinish();
  GLTestHelper::CheckGLError("no errors", __LINE__);
}

// http://crbug.com/363407
TEST_F(GLVirtualContextsTest, VertexArrayObjectRestoreRebind) {
  GLuint vao1 = 0, vao2 = 0;

  gl1_.MakeCurrent();
  // Set up red quad in vao1.
  glGenVertexArraysOES(1, &vao1);
  glBindVertexArrayOES(vao1);
  SetUpColoredUnitQuad(kFloatRed);
  glFinish();

  gl2_.MakeCurrent();
  // Set up green quad in new vao2.
  glGenVertexArraysOES(1, &vao2);
  glBindVertexArrayOES(vao2);
  SetUpColoredUnitQuad(kFloatGreen);
  glFinish();

  gl1_.MakeCurrent();
  // Test to ensure that vao1 hasn't been corrupted after rebinding.
  // Bind 0 is required so that bind vao1 is not optimized away in the service.
  glBindVertexArrayOES(0);
  glBindVertexArrayOES(vao1);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, kSize1, kSize1, 0, kExpectedRed));
  glFinish();
  GLTestHelper::CheckGLError("no errors", __LINE__);

  gl2_.MakeCurrent();
  // Test to ensure that vao1 hasn't been corrupted after rebinding.
  // Bind 0 is required so that bind vao2 is not optimized away in the service.
  glBindVertexArrayOES(0);
  glBindVertexArrayOES(vao2);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, kSize2, kSize2, 0, kExpectedGreen));
  glFinish();

  GLTestHelper::CheckGLError("no errors", __LINE__);
}

// http://crbug.com/363407
TEST_F(GLVirtualContextsTest, VertexArrayObjectRestoreDefault) {
  gl1_.MakeCurrent();
  // Set up red quad in default VAO.
  SetUpColoredUnitQuad(kFloatRed);
  glFinish();

  gl2_.MakeCurrent();
  // Set up green quad in default VAO.
  SetUpColoredUnitQuad(kFloatGreen);
  glFinish();

  // Gen & bind a non-default VAO.
  GLuint vao;
  glGenVertexArraysOES(1, &vao);
  glBindVertexArrayOES(vao);
  glFinish();

  gl1_.MakeCurrent();
  // Test to ensure that default VAO on gl1_ is still valid.
  glDrawArrays(GL_TRIANGLES, 0, 6);
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, kSize1, kSize1, 0, kExpectedRed));
  glFinish();

  gl2_.MakeCurrent();
  // Test to ensure that default VAO on gl2_ is still valid.
  // This tests that a default VAO is restored even when it's not currently
  // bound during the context switch.
  glBindVertexArrayOES(0);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, kSize2, kSize2, 0, kExpectedGreen));
  glFinish();

  GLTestHelper::CheckGLError("no errors", __LINE__);
}

}  // namespace gpu

