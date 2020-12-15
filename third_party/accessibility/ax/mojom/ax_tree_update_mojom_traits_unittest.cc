// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_tree_update_mojom_traits.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/ax_tree_update.h"
#include "ui/accessibility/mojom/ax_relative_bounds_mojom_traits.h"
#include "ui/accessibility/mojom/ax_tree_update.mojom.h"

using mojo::test::SerializeAndDeserialize;

TEST(AXTreeUpdateMojomTraitsTest, TestSerializeAndDeserializeAXTreeUpdate) {
  ui::AXTreeUpdate input, output;
  input.has_tree_data = true;
  input.tree_data.focus_id = 1;
  input.node_id_to_clear = 2;
  input.root_id = 3;
  input.nodes.resize(2);
  input.nodes[0].role = ax::mojom::Role::kButton;
  input.nodes[1].id = 4;
  input.event_from = ax::mojom::EventFrom::kUser;
  EXPECT_TRUE(
      SerializeAndDeserialize<ax::mojom::AXTreeUpdate>(&input, &output));
  EXPECT_EQ(true, output.has_tree_data);
  EXPECT_EQ(1, output.tree_data.focus_id);
  EXPECT_EQ(2, output.node_id_to_clear);
  EXPECT_EQ(3, output.root_id);
  ASSERT_EQ(2U, output.nodes.size());
  EXPECT_EQ(ax::mojom::Role::kButton, output.nodes[0].role);
  EXPECT_EQ(4, output.nodes[1].id);
  EXPECT_EQ(ax::mojom::EventFrom::kUser, output.event_from);
}
