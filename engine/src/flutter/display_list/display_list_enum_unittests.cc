// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_tile_mode.h"
#include "flutter/display_list/types.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(DisplayListEnum, ToDlTileMode) {
  ASSERT_EQ(ToDl(SkTileMode::kClamp), DlTileMode::kClamp);
  ASSERT_EQ(ToDl(SkTileMode::kRepeat), DlTileMode::kRepeat);
  ASSERT_EQ(ToDl(SkTileMode::kMirror), DlTileMode::kMirror);
  ASSERT_EQ(ToDl(SkTileMode::kDecal), DlTileMode::kDecal);
}

TEST(DisplayListEnum, ToSkTileMode) {
  ASSERT_EQ(ToSk(DlTileMode::kClamp), SkTileMode::kClamp);
  ASSERT_EQ(ToSk(DlTileMode::kRepeat), SkTileMode::kRepeat);
  ASSERT_EQ(ToSk(DlTileMode::kMirror), SkTileMode::kMirror);
  ASSERT_EQ(ToSk(DlTileMode::kDecal), SkTileMode::kDecal);
}

#define CHECK_TO_DLENUM(V) ASSERT_EQ(ToDl(SkBlendMode::V), DlBlendMode::V);
#define CHECK_TO_SKENUM(V) ASSERT_EQ(ToSk(DlBlendMode::V), SkBlendMode::V);

#define FOR_EACH_ENUM(FUNC) \
  FUNC(kSrc)                \
  FUNC(kClear)              \
  FUNC(kSrc)                \
  FUNC(kDst)                \
  FUNC(kSrcOver)            \
  FUNC(kDstOver)            \
  FUNC(kSrcIn)              \
  FUNC(kDstIn)              \
  FUNC(kSrcOut)             \
  FUNC(kDstOut)             \
  FUNC(kSrcATop)            \
  FUNC(kDstATop)            \
  FUNC(kXor)                \
  FUNC(kPlus)               \
  FUNC(kModulate)           \
  FUNC(kScreen)             \
  FUNC(kOverlay)            \
  FUNC(kDarken)             \
  FUNC(kLighten)            \
  FUNC(kColorDodge)         \
  FUNC(kColorBurn)          \
  FUNC(kHardLight)          \
  FUNC(kSoftLight)          \
  FUNC(kDifference)         \
  FUNC(kExclusion)          \
  FUNC(kMultiply)           \
  FUNC(kHue)                \
  FUNC(kSaturation)         \
  FUNC(kColor)              \
  FUNC(kLuminosity)         \
  FUNC(kLastCoeffMode)      \
  FUNC(kLastSeparableMode)  \
  FUNC(kLastMode)

TEST(DisplayListEnum, ToDlBlendMode){FOR_EACH_ENUM(CHECK_TO_DLENUM)}

TEST(DisplayListEnum, ToSkBlendMode) {
  FOR_EACH_ENUM(CHECK_TO_SKENUM)
}

#undef CHECK_TO_DLENUM
#undef CHECK_TO_SKENUM
#undef FOR_EACH_ENUM

}  // namespace testing
}  // namespace flutter
