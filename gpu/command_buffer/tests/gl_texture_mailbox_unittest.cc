// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

#include "gpu/command_buffer/client/gles2_lib.h"
#include "gpu/command_buffer/common/mailbox.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/mailbox_manager.h"
#include "gpu/command_buffer/tests/gl_manager.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_share_group.h"

namespace gpu {

namespace {
uint32 ReadTexel(GLuint id, GLint x, GLint y) {
  GLint old_fbo = 0;
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &old_fbo);

  GLuint fbo;
  glGenFramebuffers(1, &fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         id,
                         0);
  // Some drivers (NVidia/SGX) require texture settings to be a certain way or
  // they won't report FRAMEBUFFER_COMPLETE.
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

  EXPECT_EQ(static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE),
            glCheckFramebufferStatus(GL_FRAMEBUFFER));

  uint32 texel = 0;
  glReadPixels(x, y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, &texel);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());

  glBindFramebuffer(GL_FRAMEBUFFER, old_fbo);

  glDeleteFramebuffers(1, &fbo);

  return texel;
}
}

class GLTextureMailboxTest : public testing::Test {
 protected:
  void SetUp() override {
    gl1_.Initialize(GLManager::Options());
    GLManager::Options options;
    options.share_mailbox_manager = &gl1_;
    gl2_.Initialize(options);
  }

  void TearDown() override {
    gl1_.Destroy();
    gl2_.Destroy();
  }

  GLManager gl1_;
  GLManager gl2_;
};

TEST_F(GLTextureMailboxTest, ProduceAndConsumeTexture) {
  gl1_.MakeCurrent();

  GLbyte mailbox1[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(mailbox1);

  GLbyte mailbox2[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(mailbox2);

  GLuint tex1;
  glGenTextures(1, &tex1);

  glBindTexture(GL_TEXTURE_2D, tex1);
  uint32 source_pixel = 0xFF0000FF;
  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               1, 1,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               &source_pixel);

  glProduceTextureCHROMIUM(GL_TEXTURE_2D, mailbox1);
  glFlush();

  gl2_.MakeCurrent();

  GLuint tex2;
  glGenTextures(1, &tex2);

  glBindTexture(GL_TEXTURE_2D, tex2);
  glConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox1);
  EXPECT_EQ(source_pixel, ReadTexel(tex2, 0, 0));
  glProduceTextureCHROMIUM(GL_TEXTURE_2D, mailbox2);
  glFlush();

  gl1_.MakeCurrent();

  glBindTexture(GL_TEXTURE_2D, tex1);
  glConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox2);
  EXPECT_EQ(source_pixel, ReadTexel(tex1, 0, 0));
}

TEST_F(GLTextureMailboxTest, ProduceAndConsumeTextureRGB) {
  gl1_.MakeCurrent();

  GLbyte mailbox1[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(mailbox1);

  GLbyte mailbox2[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(mailbox2);

  GLuint tex1;
  glGenTextures(1, &tex1);

  glBindTexture(GL_TEXTURE_2D, tex1);
  uint32 source_pixel = 0xFF000000;
  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGB,
               1, 1,
               0,
               GL_RGB,
               GL_UNSIGNED_BYTE,
               &source_pixel);

  glProduceTextureCHROMIUM(GL_TEXTURE_2D, mailbox1);
  glFlush();

  gl2_.MakeCurrent();

  GLuint tex2;
  glGenTextures(1, &tex2);

  glBindTexture(GL_TEXTURE_2D, tex2);
  glConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox1);
  EXPECT_EQ(source_pixel, ReadTexel(tex2, 0, 0));
  glProduceTextureCHROMIUM(GL_TEXTURE_2D, mailbox2);
  glFlush();

  gl1_.MakeCurrent();

  glBindTexture(GL_TEXTURE_2D, tex1);
  glConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox2);
  EXPECT_EQ(source_pixel, ReadTexel(tex1, 0, 0));
}

