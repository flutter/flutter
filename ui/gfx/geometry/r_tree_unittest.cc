// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/geometry/r_tree.h"
#include "ui/gfx/geometry/r_tree_base.h"
#include "ui/gfx/geometry/rect.h"

namespace gfx {

class RTreeTest : public ::testing::Test {
 protected:
  typedef RTree<int> RT;

  // Given a pointer to an RTree, traverse it and verify that its internal
  // structure is consistent with RTree semantics.
  void ValidateRTree(RTreeBase* rt) {
    // If RTree is empty it should have an empty rectangle.
    if (!rt->root()->count()) {
      EXPECT_TRUE(rt->root()->rect().IsEmpty());
      EXPECT_EQ(0, rt->root()->Level());
      return;
    }
    // Root is allowed to have fewer than min_children_ but never more than
    // max_children_.
    EXPECT_LE(rt->root()->count(), rt->max_children_);
    // The root should never be a record node.
    EXPECT_GT(rt->root()->Level(), -1);
    // The root should never have a parent pointer.
    EXPECT_TRUE(rt->root()->parent() == NULL);
    // Bounds must be consistent on the root.
    CheckBoundsConsistent(rt->root());
    for (size_t i = 0; i < rt->root()->count(); ++i) {
      ValidateNode(
          rt->root()->child(i), rt->min_children_, rt->max_children_);
    }
  }

  // Recursive descent method used by ValidateRTree to check each node within
  // the RTree for consistency with RTree semantics.
  void ValidateNode(const RTreeBase::NodeBase* node_base,
                    size_t min_children,
                    size_t max_children) {
    if (node_base->Level() >= 0) {
      const RTreeBase::Node* node =
          static_cast<const RTreeBase::Node*>(node_base);
      EXPECT_GE(node->count(), min_children);
      EXPECT_LE(node->count(), max_children);
      CheckBoundsConsistent(node);
      for (size_t i = 0; i < node->count(); ++i)
        ValidateNode(node->child(i), min_children, max_children);
    }
  }

  // Check bounds are consistent with children bounds, and other checks
  // convenient to do while enumerating the children of node.
  void CheckBoundsConsistent(const RTreeBase::Node* node) {
    EXPECT_FALSE(node->rect().IsEmpty());
    Rect check_bounds;
    for (size_t i = 0; i < node->count(); ++i) {
      const RTreeBase::NodeBase* child_node = node->child(i);
      check_bounds.Union(child_node->rect());
      EXPECT_EQ(node->Level() - 1, child_node->Level());
      EXPECT_EQ(node, child_node->parent());
    }
    EXPECT_EQ(check_bounds, node->rect());
  }

  // Adds count squares stacked around the point (0,0) with key equal to width.
  void AddStackedSquares(RT* rt, int count) {
    for (int i = 1; i <= count; ++i) {
      rt->Insert(Rect(0, 0, i, i), i);
      ValidateRTree(static_cast<RTreeBase*>(rt));
    }
  }

  // Given an unordered list of matching keys, verifies that it contains all
  // values [1..length] for the length of that list.
  void VerifyAllKeys(const RT::Matches& keys) {
    for (size_t i = 1; i <= keys.size(); ++i)
      EXPECT_EQ(1U, keys.count(i));
  }

  // Given a node and a rectangle, builds an expanded rectangle list where the
  // ith element of the vector is the union of the rectangle of the ith child of
  // the node and the argument rectangle.
  void BuildExpandedRects(RTreeBase::Node* node,
                          const Rect& rect,
                          std::vector<Rect>* expanded_rects) {
    expanded_rects->clear();
    expanded_rects->reserve(node->count());
    for (size_t i = 0; i < node->count(); ++i) {
      Rect expanded_rect(rect);
      expanded_rect.Union(node->child(i)->rect());
      expanded_rects->push_back(expanded_rect);
    }
  }
};

class RTreeNodeTest : public RTreeTest {
 protected:
  typedef RTreeBase::NodeBase RTreeNodeBase;
  typedef RT::Record RTreeRecord;
  typedef RTreeBase::Node RTreeNode;
  typedef RTreeBase::Node::Rects RTreeRects;
  typedef RTreeBase::Nodes RTreeNodes;

  // Accessors to private members of RTree::Node.
  const RTreeRecord* record(RTreeNode* node, size_t i) {
    return static_cast<const RTreeRecord*>(node->child(i));
  }

  // Provides access for tests to private methods of RTree::Node.
  scoped_ptr<RTreeNode> NewNodeAtLevel(size_t level) {
    return make_scoped_ptr(new RTreeBase::Node(level));
  }

  void NodeRecomputeLocalBounds(RTreeNodeBase* node) {
    node->RecomputeLocalBounds();
  }

  bool NodeCompareVertical(RTreeNodeBase* a, RTreeNodeBase* b) {
    return RTreeBase::Node::CompareVertical(a, b);
  }

  bool NodeCompareHorizontal(RTreeNodeBase* a, RTreeNodeBase* b) {
    return RTreeBase::Node::CompareHorizontal(a, b);
  }

  bool NodeCompareCenterDistanceFromParent(
      const RTreeNodeBase* a, const RTreeNodeBase* b) {
    return RTreeBase::Node::CompareCenterDistanceFromParent(a, b);
  }

