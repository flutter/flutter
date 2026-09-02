// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"

class FlFramebufferTest : public flutter::testing::LinuxTest {
 protected:
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
};

TEST_F(FlFramebufferTest, NoDepthStencil) {
  // Presentation framebuffers are only ever copied into, so they don't need
  // a depth/stencil buffer and shouldn't allocate the memory for one.
  EXPECT_CALL(epoxy, glGenRenderbuffers).Times(0);
  EXPECT_CALL(epoxy, glRenderbufferStorage).Times(0);
  EXPECT_CALL(epoxy,
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                        ::testing::_, ::testing::_))
      .Times(0);
  EXPECT_CALL(epoxy,
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                                        ::testing::_, ::testing::_))
      .Times(0);

  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, 100, 100, FALSE);
}

TEST_F(FlFramebufferTest, MultisampleHasDepthStencil) {
  // Framebuffers rendered into by the engine still require a depth/stencil
  // buffer.
  ON_CALL(epoxy, epoxy_has_gl_extension(::testing::_))
      .WillByDefault(::testing::Return(false));

  EXPECT_CALL(epoxy, glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8,
                                           100, 100));
  EXPECT_CALL(epoxy,
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                        GL_RENDERBUFFER, ::testing::_));
  EXPECT_CALL(epoxy,
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                                        GL_RENDERBUFFER, ::testing::_));

  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new_multisample(GL_RGBA, 100, 100, /*use_msaa=*/FALSE);
}

TEST_F(FlFramebufferTest, ResourcesRemoved) {
  EXPECT_CALL(epoxy, glGenFramebuffers);
  EXPECT_CALL(epoxy, glGenTextures);
  FlFramebuffer* framebuffer = fl_framebuffer_new(GL_RGB, 100, 100, FALSE);

  EXPECT_CALL(epoxy, glDeleteFramebuffers);
  EXPECT_CALL(epoxy, glDeleteTextures);
  g_object_unref(framebuffer);
}

TEST_F(FlFramebufferTest, Sibling) {
  EXPECT_CALL(epoxy, eglCreateImageKHR);
  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, 100, 100, TRUE);
  g_autoptr(FlFramebuffer) sibling = fl_framebuffer_create_sibling(framebuffer);
}

TEST_F(FlFramebufferTest, ImpellerOffscreenMSAA) {
  ON_CALL(epoxy, epoxy_gl_version).WillByDefault(::testing::Return(30));
  ON_CALL(epoxy, epoxy_has_gl_extension(::testing::_))
      .WillByDefault(::testing::Return(false));
  ON_CALL(epoxy, glGetIntegerv(GL_MAX_SAMPLES, ::testing::_))
      .WillByDefault(::testing::SetArgPointee<1>(4));

  EXPECT_CALL(epoxy, glRenderbufferStorageMultisample(GL_RENDERBUFFER, 4,
                                                      GL_RGBA8, 100, 100));
  EXPECT_CALL(epoxy, glRenderbufferStorageMultisample(
                         GL_RENDERBUFFER, 4, GL_DEPTH24_STENCIL8, 100, 100));
  EXPECT_CALL(epoxy,
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                        GL_RENDERBUFFER, ::testing::_));
  EXPECT_CALL(epoxy,
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                        GL_RENDERBUFFER, ::testing::_));
  EXPECT_CALL(epoxy,
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                                        GL_RENDERBUFFER, ::testing::_));

  FlFramebuffer* framebuffer =
      fl_framebuffer_new_multisample(GL_RGBA, 100, 100, /*use_msaa=*/TRUE);
  EXPECT_EQ(fl_framebuffer_get_texture_id(framebuffer), 0u);

  EXPECT_CALL(epoxy, glDeleteFramebuffers);
  EXPECT_CALL(epoxy, glDeleteTextures).Times(0);
  EXPECT_CALL(epoxy, glDeleteRenderbuffers).Times(2);
  g_object_unref(framebuffer);
}

TEST_F(FlFramebufferTest, ImpellerImplicitMSAA) {
  ON_CALL(epoxy, epoxy_has_gl_extension(
                     ::testing::StrEq("GL_EXT_multisampled_render_to_texture")))
      .WillByDefault(::testing::Return(true));

  EXPECT_CALL(epoxy, glGenTextures);
  EXPECT_CALL(epoxy, glFramebufferTexture2DMultisampleEXT(
                         GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         ::testing::_, 0, 4));
  EXPECT_CALL(epoxy, glRenderbufferStorageMultisampleEXT(
                         GL_RENDERBUFFER, 4, GL_DEPTH24_STENCIL8, 100, 100));

  FlFramebuffer* framebuffer =
      fl_framebuffer_new_multisample(GL_RGBA, 100, 100, /*use_msaa=*/TRUE);

  EXPECT_CALL(epoxy, glDeleteFramebuffers);
  EXPECT_CALL(epoxy, glDeleteTextures);
  EXPECT_CALL(epoxy, glDeleteRenderbuffers);
  g_object_unref(framebuffer);
}

