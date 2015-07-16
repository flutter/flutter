// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>
#include <cmath>

#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class CHROMIUMPathRenderingTest : public testing::Test {
 public:
  static const GLsizei kResolution = 100;

 protected:
  void SetUp() override {
    GLManager::Options options;
    options.size = gfx::Size(kResolution, kResolution);
    gl_.Initialize(options);
  }

  void TearDown() override { gl_.Destroy(); }

  void ExpectEqualMatrix(const GLfloat* expected, const GLfloat* actual) {
    for (size_t i = 0; i < 16; ++i) {
      EXPECT_EQ(expected[i], actual[i]);
    }
  }
  void ExpectEqualMatrix(const GLfloat* expected, const GLint* actual) {
    for (size_t i = 0; i < 16; ++i) {
      EXPECT_EQ(static_cast<GLint>(round(expected[i])), actual[i]);
    }
  }
  GLManager gl_;
};

TEST_F(CHROMIUMPathRenderingTest, TestMatrix) {
  if (!GLTestHelper::HasExtension("GL_CHROMIUM_path_rendering")) {
    return;
  }
  static const GLfloat kIdentityMatrix[16] = {
      1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f};
  static const GLfloat kSeqMatrix[16] = {
      0.5f, -0.5f, -0.1f,  -0.8f,  4.4f,   5.5f,   6.6f,   7.7f,
      8.8f, 9.9f,  10.11f, 11.22f, 12.33f, 13.44f, 14.55f, 15.66f};
  static const GLenum kMatrixModes[] = {GL_PATH_MODELVIEW_CHROMIUM,
                                        GL_PATH_PROJECTION_CHROMIUM};
  static const GLenum kGetMatrixModes[] = {GL_PATH_MODELVIEW_MATRIX_CHROMIUM,
                                           GL_PATH_PROJECTION_MATRIX_CHROMIUM};

  for (size_t i = 0; i < arraysize(kMatrixModes); ++i) {
    GLfloat mf[16];
    GLint mi[16];
    memset(mf, 0, sizeof(mf));
    memset(mi, 0, sizeof(mi));
    glGetFloatv(kGetMatrixModes[i], mf);
    glGetIntegerv(kGetMatrixModes[i], mi);
    ExpectEqualMatrix(kIdentityMatrix, mf);
    ExpectEqualMatrix(kIdentityMatrix, mi);

    glMatrixLoadfCHROMIUM(kMatrixModes[i], kSeqMatrix);
    memset(mf, 0, sizeof(mf));
    memset(mi, 0, sizeof(mi));
    glGetFloatv(kGetMatrixModes[i], mf);
    glGetIntegerv(kGetMatrixModes[i], mi);
    ExpectEqualMatrix(kSeqMatrix, mf);
    ExpectEqualMatrix(kSeqMatrix, mi);

    glMatrixLoadIdentityCHROMIUM(kMatrixModes[i]);
    memset(mf, 0, sizeof(mf));
    memset(mi, 0, sizeof(mi));
    glGetFloatv(kGetMatrixModes[i], mf);
    glGetIntegerv(kGetMatrixModes[i], mi);
    ExpectEqualMatrix(kIdentityMatrix, mf);
    ExpectEqualMatrix(kIdentityMatrix, mi);

    EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  }
}

TEST_F(CHROMIUMPathRenderingTest, TestMatrixErrors) {
  if (!GLTestHelper::HasExtension("GL_CHROMIUM_path_rendering")) {
    return;
  }
  GLfloat mf[16];
  memset(mf, 0, sizeof(mf));

  // This should fail.
  glMatrixLoadfCHROMIUM(GL_PATH_MODELVIEW_CHROMIUM - 1, mf);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_ENUM), glGetError());

  glMatrixLoadfCHROMIUM(GL_PATH_MODELVIEW_CHROMIUM, mf);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());

  // This should fail.
  glMatrixLoadIdentityCHROMIUM(GL_PATH_PROJECTION_CHROMIUM + 1);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_ENUM), glGetError());

  glMatrixLoadIdentityCHROMIUM(GL_PATH_PROJECTION_CHROMIUM);
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
}

}  // namespace gpu
