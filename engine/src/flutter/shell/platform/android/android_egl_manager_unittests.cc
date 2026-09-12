// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_egl_manager.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

TEST(AndroidEGLManagerTest, InitialStateNotValid) {
  AndroidEGLManager manager;
  EXPECT_FALSE(manager.IsValid());
  EXPECT_EQ(manager.GetDisplay(), EGL_NO_DISPLAY);
  EXPECT_EQ(manager.GetContext(), EGL_NO_CONTEXT);
  EXPECT_EQ(manager.GetResourceContext(), EGL_NO_CONTEXT);
}

TEST(AndroidEGLManagerTest, InitializeAndLifecycle) {
  AndroidEGLManager manager;
  bool init_result = manager.Initialize();
  // On environments where EGL is supported, verify handles.
  if (init_result) {
    EXPECT_TRUE(manager.IsValid());
    EXPECT_NE(manager.GetDisplay(), EGL_NO_DISPLAY);
    EXPECT_NE(manager.GetContext(), EGL_NO_CONTEXT);
    EXPECT_NE(manager.GetResourceContext(), EGL_NO_CONTEXT);

    // Context binding tests.
    EXPECT_TRUE(manager.MakeCurrent());
    EXPECT_EQ(eglGetCurrentContext(), manager.GetContext());

    EXPECT_TRUE(manager.ClearCurrent());
    EXPECT_EQ(eglGetCurrentContext(), EGL_NO_CONTEXT);

    EXPECT_TRUE(manager.MakeResourceCurrent());
    EXPECT_EQ(eglGetCurrentContext(), manager.GetResourceContext());

    EXPECT_TRUE(manager.ClearCurrent());
    EXPECT_EQ(eglGetCurrentContext(), EGL_NO_CONTEXT);
  }
}

TEST(AndroidEGLManagerTest, SetNativeWindowNullSafe) {
  AndroidEGLManager manager;
  // Should handle nullptr safely without crashing.
  manager.SetNativeWindow(nullptr);
  EXPECT_FALSE(manager.IsValid());
}

TEST(AndroidEGLManagerTest, PresentWithoutSurfaceReturnsTrue) {
  AndroidEGLManager manager;
  // Present without initialization or window surface should return true safely.
  EXPECT_TRUE(manager.Present());
  if (manager.Initialize()) {
    EXPECT_TRUE(manager.Present());
    manager.SetNativeWindow(nullptr);
    EXPECT_TRUE(manager.Present());
  }
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
