// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/gles/context_gles.h"

namespace impeller {
namespace testing {

TEST(ContextGLESTest, MatchesJobPoolConstrainedPlatforms) {
  // MediaTek MT6779 (PowerVR Rogue GM9446), in both the casings observed in
  // the wild for ro.board.platform / ro.vendor.mediatek.platform.
  EXPECT_TRUE(ContextGLES::IsJobPoolConstrainedPlatform("mt6779"));
  EXPECT_TRUE(ContextGLES::IsJobPoolConstrainedPlatform("MT6779"));
}

TEST(ContextGLESTest, DoesNotMatchOtherPlatforms) {
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform(""));
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform("mt6"));
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform("mt677"));
  // Other MT67xx SoCs are not gated: no confirmed job-pool reports
  // (mt6762/mt6765 are PowerVR but tracked under the #187404 workaround;
  // mt6768/mt6771 ship Mali GPUs and use a different driver).
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform("mt6762"));
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform("mt6765"));
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform("mt6768"));
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform("mt6771"));
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform("mt8183"));
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform("kona"));
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform("exynos2100"));
  EXPECT_FALSE(ContextGLES::IsJobPoolConstrainedPlatform("sdm845"));
}

}  // namespace testing
}  // namespace impeller
