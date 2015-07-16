// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include "base/logging.h"
#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class GLSharedResources : public testing::Test {
 protected:
  void SetUp() override {
    GLManager::Options options;
    options.bind_generates_resource = true;
    gl1_.Initialize(options);
    options.share_group_manager = &gl1_;
    gl2_.Initialize(options);
  }

  void TearDown() override {
    gl1_.Destroy();
    gl2_.Destroy();
  }

  GLManager gl1_;
  GLManager gl2_;
};

// Test that GL creating/deleting works across context.
TEST_F(GLSharedResources, CreateDelete) {
  gl1_.MakeCurrent();
  GLuint tex = 0;
  glGenTextures(1, &tex);
  gl2_.MakeCurrent();
  glBindTexture(GL_TEXTURE_2D, tex);
  glDeleteTextures(1, &tex);
  gl1_.MakeCurrent();
  glBindTexture(GL_TEXTURE_2D,tex);
  GLTestHelper::CheckGLError("no errors", __LINE__);
  gl2_.MakeCurrent();
  GLTestHelper::CheckGLError("no errors", __LINE__);
}

}  // namespace gpu

