// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

#include "base/logging.h"
#include "gpu/command_buffer/service/feature_info.h"
#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class GLLoseContextTest : public testing::Test {
 protected:
  void SetUp() override {
    GLManager::Options options;
    gl2_.Initialize(options);
    options.context_lost_allowed = true;
    gl1a_.Initialize(options);
    options.share_group_manager = &gl1a_;
    gl1b_.Initialize(options);
  }

  void TearDown() override {
    gl1a_.Destroy();
    gl1b_.Destroy();
    gl2_.Destroy();
  }

  GLManager gl1a_;
  GLManager gl1b_;
  GLManager gl2_;
};

// Test that glLoseContextCHROMIUM loses context in the same
// share group but not other.
TEST_F(GLLoseContextTest, ShareGroup) {
  // If losing the context will cause the process to exit, do not perform this
  // test as it will cause all subsequent tests to not run.
  if (gl1a_.workarounds().exit_on_context_lost)
    return;

  gl1a_.MakeCurrent();
  glLoseContextCHROMIUM(
      GL_GUILTY_CONTEXT_RESET_EXT, GL_INNOCENT_CONTEXT_RESET_EXT);

  uint8 expected_no_draw[] = {
    GLTestHelper::kCheckClearValue,
    GLTestHelper::kCheckClearValue,
    GLTestHelper::kCheckClearValue,
    GLTestHelper::kCheckClearValue,
  };
  // Expect the read will fail.
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, 1, 1, 0, expected_no_draw));
  gl1b_.MakeCurrent();
  // Expect the read will fail.
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, 1, 1, 0, expected_no_draw));
  gl2_.MakeCurrent();
  uint8 expected_draw[] = { 0, 0, 0, 0, };
  // Expect the read will succeed.
  EXPECT_TRUE(GLTestHelper::CheckPixels(0, 0, 1, 1, 0, expected_draw));
}

}  // namespace gpu