  int NodeOverlapIncreaseToAdd(RTreeNode* node,
                               const Rect& rect,
                               const RTreeNodeBase* candidate_node,
                               const Rect& expanded_rect) {
    return node->OverlapIncreaseToAdd(rect, candidate_node, expanded_rect);
  }

  void NodeBuildLowBounds(const std::vector<RTreeNodeBase*>& vertical_sort,
                          const std::vector<RTreeNodeBase*>& horizontal_sort,
                          RTreeRects* vertical_bounds,
                          RTreeRects* horizontal_bounds) {
    RTreeBase::Node::BuildLowBounds(
        vertical_sort, horizontal_sort, vertical_bounds, horizontal_bounds);
  }

  void NodeBuildHighBounds(const std::vector<RTreeNodeBase*>& vertical_sort,
                           const std::vector<RTreeNodeBase*>& horizontal_sort,
                           RTreeRects* vertical_bounds,
                           RTreeRects* horizontal_bounds) {
    RTreeBase::Node::BuildHighBounds(
        vertical_sort, horizontal_sort, vertical_bounds, horizontal_bounds);
  }

  int NodeSmallestMarginSum(size_t start_index,
                            size_t end_index,
                            const RTreeRects& low_bounds,
                            const RTreeRects& high_bounds) {
    return RTreeBase::Node::SmallestMarginSum(
        start_index, end_index, low_bounds, high_bounds);
  }

  size_t NodeChooseSplitIndex(size_t min_children,
                              size_t max_children,
                              const RTreeRects& low_bounds,
                              const RTreeRects& high_bounds) {
    return RTreeBase::Node::ChooseSplitIndex(
        min_children, max_children, low_bounds, high_bounds);
  }

  scoped_ptr<RTreeNodeBase> NodeDivideChildren(
      RTreeNode* node,
      const RTreeRects& low_bounds,
      const RTreeRects& high_bounds,
      const std::vector<RTreeNodeBase*>& sorted_children,
      size_t split_index) {
    return node->DivideChildren(
        low_bounds, high_bounds, sorted_children, split_index);
  }

  RTreeNode* NodeLeastOverlapIncrease(RTreeNode* node,
                                      const Rect& node_rect,
                                      const RTreeRects& expanded_rects) {
    return node->LeastOverlapIncrease(node_rect, expanded_rects);
  }

