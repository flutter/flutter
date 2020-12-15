// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_SERIALIZABLE_TREE_H_
#define UI_ACCESSIBILITY_AX_SERIALIZABLE_TREE_H_

#include "ui/accessibility/ax_tree.h"
#include "ui/accessibility/ax_tree_source.h"

namespace ui {

class AX_EXPORT AXSerializableTree : public AXTree {
 public:
  AXSerializableTree();
  explicit AXSerializableTree(
      const AXTreeUpdate& initial_state);
  ~AXSerializableTree() override;

  // Create a TreeSource adapter for this tree. The client gets ownership
  // of the return value and should delete it when done.
  virtual AXTreeSource<const AXNode*, AXNodeData, AXTreeData>*
      CreateTreeSource();
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_AX_TREE_H_
