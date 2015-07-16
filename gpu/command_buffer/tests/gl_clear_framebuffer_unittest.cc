// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GL_GLEXT_PROTOTYPES
#define GL_GLEXT_PROTOTYPES
#endif

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

#include <vector>

#include "base/command_line.h"
#include "base/strings/string_number_conversions.h"
#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "gpu/config/gpu_switches.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

// A collection of tests that exercise the glClear workaround.
class GLClearFramebufferTest : public testing::TestWithParam<bool> {
 public:
  GLClearFramebufferTest() : color_handle_(0u), depth_handle_(0u) {}

 protected:
  void SetUp() override {
    if (GetParam()) {
      // Force the glClear() workaround so we can test it here.
      base::CommandLine command_line(base::CommandLine::NO_PROGRAM);
      command_line.AppendSwitchASCII(switches::kGpuDriverBugWorkarounds,
                                     base::IntToString(gpu::GL_CLEAR_BROKEN));
      gl_.InitializeWithCommandLine(GLManager::Options(), &command_line);
      DCHECK(gl_.workarounds().gl_clear_broken);
    } else {
      gl_.Initialize(GLManager::Options());
      DCHECK(!gl_.workarounds().gl_clear_broken);
    }
  }

  void InitDraw();
  void SetDrawColor(GLfloat r, GLfloat g, GLfloat b, GLfloat a);
  void SetDrawDepth(GLfloat depth);
  void DrawQuad();

  void TearDown() override {
    GLTestHelper::CheckGLError("no errors", __LINE__);
    gl_.Destroy();
  }

 private:
  GLManager gl_;
  GLuint color_handle_;
  GLuint depth_handle_;
};

void GLClearFramebufferTest::InitDraw() {
  static const char* v_shader_str =
      "attribute vec4 a_Position;\n"
      "uniform float u_depth;\n"
      "void main()\n"
      "{\n"
      "   gl_Position = a_Position;\n"
      "   gl_Position.z = u_depth;\n"
      "}\n";
  static const char* f_shader_str =
      "precision mediump float;\n"
      "uniform vec4 u_draw_color;\n"
      "void main()\n"
      "{\n"
      "  gl_FragColor = u_draw_color;\n"
      "}\n";

  GLuint program = GLTestHelper::LoadProgram(v_shader_str, f_shader_str);
  DCHECK(program);
  glUseProgram(program);
  GLuint position_loc = glGetAttribLocation(program, "a_Position");

  GLTestHelper::SetupUnitQuad(position_loc);
  color_handle_ = glGetUniformLocation(program, "u_draw_color");
  DCHECK(color_handle_ != static_cast<GLuint>(-1));
  depth_handle_ = glGetUniformLocation(program, "u_depth");
  DCHECK(depth_handle_ != static_cast<GLuint>(-1));
}

void GLClearFramebufferTest::SetDrawColor(GLfloat r,
                                          GLfloat g,
                                          GLfloat b,
                                          GLfloat a) {
  glUniform4f(color_handle_, r, g, b, a);
}

void GLClearFramebufferTest::SetDrawDepth(GLfloat depth) {
  glUniform1f(depth_handle_, depth);
}

void GLClearFramebufferTest::DrawQuad() {
  glDrawArrays(GL_TRIANGLES, 0, 6);
}

INSTANTIATE_TEST_CASE_P(GLClearFramebufferTestWithParam,
                        GLClearFramebufferTest,
                        ::testing::Values(true, false));

TEST_P(GLClearFramebufferTest, ClearColor) {
  glClearColor(1.0f, 0.5f, 0.25f, 0.5f);
  glClear(GL_COLOR_BUFFER_BIT);

  // Verify.
  const uint8 expected[] = {255, 128, 64, 128};
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, 1, 1, 1 /* tolerance */, expected));
}

TEST_P(GLClearFramebufferTest, ClearColorWithMask) {
  glColorMask(GL_TRUE, GL_FALSE, GL_FALSE, GL_FALSE);
  glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);

  // Verify.
  const uint8 expected[] = {255, 0, 0, 0};
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, 1, 1, 0 /* tolerance */, expected));
}

// crbug.com/434094
#if !defined(OS_MACOSX)
TEST_P(GLClearFramebufferTest, ClearColorWithScissor) {
  glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);

  // Verify.
  const uint8 expected[] = {255, 255, 255, 255};
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, 1, 1, 0 /* tolerance */, expected));

  glScissor(0, 0, 0, 0);
  glEnable(GL_SCISSOR_TEST);
  glClearColor(0, 0, 0, 0);
  glClear(GL_COLOR_BUFFER_BIT);

  // Verify - no changes.
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, 1, 1, 0 /* tolerance */, expected));
}
#endif

TEST_P(GLClearFramebufferTest, ClearDepthStencil) {
  const GLuint kStencilRef = 1 << 2;
  InitDraw();
  SetDrawColor(1.0f, 0.0f, 0.0f, 1.0f);
  DrawQuad();
  // Verify.
  const uint8 kRed[] = {255, 0, 0, 255};
  const uint8 kGreen[] = {0, 255, 0, 255};
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, 1, 1, 0 /* tolerance */, kRed));

  glClearStencil(kStencilRef);
  glClear(GL_STENCIL_BUFFER_BIT);
  glEnable(GL_STENCIL_TEST);
  glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
  glStencilFunc(GL_NOTEQUAL, kStencilRef, 0xFFFFFFFF);

  SetDrawColor(0.0f, 1.0f, 0.0f, 1.0f);
  DrawQuad();
  // Verify - stencil should have failed, so still red.
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, 1, 1, 0 /* tolerance */, kRed));

  glStencilFunc(GL_EQUAL, kStencilRef, 0xFFFFFFFF);
  DrawQuad();
  // Verify - stencil should have passed, so green.
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, 1, 1, 0 /* tolerance */, kGreen));

  glEnable(GL_DEPTH_TEST);
  glClearDepthf(0.0f);
  glClear(GL_DEPTH_BUFFER_BIT);

  SetDrawDepth(0.5f);
  SetDrawColor(1.0f, 0.0f, 0.0f, 1.0f);
  DrawQuad();
  // Verify - depth test should have failed, so still green.
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, 1, 1, 0 /* tolerance */, kGreen));

  glClearDepthf(0.9f);
  glClear(GL_DEPTH_BUFFER_BIT);
  DrawQuad();
  // Verify - depth test should have passed, so red.
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(0, 0, 1, 1, 0 /* tolerance */, kRed));
}

}  // namespace gpu
