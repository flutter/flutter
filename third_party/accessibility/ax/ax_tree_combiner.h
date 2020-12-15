// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_TREE_COMBINER_H_
#define UI_ACCESSIBILITY_AX_TREE_COMBINER_H_

#include <vector>

#include "ui/accessibility/ax_export.h"
#include "ui/accessibility/ax_tree_id_registry.h"
#include "ui/accessibility/ax_tree_update.h"

namespace ui {

// This helper class takes multiple accessibility trees that reference each
// other via tree IDs, and combines them into a single accessibility tree
// that spans all of them.
//
// Since node IDs are relative to each ID, it has to renumber all of the IDs
// and update all of the attributes that reference IDs of other nodes to
// ensure they point to the right node.
//
// It also makes sure the final combined tree points to the correct focused
// node across all of the trees based on the focused tree ID of the root tree.
class AX_EXPORT AXTreeCombiner {
 public:
  AXTreeCombiner();
  ~AXTreeCombiner();

  void AddTree(const AXTreeUpdate& tree, bool is_root);
  bool Combine();

  const AXTreeUpdate& combined() { return combined_; }

 private:
  int32_t MapId(AXTreeID tree_id, int32_t node_id);

  void ProcessTree(const AXTreeUpdate* tree);

  std::vector<ui::AXTreeUpdate> trees_;
  AXTreeID root_tree_id_;
  int32_t next_id_ = 1;
  std::map<AXTreeID, const AXTreeUpdate*> tree_id_map_;
  std::map<std::pair<AXTreeID, int32_t>, int32_t> tree_id_node_id_map_;
  AXTreeUpdate combined_;
};


}  // namespace ui

#endif  // UI_ACCESSIBILITY_AX_TREE_COMBINER_H_
