// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"
#include "impeller/toolkit/egl/context.h"
#include "impeller/toolkit/egl/display.h"
#include "impeller/toolkit/egl/surface.h"

namespace impeller {
namespace egl {
namespace testing {

TEST(EGLTest, ClearCurrentGuard) {
  Display display;
  if (!display.IsValid()) {
    GTEST_SKIP() << "EGL display is not valid or not supported on this platform.";
  }

  ConfigDescriptor desc;
  desc.api = API::kOpenGLES2;
  desc.surface_type = SurfaceType::kPBuffer;
  auto config = display.ChooseConfig(desc);
  if (!config) {
    GTEST_SKIP() << "Could not choose EGL config.";
  }

  auto context = display.CreateContext(*config, nullptr);
  ASSERT_NE(context, nullptr);

  ASSERT_FALSE(context->IsCurrent());

  ::eglGetError();

  bool result = context->ClearCurrent();
  EXPECT_TRUE(result);

  EXPECT_EQ(::eglGetError(), static_cast<EGLint>(EGL_SUCCESS));
}

TEST(EGLTest, ClearCurrentDoesNotDeactivateOtherContext) {
  Display display;
  if (!display.IsValid()) {
    GTEST_SKIP() << "EGL display is not valid or not supported on this platform.";
  }

  ConfigDescriptor desc;
  desc.api = API::kOpenGLES2;
  desc.surface_type = SurfaceType::kPBuffer;
  auto config = display.ChooseConfig(desc);
  if (!config) {
    GTEST_SKIP() << "Could not choose EGL config.";
  }

  auto context1 = display.CreateContext(*config, nullptr);
  auto context2 = display.CreateContext(*config, nullptr);
  ASSERT_NE(context1, nullptr);
  ASSERT_NE(context2, nullptr);

  auto surface = display.CreatePixelBufferSurface(*config, 1u, 1u);
  ASSERT_NE(surface, nullptr);

  ASSERT_TRUE(context2->MakeCurrent(*surface));
  ASSERT_TRUE(context2->IsCurrent());
  ASSERT_FALSE(context1->IsCurrent());

  EXPECT_TRUE(context1->ClearCurrent());

  EXPECT_TRUE(context2->IsCurrent());

  EXPECT_TRUE(context2->ClearCurrent());
}

}  // namespace testing
}  // namespace egl
}  // namespace impeller
