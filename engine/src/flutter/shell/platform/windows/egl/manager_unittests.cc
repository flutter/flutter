// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/egl/manager.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// Whether ANGLE can create an OpenGL ES context of |client_version| on
// |manager|'s display.
bool CanCreateGLESContext(const egl::Manager& manager, EGLint client_version) {
  const EGLint attributes[] = {EGL_CONTEXT_CLIENT_VERSION, client_version,
                               EGL_NONE};
  EGLContext context = ::eglCreateContext(
      manager.egl_display(), manager.egl_config(), EGL_NO_CONTEXT, attributes);
  if (context == EGL_NO_CONTEXT) {
    ::eglGetError();  // Clear the error.
    return false;
  }
  ::eglDestroyContext(manager.egl_display(), context);
  return true;
}

}  // namespace

TEST(EGLManagerTest, FeatureLevel10CapLimitsToOpenGLES2) {
  // Create an uncapped manager first to verify this machine supports OpenGL ES
  // 3.0; otherwise the cap has nothing to limit and the test proves nothing.
  auto uncapped = egl::Manager::Create(egl::GpuPreference::NoPreference,
                                       /*allow_inverted_surface=*/false);
  ASSERT_NE(uncapped, nullptr);
  if (!CanCreateGLESContext(*uncapped, 3)) {
    GTEST_SKIP() << "This machine only supports OpenGL ES 2.0.";
  }

  auto capped = egl::Manager::Create(egl::GpuPreference::NoPreference,
                                     /*allow_inverted_surface=*/false,
                                     egl::D3DFeatureLevel{10, 0});
  ASSERT_NE(capped, nullptr);
  EXPECT_TRUE(CanCreateGLESContext(*capped, 2));
  EXPECT_FALSE(CanCreateGLESContext(*capped, 3));
}

TEST(EGLManagerTest, ParseD3DFeatureLevel) {
  std::optional<egl::D3DFeatureLevel> level = egl::ParseD3DFeatureLevel("10_0");
  ASSERT_TRUE(level.has_value());
  EXPECT_EQ(level->major, 10);
  EXPECT_EQ(level->minor, 0);

  level = egl::ParseD3DFeatureLevel("11_1");
  ASSERT_TRUE(level.has_value());
  EXPECT_EQ(level->major, 11);
  EXPECT_EQ(level->minor, 1);
}

TEST(EGLManagerTest, ParseD3DFeatureLevelRejectsMalformed) {
  EXPECT_EQ(egl::ParseD3DFeatureLevel(""), std::nullopt);
  EXPECT_EQ(egl::ParseD3DFeatureLevel("10"), std::nullopt);
  EXPECT_EQ(egl::ParseD3DFeatureLevel("10.0"), std::nullopt);
  EXPECT_EQ(egl::ParseD3DFeatureLevel("10_"), std::nullopt);
  EXPECT_EQ(egl::ParseD3DFeatureLevel("_0"), std::nullopt);
  EXPECT_EQ(egl::ParseD3DFeatureLevel("10_0 "), std::nullopt);
  EXPECT_EQ(egl::ParseD3DFeatureLevel("ten_zero"), std::nullopt);
}

}  // namespace testing
}  // namespace flutter