TEST_F(GLTextureMailboxTest, ProduceAndConsumeTextureDirect) {
  gl1_.MakeCurrent();

  GLbyte mailbox1[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(mailbox1);

  GLbyte mailbox2[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(mailbox2);

  GLuint tex1;
  glGenTextures(1, &tex1);

  glBindTexture(GL_TEXTURE_2D, tex1);
  uint32 source_pixel = 0xFF0000FF;
  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               1, 1,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               &source_pixel);

  glProduceTextureDirectCHROMIUM(tex1, GL_TEXTURE_2D, mailbox1);
  glFlush();

  gl2_.MakeCurrent();

  GLuint tex2 = glCreateAndConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox1);
  glBindTexture(GL_TEXTURE_2D, tex2);
  EXPECT_EQ(source_pixel, ReadTexel(tex2, 0, 0));
  glProduceTextureDirectCHROMIUM(tex2, GL_TEXTURE_2D, mailbox2);
  glFlush();

  gl1_.MakeCurrent();

  GLuint tex3 = glCreateAndConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox2);
  glBindTexture(GL_TEXTURE_2D, tex3);
  EXPECT_EQ(source_pixel, ReadTexel(tex3, 0, 0));
}

TEST_F(GLTextureMailboxTest, ConsumeTextureValidatesKey) {
  GLuint tex;
  glGenTextures(1, &tex);

  glBindTexture(GL_TEXTURE_2D, tex);
  uint32 source_pixel = 0xFF0000FF;
  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               1, 1,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               &source_pixel);

  GLbyte invalid_mailbox[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(invalid_mailbox);

  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glConsumeTextureCHROMIUM(GL_TEXTURE_2D, invalid_mailbox);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), glGetError());

  // Ensure level 0 is still intact after glConsumeTextureCHROMIUM fails.
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  EXPECT_EQ(source_pixel, ReadTexel(tex, 0, 0));
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
}

TEST_F(GLTextureMailboxTest, SharedTextures) {
  gl1_.MakeCurrent();
  GLuint tex1;
  glGenTextures(1, &tex1);

  glBindTexture(GL_TEXTURE_2D, tex1);
  uint32 source_pixel = 0xFF0000FF;
  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               1, 1,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               &source_pixel);
  GLbyte mailbox[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(mailbox);

  glProduceTextureCHROMIUM(GL_TEXTURE_2D, mailbox);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glFlush();

  gl2_.MakeCurrent();
  GLuint tex2;
  glGenTextures(1, &tex2);

  glBindTexture(GL_TEXTURE_2D, tex2);
  glConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());

  // Change texture in context 2.
  source_pixel = 0xFF00FF00;
  glTexSubImage2D(GL_TEXTURE_2D,
                  0,
                  0, 0,
                  1, 1,
                  GL_RGBA,
                  GL_UNSIGNED_BYTE,
                  &source_pixel);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glFlush();

  // Check it in context 1.
  gl1_.MakeCurrent();
  EXPECT_EQ(source_pixel, ReadTexel(tex1, 0, 0));
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());

  // Change parameters (note: ReadTexel will reset those).
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                  GL_LINEAR_MIPMAP_NEAREST);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glFlush();

  // Check in context 2.
  gl2_.MakeCurrent();
  GLint parameter = 0;
  glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, &parameter);
  EXPECT_EQ(GL_REPEAT, parameter);
  parameter = 0;
  glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, &parameter);
  EXPECT_EQ(GL_LINEAR, parameter);
  parameter = 0;
  glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, &parameter);
  EXPECT_EQ(GL_LINEAR_MIPMAP_NEAREST, parameter);

  // Delete texture in context 1.
  gl1_.MakeCurrent();
  glDeleteTextures(1, &tex1);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());

  // Check texture still exists in context 2.
  gl2_.MakeCurrent();
  EXPECT_EQ(source_pixel, ReadTexel(tex2, 0, 0));
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());

  // The mailbox should still exist too.
  GLuint tex3;
  glGenTextures(1, &tex3);
  glBindTexture(GL_TEXTURE_2D, tex3);
  glConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());

  // Delete both textures.
  glDeleteTextures(1, &tex2);
  glDeleteTextures(1, &tex3);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());

  // Mailbox should be gone now.
  glGenTextures(1, &tex2);
  glBindTexture(GL_TEXTURE_2D, tex2);
  glConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), glGetError());
  glDeleteTextures(1, &tex2);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
}