  RTreeNode* NodeLeastAreaEnlargement(RTreeNode* node,
                                      const Rect& node_rect,
                                      const RTreeRects& expanded_rects) {
    return node->LeastAreaEnlargement(node_rect, expanded_rects);
  }
};

// RTreeNodeTest --------------------------------------------------------------

TEST_F(RTreeNodeTest, RemoveNodesForReinsert) {
  // Make a leaf node for testing removal from.
  scoped_ptr<RTreeNode> test_node(new RTreeNode);
  // Build 20 record nodes with rectangle centers going from (1,1) to (20,20)
  for (int i = 1; i <= 20; ++i)
    test_node->AddChild(scoped_ptr<RTreeNodeBase>(
        new RTreeRecord(Rect(i - 1, i - 1, 2, 2), i)));

  // Quick verification of the node before removing children.
  ValidateNode(test_node.get(), 1U, 20U);
  // Use a scoped vector to delete all children that get removed from the Node.
  RTreeNodes removals;
  test_node->RemoveNodesForReinsert(1, &removals);
  // Should have gotten back 1 node pointer.
  EXPECT_EQ(1U, removals.size());
  // There should be 19 left in the test_node.
  EXPECT_EQ(19U, test_node->count());
  // If we fix up the bounds on the test_node, it should verify.
  NodeRecomputeLocalBounds(test_node.get());
  ValidateNode(test_node.get(), 2U, 20U);
  // The node we removed should be node 10, as it was exactly in the center.
  EXPECT_EQ(10, static_cast<RTreeRecord*>(removals[0])->key());

  // Now remove the next 2.
  removals.clear();
  test_node->RemoveNodesForReinsert(2, &removals);
  EXPECT_EQ(2U, removals.size());
  EXPECT_EQ(17U, test_node->count());
  NodeRecomputeLocalBounds(test_node.get());
  ValidateNode(test_node.get(), 2U, 20U);
  // Lastly the 2 nodes we should have gotten back are keys 9 and 11, as their
  // centers were the closest to the center of the node bounding box.
  base::hash_set<intptr_t> results_hash;
  results_hash.insert(static_cast<RTreeRecord*>(removals[0])->key());
  results_hash.insert(static_cast<RTreeRecord*>(removals[1])->key());
  EXPECT_EQ(1U, results_hash.count(9));
  EXPECT_EQ(1U, results_hash.count(11));
}

TEST_F(RTreeNodeTest, CompareVertical) {
  // One rect with lower y than another should always sort lower.
  RTreeRecord low(Rect(0, 1, 10, 10), 1);
  RTreeRecord middle(Rect(0, 5, 10, 10), 5);
  EXPECT_TRUE(NodeCompareVertical(&low, &middle));
  EXPECT_FALSE(NodeCompareVertical(&middle, &low));

  // Try a non-overlapping higher-y rectangle.
  RTreeRecord high(Rect(-10, 20, 10, 1), 10);
  EXPECT_TRUE(NodeCompareVertical(&low, &high));
  EXPECT_FALSE(NodeCompareVertical(&high, &low));

  // Ties are broken by lowest bottom y value.
  RTreeRecord shorter_tie(Rect(10, 1, 100, 2), 2);
  EXPECT_TRUE(NodeCompareVertical(&shorter_tie, &low));
  EXPECT_FALSE(NodeCompareVertical(&low, &shorter_tie));
}

TEST_F(RTreeNodeTest, CompareHorizontal) {
  // One rect with lower x than another should always sort lower than higher x.
  RTreeRecord low(Rect(1, 0, 10, 10), 1);
  RTreeRecord middle(Rect(5, 0, 10, 10), 5);
  EXPECT_TRUE(NodeCompareHorizontal(&low, &middle));
  EXPECT_FALSE(NodeCompareHorizontal(&middle, &low));

  // Try a non-overlapping higher-x rectangle.
  RTreeRecord high(Rect(20, -10, 1, 10), 10);
  EXPECT_TRUE(NodeCompareHorizontal(&low, &high));
  EXPECT_FALSE(NodeCompareHorizontal(&high, &low));

  // Ties are broken by lowest bottom x value.
  RTreeRecord shorter_tie(Rect(1, 10, 2, 100), 2);
  EXPECT_TRUE(NodeCompareHorizontal(&shorter_tie, &low));
  EXPECT_FALSE(NodeCompareHorizontal(&low, &shorter_tie));
}

TEST_F(RTreeNodeTest, CompareCenterDistanceFromParent) {
  // Create a test node we can add children to, for distance comparisons.
  scoped_ptr<RTreeNode> parent(new RTreeNode);

  // Add three children, one each with centers at (0, 0), (10, 10), (-9, -9),
  // around which a bounding box will be centered at (0, 0)
  scoped_ptr<RTreeRecord> center_zero(new RTreeRecord(Rect(-1, -1, 2, 2), 1));
  parent->AddChild(center_zero.Pass());

  scoped_ptr<RTreeRecord> center_positive(new RTreeRecord(Rect(9, 9, 2, 2), 2));
  parent->AddChild(center_positive.Pass());

  scoped_ptr<RTreeRecord> center_negative(
      new RTreeRecord(Rect(-10, -10, 2, 2), 3));
  parent->AddChild(center_negative.Pass());

  ValidateNode(parent.get(), 1U, 5U);
  EXPECT_EQ(Rect(-10, -10, 21, 21), parent->rect());

  EXPECT_TRUE(
      NodeCompareCenterDistanceFromParent(parent->child(0), parent->child(1)));
  EXPECT_FALSE(
      NodeCompareCenterDistanceFromParent(parent->child(1), parent->child(0)));
  EXPECT_TRUE(
      NodeCompareCenterDistanceFromParent(parent->child(0), parent->child(2)));
  EXPECT_FALSE(
      NodeCompareCenterDistanceFromParent(parent->child(2), parent->child(0)));
  EXPECT_TRUE(
      NodeCompareCenterDistanceFromParent(parent->child(2), parent->child(1)));
  EXPECT_FALSE(
      NodeCompareCenterDistanceFromParent(parent->child(1), parent->child(2)));
}

TEST_F(RTreeNodeTest, OverlapIncreaseToAdd) {
  // Create a test node with three children, for overlap comparisons.
  scoped_ptr<RTreeNode> parent(new RTreeNode);

  // Add three children, each 4 wide and tall, at (0, 0), (3, 3), (6, 6) with
  // overlapping corners.
  Rect top(0, 0, 4, 4);
  parent->AddChild(scoped_ptr<RTreeNodeBase>(new RTreeRecord(top, 1)));
  Rect middle(3, 3, 4, 4);
  parent->AddChild(scoped_ptr<RTreeNodeBase>(new RTreeRecord(middle, 2)));
  Rect bottom(6, 6, 4, 4);
  parent->AddChild(scoped_ptr<RTreeNodeBase>(new RTreeRecord(bottom, 3)));
  ValidateNode(parent.get(), 1U, 5U);

  // Test a rect in corner.
  Rect corner(0, 0, 1, 1);
  Rect expanded = top;
  expanded.Union(corner);
  // It should not add any overlap to add this to the first child at (0, 0).
  EXPECT_EQ(0, NodeOverlapIncreaseToAdd(
      parent.get(), corner, parent->child(0), expanded));

  expanded = middle;
  expanded.Union(corner);
  // Overlap for middle rectangle should increase from 2 pixels at (3, 3) and
  // (6, 6) to 17 pixels, as it will now cover 4x4 rectangle top,
  // so a change of +15.
  EXPECT_EQ(15, NodeOverlapIncreaseToAdd(
      parent.get(), corner, parent->child(1), expanded));

  expanded = bottom;
  expanded.Union(corner);
  // Overlap for bottom rectangle should increase from 1 pixel at (6, 6) to
  // 32 pixels, as it will now cover both 4x4 rectangles top and middle,
  // so a change of 31.
  EXPECT_EQ(31, NodeOverlapIncreaseToAdd(
      parent.get(), corner, parent->child(2), expanded));

  // Test a rect that doesn't overlap with anything, in the far right corner.
  Rect far_corner(9, 0, 1, 1);
  expanded = top;
  expanded.Union(far_corner);
  // Overlap of top should go from 1 to 4, as it will now cover the entire first
  // row of pixels in middle.
  EXPECT_EQ(3, NodeOverlapIncreaseToAdd(
      parent.get(), far_corner, parent->child(0), expanded));

  expanded = middle;
  expanded.Union(far_corner);
  // Overlap of middle should go from 2 to 8, as it will cover the rightmost 4
  // pixels of top and the top 4 pixels of bottom as it expands.
  EXPECT_EQ(6, NodeOverlapIncreaseToAdd(
      parent.get(), far_corner, parent->child(1), expanded));

  expanded = bottom;
  expanded.Union(far_corner);
  // Overlap of bottom should go from 1 to 4, as it will now cover the rightmost
  // 4 pixels of middle.
  EXPECT_EQ(3, NodeOverlapIncreaseToAdd(
      parent.get(), far_corner, parent->child(2), expanded));
}

TEST_F(RTreeNodeTest, BuildLowBounds) {
  RTreeNodes records;
  records.reserve(10);
  for (int i = 1; i <= 10; ++i)
    records.push_back(new RTreeRecord(Rect(0, 0, i, i), i));

  RTreeRects vertical_bounds;
  RTreeRects horizontal_bounds;
  NodeBuildLowBounds(
      records.get(), records.get(), &vertical_bounds, &horizontal_bounds);
  for (int i = 0; i < 10; ++i) {
    EXPECT_EQ(records[i]->rect(), vertical_bounds[i]);
    EXPECT_EQ(records[i]->rect(), horizontal_bounds[i]);
  }
}

TEST_F(RTreeNodeTest, BuildHighBounds) {
  RTreeNodes records;
  records.reserve(25);
  for (int i = 0; i < 25; ++i)
    records.push_back(new RTreeRecord(Rect(i, i, 25 - i, 25 - i), i));

  RTreeRects vertical_bounds;
  RTreeRects horizontal_bounds;
  NodeBuildHighBounds(
      records.get(), records.get(), &vertical_bounds, &horizontal_bounds);
  for (int i = 0; i < 25; ++i) {
    EXPECT_EQ(records[i]->rect(), vertical_bounds[i]);
    EXPECT_EQ(records[i]->rect(), horizontal_bounds[i]);
  }
}

TEST_F(RTreeNodeTest, ChooseSplitAxisAndIndexVertical) {
  RTreeRects low_vertical_bounds;
  RTreeRects high_vertical_bounds;
  RTreeRects low_horizontal_bounds;
  RTreeRects high_horizontal_bounds;
  // In this test scenario we describe a mirrored, stacked configuration of
  // horizontal, 1 pixel high rectangles labeled a-f like this:
  //
  // shape: | v sort: | h sort: |
  // -------+---------+---------+
  // aaaaa  |    0    |    0    |
  //  bbb   |    1    |    2    |
  //   c    |    2    |    4    |
  //   d    |    3    |    5    |
  //  eee   |    4    |    3    |
  // fffff  |    5    |    1    |
  //
  // These are already sorted vertically from top to bottom. Bounding rectangles
  // of these vertically sorted will be 5 wide, i tall bounding boxes.
  for (int i = 0; i < 6; ++i) {
    low_vertical_bounds.push_back(Rect(0, 0, 5, i + 1));
    high_vertical_bounds.push_back(Rect(0, i, 5, 6 - i));
  }

  // Low bounds of horizontal sort start with bounds of box a and then jump to
  // cover everything, as box f is second in horizontal sort.
  low_horizontal_bounds.push_back(Rect(0, 0, 5, 1));
  for (int i = 0; i < 5; ++i)
    low_horizontal_bounds.push_back(Rect(0, 0, 5, 6));

  // High horizontal bounds are hand-calculated.
  high_horizontal_bounds.push_back(Rect(0, 0, 5, 6));
  high_horizontal_bounds.push_back(Rect(0, 1, 5, 5));
  high_horizontal_bounds.push_back(Rect(1, 1, 3, 4));
  high_horizontal_bounds.push_back(Rect(1, 2, 3, 3));
  high_horizontal_bounds.push_back(Rect(2, 2, 1, 2));
  high_horizontal_bounds.push_back(Rect(2, 3, 1, 1));

  int smallest_vertical_margin =
      NodeSmallestMarginSum(2, 3, low_vertical_bounds, high_vertical_bounds);
  int smallest_horizontal_margin = NodeSmallestMarginSum(
      2, 3, low_horizontal_bounds, high_horizontal_bounds);
  EXPECT_LT(smallest_vertical_margin, smallest_horizontal_margin);

  EXPECT_EQ(
      3U,
      NodeChooseSplitIndex(2, 5, low_vertical_bounds, high_vertical_bounds));
}

TEST_F(RTreeNodeTest, ChooseSplitAxisAndIndexHorizontal) {
  RTreeRects low_vertical_bounds;
  RTreeRects high_vertical_bounds;
  RTreeRects low_horizontal_bounds;
  RTreeRects high_horizontal_bounds;
  // We rotate the shape from ChooseSplitAxisAndIndexVertical to test
  // horizontal split axis detection:
  //
  //         +--------+
  //         | a    f |
  //         | ab  ef |
  // sort:   | abcdef |
  //         | ab  ef |
  //         | a    f |
  //         |--------+
  // v sort: | 024531 |
  // h sort: | 012345 |
  //         +--------+
  //
  // Low bounds of vertical sort start with bounds of box a and then jump to
  // cover everything, as box f is second in vertical sort.
  low_vertical_bounds.push_back(Rect(0, 0, 1, 5));
  for (int i = 0; i < 5; ++i)
    low_vertical_bounds.push_back(Rect(0, 0, 6, 5));

  // High vertical bounds are hand-calculated.
  high_vertical_bounds.push_back(Rect(0, 0, 6, 5));
  high_vertical_bounds.push_back(Rect(1, 0, 5, 5));
  high_vertical_bounds.push_back(Rect(1, 1, 4, 3));
  high_vertical_bounds.push_back(Rect(2, 1, 3, 3));
  high_vertical_bounds.push_back(Rect(2, 2, 2, 1));
  high_vertical_bounds.push_back(Rect(3, 2, 1, 1));

  // These are already sorted horizontally from left to right. Bounding
  // rectangles of these horizontally sorted will be i wide, 5 tall bounding
  // boxes.
  for (int i = 0; i < 6; ++i) {
    low_horizontal_bounds.push_back(Rect(0, 0, i + 1, 5));
    high_horizontal_bounds.push_back(Rect(i, 0, 6 - i, 5));
  }

  int smallest_vertical_margin =
      NodeSmallestMarginSum(2, 3, low_vertical_bounds, high_vertical_bounds);
  int smallest_horizontal_margin = NodeSmallestMarginSum(
      2, 3, low_horizontal_bounds, high_horizontal_bounds);

  EXPECT_GT(smallest_vertical_margin, smallest_horizontal_margin);

  EXPECT_EQ(3U,
            NodeChooseSplitIndex(
                2, 5, low_horizontal_bounds, high_horizontal_bounds));
}

TEST_F(RTreeNodeTest, DivideChildren) {
  // Create a test node to split.
  scoped_ptr<RTreeNode> test_node(new RTreeNode);
  std::vector<RTreeNodeBase*> sorted_children;
  RTreeRects low_bounds;
  RTreeRects high_bounds;
  // Insert 10 record nodes, also inserting them into our children array.
  for (int i = 1; i <= 10; ++i) {
    scoped_ptr<RTreeRecord> record(new RTreeRecord(Rect(0, 0, i, i), i));
    sorted_children.push_back(record.get());
    test_node->AddChild(record.Pass());
    low_bounds.push_back(Rect(0, 0, i, i));
    high_bounds.push_back(Rect(0, 0, 10, 10));
  }
  // Split the children in half.
  scoped_ptr<RTreeNodeBase> split_node_base(NodeDivideChildren(
      test_node.get(), low_bounds, high_bounds, sorted_children, 5));
  RTreeNode* split_node = static_cast<RTreeNode*>(split_node_base.get());
  // Both nodes should be valid.
  ValidateNode(test_node.get(), 1U, 10U);
  ValidateNode(split_node, 1U, 10U);
  // Both nodes should have five children.
  EXPECT_EQ(5U, test_node->count());
  EXPECT_EQ(5U, split_node->count());
  // Test node should have children 1-5, split node should have children 6-10.
  for (int i = 0; i < 5; ++i) {
    EXPECT_EQ(i + 1, record(test_node.get(), i)->key());
    EXPECT_EQ(i + 6, record(split_node, i)->key());
  }
}

TEST_F(RTreeNodeTest, RemoveChildNoOrphans) {
  scoped_ptr<RTreeNode> test_parent(new RTreeNode);
  test_parent->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(0, 0, 1, 1), 1)));
  test_parent->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(0, 0, 2, 2), 2)));
  test_parent->AddChild(
    scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(0, 0, 3, 3), 3)));
  ValidateNode(test_parent.get(), 1U, 5U);

  RTreeNodes orphans;

  // Remove the middle node.
  scoped_ptr<RTreeNodeBase> middle_child(
      test_parent->RemoveChild(test_parent->child(1), &orphans));
  EXPECT_EQ(0U, orphans.size());
  EXPECT_EQ(2U, test_parent->count());
  NodeRecomputeLocalBounds(test_parent.get());
  ValidateNode(test_parent.get(), 1U, 5U);

  // Remove the end node.
  scoped_ptr<RTreeNodeBase> end_child(
      test_parent->RemoveChild(test_parent->child(1), &orphans));
  EXPECT_EQ(0U, orphans.size());
  EXPECT_EQ(1U, test_parent->count());
  NodeRecomputeLocalBounds(test_parent.get());
  ValidateNode(test_parent.get(), 1U, 5U);

  // Remove the first node.
  scoped_ptr<RTreeNodeBase> first_child(
      test_parent->RemoveChild(test_parent->child(0), &orphans));
  EXPECT_EQ(0U, orphans.size());
  EXPECT_EQ(0U, test_parent->count());
}

