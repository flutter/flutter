// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

#include <cmath>

#include "base/basictypes.h"
#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "base/run_loop.h"
#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class GLReadbackTest : public testing::Test {
 protected:
  void SetUp() override { gl_.Initialize(GLManager::Options()); }

  void TearDown() override { gl_.Destroy(); }

  static void WaitForQueryCallback(int q, base::Closure cb) {
    unsigned int done = 0;
    glGetQueryObjectuivEXT(q, GL_QUERY_RESULT_AVAILABLE_EXT, &done);
    if (done) {
      cb.Run();
    } else {
      base::MessageLoop::current()->PostDelayedTask(
          FROM_HERE,
          base::Bind(&WaitForQueryCallback, q, cb),
          base::TimeDelta::FromMilliseconds(3));
    }
  }

  void WaitForQuery(int q) {
    base::RunLoop run_loop;
    WaitForQueryCallback(q, run_loop.QuitClosure());
    run_loop.Run();
  }

  GLManager gl_;
};


TEST_F(GLReadbackTest, ReadPixelsWithPBOAndQuery) {
  const GLint kBytesPerPixel = 4;
  const GLint kWidth = 2;
  const GLint kHeight = 2;

  GLuint b, q;
  glClearColor(0.0, 0.0, 1.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
  glGenBuffers(1, &b);
  glGenQueriesEXT(1, &q);
  glBindBuffer(GL_PIXEL_PACK_TRANSFER_BUFFER_CHROMIUM, b);
  glBufferData(GL_PIXEL_PACK_TRANSFER_BUFFER_CHROMIUM,
               kWidth * kHeight * kBytesPerPixel,
               NULL,
               GL_STREAM_READ);
  glBeginQueryEXT(GL_ASYNC_PIXEL_PACK_COMPLETED_CHROMIUM, q);
  glReadPixels(0, 0, kWidth, kHeight, GL_RGBA, GL_UNSIGNED_BYTE, 0);
  glEndQueryEXT(GL_ASYNC_PIXEL_PACK_COMPLETED_CHROMIUM);
  glFlush();
  WaitForQuery(q);

  // TODO(hubbe): Check that glMapBufferCHROMIUM does not block here.
  unsigned char *data = static_cast<unsigned char *>(
      glMapBufferCHROMIUM(
          GL_PIXEL_PACK_TRANSFER_BUFFER_CHROMIUM,
          GL_READ_ONLY));
  EXPECT_TRUE(data);
  EXPECT_EQ(data[0], 0);   // red
  EXPECT_EQ(data[1], 0);   // green
  EXPECT_EQ(data[2], 255); // blue
  glUnmapBufferCHROMIUM(GL_PIXEL_PACK_TRANSFER_BUFFER_CHROMIUM);
  glBindBuffer(GL_PIXEL_PACK_TRANSFER_BUFFER_CHROMIUM, 0);
  glDeleteBuffers(1, &b);
  glDeleteQueriesEXT(1, &q);
  GLTestHelper::CheckGLError("no errors", __LINE__);
}

static float HalfToFloat32(uint16 value) {
  int32 s = (value >> 15) & 0x00000001;
  int32 e = (value >> 10) & 0x0000001f;
  int32 m =  value        & 0x000003ff;

  if (e == 0) {
    if (m == 0) {
      uint32 result = s << 31;
      return bit_cast<float>(result);
    } else {
      while (!(m & 0x00000400)) {
        m <<= 1;
        e -=  1;
      }

      e += 1;
      m &= ~0x00000400;
    }
  } else if (e == 31) {
    if (m == 0) {
      uint32 result = (s << 31) | 0x7f800000;
      return bit_cast<float>(result);
    } else {
      uint32 result = (s << 31) | 0x7f800000 | (m << 13);
      return bit_cast<float>(result);
    }
  }

  e = e + (127 - 15);
  m = m << 13;

  uint32 result = (s << 31) | (e << 23) | m;
  return bit_cast<float>(result);
}

static GLuint CompileShader(GLenum type, const char *data) {
  const char *shaderStrings[1] = { data };

  GLuint shader = glCreateShader(type);
  glShaderSource(shader, 1, shaderStrings, NULL);
  glCompileShader(shader);

  GLint compile_status = 0;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compile_status);
  if (compile_status != GL_TRUE) {
    glDeleteShader(shader);
    shader = 0;
  }

  return shader;
}