TEST_F(FlFramebufferTest, ImpellerNoMSAA) {
  ON_CALL(epoxy, epoxy_gl_version).WillByDefault(::testing::Return(20));
  ON_CALL(epoxy, epoxy_has_gl_extension(::testing::_))
      .WillByDefault(::testing::Return(false));

  EXPECT_CALL(epoxy, glGenTextures);
  EXPECT_CALL(epoxy,
              glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                     GL_TEXTURE_2D, ::testing::_, 0));
  EXPECT_CALL(epoxy, glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8,
                                           100, 100));

  FlFramebuffer* framebuffer =
      fl_framebuffer_new_multisample(GL_RGBA, 100, 100, /*use_msaa=*/TRUE);

  EXPECT_CALL(epoxy, glDeleteFramebuffers);
  EXPECT_CALL(epoxy, glDeleteTextures);
  EXPECT_CALL(epoxy, glDeleteRenderbuffers);
  g_object_unref(framebuffer);
}

TEST_F(FlFramebufferTest, SkiaNoMSAA) {
  ON_CALL(epoxy, epoxy_gl_version).WillByDefault(::testing::Return(30));
  ON_CALL(epoxy, glGetIntegerv(GL_MAX_SAMPLES, ::testing::_))
      .WillByDefault(::testing::SetArgPointee<1>(4));

  EXPECT_CALL(epoxy, glGenTextures);
  EXPECT_CALL(epoxy,
              glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                     GL_TEXTURE_2D, ::testing::_, 0));
  EXPECT_CALL(epoxy, glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8,
                                           100, 100));

  FlFramebuffer* framebuffer =
      fl_framebuffer_new_multisample(GL_RGBA, 100, 100, /*use_msaa=*/FALSE);

  EXPECT_CALL(epoxy, glDeleteFramebuffers);
  EXPECT_CALL(epoxy, glDeleteTextures);
  EXPECT_CALL(epoxy, glDeleteRenderbuffers);
  g_object_unref(framebuffer);
}

TEST_F(FlFramebufferTest, ImpellerOffscreenMSAABgra) {
  ON_CALL(epoxy, epoxy_gl_version).WillByDefault(::testing::Return(30));
  ON_CALL(epoxy, glGetIntegerv(GL_MAX_SAMPLES, ::testing::_))
      .WillByDefault(::testing::SetArgPointee<1>(4));

  EXPECT_CALL(epoxy, glGenRenderbuffers).Times(2);
  // GL_EXT_texture_format_BGRA8888 only defines BGRA for textures, not
  // renderbuffers. When explicit offscreen MSAA is used without
  // GL_EXT_multisampled_render_to_texture, a multisample renderbuffer is
  // created which must use GL_RGBA8.
  EXPECT_CALL(epoxy, glRenderbufferStorageMultisample(GL_RENDERBUFFER, 4,
                                                      GL_RGBA8, 100, 100));
  EXPECT_CALL(epoxy, glRenderbufferStorageMultisample(
                         GL_RENDERBUFFER, 4, GL_DEPTH24_STENCIL8, 100, 100));
  EXPECT_CALL(epoxy,
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                        GL_RENDERBUFFER, ::testing::_));
  EXPECT_CALL(epoxy,
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                        GL_RENDERBUFFER, ::testing::_));
  EXPECT_CALL(epoxy,
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                                        GL_RENDERBUFFER, ::testing::_));

  FlFramebuffer* framebuffer =
      fl_framebuffer_new_multisample(GL_BGRA_EXT, 100, 100, /*use_msaa=*/TRUE);
  EXPECT_EQ(fl_framebuffer_get_texture_id(framebuffer), 0u);

  EXPECT_CALL(epoxy, glDeleteFramebuffers);
  EXPECT_CALL(epoxy, glDeleteTextures).Times(0);
  EXPECT_CALL(epoxy, glDeleteRenderbuffers).Times(2);
  g_object_unref(framebuffer);
}

TEST_F(FlFramebufferTest, ImpellerImplicitMSAABgra) {
  ON_CALL(epoxy, epoxy_has_gl_extension(
                     ::testing::StrEq("GL_EXT_multisampled_render_to_texture")))
      .WillByDefault(::testing::Return(true));

  EXPECT_CALL(epoxy, glGenTextures);
  EXPECT_CALL(epoxy, glFramebufferTexture2DMultisampleEXT(
                         GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         ::testing::_, 0, 4));
  EXPECT_CALL(epoxy, glRenderbufferStorageMultisampleEXT(
                         GL_RENDERBUFFER, 4, GL_DEPTH24_STENCIL8, 100, 100));

  FlFramebuffer* framebuffer =
      fl_framebuffer_new_multisample(GL_BGRA_EXT, 100, 100, /*use_msaa=*/TRUE);

  EXPECT_CALL(epoxy, glDeleteFramebuffers);
  EXPECT_CALL(epoxy, glDeleteTextures);
  EXPECT_CALL(epoxy, glDeleteRenderbuffers);
  g_object_unref(framebuffer);
}