TEST_F(RTreeNodeTest, RemoveChildOrphans) {
  // Build binary tree of Nodes of height 4, keeping weak pointers to the
  // Levels 0 and 1 Nodes and the Records so we can test removal of them below.
  std::vector<RTreeNode*> level_1_children;
  std::vector<RTreeNode*> level_0_children;
  std::vector<RTreeRecord*> records;
  int id = 1;
  scoped_ptr<RTreeNode> root(NewNodeAtLevel(2));
  for (int i = 0; i < 2; ++i) {
    scoped_ptr<RTreeNode> level_1_child(NewNodeAtLevel(1));
    for (int j = 0; j < 2; ++j) {
      scoped_ptr<RTreeNode> level_0_child(new RTreeNode);
      for (int k = 0; k < 2; ++k) {
        scoped_ptr<RTreeRecord> record(
            new RTreeRecord(Rect(0, 0, id, id), id));
        ++id;
        records.push_back(record.get());
        level_0_child->AddChild(record.Pass());
      }
      level_0_children.push_back(level_0_child.get());
      level_1_child->AddChild(level_0_child.Pass());
    }
    level_1_children.push_back(level_1_child.get());
    root->AddChild(level_1_child.Pass());
  }

  // This should now be a valid tree structure.
  ValidateNode(root.get(), 2U, 2U);
  EXPECT_EQ(2U, level_1_children.size());
  EXPECT_EQ(4U, level_0_children.size());
  EXPECT_EQ(8U, records.size());

  // Now remove all of the level 0 nodes so we get the record nodes as orphans.
  RTreeNodes orphans;
  for (size_t i = 0; i < level_0_children.size(); ++i)
    level_1_children[i / 2]->RemoveChild(level_0_children[i], &orphans);

  // Orphans should be all 8 records but no order guarantee.
  EXPECT_EQ(8U, orphans.size());
  for (std::vector<RTreeRecord*>::iterator it = records.begin();
      it != records.end(); ++it) {
    RTreeNodes::iterator orphan =
        std::find(orphans.begin(), orphans.end(), *it);
    EXPECT_NE(orphan, orphans.end());
    orphans.erase(orphan);
  }
  EXPECT_EQ(0U, orphans.size());
}