TEST_F(GLTextureMailboxTest, ProduceFrontBuffer) {
  gl1_.MakeCurrent();
  Mailbox mailbox;
  glGenMailboxCHROMIUM(mailbox.name);

  gl2_.MakeCurrent();
  gl2_.decoder()->ProduceFrontBuffer(mailbox);

  gl1_.MakeCurrent();
  GLuint tex1;
  glGenTextures(1, &tex1);
  glBindTexture(GL_TEXTURE_2D, tex1);
  glConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox.name);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());

  gl2_.MakeCurrent();
  glResizeCHROMIUM(10, 10, 1);
  glClearColor(1, 0, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  ::gles2::GetGLContext()->SwapBuffers();

  gl1_.MakeCurrent();
  EXPECT_EQ(0xFF0000FFu, ReadTexel(tex1, 0, 0));
  EXPECT_EQ(0xFF0000FFu, ReadTexel(tex1, 9, 9));
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());

  gl2_.MakeCurrent();
  glClearColor(0, 1, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  glFlush();

  gl1_.MakeCurrent();
  EXPECT_EQ(0xFF0000FFu, ReadTexel(tex1, 0, 0));

  gl2_.MakeCurrent();
  ::gles2::GetGLContext()->SwapBuffers();

  gl1_.MakeCurrent();
  EXPECT_EQ(0xFF00FF00u, ReadTexel(tex1, 0, 0));

  gl2_.MakeCurrent();
  gl2_.Destroy();

  gl1_.MakeCurrent();
  EXPECT_EQ(0xFF00FF00u, ReadTexel(tex1, 0, 0));
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  glDeleteTextures(1, &tex1);
}

TEST_F(GLTextureMailboxTest, ProduceTextureDirectInvalidTarget) {
  gl1_.MakeCurrent();

  GLbyte mailbox1[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(mailbox1);

  GLuint tex1;
  glGenTextures(1, &tex1);

  glBindTexture(GL_TEXTURE_CUBE_MAP, tex1);
  uint32 source_pixel = 0xFF0000FF;
  glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X,
               0,
               GL_RGBA,
               1, 1,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               &source_pixel);

  glProduceTextureDirectCHROMIUM(tex1, GL_TEXTURE_2D, mailbox1);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), glGetError());
}

// http://crbug.com/281565
#if !defined(OS_ANDROID)
TEST_F(GLTextureMailboxTest, ProduceFrontBufferMultipleContexts) {
  gl1_.MakeCurrent();
  Mailbox mailbox[2];
  glGenMailboxCHROMIUM(mailbox[0].name);
  glGenMailboxCHROMIUM(mailbox[1].name);
  GLuint tex[2];
  glGenTextures(2, tex);

  GLManager::Options options;
  options.share_mailbox_manager = &gl1_;
  GLManager other_gl[2];
  for (size_t i = 0; i < 2; ++i) {
    other_gl[i].Initialize(options);
    other_gl[i].MakeCurrent();
    other_gl[i].decoder()->ProduceFrontBuffer(mailbox[i]);
    // Make sure both "other gl" are in the same share group.
    if (!options.share_group_manager)
      options.share_group_manager = other_gl+i;
  }


  gl1_.MakeCurrent();
  for (size_t i = 0; i < 2; ++i) {
    glBindTexture(GL_TEXTURE_2D, tex[i]);
    glConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox[i].name);
    EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  }

  for (size_t i = 0; i < 2; ++i) {
    other_gl[i].MakeCurrent();
    glResizeCHROMIUM(10, 10, 1);
    glClearColor(1-i%2, i%2, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    ::gles2::GetGLContext()->SwapBuffers();
  }

  gl1_.MakeCurrent();
  EXPECT_EQ(0xFF0000FFu, ReadTexel(tex[0], 0, 0));
  EXPECT_EQ(0xFF00FF00u, ReadTexel(tex[1], 9, 9));

  for (size_t i = 0; i < 2; ++i) {
    other_gl[i].MakeCurrent();
    other_gl[i].Destroy();
  }

  gl1_.MakeCurrent();
  glDeleteTextures(2, tex);
}
#endif

}  // namespace gpu

