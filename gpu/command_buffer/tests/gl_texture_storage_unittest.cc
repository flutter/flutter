// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class TextureStorageTest : public testing::Test {
 protected:
  static const GLsizei kResolution = 64;
  void SetUp() override {
    GLManager::Options options;
    options.size = gfx::Size(kResolution, kResolution);
    gl_.Initialize(options);
    gl_.MakeCurrent();

    glGenTextures(1, &tex_);
    glBindTexture(GL_TEXTURE_2D, tex_);

    glGenFramebuffers(1, &fbo_);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo_);
    glFramebufferTexture2D(GL_FRAMEBUFFER,
                           GL_COLOR_ATTACHMENT0,
                           GL_TEXTURE_2D,
                           tex_,
                           0);

    const GLubyte* extensions = glGetString(GL_EXTENSIONS);
    extension_available_ = strstr(reinterpret_cast<const char*>(
        extensions), "GL_EXT_texture_storage");
  }

  void TearDown() override { gl_.Destroy(); }

  GLManager gl_;
  GLuint tex_;
  GLuint fbo_;
  bool extension_available_;
};

TEST_F(TextureStorageTest, CorrectPixels) {
  if (!extension_available_)
    return;

  glTexStorage2DEXT(GL_TEXTURE_2D, 2, GL_RGBA8_OES, 2, 2);

  uint8 source_pixels[16] = {
      1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4
  };
  glTexSubImage2D(GL_TEXTURE_2D,
                  0,
                  0, 0,
                  2, 2,
                  GL_RGBA, GL_UNSIGNED_BYTE,
                  source_pixels);
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, 2, 2, 0, source_pixels));
}

TEST_F(TextureStorageTest, IsImmutable) {
  if (!extension_available_)
    return;

  glTexStorage2DEXT(GL_TEXTURE_2D, 1, GL_RGBA8_OES, 4, 4);

  GLint param = 0;
  glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_IMMUTABLE_FORMAT_EXT, &param);
  EXPECT_TRUE(param);
}

TEST_F(TextureStorageTest, OneLevel) {
  if (!extension_available_)
    return;

  glTexStorage2DEXT(GL_TEXTURE_2D, 1, GL_RGBA8_OES, 4, 4);

  uint8 source_pixels[64] = { 0 };

  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 4, 4,
                  GL_RGBA, GL_UNSIGNED_BYTE, source_pixels);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glTexSubImage2D(GL_TEXTURE_2D, 1, 0, 0, 2, 2,
                  GL_RGBA, GL_UNSIGNED_BYTE, source_pixels);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), glGetError());
}

TEST_F(TextureStorageTest, MultipleLevels) {
  if (!extension_available_)
    return;

  glTexStorage2DEXT(GL_TEXTURE_2D, 2, GL_RGBA8_OES, 2, 2);

  uint8 source_pixels[16] = { 0 };

  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 2, 2,
                  GL_RGBA, GL_UNSIGNED_BYTE, source_pixels);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glTexSubImage2D(GL_TEXTURE_2D, 1, 0, 0, 1, 1,
                  GL_RGBA, GL_UNSIGNED_BYTE, source_pixels);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glTexSubImage2D(GL_TEXTURE_2D, 2, 0, 0, 1, 1,
                  GL_RGBA, GL_UNSIGNED_BYTE, source_pixels);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), glGetError());
}

TEST_F(TextureStorageTest, BadTarget) {
  if (!extension_available_)
    return;

  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glTexStorage2DEXT(GL_TEXTURE_CUBE_MAP, 1, GL_RGBA8_OES, 4, 4);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_ENUM), glGetError());
}

TEST_F(TextureStorageTest, InvalidId) {
  if (!extension_available_)
    return;

  glDeleteTextures(1, &tex_);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glTexStorage2DEXT(GL_TEXTURE_2D, 1, GL_RGBA8_OES, 4, 4);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), glGetError());
}

TEST_F(TextureStorageTest, CannotRedefine) {
  if (!extension_available_)
    return;

  glTexStorage2DEXT(GL_TEXTURE_2D, 1, GL_RGBA8_OES, 4, 4);

  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glTexStorage2DEXT(GL_TEXTURE_2D, 1, GL_RGBA8_OES, 4, 4);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), glGetError());

  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               4, 4,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               NULL);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), glGetError());
}

}  // namespace gpu



