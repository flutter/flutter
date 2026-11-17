// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_egl_image.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"

TEST(FlEGLImageTest, Test) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;

  EXPECT_CALL(epoxy, eglCreateImageKHR(testing::_, testing::_, testing::_,
                                       testing::_, testing::_))
      .Times(1);
  EXPECT_CALL(epoxy, eglDestroyImageKHR(testing::_, testing::_)).Times(1);

  GLuint texture_id = 99;
  g_autoptr(FlEGLImage) image = fl_egl_image_new(texture_id);
  EXPECT_NE(fl_egl_image_get_image(image), EGL_NO_IMAGE_KHR);
}
