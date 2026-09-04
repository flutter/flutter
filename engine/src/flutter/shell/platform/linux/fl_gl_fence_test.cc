// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_gl_fence.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"

class FlGLFenceTest : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override { opengl_manager = fl_opengl_manager_new(); }

  ~FlGLFenceTest() override { g_clear_object(&opengl_manager); }

  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  FlOpenGLManager* opengl_manager = nullptr;
};

// A fence is created in the current context, and the commands are flushed so
// that it can actually be reached.
TEST_F(FlGLFenceTest, New) {
  EXPECT_CALL(epoxy,
              eglCreateSyncKHR(::testing::_, EGL_SYNC_FENCE_KHR, ::testing::_));

  g_autoptr(FlGLFence) fence = fl_gl_fence_new(opengl_manager);
  EXPECT_NE(fence, nullptr);
}

// Drivers without fence support are reported so the caller can fall back to
// another form of synchronization.
// A driver that fails to create a fence still returns an object, which is safe
// to wait on and does nothing.
TEST_F(FlGLFenceTest, NewFails) {
  EXPECT_CALL(epoxy, eglCreateSyncKHR)
      .WillOnce(::testing::Return(EGL_NO_SYNC_KHR));

  g_autoptr(FlGLFence) fence = fl_gl_fence_new(opengl_manager);
  ASSERT_NE(fence, nullptr);

  EXPECT_CALL(epoxy, eglClientWaitSyncKHR).Times(0);
  EXPECT_CALL(epoxy, eglWaitSyncKHR).Times(0);
  fl_gl_fence_wait(fence);
}

// OpenGL can do the waiting, which doesn't block the calling thread.
TEST_F(FlGLFenceTest, Wait) {
  g_autoptr(FlGLFence) fence = fl_gl_fence_new(opengl_manager);
  ASSERT_NE(fence, nullptr);

  EXPECT_CALL(epoxy, eglWaitSyncKHR(::testing::_, ::testing::_, 0))
      .WillOnce(::testing::Return(EGL_TRUE));
  EXPECT_CALL(epoxy, eglClientWaitSyncKHR).Times(0);

  fl_gl_fence_wait(fence);
}

// Drivers that can create fences but can't wait on them without blocking fall
// back to blocking, which is slower but still correct.
TEST_F(FlGLFenceTest, WaitUnsupported) {
  EXPECT_CALL(epoxy, epoxy_has_egl_extension(
                         ::testing::_, ::testing::StrEq("EGL_KHR_wait_sync")))
      .WillRepeatedly(::testing::Return(false));

  g_autoptr(FlGLFence) fence = fl_gl_fence_new(opengl_manager);
  ASSERT_NE(fence, nullptr);

  EXPECT_CALL(epoxy, eglWaitSyncKHR).Times(0);
  EXPECT_CALL(epoxy, eglClientWaitSyncKHR)
      .WillOnce(::testing::Return(EGL_CONDITION_SATISFIED_KHR));

  fl_gl_fence_wait(fence);
}

// The fence is destroyed with the display it was created on, so it doesn't
// depend on a context being current when it is freed.
TEST_F(FlGLFenceTest, Destroy) {
  FlGLFence* fence = fl_gl_fence_new(opengl_manager);
  ASSERT_NE(fence, nullptr);

  EXPECT_CALL(epoxy, eglDestroySyncKHR).WillOnce(::testing::Return(EGL_TRUE));

  g_object_unref(fence);
}
