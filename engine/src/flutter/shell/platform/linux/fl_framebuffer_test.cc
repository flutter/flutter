// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"

TEST(FlFramebufferTest, HasDepthStencil) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;

  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, 100, 100, FALSE);

  GLint depth_type = GL_NONE;
  glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                        GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
                                        &depth_type);
  EXPECT_NE(depth_type, GL_NONE);

  GLint stencil_type = GL_NONE;
  glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                                        GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
                                        &stencil_type);
  EXPECT_NE(stencil_type, GL_NONE);
}

TEST(FlFramebufferTest, ResourcesRemoved) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;

  EXPECT_CALL(epoxy, glGenFramebuffers);
  EXPECT_CALL(epoxy, glGenTextures);
  EXPECT_CALL(epoxy, glGenRenderbuffers);
  FlFramebuffer* framebuffer = fl_framebuffer_new(GL_RGB, 100, 100, FALSE);

  EXPECT_CALL(epoxy, glDeleteFramebuffers);
  EXPECT_CALL(epoxy, glDeleteTextures);
  EXPECT_CALL(epoxy, glDeleteRenderbuffers);
  g_object_unref(framebuffer);
}

TEST(FlFramebufferTest, Sibling) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;

  EXPECT_CALL(epoxy, eglCreateImageKHR);
  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, 100, 100, TRUE);
  g_autoptr(FlFramebuffer) sibling = fl_framebuffer_create_sibling(framebuffer);
}
