// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_tree_serializer.h"

#include <stddef.h>
#include <stdint.h>

#include <memory>

#include "base/macros.h"
#include "base/strings/string_number_conversions.h"
#include "testing/gmock/include/gmock/gmock-matchers.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/ax_node.h"
#include "ui/accessibility/ax_serializable_tree.h"
#include "ui/accessibility/ax_tree.h"

using testing::UnorderedElementsAre;

namespace ui {

using BasicAXTreeSerializer =
    AXTreeSerializer<const AXNode*, AXNodeData, AXTreeData>;

// The framework for these tests is that each test sets up |treedata0_|
// and |treedata1_| and then calls GetTreeSerializer, which creates a
// serializer for a tree that's initially in state |treedata0_|, but then
// changes to state |treedata1_|. This allows each test to check the
// updates created by AXTreeSerializer or unit-test its private
// member functions.
class AXTreeSerializerTest : public testing::Test {
 public:
  AXTreeSerializerTest() {}
  ~AXTreeSerializerTest() override {}

 protected:
  void CreateTreeSerializer();

  AXTreeUpdate treedata0_;
  AXTreeUpdate treedata1_;
  std::unique_ptr<AXSerializableTree> tree0_;
  std::unique_ptr<AXSerializableTree> tree1_;
  std::unique_ptr<AXTreeSource<const AXNode*, AXNodeData, AXTreeData>>
      tree0_source_;
  std::unique_ptr<AXTreeSource<const AXNode*, AXNodeData, AXTreeData>>
      tree1_source_;
  std::unique_ptr<BasicAXTreeSerializer> serializer_;

