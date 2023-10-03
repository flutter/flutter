// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"

namespace impeller {
namespace testing {

// This test just checks that the proc table is initialized correctly.
//
// If this test doesn't pass, no test that uses the proc table will pass.
TEST(MockGLES, CanInitialize) {
  auto mock_gles = MockGLES::Init();

  EXPECT_EQ(mock_gles->GetProcTable().GetString(GL_VENDOR),
            (unsigned char*)"MockGLES");
}

// Tests we can call two functions and capture the calls.
TEST(MockGLES, CapturesPushAndPopDebugGroup) {
  auto mock_gles = MockGLES::Init();

  auto& gl = mock_gles->GetProcTable();
  gl.PushDebugGroupKHR(GL_DEBUG_SOURCE_APPLICATION_KHR, 0, -1, "test");
  gl.PopDebugGroupKHR();

  auto calls = mock_gles->GetCapturedCalls();
  EXPECT_EQ(calls, std::vector<std::string>(
                       {"PushDebugGroupKHR", "PopDebugGroupKHR"}));
}

// Tests that if we call a function we have not mocked, it's OK.
TEST(MockGLES, CanCallUnmockedFunction) {
  auto mock_gles = MockGLES::Init();

  auto& gl = mock_gles->GetProcTable();
  gl.DeleteFramebuffers(1, nullptr);

  // Test should still complete.
  // If we end up mocking DeleteFramebuffers, delete this test.
}

}  // namespace testing
}  // namespace impeller
