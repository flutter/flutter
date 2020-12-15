// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_TREE_SOURCE_CHECKER_H_
#define UI_ACCESSIBILITY_AX_TREE_SOURCE_CHECKER_H_

#include <map>

#include "base/strings/string_number_conversions.h"
#include "base/strings/stringprintf.h"
#include "ui/accessibility/ax_tree_source.h"

namespace ui {

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
class AXTreeSourceChecker {
 public:
  explicit AXTreeSourceChecker(
      AXTreeSource<AXSourceNode, AXNodeData, AXTreeData>* tree);
  ~AXTreeSourceChecker();

  // Returns true if everything reachable from the root of the tree is
  // consistent in its parent/child connections, and returns the error
  // as a string.
  bool CheckAndGetErrorString(std::string* error_string);

 private:
  bool Check(AXSourceNode node, std::string indent, std::string* output);
  std::string NodeToString(AXSourceNode node);

  AXTreeSource<AXSourceNode, AXNodeData, AXTreeData>* tree_;

  std::map<int32_t, int32_t> node_id_to_parent_id_map_;

  DISALLOW_COPY_AND_ASSIGN(AXTreeSourceChecker);
};

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
AXTreeSourceChecker<AXSourceNode, AXNodeData, AXTreeData>::AXTreeSourceChecker(
    AXTreeSource<AXSourceNode, AXNodeData, AXTreeData>* tree)
    : tree_(tree) {}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
AXTreeSourceChecker<AXSourceNode, AXNodeData, AXTreeData>::
    ~AXTreeSourceChecker() = default;

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
bool AXTreeSourceChecker<AXSourceNode, AXNodeData, AXTreeData>::
    CheckAndGetErrorString(std::string* error_string) {
  node_id_to_parent_id_map_.clear();

  AXSourceNode root = tree_->GetRoot();
  if (!tree_->IsValid(root)) {
    *error_string = "Root is not valid.";
    return false;
  }

  int32_t root_id = tree_->GetId(root);
  node_id_to_parent_id_map_[root_id] = -1;

  return Check(root, "", error_string);
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
std::string
AXTreeSourceChecker<AXSourceNode, AXNodeData, AXTreeData>::NodeToString(
    AXSourceNode node) {
  AXNodeData node_data;
  tree_->SerializeNode(node, &node_data);

  std::vector<AXSourceNode> children;
  tree_->GetChildren(node, &children);
  std::string children_str;
  if (children.size() == 0) {
    children_str = "(no children)";
  } else {
    for (size_t i = 0; i < children.size(); i++) {
      auto& child = children[i];
      int32_t child_id = tree_->IsValid(child) ? tree_->GetId(child) : -1;
      if (i == 0)
        children_str += "child_ids=" + base::NumberToString(child_id);
      else
        children_str += "," + base::NumberToString(child_id);
    }
  }

  int32_t parent_id = tree_->IsValid(tree_->GetParent(node))
                          ? tree_->GetId(tree_->GetParent(node))
                          : -1;

  return base::StringPrintf("%s %s parent_id=%d", node_data.ToString().c_str(),
                            children_str.c_str(), parent_id);
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
bool AXTreeSourceChecker<AXSourceNode, AXNodeData, AXTreeData>::Check(
    AXSourceNode node,
    std::string indent,
    std::string* output) {
  *output += indent + NodeToString(node);

  int32_t node_id = tree_->GetId(node);
  if (node_id <= 0) {
    std::string msg = base::StringPrintf(
        "Got a node with id %d, but all node IDs should be >= 1:\n%s\n",
        node_id, NodeToString(node).c_str());
    *output = msg + *output;
    return false;
  }

  // Check parent.
  int32_t expected_parent_id = node_id_to_parent_id_map_[node_id];
  AXSourceNode parent = tree_->GetParent(node);
  if (expected_parent_id == -1) {
    if (tree_->IsValid(parent)) {
      std::string msg = base::StringPrintf(
          "Node %d is the root, so its parent should be invalid, but we "
          "got a node with id %d.\n"
          "Node: %s\n"
          "Parent: %s\n",
          node_id, tree_->GetId(parent), NodeToString(node).c_str(),
          NodeToString(parent).c_str());
      *output = msg + *output;
      return false;
    }
  } else {
    if (!tree_->IsValid(parent)) {
      std::string msg = base::StringPrintf(
          "Node %d is not the root, but its parent was invalid:\n%s\n", node_id,
          NodeToString(node).c_str());
      *output = msg + *output;
      return false;
    }
    int32_t parent_id = tree_->GetId(parent);
    if (parent_id != expected_parent_id) {
      AXSourceNode expected_parent = tree_->GetFromId(expected_parent_id);
      std::string msg = base::StringPrintf(
          "Expected node %d to have a parent of %d, but found a parent of %d.\n"
          "Node: %s\n"
          "Parent: %s\n"
          "Expected parent: %s\n",
          node_id, expected_parent_id, parent_id, NodeToString(node).c_str(),
          NodeToString(parent).c_str(), NodeToString(expected_parent).c_str());
      *output = msg + *output;
      return false;
    }
  }

  // Check children.
  std::vector<AXSourceNode> children;
  tree_->GetChildren(node, &children);

  for (size_t i = 0; i < children.size(); i++) {
    auto& child = children[i];
    if (!tree_->IsValid(child)) {
      std::string msg =
          base::StringPrintf("Node %d has an invalid child (index %d): %s\n",
                             node_id, int{i}, NodeToString(node).c_str());
      *output = msg + *output;
      return false;
    }

    int32_t child_id = tree_->GetId(child);
    if (node_id_to_parent_id_map_.find(child_id) !=
        node_id_to_parent_id_map_.end()) {
      *output += "\n" + indent + "  ";
      AXNodeData child_data;
      tree_->SerializeNode(child, &child_data);
      *output += child_data.ToString() + "\n";

      std::string msg = base::StringPrintf(
          "Node %d has a child with ID %d, but we've previously seen a node "
          "with that ID, with a parent of %d.\n"
          "Node: %s",
          node_id, child_id, node_id_to_parent_id_map_[child_id],
          NodeToString(node).c_str());
      *output = msg + *output;
      return false;
    }

    node_id_to_parent_id_map_[child_id] = node_id;
  }

  *output += "\n";

  for (auto& child : children) {
    if (!Check(child, indent + "  ", output))
      return false;
  }

  return true;
}

}  // namespace ui

#endif  // UI_ACCESSIBILITY_AX_TREE_SOURCE_CHECKER_H_
