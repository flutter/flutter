// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_tree_combiner.h"

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/ax_enums.mojom.h"

namespace ui {

TEST(CombineAXTreesTest, RenumberOneTree) {
  AXTreeID tree_id_1 = AXTreeID::CreateNewAXTreeID();

  AXTreeUpdate tree;
  tree.has_tree_data = true;
  tree.tree_data.tree_id = tree_id_1;
  tree.root_id = 2;
  tree.nodes.resize(3);
  tree.nodes[0].id = 2;
  tree.nodes[0].child_ids.push_back(4);
  tree.nodes[0].child_ids.push_back(6);
  tree.nodes[1].id = 4;
  tree.nodes[2].id = 6;

  AXTreeCombiner combiner;
  combiner.AddTree(tree, true);
  combiner.Combine();

  const AXTreeUpdate& combined = combiner.combined();

  EXPECT_EQ(1, combined.root_id);
  ASSERT_EQ(3U, combined.nodes.size());
  EXPECT_EQ(1, combined.nodes[0].id);
  ASSERT_EQ(2U, combined.nodes[0].child_ids.size());
  EXPECT_EQ(2, combined.nodes[0].child_ids[0]);
  EXPECT_EQ(3, combined.nodes[0].child_ids[1]);
  EXPECT_EQ(2, combined.nodes[1].id);
  EXPECT_EQ(3, combined.nodes[2].id);
}

TEST(CombineAXTreesTest, EmbedChildTree) {
  AXTreeID tree_id_1 = AXTreeID::CreateNewAXTreeID();
  AXTreeID tree_id_2 = AXTreeID::CreateNewAXTreeID();

  AXTreeUpdate parent_tree;
  parent_tree.root_id = 1;
  parent_tree.has_tree_data = true;
  parent_tree.tree_data.tree_id = tree_id_1;
  parent_tree.nodes.resize(3);
  parent_tree.nodes[0].id = 1;
  parent_tree.nodes[0].child_ids.push_back(2);
  parent_tree.nodes[0].child_ids.push_back(3);
  parent_tree.nodes[1].id = 2;
  parent_tree.nodes[1].role = ax::mojom::Role::kButton;
  parent_tree.nodes[2].id = 3;
  parent_tree.nodes[2].role = ax::mojom::Role::kIframe;
  parent_tree.nodes[2].AddStringAttribute(
      ax::mojom::StringAttribute::kChildTreeId, tree_id_2.ToString());

  AXTreeUpdate child_tree;
  child_tree.root_id = 1;
  child_tree.has_tree_data = true;
  child_tree.tree_data.parent_tree_id = tree_id_1;
  child_tree.tree_data.tree_id = tree_id_2;
  child_tree.nodes.resize(3);
  child_tree.nodes[0].id = 1;
  child_tree.nodes[0].child_ids.push_back(2);
  child_tree.nodes[0].child_ids.push_back(3);
  child_tree.nodes[1].id = 2;
  child_tree.nodes[1].role = ax::mojom::Role::kCheckBox;
  child_tree.nodes[2].id = 3;
  child_tree.nodes[2].role = ax::mojom::Role::kRadioButton;

  AXTreeCombiner combiner;
  combiner.AddTree(parent_tree, true);
  combiner.AddTree(child_tree, false);
  combiner.Combine();

  const AXTreeUpdate& combined = combiner.combined();

  EXPECT_EQ(1, combined.root_id);
  ASSERT_EQ(6U, combined.nodes.size());
  EXPECT_EQ(1, combined.nodes[0].id);
  ASSERT_EQ(2U, combined.nodes[0].child_ids.size());
  EXPECT_EQ(2, combined.nodes[0].child_ids[0]);
  EXPECT_EQ(3, combined.nodes[0].child_ids[1]);
  EXPECT_EQ(2, combined.nodes[1].id);
  EXPECT_EQ(ax::mojom::Role::kButton, combined.nodes[1].role);
  EXPECT_EQ(3, combined.nodes[2].id);
  EXPECT_EQ(ax::mojom::Role::kIframe, combined.nodes[2].role);
  EXPECT_EQ(1U, combined.nodes[2].child_ids.size());
  EXPECT_EQ(4, combined.nodes[2].child_ids[0]);
  EXPECT_EQ(4, combined.nodes[3].id);
  EXPECT_EQ(5, combined.nodes[4].id);
  EXPECT_EQ(ax::mojom::Role::kCheckBox, combined.nodes[4].role);
  EXPECT_EQ(6, combined.nodes[5].id);
  EXPECT_EQ(ax::mojom::Role::kRadioButton, combined.nodes[5].role);
}

TEST(CombineAXTreesTest, MapAllIdAttributes) {
  AXTreeID tree_id_1 = AXTreeID::CreateNewAXTreeID();

  // This is a nonsensical accessibility tree, the goal is to make sure
  // that all attributes that reference IDs of other nodes are remapped.

  AXTreeUpdate tree;
  tree.has_tree_data = true;
  tree.tree_data.tree_id = tree_id_1;
  tree.root_id = 11;
  tree.nodes.resize(2);
  tree.nodes[0].id = 11;
  tree.nodes[0].child_ids.push_back(22);
  tree.nodes[0].AddIntAttribute(ax::mojom::IntAttribute::kTableHeaderId, 22);
  tree.nodes[0].AddIntAttribute(ax::mojom::IntAttribute::kTableRowHeaderId, 22);
  tree.nodes[0].AddIntAttribute(ax::mojom::IntAttribute::kTableColumnHeaderId,
                                22);
  tree.nodes[0].AddIntAttribute(ax::mojom::IntAttribute::kActivedescendantId,
                                22);
  std::vector<int32_t> ids { 22 };
  tree.nodes[0].AddIntListAttribute(
      ax::mojom::IntListAttribute::kIndirectChildIds, ids);
  tree.nodes[0].AddIntListAttribute(ax::mojom::IntListAttribute::kControlsIds,
                                    ids);
  tree.nodes[0].AddIntListAttribute(
      ax::mojom::IntListAttribute::kDescribedbyIds, ids);
  tree.nodes[0].AddIntListAttribute(ax::mojom::IntListAttribute::kFlowtoIds,
                                    ids);
  tree.nodes[0].AddIntListAttribute(ax::mojom::IntListAttribute::kLabelledbyIds,
                                    ids);
  tree.nodes[1].id = 22;

  AXTreeCombiner combiner;
  combiner.AddTree(tree, true);
  combiner.Combine();

  const AXTreeUpdate& combined = combiner.combined();

  EXPECT_EQ(1, combined.root_id);
  ASSERT_EQ(2U, combined.nodes.size());
  EXPECT_EQ(1, combined.nodes[0].id);
  ASSERT_EQ(1U, combined.nodes[0].child_ids.size());
  EXPECT_EQ(2, combined.nodes[0].child_ids[0]);
  EXPECT_EQ(2, combined.nodes[1].id);

  EXPECT_EQ(2, combined.nodes[0].GetIntAttribute(
                   ax::mojom::IntAttribute::kTableHeaderId));
  EXPECT_EQ(2, combined.nodes[0].GetIntAttribute(
                   ax::mojom::IntAttribute::kTableRowHeaderId));
  EXPECT_EQ(2, combined.nodes[0].GetIntAttribute(
                   ax::mojom::IntAttribute::kTableColumnHeaderId));
  EXPECT_EQ(2, combined.nodes[0].GetIntAttribute(
                   ax::mojom::IntAttribute::kActivedescendantId));
  EXPECT_EQ(2, combined.nodes[0].GetIntListAttribute(
                   ax::mojom::IntListAttribute::kIndirectChildIds)[0]);
  EXPECT_EQ(2, combined.nodes[0].GetIntListAttribute(
                   ax::mojom::IntListAttribute::kControlsIds)[0]);
  EXPECT_EQ(2, combined.nodes[0].GetIntListAttribute(
                   ax::mojom::IntListAttribute::kDescribedbyIds)[0]);
  EXPECT_EQ(2, combined.nodes[0].GetIntListAttribute(
                   ax::mojom::IntListAttribute::kFlowtoIds)[0]);
  EXPECT_EQ(2, combined.nodes[0].GetIntListAttribute(
                   ax::mojom::IntListAttribute::kLabelledbyIds)[0]);
}

TEST(CombineAXTreesTest, FocusedTree) {
  AXTreeID tree_id_1 = AXTreeID::CreateNewAXTreeID();
  AXTreeID tree_id_2 = AXTreeID::CreateNewAXTreeID();

  AXTreeUpdate parent_tree;
  parent_tree.has_tree_data = true;
  parent_tree.tree_data.tree_id = tree_id_1;
  parent_tree.tree_data.focused_tree_id = tree_id_2;
  parent_tree.tree_data.focus_id = 2;
  parent_tree.root_id = 1;
  parent_tree.nodes.resize(3);
  parent_tree.nodes[0].id = 1;
  parent_tree.nodes[0].child_ids.push_back(2);
  parent_tree.nodes[0].child_ids.push_back(3);
  parent_tree.nodes[1].id = 2;
  parent_tree.nodes[1].role = ax::mojom::Role::kButton;
  parent_tree.nodes[2].id = 3;
  parent_tree.nodes[2].role = ax::mojom::Role::kIframe;
  parent_tree.nodes[2].AddStringAttribute(
      ax::mojom::StringAttribute::kChildTreeId, tree_id_2.ToString());

  AXTreeUpdate child_tree;
  child_tree.has_tree_data = true;
  child_tree.tree_data.parent_tree_id = tree_id_1;
  child_tree.tree_data.tree_id = tree_id_2;
  child_tree.tree_data.focus_id = 3;
  child_tree.root_id = 1;
  child_tree.nodes.resize(3);
  child_tree.nodes[0].id = 1;
  child_tree.nodes[0].child_ids.push_back(2);
  child_tree.nodes[0].child_ids.push_back(3);
  child_tree.nodes[1].id = 2;
  child_tree.nodes[1].role = ax::mojom::Role::kCheckBox;
  child_tree.nodes[2].id = 3;
  child_tree.nodes[2].role = ax::mojom::Role::kRadioButton;

  AXTreeCombiner combiner;
  combiner.AddTree(parent_tree, true);
  combiner.AddTree(child_tree, false);
  combiner.Combine();

  const AXTreeUpdate& combined = combiner.combined();

  ASSERT_EQ(6U, combined.nodes.size());
  EXPECT_EQ(6, combined.tree_data.focus_id);
}

TEST(CombineAXTreesTest, EmptyTree) {
  AXTreeUpdate tree;

  AXTreeCombiner combiner;
  combiner.AddTree(tree, true);
  combiner.Combine();

  const AXTreeUpdate& combined = combiner.combined();
  ASSERT_EQ(0U, combined.nodes.size());
}

}  // namespace ui