TEST_F(RTreeNodeTest, RemoveAndReturnLastChild) {
  scoped_ptr<RTreeNode> test_parent(new RTreeNode);
  test_parent->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(0, 0, 1, 1), 1)));
  test_parent->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(0, 0, 2, 2), 2)));
  test_parent->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(0, 0, 3, 3), 3)));
  ValidateNode(test_parent.get(), 1U, 5U);

  RTreeNodeBase* child = test_parent->child(2);
  scoped_ptr<RTreeNodeBase> last_child(test_parent->RemoveAndReturnLastChild());
  EXPECT_EQ(child, last_child.get());
  EXPECT_EQ(2U, test_parent->count());
  NodeRecomputeLocalBounds(test_parent.get());
  ValidateNode(test_parent.get(), 1U, 5U);

  child = test_parent->child(1);
  scoped_ptr<RTreeNodeBase> middle_child(
      test_parent->RemoveAndReturnLastChild());
  EXPECT_EQ(child, middle_child.get());
  EXPECT_EQ(1U, test_parent->count());
  NodeRecomputeLocalBounds(test_parent.get());
  ValidateNode(test_parent.get(), 1U, 5U);

  child = test_parent->child(0);
  scoped_ptr<RTreeNodeBase> first_child(
      test_parent->RemoveAndReturnLastChild());
  EXPECT_EQ(child, first_child.get());
  EXPECT_EQ(0U, test_parent->count());
}

