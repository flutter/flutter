// Copyright (c) 2012 The Chromium Authors. All rights reserved.
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

class DepthTextureTest : public testing::Test {
 protected:
  static const GLsizei kResolution = 64;
  void SetUp() override {
    GLManager::Options options;
    options.size = gfx::Size(kResolution, kResolution);
    gl_.Initialize(options);
  }

  void TearDown() override { gl_.Destroy(); }

  GLuint SetupUnitQuad(GLint position_location);

  GLManager gl_;
};

GLuint DepthTextureTest::SetupUnitQuad(GLint position_location) {
  GLuint vbo = 0;
  glGenBuffers(1, &vbo);
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  static float vertices[] = {
      1.0f,  1.0f,  1.0f,
     -1.0f,  1.0f,  0.0f,
     -1.0f, -1.0f, -1.0f,
      1.0f,  1.0f,  1.0f,
     -1.0f, -1.0f, -1.0f,
      1.0f, -1.0f,  0.0f,
  };
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
  glEnableVertexAttribArray(position_location);
  glVertexAttribPointer(position_location, 3, GL_FLOAT, GL_FALSE, 0, 0);

  return vbo;
}

namespace {

struct FormatType {
  GLenum format;
  GLenum type;
};

}  // anonymous namespace

TEST_F(DepthTextureTest, RenderTo) {
  if (!GLTestHelper::HasExtension("GL_CHROMIUM_depth_texture")) {
    return;
  }

  bool have_depth_stencil = GLTestHelper::HasExtension(
      "GL_OES_packed_depth_stencil");

  static const char* v_shader_str = SHADER(
      attribute vec4 v_position;
      void main()
      {
         gl_Position = v_position;
      }
  );
  static const char* f_shader_str = SHADER(
      precision mediump float;
      uniform sampler2D u_texture;
      uniform vec2 u_resolution;
      void main()
      {
        vec2 texcoord = gl_FragCoord.xy / u_resolution;
        gl_FragColor = texture2D(u_texture, texcoord);
      }
  );

  GLuint program = GLTestHelper::LoadProgram(v_shader_str, f_shader_str);

  GLint position_loc = glGetAttribLocation(program, "v_position");
  GLint resolution_loc = glGetUniformLocation(program, "u_resolution");

  SetupUnitQuad(position_loc);

  // Depth test needs to be on for the depth buffer to be updated.
  glEnable(GL_DEPTH_TEST);

  // create an fbo
  GLuint fbo = 0;
  glGenFramebuffers(1, &fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, fbo);

  // create a depth texture.
  GLuint color_texture = 0;
  GLuint depth_texture = 0;

  glGenTextures(1, &color_texture);
  glBindTexture(GL_TEXTURE_2D, color_texture);
  glTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, kResolution, kResolution,
      0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glFramebufferTexture2D(
      GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color_texture, 0);

  glGenTextures(1, &depth_texture);
  glBindTexture(GL_TEXTURE_2D, depth_texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glFramebufferTexture2D(
      GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depth_texture, 0);

  glUseProgram(program);
  glUniform2f(resolution_loc, kResolution, kResolution);

  static const FormatType format_types[] = {
    { GL_DEPTH_COMPONENT, GL_UNSIGNED_SHORT },
    { GL_DEPTH_COMPONENT, GL_UNSIGNED_INT },
    { GL_DEPTH_STENCIL_OES, GL_UNSIGNED_INT_24_8_OES },
  };
  for (size_t ii = 0; ii < arraysize(format_types); ++ii) {
    const FormatType& format_type = format_types[ii];
    GLenum format = format_type.format;
    GLenum type = format_type.type;

    if (format == GL_DEPTH_STENCIL_OES && !have_depth_stencil) {
      continue;
    }

    glBindTexture(GL_TEXTURE_2D, depth_texture);
    glTexImage2D(
        GL_TEXTURE_2D, 0, format, kResolution, kResolution,
        0, format, type, NULL);

    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    EXPECT_EQ(static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE), status)
        << "iteration: " << ii;
    if (status != GL_FRAMEBUFFER_COMPLETE) {
      continue;
    }

    if (!GLTestHelper::CheckGLError("no errors after setup", __LINE__)) {
      continue;
    }

    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Disconnect the texture so we'll render with the default texture.
    glBindTexture(GL_TEXTURE_2D, 0);

    // Render to the fbo.
    glDrawArrays(GL_TRIANGLES, 0, 6);

    if (!GLTestHelper::CheckGLError("no errors after depth draw", __LINE__)) {
      continue;
    }

    // Render with the depth texture.
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, depth_texture);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLES, 0, 6);

    if (!GLTestHelper::CheckGLError("no errors after texture draw", __LINE__)) {
      continue;
    }

    uint8 actual_pixels[kResolution * kResolution * 4] = { 0, };
    glReadPixels(
        0, 0, kResolution, kResolution, GL_RGBA, GL_UNSIGNED_BYTE,
        actual_pixels);

    if (!GLTestHelper::CheckGLError("no errors after readpixels", __LINE__)) {
      continue;
    }

    // Check that each pixel's red value is less than the previous pixel in
    // either direction. Basically verify we have a gradient. No assumption is
    // made about the other channels green, blue and alpha since, according to
    // the GL_CHROMIUM_depth_texture spec, they have undefined values for
    // depth textures.
    int bad_count = 0;  // used to not spam the log with too many messages.
    for (GLint yy = 0; bad_count < 16 && yy < kResolution; ++yy) {
      for (GLint xx = 0; bad_count < 16 && xx < kResolution; ++xx) {
        const uint8* actual = &actual_pixels[(yy * kResolution + xx) * 4];
        const uint8* left = actual - 4;
        const uint8* down = actual - kResolution * 4;

        // NOTE: Qualcomm on Nexus 4 the right most column has the same
        // values as the next to right most column. (bad interpolator?)
        if (xx > 0 && xx < kResolution - 1) {
          EXPECT_GT(actual[0], left[0])
              << "pixel at " << xx << ", " << yy
              << " actual[0] =" << static_cast<unsigned>(actual[0])
              << " left[0] =" << static_cast<unsigned>(left[0])
              << " actual =" << reinterpret_cast<const void*>(actual)
              << " left =" << reinterpret_cast<const void*>(left);
          bad_count += (actual[0] > left[0] ? 0 : 1);
        }

        if (yy > 0 && yy < kResolution - 1) {
          EXPECT_GT(actual[0], down[0]) << "pixel at " << xx << ", " << yy;
          bad_count += (actual[0] > down[0] ? 0 : 1);
        }
      }
    }

    // Check that bottom left corner is vastly different thatn top right.
    EXPECT_GT(
        actual_pixels[(kResolution * kResolution - 1) * 4] - actual_pixels[0],
        0xC0);

    GLTestHelper::CheckGLError("no errors after everything", __LINE__);
  }
}

}  // namespace gpu