TEST_F(GLReadbackTest, ReadPixelsFloat) {
  const GLsizei kTextureSize = 4;
  const GLfloat kDrawColor[4] = { -10.9f, 0.5f, 10.5f, 100.12f };
  const GLfloat kEpsilon = 0.01f;

  struct TestFormat {
    GLint format;
    GLint type;
    uint32 comp_count;
  };
  TestFormat test_formats[4];
  size_t test_count = 0;
  const char *extensions = reinterpret_cast<const char*>(
      glGetString(GL_EXTENSIONS));
  if (strstr(extensions, "GL_OES_texture_half_float") != NULL) {
      TestFormat rgb16f = { GL_RGB, GL_HALF_FLOAT_OES, 3 };
      test_formats[test_count++] = rgb16f;

      TestFormat rgba16f = { GL_RGBA, GL_HALF_FLOAT_OES, 4 };
      test_formats[test_count++] = rgba16f;
  }
  if (strstr(extensions, "GL_OES_texture_float") != NULL) {
      TestFormat rgb32f = { GL_RGB, GL_FLOAT, 3 };
      test_formats[test_count++] = rgb32f;

      TestFormat rgba32f = { GL_RGBA, GL_FLOAT, 4 };
      test_formats[test_count++] = rgba32f;
  }

  const char *vs_source =
      "precision mediump float;\n"
      "attribute vec4 a_position;\n"
      "void main() {\n"
      "  gl_Position =  a_position;\n"
      "}\n";

  GLuint vertex_shader = CompileShader(GL_VERTEX_SHADER, vs_source);
  ASSERT_NE(vertex_shader, GLuint(0));

  const char *fs_source =
      "precision mediump float;\n"
      "uniform vec4 u_color;\n"
      "void main() {\n"
      "  gl_FragColor = u_color;\n"
      "}\n";

  GLuint fragment_shader = CompileShader(GL_FRAGMENT_SHADER, fs_source);
  ASSERT_NE(fragment_shader, GLuint(0));

  GLuint program = glCreateProgram();
  glAttachShader(program, vertex_shader);
  glDeleteShader(vertex_shader);
  glAttachShader(program, fragment_shader);
  glDeleteShader(fragment_shader);
  glLinkProgram(program);

  GLint link_status = 0;
  glGetProgramiv(program, GL_LINK_STATUS, &link_status);
  if (link_status != GL_TRUE) {
    glDeleteProgram(program);
    program = 0;
  }
  ASSERT_NE(program, GLuint(0));

  EXPECT_EQ(glGetError(), GLenum(GL_NO_ERROR));

  float quad_vertices[] = {
      -1.0, -1.0,
      1.0, -1.0,
      1.0, 1.0,
      -1.0, 1.0
  };

  GLuint vertex_buffer;
  glGenBuffers(1, &vertex_buffer);
  glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
  glBufferData(
      GL_ARRAY_BUFFER, sizeof(quad_vertices),
      reinterpret_cast<void*>(quad_vertices), GL_STATIC_DRAW);

  GLint position_location = glGetAttribLocation(program, "a_position");
  glVertexAttribPointer(
      position_location, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), NULL);
  glEnableVertexAttribArray(position_location);

  glUseProgram(program);
  glUniform4fv(glGetUniformLocation(program, "u_color"), 1, kDrawColor);

  EXPECT_EQ(glGetError(), GLenum(GL_NO_ERROR));

  for (size_t ii = 0; ii < test_count; ++ii) {
    GLuint texture_id = 0;
    glGenTextures(1, &texture_id);
    glBindTexture(GL_TEXTURE_2D, texture_id);
    glTexImage2D(
        GL_TEXTURE_2D, 0, test_formats[ii].format, kTextureSize, kTextureSize,
        0, test_formats[ii].format, test_formats[ii].type, NULL);

    GLuint framebuffer = 0;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(
        GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture_id, 0);

    EXPECT_EQ(glGetError(), GLenum(GL_NO_ERROR));

    // Make sure this floating point framebuffer is supported
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE) {
      // Check if this implementation supports reading floats back from this
      // framebuffer
      GLint read_format = 0;
      glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_FORMAT, &read_format);
      GLint read_type = 0;
      glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_TYPE, &read_type);

      EXPECT_EQ(glGetError(), GLenum(GL_NO_ERROR));

      if ((read_format == GL_RGB || read_format == GL_RGBA) &&
          read_type == test_formats[ii].type) {
        glClear(GL_COLOR_BUFFER_BIT);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

        uint32 read_comp_count = 0;
        switch (read_format) {
          case GL_RGB:
            read_comp_count = 3;
            break;
          case GL_RGBA:
            read_comp_count = 4;
            break;
        }

        switch (read_type) {
          case GL_HALF_FLOAT_OES: {
            scoped_ptr<GLushort[]> buf(
                new GLushort[kTextureSize * kTextureSize * read_comp_count]);
            glReadPixels(
                0, 0, kTextureSize, kTextureSize, read_format, read_type,
                buf.get());
            EXPECT_EQ(glGetError(), GLenum(GL_NO_ERROR));
            for (uint32 jj = 0; jj < kTextureSize * kTextureSize; ++jj) {
              for (uint32 kk = 0; kk < test_formats[ii].comp_count; ++kk) {
                EXPECT_LE(
                    std::abs(HalfToFloat32(buf[jj * read_comp_count + kk]) -
                        kDrawColor[kk]),
                    std::abs(kDrawColor[kk] * kEpsilon));
              }
            }
            break;
          }
          case GL_FLOAT: {
            scoped_ptr<GLfloat[]> buf(
                new GLfloat[kTextureSize * kTextureSize * read_comp_count]);
            glReadPixels(
                0, 0, kTextureSize, kTextureSize, read_format, read_type,
                buf.get());
            EXPECT_EQ(glGetError(), GLenum(GL_NO_ERROR));
            for (uint32 jj = 0; jj < kTextureSize * kTextureSize; ++jj) {
              for (uint32 kk = 0; kk < test_formats[ii].comp_count; ++kk) {
                EXPECT_LE(
                    std::abs(buf[jj * read_comp_count + kk] - kDrawColor[kk]),
                    std::abs(kDrawColor[kk] * kEpsilon));
              }
            }
            break;
          }
        }
      }
    }

    glDeleteFramebuffers(1, &framebuffer);
    glDeleteTextures(1, &texture_id);
  }

  glDeleteBuffers(1, &vertex_buffer);
  glDeleteProgram(program);
}

}  // namespace gpu