 private:
  DISALLOW_COPY_AND_ASSIGN(AXTreeSerializerTest);
};

void AXTreeSerializerTest::CreateTreeSerializer() {
  if (serializer_)
    return;

  tree0_ = std::make_unique<AXSerializableTree>(treedata0_);
  tree1_ = std::make_unique<AXSerializableTree>(treedata1_);

  // Serialize tree0 so that AXTreeSerializer thinks that its client
  // is totally in sync.
  tree0_source_.reset(tree0_->CreateTreeSource());
  serializer_ = std::make_unique<BasicAXTreeSerializer>(tree0_source_.get());
  AXTreeUpdate unused_update;
  ASSERT_TRUE(serializer_->SerializeChanges(tree0_->root(), &unused_update));

  // Pretend that tree0_ turned into tree1_. The next call to
  // AXTreeSerializer will force it to consider these changes to
  // the tree and send them as part of the next update.
  tree1_source_.reset(tree1_->CreateTreeSource());
  serializer_->ChangeTreeSourceForTesting(tree1_source_.get());
}

// In this test, one child is added to the root. Only the root and
// new child should be added.
TEST_F(AXTreeSerializerTest, UpdateContainsOnlyChangedNodes) {
  // (1 (2 3))
  treedata0_.root_id = 1;
  treedata0_.nodes.resize(3);
  treedata0_.nodes[0].id = 1;
  treedata0_.nodes[0].child_ids.push_back(2);
  treedata0_.nodes[0].child_ids.push_back(3);
  treedata0_.nodes[1].id = 2;
  treedata0_.nodes[2].id = 3;

  // (1 (4 2 3))
  treedata1_.root_id = 1;
  treedata1_.nodes.resize(4);
  treedata1_.nodes[0].id = 1;
  treedata1_.nodes[0].child_ids.push_back(4);
  treedata1_.nodes[0].child_ids.push_back(2);
  treedata1_.nodes[0].child_ids.push_back(3);
  treedata1_.nodes[1].id = 2;
  treedata1_.nodes[2].id = 3;
  treedata1_.nodes[3].id = 4;

  CreateTreeSerializer();
  AXTreeUpdate update;
  ASSERT_TRUE(serializer_->SerializeChanges(tree1_->GetFromId(1), &update));

  // The update should only touch nodes 1 and 4 - nodes 2 and 3 are unchanged
  // and shouldn't be affected.
  EXPECT_EQ(0, update.node_id_to_clear);
  ASSERT_EQ(2u, update.nodes.size());
  EXPECT_EQ(1, update.nodes[0].id);
  EXPECT_EQ(4, update.nodes[1].id);
}

// When the root changes, the whole tree is updated, even if some of it
// is unaffected.
TEST_F(AXTreeSerializerTest, NewRootUpdatesEntireTree) {
  // (1 (2 (3 (4))))
  treedata0_.root_id = 1;
  treedata0_.nodes.resize(4);
  treedata0_.nodes[0].id = 1;
  treedata0_.nodes[0].child_ids.push_back(2);
  treedata0_.nodes[1].id = 2;
  treedata0_.nodes[1].child_ids.push_back(3);
  treedata0_.nodes[2].id = 3;
  treedata0_.nodes[2].child_ids.push_back(4);
  treedata0_.nodes[3].id = 4;

  // (5 (2 (3 (4))))
  treedata1_.root_id = 5;
  treedata1_.nodes.resize(4);
  treedata1_.nodes[0].id = 5;
  treedata1_.nodes[0].child_ids.push_back(2);
  treedata1_.nodes[1].id = 2;
  treedata1_.nodes[1].child_ids.push_back(3);
  treedata1_.nodes[2].id = 3;
  treedata1_.nodes[2].child_ids.push_back(4);
  treedata1_.nodes[3].id = 4;

  CreateTreeSerializer();
  AXTreeUpdate update;
  ASSERT_TRUE(serializer_->SerializeChanges(tree1_->GetFromId(4), &update));

  // The update should delete the subtree rooted at node id=1, and
  // then include all four nodes in the update, even though the
  // subtree rooted at id=2 didn't actually change.
  EXPECT_EQ(1, update.node_id_to_clear);
  ASSERT_EQ(4u, update.nodes.size());
  EXPECT_EQ(5, update.nodes[0].id);
  EXPECT_EQ(2, update.nodes[1].id);
  EXPECT_EQ(3, update.nodes[2].id);
  EXPECT_EQ(4, update.nodes[3].id);
}

// When a node is reparented, the subtree including both the old parent
// and new parent of the reparented node must be deleted and recreated.
TEST_F(AXTreeSerializerTest, ReparentingUpdatesSubtree) {
  // (1 (2 (3 (4) 5)))
  treedata0_.root_id = 1;
  treedata0_.nodes.resize(5);
  treedata0_.nodes[0].id = 1;
  treedata0_.nodes[0].child_ids.push_back(2);
  treedata0_.nodes[1].id = 2;
  treedata0_.nodes[1].child_ids.push_back(3);
  treedata0_.nodes[1].child_ids.push_back(5);
  treedata0_.nodes[2].id = 3;
  treedata0_.nodes[2].child_ids.push_back(4);
  treedata0_.nodes[3].id = 4;
  treedata0_.nodes[4].id = 5;

  // Node 5 has been reparented from being a child of node 2,
  // to a child of node 4.
  // (1 (2 (3 (4 (5)))))
  treedata1_.root_id = 1;
  treedata1_.nodes.resize(5);
  treedata1_.nodes[0].id = 1;
  treedata1_.nodes[0].child_ids.push_back(2);
  treedata1_.nodes[1].id = 2;
  treedata1_.nodes[1].child_ids.push_back(3);
  treedata1_.nodes[2].id = 3;
  treedata1_.nodes[2].child_ids.push_back(4);
  treedata1_.nodes[3].id = 4;
  treedata1_.nodes[3].child_ids.push_back(5);
  treedata1_.nodes[4].id = 5;

  CreateTreeSerializer();
  AXTreeUpdate update;
  ASSERT_TRUE(serializer_->SerializeChanges(tree1_->GetFromId(4), &update));

  // The update should unserialize without errors.
  AXTree dst_tree(treedata0_);
  EXPECT_TRUE(dst_tree.Unserialize(update)) << dst_tree.error();

  // The update should delete the subtree rooted at node id=2, and
  // then include nodes 2...5.
  EXPECT_EQ(2, update.node_id_to_clear);
  ASSERT_EQ(4u, update.nodes.size());
  EXPECT_EQ(2, update.nodes[0].id);
  EXPECT_EQ(3, update.nodes[1].id);
  EXPECT_EQ(4, update.nodes[2].id);
  EXPECT_EQ(5, update.nodes[3].id);
}

// Similar to ReparentingUpdatesSubtree, except that InvalidateSubtree is
// called on id=1 - we need to make sure that the reparenting is still
// detected.
TEST_F(AXTreeSerializerTest, ReparentingWithInvalidationUpdatesSubtree) {
  // (1 (2 (3 (4 (5)))))
  treedata0_.root_id = 1;
  treedata0_.nodes.resize(5);
  treedata0_.nodes[0].id = 1;
  treedata0_.nodes[0].child_ids.push_back(2);
  treedata0_.nodes[1].id = 2;
  treedata0_.nodes[1].child_ids.push_back(3);
  treedata0_.nodes[2].id = 3;
  treedata0_.nodes[2].child_ids.push_back(4);
  treedata0_.nodes[3].id = 4;
  treedata0_.nodes[3].child_ids.push_back(5);
  treedata0_.nodes[4].id = 5;

  // Node 5 has been reparented from being a child of node 4,
  // to a child of node 2.
  // (1 (2 (3 (4) 5)))
  treedata1_.root_id = 1;
  treedata1_.nodes.resize(5);
  treedata1_.nodes[0].id = 1;
  treedata1_.nodes[0].child_ids.push_back(2);
  treedata1_.nodes[1].id = 2;
  treedata1_.nodes[1].child_ids.push_back(3);
  treedata1_.nodes[1].child_ids.push_back(5);
  treedata1_.nodes[2].id = 3;
  treedata1_.nodes[2].child_ids.push_back(4);
  treedata1_.nodes[3].id = 4;
  treedata1_.nodes[4].id = 5;

  CreateTreeSerializer();
  AXTreeUpdate update;
  serializer_->InvalidateSubtree(tree1_->GetFromId(1));
  ASSERT_TRUE(serializer_->SerializeChanges(tree1_->GetFromId(4), &update));

  // The update should unserialize without errors.
  AXTree dst_tree(treedata0_);
  EXPECT_TRUE(dst_tree.Unserialize(update)) << dst_tree.error();
}

// A variant of AXTreeSource that returns true for IsValid() for one
// particular id.
class AXTreeSourceWithInvalidId
    : public AXTreeSource<const AXNode*, AXNodeData, AXTreeData> {
 public:
  AXTreeSourceWithInvalidId(AXTree* tree, int invalid_id)
      : tree_(tree),
        invalid_id_(invalid_id) {}
  ~AXTreeSourceWithInvalidId() override {}

  // AXTreeSource implementation.
  bool GetTreeData(AXTreeData* data) const override {
    *data = AXTreeData();
    return true;
  }
  AXNode* GetRoot() const override { return tree_->root(); }
  AXNode* GetFromId(int32_t id) const override { return tree_->GetFromId(id); }
  int32_t GetId(const AXNode* node) const override { return node->id(); }
  void GetChildren(const AXNode* node,
                   std::vector<const AXNode*>* out_children) const override {
    *out_children = std::vector<const AXNode*>(node->children().cbegin(),
                                               node->children().cend());
  }
  AXNode* GetParent(const AXNode* node) const override {
    return node->parent();
  }
  bool IsIgnored(const AXNode* node) const override {
    return node->IsIgnored();
  }
  bool IsValid(const AXNode* node) const override {
    return node != nullptr && node->id() != invalid_id_;
  }
  bool IsEqual(const AXNode* node1, const AXNode* node2) const override {
    return node1 == node2;
  }
  const AXNode* GetNull() const override { return nullptr; }
  void SerializeNode(const AXNode* node, AXNodeData* out_data) const override {
    *out_data = node->data();
    if (node->id() == invalid_id_)
      out_data->id = -1;
  }

 private:
  AXTree* tree_;
  int invalid_id_;

  DISALLOW_COPY_AND_ASSIGN(AXTreeSourceWithInvalidId);
};

// Test that the serializer skips invalid children.
TEST(AXTreeSerializerInvalidTest, InvalidChild) {
  // (1 (2 3))
  AXTreeUpdate treedata;
  treedata.root_id = 1;
  treedata.nodes.resize(3);
  treedata.nodes[0].id = 1;
  treedata.nodes[0].child_ids.push_back(2);
  treedata.nodes[0].child_ids.push_back(3);
  treedata.nodes[1].id = 2;
  treedata.nodes[2].id = 3;

  AXTree tree(treedata);
  AXTreeSourceWithInvalidId source(&tree, 3);

  BasicAXTreeSerializer serializer(&source);
  AXTreeUpdate update;
  ASSERT_TRUE(serializer.SerializeChanges(tree.root(), &update));

  ASSERT_EQ(2U, update.nodes.size());
  EXPECT_EQ(1, update.nodes[0].id);
  EXPECT_EQ(2, update.nodes[1].id);
}

// Test that we can set a maximum number of nodes to serialize.
TEST_F(AXTreeSerializerTest, MaximumSerializedNodeCount) {
  // (1 (2 (3 4) 5 (6 7)))
  treedata0_.root_id = 1;
  treedata0_.nodes.resize(7);
  treedata0_.nodes[0].id = 1;
  treedata0_.nodes[0].child_ids.push_back(2);
  treedata0_.nodes[0].child_ids.push_back(5);
  treedata0_.nodes[1].id = 2;
  treedata0_.nodes[1].child_ids.push_back(3);
  treedata0_.nodes[1].child_ids.push_back(4);
  treedata0_.nodes[2].id = 3;
  treedata0_.nodes[3].id = 4;
  treedata0_.nodes[4].id = 5;
  treedata0_.nodes[4].child_ids.push_back(6);
  treedata0_.nodes[4].child_ids.push_back(7);
  treedata0_.nodes[5].id = 6;
  treedata0_.nodes[6].id = 7;

  tree0_ = std::make_unique<AXSerializableTree>(treedata0_);
  tree0_source_.reset(tree0_->CreateTreeSource());
  serializer_ = std::make_unique<BasicAXTreeSerializer>(tree0_source_.get());
  serializer_->set_max_node_count(4);
  AXTreeUpdate update;
  ASSERT_TRUE(serializer_->SerializeChanges(tree0_->root(), &update));
  // It actually serializes 5 nodes, not 4 - to be consistent.
  // It skips the children of node 5.
  ASSERT_EQ(5u, update.nodes.size());
}

#if !defined(ADDRESS_SANITIZER)
// If duplicate ids are encountered, it returns an error and the next
// update will re-send the entire tree.
// Test does not work with address sanitizer -- if EXPECT_DEATH is used to
// catch the "Illegal parenting" NOTREACHED(), an ASAN crash is still generated.
TEST_F(AXTreeSerializerTest, DuplicateIdsReturnsErrorAndFlushes) {
  // (1 (2 (3 (4) 5)))
  treedata0_.root_id = 1;
  treedata0_.nodes.resize(5);
  treedata0_.nodes[0].id = 1;
  treedata0_.nodes[0].child_ids.push_back(2);
  treedata0_.nodes[1].id = 2;
  treedata0_.nodes[1].child_ids.push_back(3);
  treedata0_.nodes[1].child_ids.push_back(5);
  treedata0_.nodes[2].id = 3;
  treedata0_.nodes[2].child_ids.push_back(4);
  treedata0_.nodes[3].id = 4;
  treedata0_.nodes[4].id = 5;

  // (1 (2 (6 (7) 5)))
  treedata1_.root_id = 1;
  treedata1_.nodes.resize(5);
  treedata1_.nodes[0].id = 1;
  treedata1_.nodes[0].child_ids.push_back(2);
  treedata1_.nodes[1].id = 2;
  treedata1_.nodes[1].child_ids.push_back(6);
  treedata1_.nodes[1].child_ids.push_back(5);
  treedata1_.nodes[2].id = 6;
  treedata1_.nodes[2].child_ids.push_back(7);
  treedata1_.nodes[3].id = 7;
  treedata1_.nodes[4].id = 5;

  CreateTreeSerializer();

  // Do some open-heart surgery on tree1, giving it a duplicate node.
  // This could not happen with an AXTree, but could happen with
  // another AXTreeSource if the structure it wraps is buggy. We want to
  // fail but not crash when that happens.
  std::vector<AXNode*> node2_children;
  node2_children.push_back(tree1_->GetFromId(7));
  node2_children.push_back(tree1_->GetFromId(6));
  tree1_->GetFromId(2)->SwapChildren(&node2_children);

  AXTreeUpdate update;
  ASSERT_FALSE(serializer_->SerializeChanges(tree1_->GetFromId(7), &update));

  // Swap it back, fixing the tree.
  tree1_->GetFromId(2)->SwapChildren(&node2_children);

  // Now try to serialize again. We should get the whole tree because the
  // previous failed call to SerializeChanges reset it.
  update = AXTreeUpdate();
  serializer_->SerializeChanges(tree1_->GetFromId(7), &update);
  ASSERT_EQ(5u, update.nodes.size());
}
#endif

// If a tree serializer is reset, that means it doesn't know about
// the state of the client tree anymore. The safest thing to do in
// that circumstance is to force the client to clear everything.
TEST_F(AXTreeSerializerTest, ResetUpdatesNodeIdToClear) {
  // (1 (2 (3 (4 (5)))))
  treedata0_.root_id = 1;
  treedata0_.nodes.resize(5);
  treedata0_.nodes[0].id = 1;
  treedata0_.nodes[0].child_ids.push_back(2);
  treedata0_.nodes[1].id = 2;
  treedata0_.nodes[1].child_ids.push_back(3);
  treedata0_.nodes[2].id = 3;
  treedata0_.nodes[2].child_ids.push_back(4);
  treedata0_.nodes[3].id = 4;
  treedata0_.nodes[3].child_ids.push_back(5);
  treedata0_.nodes[4].id = 5;

  // Node 5 has been reparented from being a child of node 4,
  // to a child of node 2.
  // (1 (2 (3 (4) 5)))
  treedata1_.root_id = 1;
  treedata1_.nodes.resize(5);
  treedata1_.nodes[0].id = 1;
  treedata1_.nodes[0].child_ids.push_back(2);
  treedata1_.nodes[1].id = 2;
  treedata1_.nodes[1].child_ids.push_back(3);
  treedata1_.nodes[1].child_ids.push_back(5);
  treedata1_.nodes[2].id = 3;
  treedata1_.nodes[2].child_ids.push_back(4);
  treedata1_.nodes[3].id = 4;
  treedata1_.nodes[4].id = 5;

  CreateTreeSerializer();

  serializer_->Reset();

  AXTreeUpdate update;
  ASSERT_TRUE(serializer_->SerializeChanges(tree1_->GetFromId(4), &update));

  // The update should unserialize without errors.
  AXTree dst_tree(treedata0_);
  EXPECT_TRUE(dst_tree.Unserialize(update)) << dst_tree.error();
}

// Ensure that calling Reset doesn't cause any problems if
// the root changes.
TEST_F(AXTreeSerializerTest, ResetWorksWithNewRootId) {
  // (1 (2))
  treedata0_.root_id = 1;
  treedata0_.nodes.resize(2);
  treedata0_.nodes[0].id = 1;
  treedata0_.nodes[0].child_ids.push_back(2);
  treedata0_.nodes[1].id = 2;

  // (3 (4))
  treedata1_.root_id = 3;
  treedata1_.nodes.resize(2);
  treedata1_.nodes[0].id = 3;
  treedata1_.nodes[0].child_ids.push_back(4);
  treedata1_.nodes[1].id = 4;

  CreateTreeSerializer();
  serializer_->Reset();

  AXTreeUpdate update;
  ASSERT_TRUE(serializer_->SerializeChanges(tree1_->GetFromId(4), &update));

  // The update should unserialize without errors.
  AXTree dst_tree(treedata0_);
  EXPECT_TRUE(dst_tree.Unserialize(update)) << dst_tree.error();
}

// Wraps an AXTreeSource and provides access to the results of the
// SerializerClearedNode callback.
class AXTreeSourceTestWrapper
    : public AXTreeSource<const AXNode*, AXNodeData, AXTreeData> {
 public:
  explicit AXTreeSourceTestWrapper(
      AXTreeSource<const AXNode*, AXNodeData, AXTreeData>* tree_source)
      : tree_source_(tree_source) {}
  ~AXTreeSourceTestWrapper() override = default;

  // Override SerializerClearedNode and provide a way to access it.
  void SerializerClearedNode(int32_t node_id) override {
    cleared_node_ids_.insert(node_id);
  }

  void ClearClearedNodeIds() { cleared_node_ids_.clear(); }
  std::set<int32_t>& cleared_node_ids() { return cleared_node_ids_; }

  // The rest of the AXTreeSource implementation just calls through to
  // tree_source_.
  bool GetTreeData(AXTreeData* data) const override {
    return tree_source_->GetTreeData(data);
  }
  const AXNode* GetRoot() const override { return tree_source_->GetRoot(); }
  const AXNode* GetFromId(int32_t id) const override {
    return tree_source_->GetFromId(id);
  }
  int32_t GetId(const AXNode* node) const override {
    return tree_source_->GetId(node);
  }
  void GetChildren(const AXNode* node,
                   std::vector<const AXNode*>* out_children) const override {
    return tree_source_->GetChildren(node, out_children);
  }
  const AXNode* GetParent(const AXNode* node) const override {
    return tree_source_->GetParent(node);
  }
  bool IsIgnored(const AXNode* node) const override {
    return tree_source_->IsIgnored(node);
  }
  bool IsValid(const AXNode* node) const override {
    return tree_source_->IsValid(node);
  }
  bool IsEqual(const AXNode* node1, const AXNode* node2) const override {
    return tree_source_->IsEqual(node1, node2);
  }
  const AXNode* GetNull() const override { return tree_source_->GetNull(); }
  void SerializeNode(const AXNode* node, AXNodeData* out_data) const override {
    tree_source_->SerializeNode(node, out_data);
  }

 private:
  AXTreeSource<const AXNode*, AXNodeData, AXTreeData>* tree_source_;
  std::set<int32_t> cleared_node_ids_;
};

TEST_F(AXTreeSerializerTest, TestClearedNodesWhenUpdatingRoot) {
  // (1 (2 (3 (4))))
  treedata0_.root_id = 1;
  treedata0_.nodes.resize(4);
  treedata0_.nodes[0].id = 1;
  treedata0_.nodes[0].child_ids.push_back(2);
  treedata0_.nodes[1].id = 2;
  treedata0_.nodes[1].child_ids.push_back(3);
  treedata0_.nodes[2].id = 3;
  treedata0_.nodes[2].child_ids.push_back(4);
  treedata0_.nodes[3].id = 4;

  // (5 (2 (3 (4))))
  treedata1_.root_id = 5;
  treedata1_.nodes.resize(4);
  treedata1_.nodes[0].id = 5;
  treedata1_.nodes[0].child_ids.push_back(2);
  treedata1_.nodes[1].id = 2;
  treedata1_.nodes[1].child_ids.push_back(3);
  treedata1_.nodes[2].id = 3;
  treedata1_.nodes[2].child_ids.push_back(4);
  treedata1_.nodes[3].id = 4;

  // Similar sequence to CreateTreeSerializer, but using
  // AXTreeSourceTestWrapper instead.
  tree0_ = std::make_unique<AXSerializableTree>(treedata0_);
  tree1_ = std::make_unique<AXSerializableTree>(treedata1_);
  tree0_source_.reset(tree0_->CreateTreeSource());
  AXTreeSourceTestWrapper tree0_source_wrapper(tree0_source_.get());
  serializer_ = std::make_unique<BasicAXTreeSerializer>(&tree0_source_wrapper);
  AXTreeUpdate unused_update;
  ASSERT_TRUE(serializer_->SerializeChanges(tree0_->root(), &unused_update));
  tree1_source_.reset(tree1_->CreateTreeSource());
  AXTreeSourceTestWrapper tree1_source_wrapper(tree1_source_.get());
  serializer_->ChangeTreeSourceForTesting(&tree1_source_wrapper);
  ASSERT_EQ(4U, serializer_->ClientTreeNodeCount());

  // If we swap out the root, all of the node IDs should have
  // SerializerClearedNode called on them.
  tree1_source_wrapper.ClearClearedNodeIds();
  ASSERT_TRUE(serializer_->SerializeChanges(tree1_->root(), &unused_update));
  EXPECT_THAT(tree1_source_wrapper.cleared_node_ids(),
              UnorderedElementsAre(1, 2, 3, 4));

  // Destroy the serializer first so that the AXTreeSources it points to
  // don't go out of scope first.
  serializer_.reset();
}

TEST_F(AXTreeSerializerTest, TestClearedNodesWhenUpdatingBranch) {
  // (1 (2 (3 (4))))
  treedata0_.root_id = 1;
  treedata0_.nodes.resize(4);
  treedata0_.nodes[0].id = 1;
  treedata0_.nodes[0].child_ids.push_back(2);
  treedata0_.nodes[1].id = 2;
  treedata0_.nodes[1].child_ids.push_back(3);
  treedata0_.nodes[2].id = 3;
  treedata0_.nodes[2].child_ids.push_back(4);
  treedata0_.nodes[3].id = 4;

  // (1 (2 (5 (6))))
  treedata1_.root_id = 1;
  treedata1_.nodes.resize(4);
  treedata1_.nodes[0].id = 1;
  treedata1_.nodes[0].child_ids.push_back(2);
  treedata1_.nodes[1].id = 2;
  treedata1_.nodes[1].child_ids.push_back(5);
  treedata1_.nodes[2].id = 5;
  treedata1_.nodes[2].child_ids.push_back(6);
  treedata1_.nodes[3].id = 6;

  // Similar sequence to CreateTreeSerializer, but using
  // AXTreeSourceTestWrapper instead.
  tree0_ = std::make_unique<AXSerializableTree>(treedata0_);
  tree1_ = std::make_unique<AXSerializableTree>(treedata1_);
  tree0_source_.reset(tree0_->CreateTreeSource());
  AXTreeSourceTestWrapper tree0_source_wrapper(tree0_source_.get());
  serializer_ = std::make_unique<BasicAXTreeSerializer>(&tree0_source_wrapper);
  AXTreeUpdate unused_update;
  ASSERT_TRUE(serializer_->SerializeChanges(tree0_->root(), &unused_update));
  tree1_source_.reset(tree1_->CreateTreeSource());
  AXTreeSourceTestWrapper tree1_source_wrapper(tree1_source_.get());
  serializer_->ChangeTreeSourceForTesting(&tree1_source_wrapper);
  ASSERT_EQ(4U, serializer_->ClientTreeNodeCount());

  // If we replace one branch with another, we should get calls to
  // SerializerClearedNode with all of the node IDs no longer in the tree.
  tree1_source_wrapper.ClearClearedNodeIds();
  ASSERT_TRUE(
      serializer_->SerializeChanges(tree1_->GetFromId(2), &unused_update));
  EXPECT_THAT(tree1_source_wrapper.cleared_node_ids(),
              UnorderedElementsAre(3, 4));

  // Destroy the serializer first so that the AXTreeSources it points to
  // don't go out of scope first.
  serializer_.reset();
}

}  // namespace ui
