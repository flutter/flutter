// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_tree_data_mojom_traits.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/ax_tree_data.h"
#include "ui/accessibility/mojom/ax_tree_data.mojom.h"

using mojo::test::SerializeAndDeserialize;

TEST(AXTreeDataMojomTraitsTest, TestSerializeAndDeserializeAXTreeData) {
  ui::AXTreeID tree_id_1 = ui::AXTreeID::CreateNewAXTreeID();
  ui::AXTreeID tree_id_2 = ui::AXTreeID::CreateNewAXTreeID();
  ui::AXTreeID tree_id_3 = ui::AXTreeID::CreateNewAXTreeID();

  ui::AXTreeData input, output;
  input.tree_id = tree_id_1;
  input.parent_tree_id = tree_id_2;
  input.focused_tree_id = tree_id_3;
  input.doctype = "4";
  input.loaded = true;
  input.loading_progress = 5;
  input.mimetype = "6";
  input.title = "7";
  input.url = "8";
  input.focus_id = 9;
  input.sel_is_backward = true;  // Set to true only for testing purposes.
  input.sel_anchor_object_id = 10;
  input.sel_anchor_offset = 11;
  input.sel_anchor_affinity = ax::mojom::TextAffinity::kUpstream;
  input.sel_focus_object_id = 12;
  input.sel_focus_offset = 13;
  input.sel_focus_affinity = ax::mojom::TextAffinity::kDownstream;
  input.root_scroller_id = 14;

  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXTreeData>(&input, &output));

  EXPECT_EQ(tree_id_1, output.tree_id);
  EXPECT_EQ(tree_id_2, output.parent_tree_id);
  EXPECT_EQ(tree_id_3, output.focused_tree_id);
  EXPECT_EQ("4", output.doctype);
  EXPECT_EQ(true, output.loaded);
  EXPECT_EQ(5, output.loading_progress);
  EXPECT_EQ("6", output.mimetype);
  EXPECT_EQ("7", output.title);
  EXPECT_EQ("8", output.url);
  EXPECT_EQ(9, output.focus_id);
  EXPECT_TRUE(output.sel_is_backward);
  EXPECT_EQ(10, output.sel_anchor_object_id);
  EXPECT_EQ(11, output.sel_anchor_offset);
  EXPECT_EQ(ax::mojom::TextAffinity::kUpstream, output.sel_anchor_affinity);
  EXPECT_EQ(12, output.sel_focus_object_id);
  EXPECT_EQ(13, output.sel_focus_offset);
  EXPECT_EQ(ax::mojom::TextAffinity::kDownstream, output.sel_focus_affinity);
  EXPECT_EQ(14, output.root_scroller_id);
}
