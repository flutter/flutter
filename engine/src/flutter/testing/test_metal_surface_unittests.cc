// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/test_metal_surface.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

TEST(TestMetalSurface, EmptySurfaceIsInvalid) {
  if (!TestMetalSurface::PlatformSupportsMetal()) {
    GTEST_SKIP();
  }

  auto surface = TestMetalSurface::Create();
  ASSERT_NE(surface, nullptr);
  ASSERT_FALSE(surface->IsValid());
}

TEST(TestMetalSurface, CanCreateValidTestMetalSurface) {
  if (!TestMetalSurface::PlatformSupportsMetal()) {
    GTEST_SKIP();
  }

  auto surface = TestMetalSurface::Create(SkISize::Make(100, 100));
  ASSERT_NE(surface, nullptr);
  ASSERT_TRUE(surface->IsValid());
  ASSERT_NE(surface->GetSurface(), nullptr);
  ASSERT_NE(surface->GetGrContext(), nullptr);
}

}  // namespace testing
}  // namespace flutter
