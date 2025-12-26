// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <optional>

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"

namespace impeller {
namespace testing {

#define EXPECT_AVAILABLE(proc_ivar) \
  EXPECT_TRUE(mock_gles->GetProcTable().proc_ivar.IsAvailable());
#define EXPECT_UNAVAILABLE(proc_ivar) \
  EXPECT_FALSE(mock_gles->GetProcTable().proc_ivar.IsAvailable());

TEST(ProcTableGLES, ResolvesCorrectClearDepthProcOnES) {
  auto mock_gles = MockGLES::Init(std::nullopt, "OpenGL ES 3.0");
  EXPECT_TRUE(mock_gles->GetProcTable().GetDescription()->IsES());

  FOR_EACH_IMPELLER_ES_ONLY_PROC(EXPECT_AVAILABLE);
  FOR_EACH_IMPELLER_DESKTOP_ONLY_PROC(EXPECT_UNAVAILABLE);
}

TEST(ProcTableGLES, ResolvesCorrectClearDepthProcOnDesktopGL) {
  auto mock_gles = MockGLES::Init(std::nullopt, "OpenGL 4.0");
  EXPECT_FALSE(mock_gles->GetProcTable().GetDescription()->IsES());

  FOR_EACH_IMPELLER_DESKTOP_ONLY_PROC(EXPECT_AVAILABLE);
  FOR_EACH_IMPELLER_ES_ONLY_PROC(EXPECT_UNAVAILABLE);
}

TEST(GLErrorToString, ReturnsCorrectStringForKnownErrors) {
  EXPECT_EQ(GLErrorToString(GL_NO_ERROR), "GL_NO_ERROR");
  EXPECT_EQ(GLErrorToString(GL_INVALID_ENUM), "GL_INVALID_ENUM");
  EXPECT_EQ(GLErrorToString(GL_INVALID_VALUE), "GL_INVALID_VALUE");
  EXPECT_EQ(GLErrorToString(GL_INVALID_OPERATION), "GL_INVALID_OPERATION");
  EXPECT_EQ(GLErrorToString(GL_INVALID_FRAMEBUFFER_OPERATION),
            "GL_INVALID_FRAMEBUFFER_OPERATION");
  EXPECT_EQ(GLErrorToString(GL_FRAMEBUFFER_COMPLETE),
            "GL_FRAMEBUFFER_COMPLETE");
  EXPECT_EQ(GLErrorToString(GL_OUT_OF_MEMORY), "GL_OUT_OF_MEMORY");
}

TEST(GLErrorToString, ReturnsUnknownForInvalidError) {
  // Test with an invalid error code
  GLenum invalid_error = 0x9999;
  EXPECT_EQ(GLErrorToString(invalid_error), "Unknown.");
}

TEST(GLErrorToString, ReturnValueIsValidStringView) {
  // Test that the returned string_view is valid and non-empty
  auto result = GLErrorToString(GL_NO_ERROR);
  EXPECT_FALSE(result.empty());
  EXPECT_NE(result.data(), nullptr);

  // Test that we can compare with string literals
  EXPECT_TRUE(result == "GL_NO_ERROR");
}

TEST(GLProc, NameFieldWorksWithStringView) {
  GLProc<void()> proc;

  // Test setting name with string literal
  const char* literal = "glTestFunction";
  proc.name = literal;

  EXPECT_EQ(proc.name, "glTestFunction");
  EXPECT_FALSE(proc.name.empty());

  // Test that the string_view properly references the original data
  EXPECT_EQ(proc.name.data(), literal);
}

}  // namespace testing
}  // namespace impeller
