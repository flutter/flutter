// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

}  // namespace testing
}  // namespace flutter
