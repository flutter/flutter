// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gmock/gmock.h"

#include "flutter/shell/platform/linux/fl_compositor_opengl_private.h"

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"
#include "flutter/testing/testing.h"

namespace {

class FlCompositorOpenGLGtk4Test : public flutter::testing::LinuxTest {
 protected:
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
};

TEST_F(FlCompositorOpenGLGtk4Test, SharedGLTextureFallbackUsesFence) {
  g_autoptr(FlCompositorOpenGL) compositor = FL_COMPOSITOR_OPENGL(
      g_object_new(fl_compositor_opengl_get_type(), nullptr));
  compositor->shareable = TRUE;
  // Force the direct GdkGLTexture fallback independently of the test process
  // environment and of GTK's DMA-BUF support.
  compositor->dmabuf_disabled = TRUE;

  EXPECT_CALL(epoxy,
              eglCreateSyncKHR(::testing::_, EGL_SYNC_FENCE_KHR, ::testing::_));
  EXPECT_CALL(epoxy, glFinish()).Times(0);

  fl_compositor_opengl_gtk4_finish_present(compositor, GL_RGBA, 1, 1);
}

TEST_F(FlCompositorOpenGLGtk4Test,
       SharedGLTextureFallbackWithoutFencesCompletesFrame) {
  g_autoptr(FlCompositorOpenGL) compositor = FL_COMPOSITOR_OPENGL(
      g_object_new(fl_compositor_opengl_get_type(), nullptr));
  compositor->shareable = TRUE;
  compositor->dmabuf_disabled = TRUE;

  EXPECT_CALL(epoxy, epoxy_has_egl_extension(::testing::_, ::testing::_))
      .WillRepeatedly(::testing::Return(false));
  EXPECT_CALL(epoxy, eglCreateSyncKHR).Times(0);
  EXPECT_CALL(epoxy, glFinish());

  fl_compositor_opengl_gtk4_finish_present(compositor, GL_RGBA, 1, 1);
}

TEST_F(FlCompositorOpenGLGtk4Test, ReadbackDoesNotSynchronizeTwice) {
  g_autoptr(FlCompositorOpenGL) compositor = FL_COMPOSITOR_OPENGL(
      g_object_new(fl_compositor_opengl_get_type(), nullptr));
  compositor->shareable = FALSE;

  EXPECT_CALL(epoxy, glFinish()).Times(0);

  fl_compositor_opengl_gtk4_finish_present(compositor, GL_RGBA, 1, 1);
}

}  // namespace
