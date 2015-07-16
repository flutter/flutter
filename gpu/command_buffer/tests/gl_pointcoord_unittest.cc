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

class PointCoordTest : public testing::Test {
 public:
  static const GLsizei kResolution = 256;

 protected:
  void SetUp() override {
    GLManager::Options options;
    options.size = gfx::Size(kResolution, kResolution);
    gl_.Initialize(options);
  }

  void TearDown() override { gl_.Destroy(); }

  GLuint SetupQuad(GLint position_location, GLfloat pixel_offset);

  GLManager gl_;
};

GLuint PointCoordTest::SetupQuad(
    GLint position_location, GLfloat pixel_offset) {
  GLuint vbo = 0;
  glGenBuffers(1, &vbo);
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  float vertices[] = {
    -0.5f + pixel_offset, -0.5f + pixel_offset,
     0.5f + pixel_offset, -0.5f + pixel_offset,
    -0.5f + pixel_offset,  0.5f + pixel_offset,
     0.5f + pixel_offset,  0.5f + pixel_offset,
  };
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
  glEnableVertexAttribArray(position_location);
  glVertexAttribPointer(position_location, 2, GL_FLOAT, GL_FALSE, 0, 0);

  return vbo;
}

namespace {

struct FormatType {
  GLenum format;
  GLenum type;
};

GLfloat s2p(GLfloat s) {
  return (s + 1.0) * 0.5 * PointCoordTest::kResolution;
}

}  // anonymous namespace

// crbug.com/162976
// Flaky on Linux ATI bot.
#if (defined(OS_LINUX) && defined(NDEBUG))
#define MAYBE_RenderTo DISABLED_RenderTo
#else
#define MAYBE_RenderTo RenderTo
#endif

TEST_F(PointCoordTest, MAYBE_RenderTo) {
  static const char* v_shader_str = SHADER(
      attribute vec4 a_position;
      uniform float u_pointsize;
      void main()
      {
        gl_PointSize = u_pointsize;
        gl_Position = a_position;
      }
  );
  static const char* f_shader_str = SHADER(
      precision mediump float;
      void main()
      {
        gl_FragColor = vec4(
          gl_PointCoord.x,
          gl_PointCoord.y,
          0,
          1);
      }
  );

  GLuint program = GLTestHelper::LoadProgram(v_shader_str, f_shader_str);
  glUseProgram(program);

  GLint position_loc = glGetAttribLocation(program, "a_position");
  GLint pointsize_loc = glGetUniformLocation(program, "u_pointsize");

  GLint range[2] = { 0, 0 };
  glGetIntegerv(GL_ALIASED_POINT_SIZE_RANGE, &range[0]);
  GLint max_point_size = range[1];
  EXPECT_GE(max_point_size, 1);

  max_point_size = std::min(max_point_size, 64);
  GLint point_width = max_point_size / kResolution;
  GLint point_step = max_point_size / 4;
  point_step = std::max(1, point_step);

  glUniform1f(pointsize_loc, max_point_size);

  GLfloat pixel_offset = (max_point_size % 2) ? (1.0f / kResolution) : 0;

  SetupQuad(position_loc, pixel_offset);

  glClear(GL_COLOR_BUFFER_BIT);
  glDrawArrays(GL_POINTS, 0, 4);

  for (GLint py = 0; py < 2; ++py) {
    for (GLint px = 0; px < 2; ++px) {
      GLfloat point_x = -0.5 + px + pixel_offset;
      GLfloat point_y = -0.5 + py + pixel_offset;
      for (GLint yy = 0; yy < max_point_size; yy += point_step) {
        for (GLint xx = 0; xx < max_point_size; xx += point_step) {
          // formula for s and t from OpenGL ES 2.0 spec section 3.3
          GLfloat xw = s2p(point_x);
          GLfloat yw = s2p(point_y);
          GLfloat u = xx / max_point_size * 2 - 1;
          GLfloat v = yy / max_point_size * 2 - 1;
          GLint xf = s2p(point_x + u * point_width);
          GLint yf = s2p(point_y + v * point_width);
          GLfloat s = 0.5 + (xf + 0.5 - xw) / max_point_size;
          GLfloat t = 0.5 + (yf + 0.5 - yw) / max_point_size;
          uint8 color[4] = {
            static_cast<uint8>(s * 255),
            static_cast<uint8>((1 - t) * 255),
            0,
            255,
          };
          GLTestHelper::CheckPixels(xf, yf, 1, 1, 4, color);
        }
      }
    }
  }

  GLTestHelper::CheckGLError("no errors", __LINE__);
}

}  // namespace gpu



