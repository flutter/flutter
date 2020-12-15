// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_tree_source_checker.h"

#include "base/strings/string_util.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/ax_enums.mojom.h"
#include "ui/accessibility/ax_node_data.h"
#include "ui/accessibility/ax_tree_source.h"

namespace ui {
namespace {

struct FakeAXTreeData {};

struct FakeAXNode {
  int32_t id;
  ax::mojom::Role role;
  std::vector<int32_t> child_ids;
  int32_t parent_id;
};

// It's distracting to see an empty bounding box from every node, so do a
// search-and-replace to get rid of those strings.
void CleanAXNodeDataString(std::string* error_str) {
  base::ReplaceSubstringsAfterOffset(error_str, 0, " (0, 0)-(0, 0)", "");
}

// A simple implementation of AXTreeSource initialized from a simple static
// vector of node data, where both the child and parent connections are
// explicit. This allows us to test that AXTreeSourceChecker properly warns
// about errors in accessibility trees that have inconsistent parent/child
// links.
class FakeAXTreeSource
    : public AXTreeSource<const FakeAXNode*, ui::AXNodeData, FakeAXTreeData> {
 public:
  FakeAXTreeSource(std::vector<FakeAXNode> nodes, int32_t root_id)
      : nodes_(nodes), root_id_(root_id) {
    for (size_t i = 0; i < nodes_.size(); ++i)
      id_to_node_[nodes_[i].id] = &nodes_[i];
  }

  // AXTreeSource overrides.
  bool GetTreeData(FakeAXTreeData* data) const override { return true; }

  const FakeAXNode* GetRoot() const override { return GetFromId(root_id_); }

  const FakeAXNode* GetFromId(int32_t id) const override {
    const auto& iter = id_to_node_.find(id);
    if (iter != id_to_node_.end())
      return iter->second;
    return nullptr;
  }

  int32_t GetId(const FakeAXNode* node) const override { return node->id; }

  void GetChildren(
      const FakeAXNode* node,
      std::vector<const FakeAXNode*>* out_children) const override {
    for (size_t i = 0; i < node->child_ids.size(); ++i)
      out_children->push_back(GetFromId(node->child_ids[i]));
  }

  const FakeAXNode* GetParent(const FakeAXNode* node) const override {
    return GetFromId(node->parent_id);
  }

  bool IsIgnored(const FakeAXNode* node) const override { return false; }

  bool IsValid(const FakeAXNode* node) const override {
    return node != nullptr;
  }

  bool IsEqual(const FakeAXNode* node1,
               const FakeAXNode* node2) const override {
    return node1 == node2;
  }

  const FakeAXNode* GetNull() const override { return nullptr; }

  void SerializeNode(const FakeAXNode* node,
                     AXNodeData* out_data) const override {
    out_data->id = node->id;
    out_data->role = node->role;
  }

 private:
  std::vector<FakeAXNode> nodes_;
  std::map<int32_t, FakeAXNode*> id_to_node_;
  int32_t root_id_;
};

}  // namespace

using FakeAXTreeSourceChecker =
    AXTreeSourceChecker<const FakeAXNode*, ui::AXNodeData, FakeAXTreeData>;

TEST(AXTreeSourceCheckerTest, SimpleValidTree) {
  std::vector<FakeAXNode> nodes = {
      {1, ax::mojom::Role::kRootWebArea, {2}, -1},
      {2, ax::mojom::Role::kRootWebArea, {}, 1},
  };
  FakeAXTreeSource node_source(nodes, 1);
  FakeAXTreeSourceChecker checker(&node_source);
  std::string error_string;
  EXPECT_TRUE(checker.CheckAndGetErrorString(&error_string));
}

TEST(AXTreeSourceCheckerTest, BadRoot) {
  std::vector<FakeAXNode> nodes = {
      {1, ax::mojom::Role::kRootWebArea, {2}, -1},
      {2, ax::mojom::Role::kRootWebArea, {}, 1},
  };
  FakeAXTreeSource node_source(nodes, 3);
  FakeAXTreeSourceChecker checker(&node_source);
  std::string error_string;
  EXPECT_FALSE(checker.CheckAndGetErrorString(&error_string));
  CleanAXNodeDataString(&error_string);
  EXPECT_EQ("Root is not valid.", error_string);
}

TEST(AXTreeSourceCheckerTest, BadNodeIdOfRoot) {
  std::vector<FakeAXNode> nodes = {
      {0, ax::mojom::Role::kRootWebArea, {2}, -1},
      {2, ax::mojom::Role::kRootWebArea, {}, 0},
  };
  FakeAXTreeSource node_source(nodes, 0);
  FakeAXTreeSourceChecker checker(&node_source);
  std::string error_string;
  EXPECT_FALSE(checker.CheckAndGetErrorString(&error_string));
  CleanAXNodeDataString(&error_string);
  EXPECT_EQ(
      "Got a node with id 0, but all node IDs should be >= 1:\n"
      "id=0 rootWebArea child_ids=2 parent_id=-1\n"
      "id=0 rootWebArea child_ids=2 parent_id=-1",
      error_string);
}

TEST(AXTreeSourceCheckerTest, BadNodeIdOfChild) {
  std::vector<FakeAXNode> nodes = {
      {1, ax::mojom::Role::kRootWebArea, {-5}, -1},
      {-5, ax::mojom::Role::kRootWebArea, {}, 1},
  };
  FakeAXTreeSource node_source(nodes, -5);
  FakeAXTreeSourceChecker checker(&node_source);
  std::string error_string;
  EXPECT_FALSE(checker.CheckAndGetErrorString(&error_string));
  CleanAXNodeDataString(&error_string);
  EXPECT_EQ(
      "Got a node with id -5, but all node IDs should be >= 1:\n"
      "id=-5 rootWebArea (no children) parent_id=1\n"
      "id=-5 rootWebArea (no children) parent_id=1",
      error_string);
}

TEST(AXTreeSourceCheckerTest, RootShouldNotBeNodeWithParent) {
  std::vector<FakeAXNode> nodes = {
      {1, ax::mojom::Role::kRootWebArea, {2}, -1},
      {2, ax::mojom::Role::kRootWebArea, {}, 1},
  };
  FakeAXTreeSource node_source(nodes, 2);
  FakeAXTreeSourceChecker checker(&node_source);
  std::string error_string;
  EXPECT_FALSE(checker.CheckAndGetErrorString(&error_string));
  CleanAXNodeDataString(&error_string);
  EXPECT_EQ(
      "Node 2 is the root, so its parent should be invalid, "
      "but we got a node with id 1.\n"
      "Node: id=2 rootWebArea (no children) parent_id=1\n"
      "Parent: id=1 rootWebArea child_ids=2 parent_id=-1\n"
      "id=2 rootWebArea (no children) parent_id=1",
      error_string);
}

TEST(AXTreeSourceCheckerTest, MissingParent) {
  std::vector<FakeAXNode> nodes = {
      {1, ax::mojom::Role::kRootWebArea, {2}, -1},
      {2, ax::mojom::Role::kRootWebArea, {}, -1},
  };
  FakeAXTreeSource node_source(nodes, 1);
  FakeAXTreeSourceChecker checker(&node_source);
  std::string error_string;
  EXPECT_FALSE(checker.CheckAndGetErrorString(&error_string));
  CleanAXNodeDataString(&error_string);
  EXPECT_EQ(
      "Node 2 is not the root, but its parent was invalid:\n"
      "id=2 rootWebArea (no children) parent_id=-1\n"
      "id=1 rootWebArea child_ids=2 parent_id=-1\n"
      "  id=2 rootWebArea (no children) parent_id=-1",
      error_string);
}

TEST(AXTreeSourceCheckerTest, InvalidParent) {
  std::vector<FakeAXNode> nodes = {
      {1, ax::mojom::Role::kRootWebArea, {2, 3}, -1},
      {2, ax::mojom::Role::kButton, {}, 1},
      {3, ax::mojom::Role::kParagraph, {}, 2},
  };
  FakeAXTreeSource node_source(nodes, 1);
  FakeAXTreeSourceChecker checker(&node_source);
  std::string error_string;
  EXPECT_FALSE(checker.CheckAndGetErrorString(&error_string));
  CleanAXNodeDataString(&error_string);
  EXPECT_EQ(
      "Expected node 3 to have a parent of 1, but found a parent of 2.\n"
      "Node: id=3 paragraph (no children) parent_id=2\n"
      "Parent: id=2 button (no children) parent_id=1\n"
      "Expected parent: id=1 rootWebArea child_ids=2,3 parent_id=-1\n"
      "id=1 rootWebArea child_ids=2,3 parent_id=-1\n"
      "  id=2 button (no children) parent_id=1\n"
      "  id=3 paragraph (no children) parent_id=2",
      error_string);
}

}  // namespace ui
