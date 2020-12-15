// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_action_data_mojom_traits.h"

#include "base/strings/utf_string_conversions.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/ax_action_data.h"
#include "ui/accessibility/mojom/ax_action_data.mojom.h"
#include "ui/gfx/geometry/point.h"
#include "ui/gfx/geometry/rect.h"

using mojo::test::SerializeAndDeserialize;

TEST(AXActionDataMojomTraitsTest, RoundTrip) {
  ui::AXActionData input;
  input.action = ax::mojom::Action::kBlur;
  input.target_tree_id = ui::AXTreeID::CreateNewAXTreeID();
  EXPECT_EQ(32U, input.target_tree_id.ToString().size());
  input.source_extension_id = "extension_id";
  input.target_node_id = 2;
  input.request_id = 3;
  input.flags = 4;
  input.anchor_node_id = 5;
  input.anchor_offset = 6;
  input.focus_node_id = 7;
  input.focus_offset = 8;
  input.custom_action_id = 9;
  input.target_rect = gfx::Rect(10, 11, 12, 13);
  input.target_point = gfx::Point(14, 15);
  input.value = "value";
  input.hit_test_event_to_fire = ax::mojom::Event::kFocus;

  ui::AXActionData output;
  EXPECT_TRUE(
      SerializeAndDeserialize<ax::mojom::AXActionData>(&input, &output));

  EXPECT_EQ(output.action, ax::mojom::Action::kBlur);
  EXPECT_EQ(output.target_tree_id, input.target_tree_id);
  EXPECT_EQ(output.target_tree_id.ToString(), input.target_tree_id.ToString());
  EXPECT_EQ(output.source_extension_id, "extension_id");
  EXPECT_EQ(output.target_node_id, 2);
  EXPECT_EQ(output.request_id, 3);
  EXPECT_EQ(output.flags, 4);
  EXPECT_EQ(output.anchor_node_id, 5);
  EXPECT_EQ(output.anchor_offset, 6);
  EXPECT_EQ(output.focus_node_id, 7);
  EXPECT_EQ(output.focus_offset, 8);
  EXPECT_EQ(output.custom_action_id, 9);
  EXPECT_EQ(output.target_rect, gfx::Rect(10, 11, 12, 13));
  EXPECT_EQ(output.target_point, gfx::Point(14, 15));
  EXPECT_EQ(output.value, "value");
  EXPECT_EQ(output.hit_test_event_to_fire, ax::mojom::Event::kFocus);
}
