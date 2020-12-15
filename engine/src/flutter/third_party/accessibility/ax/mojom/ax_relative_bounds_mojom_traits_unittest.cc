// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_relative_bounds_mojom_traits.h"

#include "mojo/public/cpp/test_support/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/ax_relative_bounds.h"
#include "ui/accessibility/mojom/ax_relative_bounds.mojom.h"

using mojo::test::SerializeAndDeserialize;

TEST(AXRelativeBoundsMojomTraitsTest, RoundTrip) {
  ui::AXRelativeBounds input;
  input.offset_container_id = 111;
  input.bounds = gfx::RectF(1, 2, 3, 4);
  input.transform = std::make_unique<gfx::Transform>();
  input.transform->Scale(1.0, 2.0);

  ui::AXRelativeBounds output;
  EXPECT_TRUE(
      SerializeAndDeserialize<ax::mojom::AXRelativeBounds>(&input, &output));
  EXPECT_EQ(111, output.offset_container_id);
  EXPECT_EQ(1, output.bounds.x());
  EXPECT_EQ(2, output.bounds.y());
  EXPECT_EQ(3, output.bounds.width());
  EXPECT_EQ(4, output.bounds.height());
  EXPECT_FALSE(output.transform->IsIdentity());
}
