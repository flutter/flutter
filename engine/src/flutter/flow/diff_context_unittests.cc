// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/diff_context_test.h"

namespace flutter {
namespace testing {

TEST_F(DiffContextTest, ClipAlignment) {
  MockLayerTree t1;
  t1.root()->Add(CreateDisplayListLayer(
      CreateDisplayList(SkRect::MakeLTRB(30, 30, 50, 50))));
  auto damage = DiffLayerTree(t1, MockLayerTree(), SkIRect::MakeEmpty(), 0, 0);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(30, 30, 50, 50));
  EXPECT_EQ(damage.buffer_damage, SkIRect::MakeLTRB(30, 30, 50, 50));

  damage = DiffLayerTree(t1, MockLayerTree(), SkIRect::MakeEmpty(), 1, 1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(30, 30, 50, 50));
  EXPECT_EQ(damage.buffer_damage, SkIRect::MakeLTRB(30, 30, 50, 50));

  damage = DiffLayerTree(t1, MockLayerTree(), SkIRect::MakeEmpty(), 8, 1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(24, 30, 56, 50));
  EXPECT_EQ(damage.buffer_damage, SkIRect::MakeLTRB(24, 30, 56, 50));

  damage = DiffLayerTree(t1, MockLayerTree(), SkIRect::MakeEmpty(), 1, 8);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(30, 24, 50, 56));
  EXPECT_EQ(damage.buffer_damage, SkIRect::MakeLTRB(30, 24, 50, 56));

  damage = DiffLayerTree(t1, MockLayerTree(), SkIRect::MakeEmpty(), 16, 16);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(16, 16, 64, 64));
  EXPECT_EQ(damage.buffer_damage, SkIRect::MakeLTRB(16, 16, 64, 64));
}

}  // namespace testing
}  // namespace flutter
