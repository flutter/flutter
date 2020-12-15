// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_tree_combiner.h"

#include "ui/accessibility/ax_enums.mojom.h"
#include "ui/accessibility/ax_tree.h"
#include "ui/gfx/geometry/rect_f.h"

namespace ui {

AXTreeCombiner::AXTreeCombiner() {
}

AXTreeCombiner::~AXTreeCombiner() {
}

void AXTreeCombiner::AddTree(const AXTreeUpdate& tree, bool is_root) {
  if (tree.tree_data.tree_id == AXTreeIDUnknown()) {
    LOG(WARNING) << "Skipping AXTreeID because its tree ID is unknown";
    return;
  }

  trees_.push_back(tree);
  if (is_root) {
    DCHECK_EQ(root_tree_id_, AXTreeIDUnknown());
    root_tree_id_ = tree.tree_data.tree_id;
  }
}

bool AXTreeCombiner::Combine() {
  // First create a map from tree ID to tree update.
  for (const auto& tree : trees_) {
    AXTreeID tree_id = tree.tree_data.tree_id;
    if (tree_id_map_.find(tree_id) != tree_id_map_.end())
      return false;
    tree_id_map_[tree.tree_data.tree_id] = &tree;
  }

  // Make sure the root tree ID is in the map, otherwise fail.
  if (tree_id_map_.find(root_tree_id_) == tree_id_map_.end())
    return false;

  // Process the nodes recursively, starting with the root tree.
  const AXTreeUpdate* root = tree_id_map_.find(root_tree_id_)->second;
  ProcessTree(root);

  // Set the root id.
  combined_.root_id = combined_.nodes.size() > 0 ? combined_.nodes[0].id : 0;

  // Finally, handle the tree ID, taking into account which subtree might
  // have focus and mapping IDs from the tree data appropriately.
  combined_.has_tree_data = true;
  combined_.tree_data = root->tree_data;
  AXTreeID focused_tree_id = root->tree_data.focused_tree_id;
  const AXTreeUpdate* focused_tree = root;
  if (tree_id_map_.find(focused_tree_id) != tree_id_map_.end())
    focused_tree = tree_id_map_[focused_tree_id];
  combined_.tree_data.focus_id =
      MapId(focused_tree_id, focused_tree->tree_data.focus_id);
  combined_.tree_data.sel_is_backward =
      MapId(focused_tree_id, focused_tree->tree_data.sel_is_backward);
  combined_.tree_data.sel_anchor_object_id =
      MapId(focused_tree_id, focused_tree->tree_data.sel_anchor_object_id);
  combined_.tree_data.sel_focus_object_id =
      MapId(focused_tree_id, focused_tree->tree_data.sel_focus_object_id);
  combined_.tree_data.sel_anchor_offset =
      focused_tree->tree_data.sel_anchor_offset;
  combined_.tree_data.sel_focus_offset =
      focused_tree->tree_data.sel_focus_offset;

  // Debug-mode check that the resulting combined tree is valid.
  AXTree tree;
  DCHECK(tree.Unserialize(combined_))
      << combined_.ToString() << "\n" << tree.error();

  return true;
}

int32_t AXTreeCombiner::MapId(AXTreeID tree_id, int32_t node_id) {
  auto tree_id_node_id = std::make_pair(tree_id, node_id);
  if (tree_id_node_id_map_[tree_id_node_id] == 0)
    tree_id_node_id_map_[tree_id_node_id] = next_id_++;
  return tree_id_node_id_map_[tree_id_node_id];
}

void AXTreeCombiner::ProcessTree(const AXTreeUpdate* tree) {
  AXTreeID tree_id = tree->tree_data.tree_id;
  for (size_t i = 0; i < tree->nodes.size(); ++i) {
    AXNodeData node = tree->nodes[i];
    AXTreeID child_tree_id = AXTreeID::FromString(
        node.GetStringAttribute(ax::mojom::StringAttribute::kChildTreeId));

    // Map the node's ID.
    node.id = MapId(tree_id, node.id);

    // Map the node's child IDs.
    for (size_t j = 0; j < node.child_ids.size(); ++j)
      node.child_ids[j] = MapId(tree_id, node.child_ids[j]);

    // Map the container id.
    if (node.relative_bounds.offset_container_id > 0)
      node.relative_bounds.offset_container_id =
          MapId(tree_id, node.relative_bounds.offset_container_id);

    // Map other int attributes that refer to node IDs.
    for (size_t j = 0; j < node.int_attributes.size(); ++j) {
      auto& attr = node.int_attributes[j];
      if (IsNodeIdIntAttribute(attr.first))
        attr.second = MapId(tree_id, attr.second);
    }

    // Map other int list attributes that refer to node IDs.
    for (size_t j = 0; j < node.intlist_attributes.size(); ++j) {
      auto& attr = node.intlist_attributes[j];
      if (IsNodeIdIntListAttribute(attr.first)) {
        for (size_t k = 0; k < attr.second.size(); k++)
          attr.second[k] = MapId(tree_id, attr.second[k]);
      }
    }

    // Remove the ax::mojom::StringAttribute::kChildTreeId attribute.
    for (size_t j = 0; j < node.string_attributes.size(); ++j) {
      auto& attr = node.string_attributes[j];
      if (attr.first == ax::mojom::StringAttribute::kChildTreeId) {
        attr.first = ax::mojom::StringAttribute::kNone;
        attr.second = "";
      }
    }

    // See if this node has a child tree. As a sanity check make sure the
    // child tree lists this tree as its parent tree id.
    const AXTreeUpdate* child_tree = nullptr;
    if (tree_id_map_.find(child_tree_id) != tree_id_map_.end()) {
      child_tree = tree_id_map_.find(child_tree_id)->second;
      if (child_tree->tree_data.parent_tree_id != tree_id)
        child_tree = nullptr;
      if (child_tree && child_tree->nodes.empty())
        child_tree = nullptr;
      if (child_tree) {
        node.child_ids.push_back(MapId(child_tree_id,
                                       child_tree->nodes[0].id));
      }
    }

    // Put the rewritten AXNodeData into the output data structure.
    combined_.nodes.push_back(node);

    // Recurse into the child tree now, if any.
    if (child_tree)
      ProcessTree(child_tree);
  }
}

}  // namespace ui