TEST_F(RTreeNodeTest, LeastOverlapIncrease) {
  scoped_ptr<RTreeNode> test_parent(NewNodeAtLevel(1));
  // Construct 4 nodes with 1x2 rects spaced horizontally 1 pixel apart, or:
  //
  // a b c d
  // a b c d
  //
  for (int i = 0; i < 4; ++i) {
    scoped_ptr<RTreeNode> node(new RTreeNode);
    scoped_ptr<RTreeRecord> record(
        new RTreeRecord(Rect(i * 2, 0, 1, 2), i + 1));
    node->AddChild(record.Pass());
    test_parent->AddChild(node.Pass());
  }

  ValidateNode(test_parent.get(), 1U, 5U);

  // Test rect at (7, 0) should require minimum overlap on the part of the
  // fourth rectangle to add:
  //
  // a b c dT
  // a b c d
  //
  Rect test_rect_far(7, 0, 1, 1);
  RTreeRects expanded_rects;
  BuildExpandedRects(test_parent.get(), test_rect_far, &expanded_rects);
  RTreeNode* result = NodeLeastOverlapIncrease(
      test_parent.get(), test_rect_far, expanded_rects);
  EXPECT_EQ(4, record(result, 0)->key());

  // Test rect covering the bottom half of all children should be a 4-way tie,
  // so LeastOverlapIncrease should return NULL:
  //
  // a b c d
  // TTTTTTT
  //
  Rect test_rect_tie(0, 1, 7, 1);
  BuildExpandedRects(test_parent.get(), test_rect_tie, &expanded_rects);
  result = NodeLeastOverlapIncrease(
      test_parent.get(), test_rect_tie, expanded_rects);
  EXPECT_TRUE(result == NULL);

  // Test rect completely inside c should return the third rectangle:
  //
  // a b T d
  // a b c d
  //
  Rect test_rect_inside(4, 0, 1, 1);
  BuildExpandedRects(test_parent.get(), test_rect_inside, &expanded_rects);
  result = NodeLeastOverlapIncrease(
      test_parent.get(), test_rect_inside, expanded_rects);
  EXPECT_EQ(3, record(result, 0)->key());

  // Add a rectangle that overlaps completely with rectangle c, to test
  // when there is a tie between two completely contained rectangles:
  //
  // a b Ted
  // a b eed
  //
  scoped_ptr<RTreeNode> record_parent(new RTreeNode);
  record_parent->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(4, 0, 2, 2), 9)));
  test_parent->AddChild(record_parent.Pass());
  BuildExpandedRects(test_parent.get(), test_rect_inside, &expanded_rects);
  result = NodeLeastOverlapIncrease(
      test_parent.get(), test_rect_inside, expanded_rects);
  EXPECT_TRUE(result == NULL);
}

