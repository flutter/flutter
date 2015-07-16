// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include <android/native_window_jni.h>

#include "base/bind.h"
#include "base/logging.h"
#include "base/synchronization/waitable_event.h"
#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/native_widget_types.h"
#include "ui/gl/android/surface_texture.h"
#include "ui/gl/gl_surface.h"

namespace gpu {

class GLSurfaceTextureTest : public testing::Test {
 protected:
  void SetUp() override { gl_.Initialize(GLManager::Options()); }

  void TearDown() override { gl_.Destroy(); }

  GLManager gl_;
};

TEST_F(GLSurfaceTextureTest, SimpleTest) {
  // TODO(sievers): Eliminate the need for this by using a client-side
  // abstraction for the SurfaceTexture in this test.
  GLuint texture = 0xFEEDBEEF;

  scoped_refptr<gfx::SurfaceTexture> surface_texture(
      gfx::SurfaceTexture::Create(texture));
  gfx::AcceleratedWidget window = surface_texture->CreateSurface();
  EXPECT_TRUE(window != NULL);

  scoped_refptr<gfx::GLSurface> gl_surface =
      gfx::GLSurface::CreateViewGLSurface(window);
  EXPECT_TRUE(gl_surface.get() != NULL);

  gl_.SetSurface(gl_surface.get());

  glClearColor(0.0f, 1.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
//  glSwapBuffers();

  surface_texture->UpdateTexImage();

  GLTestHelper::CheckGLError("no errors", __LINE__);

  ANativeWindow_release(window);
}

}  // namespace gpu

