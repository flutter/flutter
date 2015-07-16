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

namespace gpu {

class GLChromiumFramebufferMultisampleTest : public testing::Test {
 protected:
  void SetUp() override { gl_.Initialize(GLManager::Options()); }

  void TearDown() override { gl_.Destroy(); }

  GLManager gl_;
};

// Test that GL is at least minimally working.
TEST_F(GLChromiumFramebufferMultisampleTest, CachedBindingsTest) {
  if (!GLTestHelper::HasExtension("GL_CHROMIUM_framebuffer_multisample")) {
    return;
  }

  GLuint fbo = 0;
  glGenFramebuffers(1, &fbo);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  // If the caching is bad the second call to glBindFramebuffer will do nothing.
  // which means the draw buffer is bad and will not return
  // GL_FRAMEBUFFER_COMPLETE and rendering will generate an error.
  EXPECT_EQ(static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE),
            glCheckFramebufferStatus(GL_FRAMEBUFFER));

  glClear(GL_COLOR_BUFFER_BIT);
  GLTestHelper::CheckGLError("no errors", __LINE__);
}

TEST_F(GLChromiumFramebufferMultisampleTest, DrawAndResolve) {
  if (!GLTestHelper::HasExtension("GL_CHROMIUM_framebuffer_multisample")) {
    return;
  }

  static const char* v_shader_str =
      "attribute vec4 a_Position;\n"
      "void main()\n"
      "{\n"
      "   gl_Position = a_Position;\n"
      "}\n";
  static const char* f_shader_str =
      "precision mediump float;\n"
      "void main()\n"
      "{\n"
      "  gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);\n"
      "}\n";

  GLuint program = GLTestHelper::LoadProgram(v_shader_str, f_shader_str);
  glUseProgram(program);
  GLuint position_loc = glGetAttribLocation(program, "a_Position");

  GLTestHelper::SetupUnitQuad(position_loc);

  const GLuint width = 100;
  const GLuint height = 100;

  // Create a sample buffer.
  GLsizei num_samples = 4, max_samples = 0;
  glGetIntegerv(GL_MAX_SAMPLES, &max_samples);
  num_samples = std::min(num_samples, max_samples);

  GLuint sample_fbo, sample_rb;
  glGenRenderbuffers(1, &sample_rb);
  glBindRenderbuffer(GL_RENDERBUFFER, sample_rb);
  glRenderbufferStorageMultisampleCHROMIUM(
      GL_RENDERBUFFER, num_samples, GL_RGBA8_OES, width, height);
  GLint param = 0;
  glGetRenderbufferParameteriv(
      GL_RENDERBUFFER, GL_RENDERBUFFER_SAMPLES, &param);
  EXPECT_GE(param, num_samples);

  glGenFramebuffers(1, &sample_fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, sample_fbo);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                            GL_COLOR_ATTACHMENT0,
                            GL_RENDERBUFFER,
                            sample_rb);
  EXPECT_EQ(static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE),
            glCheckFramebufferStatus(GL_FRAMEBUFFER));

  // Create another FBO to resolve the multisample buffer into.
  GLuint resolve_fbo, resolve_tex;
  glGenTextures(1, &resolve_tex);
  glBindTexture(GL_TEXTURE_2D, resolve_tex);
  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               width,
               height,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               NULL);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glGenFramebuffers(1, &resolve_fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, resolve_fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         resolve_tex,
                         0);
  EXPECT_EQ(static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE),
            glCheckFramebufferStatus(GL_FRAMEBUFFER));

  // Draw one triangle (bottom left half).
  glViewport(0, 0, width, height);
  glBindFramebuffer(GL_FRAMEBUFFER, sample_fbo);
  glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glDrawArrays(GL_TRIANGLES, 0, 3);

  // Resolve.
  glBindFramebuffer(GL_READ_FRAMEBUFFER, sample_fbo);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, resolve_fbo);
  glClearColor(1.0f, 0.0f, 0.0f, 0.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glBlitFramebufferCHROMIUM(0,
                            0,
                            width,
                            height,
                            0,
                            0,
                            width,
                            height,
                            GL_COLOR_BUFFER_BIT,
                            GL_NEAREST);

  // Verify.
  const uint8 green[] = {0, 255, 0, 255};
  const uint8 black[] = {0, 0, 0, 0};
  glBindFramebuffer(GL_READ_FRAMEBUFFER, resolve_fbo);
  EXPECT_TRUE(
      GLTestHelper::CheckPixels(width / 4, (3 * height) / 4, 1, 1, 0, green));
  EXPECT_TRUE(GLTestHelper::CheckPixels(width - 1, 0, 1, 1, 0, black));
}

}  // namespace gpu