TEST_F(RTreeNodeTest, LeastAreaEnlargement) {
  scoped_ptr<RTreeNode> test_parent(NewNodeAtLevel(1));
  // Construct 4 nodes in a cross-hairs style configuration:
  //
  //  a
  // b c
  //  d
  //
  scoped_ptr<RTreeNode> node(new RTreeNode);
  node->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(1, 0, 1, 1), 1)));
  test_parent->AddChild(node.Pass());
  node.reset(new RTreeNode);
  node->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(0, 1, 1, 1), 2)));
  test_parent->AddChild(node.Pass());
  node.reset(new RTreeNode);
  node->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(2, 1, 1, 1), 3)));
  test_parent->AddChild(node.Pass());
  node.reset(new RTreeNode);
  node->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(1, 2, 1, 1), 4)));
  test_parent->AddChild(node.Pass());

  ValidateNode(test_parent.get(), 1U, 5U);

  // Test rect at (1, 3) should require minimum area to add to Node d:
  //
  //  a
  // b c
  //  d
  //  T
  //
  Rect test_rect_below(1, 3, 1, 1);
  RTreeRects expanded_rects;
  BuildExpandedRects(test_parent.get(), test_rect_below, &expanded_rects);
  RTreeNode* result = NodeLeastAreaEnlargement(
      test_parent.get(), test_rect_below, expanded_rects);
  EXPECT_EQ(4, record(result, 0)->key());

  // Test rect completely inside b should require minimum area to add to Node b:
  //
  //  a
  // T c
  //  d
  //
  Rect test_rect_inside(0, 1, 1, 1);
  BuildExpandedRects(test_parent.get(), test_rect_inside, &expanded_rects);
  result = NodeLeastAreaEnlargement(
      test_parent.get(), test_rect_inside, expanded_rects);
  EXPECT_EQ(2, record(result, 0)->key());

  // Add e at (0, 1) to overlap b and c, to test tie-breaking:
  //
  //  a
  // eee
  //  d
  //
  node.reset(new RTreeNode);
  node->AddChild(
      scoped_ptr<RTreeNodeBase>(new RTreeRecord(Rect(0, 1, 3, 1), 7)));
  test_parent->AddChild(node.Pass());

  ValidateNode(test_parent.get(), 1U, 5U);

  // Test rect at (3, 1) should tie between c and e, but c has smaller area so
  // the algorithm should select c:
  //
  //
  //  a
  // eeeT
  //  d
  //
  Rect test_rect_tie_breaker(3, 1, 1, 1);
  BuildExpandedRects(test_parent.get(), test_rect_tie_breaker, &expanded_rects);
  result = NodeLeastAreaEnlargement(
      test_parent.get(), test_rect_tie_breaker, expanded_rects);
  EXPECT_EQ(3, record(result, 0)->key());
}

// RTreeTest ------------------------------------------------------------------

// An empty RTree should never return AppendIntersectingRecords results, and
// RTrees should be empty upon construction.
TEST_F(RTreeTest, AppendIntersectingRecordsOnEmptyTree) {
  RT rt(2, 10);
  ValidateRTree(&rt);
  RT::Matches results;
  Rect test_rect(25, 25);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(0U, results.size());
  ValidateRTree(&rt);
}

// Clear should empty the tree, meaning that all queries should not return
// results after.
TEST_F(RTreeTest, ClearEmptiesTreeOfSingleNode) {
  RT rt(2, 5);
  rt.Insert(Rect(0, 0, 100, 100), 1);
  rt.Clear();
  RT::Matches results;
  Rect test_rect(1, 1);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(0U, results.size());
  ValidateRTree(&rt);
}

// Even with a complex internal structure, clear should empty the tree, meaning
// that all queries should not return results after.
TEST_F(RTreeTest, ClearEmptiesTreeOfManyNodes) {
  RT rt(2, 5);
  AddStackedSquares(&rt, 100);
  rt.Clear();
  RT::Matches results;
  Rect test_rect(1, 1);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(0U, results.size());
  ValidateRTree(&rt);
}

// Duplicate inserts should overwrite previous inserts.
TEST_F(RTreeTest, DuplicateInsertsOverwrite) {
  RT rt(2, 5);
  // Add 100 stacked squares, but always with duplicate key of 0.
  for (int i = 1; i <= 100; ++i) {
    rt.Insert(Rect(0, 0, i, i), 0);
    ValidateRTree(&rt);
  }
  RT::Matches results;
  Rect test_rect(1, 1);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(1U, results.size());
  EXPECT_EQ(1U, results.count(0));
}

// Call Remove() once on something that's been inserted repeatedly.
TEST_F(RTreeTest, DuplicateInsertRemove) {
  RT rt(3, 9);
  AddStackedSquares(&rt, 25);
  for (int i = 1; i <= 100; ++i) {
    rt.Insert(Rect(0, 0, i, i), 26);
    ValidateRTree(&rt);
  }
  rt.Remove(26);
  RT::Matches results;
  Rect test_rect(1, 1);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(25U, results.size());
  VerifyAllKeys(results);
}

// Call Remove() repeatedly on something that's been inserted once.
TEST_F(RTreeTest, InsertDuplicateRemove) {
  RT rt(7, 15);
  AddStackedSquares(&rt, 101);
  for (int i = 0; i < 100; ++i) {
    rt.Remove(101);
    ValidateRTree(&rt);
  }
  RT::Matches results;
  Rect test_rect(1, 1);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(100U, results.size());
  VerifyAllKeys(results);
}

// Stacked rects should meet all matching queries regardless of nesting.
TEST_F(RTreeTest, AppendIntersectingRecordsStackedSquaresNestedHit) {
  RT rt(2, 5);
  AddStackedSquares(&rt, 100);
  RT::Matches results;
  Rect test_rect(1, 1);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(100U, results.size());
  VerifyAllKeys(results);
}

// Stacked rects should meet all matching queries when contained completely by
// the query rectangle.
TEST_F(RTreeTest, AppendIntersectingRecordsStackedSquaresContainedHit) {
  RT rt(2, 10);
  AddStackedSquares(&rt, 100);
  RT::Matches results;
  Rect test_rect(0, 0, 100, 100);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(100U, results.size());
  VerifyAllKeys(results);
}

// Stacked rects should miss a missing query when the query has no intersection
// with the rects.
TEST_F(RTreeTest, AppendIntersectingRecordsStackedSquaresCompleteMiss) {
  RT rt(2, 7);
  AddStackedSquares(&rt, 100);
  RT::Matches results;
  Rect test_rect(150, 150, 100, 100);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(0U, results.size());
}

// Removing half the nodes after insertion should still result in a valid tree.
TEST_F(RTreeTest, RemoveHalfStackedRects) {
  RT rt(2, 11);
  AddStackedSquares(&rt, 200);
  for (int i = 101; i <= 200; ++i) {
    rt.Remove(i);
    ValidateRTree(&rt);
  }
  RT::Matches results;
  Rect test_rect(1, 1);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(100U, results.size());
  VerifyAllKeys(results);

  // Add the nodes back in.
  for (int i = 101; i <= 200; ++i) {
    rt.Insert(Rect(0, 0, i, i), i);
    ValidateRTree(&rt);
  }
  results.clear();
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(200U, results.size());
  VerifyAllKeys(results);
}

TEST_F(RTreeTest, InsertDupToRoot) {
  RT rt(2, 5);
  rt.Insert(Rect(0, 0, 1, 2), 1);
  ValidateRTree(&rt);
  rt.Insert(Rect(0, 0, 2, 1), 1);
  ValidateRTree(&rt);
}

TEST_F(RTreeTest, InsertNegativeCoordsRect) {
  RT rt(5, 11);
  for (int i = 1; i <= 100; ++i) {
    rt.Insert(Rect(-i, -i, i, i), (i * 2) - 1);
    ValidateRTree(&rt);
    rt.Insert(Rect(0, 0, i, i), i * 2);
    ValidateRTree(&rt);
  }
  RT::Matches results;
  Rect test_rect(-1, -1, 2, 2);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(200U, results.size());
  VerifyAllKeys(results);
}

TEST_F(RTreeTest, RemoveNegativeCoordsRect) {
  RT rt(7, 21);

  // Add 100 positive stacked squares.
  AddStackedSquares(&rt, 100);

  // Now add 100 negative stacked squares.
  for (int i = 101; i <= 200; ++i) {
    rt.Insert(Rect(100 - i, 100 - i, i - 100, i - 100), 301 - i);
    ValidateRTree(&rt);
  }

  // Now remove half of the negative squares.
  for (int i = 101; i <= 150; ++i) {
    rt.Remove(301 - i);
    ValidateRTree(&rt);
  }

  // Queries should return 100 positive and 50 negative stacked squares.
  RT::Matches results;
  Rect test_rect(-1, -1, 2, 2);
  rt.AppendIntersectingRecords(test_rect, &results);
  EXPECT_EQ(150U, results.size());
  VerifyAllKeys(results);
}

TEST_F(RTreeTest, InsertEmptyRectReplacementRemovesKey) {
  RT rt(10, 31);
  AddStackedSquares(&rt, 50);
  ValidateRTree(&rt);

  // Replace last square with empty rect.
  rt.Insert(Rect(), 50);
  ValidateRTree(&rt);

  // Now query large area to get all rects in tree.
  RT::Matches results;
  Rect test_rect(0, 0, 100, 100);
  rt.AppendIntersectingRecords(test_rect, &results);

  // Should only be 49 rects in tree.
  EXPECT_EQ(49U, results.size());
  VerifyAllKeys(results);
}

TEST_F(RTreeTest, InsertReplacementMaintainsTree) {
  RT rt(2, 5);
  AddStackedSquares(&rt, 100);
  ValidateRTree(&rt);

  for (int i = 1; i <= 100; ++i) {
    rt.Insert(Rect(0, 0, 0, 0), i);
    ValidateRTree(&rt);
  }
}

}  // namespace gfx
