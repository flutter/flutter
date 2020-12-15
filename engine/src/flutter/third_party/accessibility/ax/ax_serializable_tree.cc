// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_serializable_tree.h"

#include <stdint.h>

#include "ui/accessibility/ax_node.h"

namespace ui {

// This class is an implementation of the AXTreeSource interface with
// AXNode as the node type, that just delegates to an AXTree. The purpose
// of this is so that AXTreeSerializer only needs to work with the
// AXTreeSource abstraction and doesn't need to actually know about
// AXTree directly. Another AXTreeSource is used to abstract the Blink
// accessibility tree.
class AX_EXPORT AXTreeSourceAdapter
    : public AXTreeSource<const AXNode*, AXNodeData, AXTreeData> {
 public:
  AXTreeSourceAdapter(AXTree* tree) : tree_(tree) {}
  ~AXTreeSourceAdapter() override {}

  // AXTreeSource implementation.
  bool GetTreeData(AXTreeData* data) const override {
    *data = tree_->data();
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

  bool IsValid(const AXNode* node) const override { return node != nullptr; }

  bool IsEqual(const AXNode* node1, const AXNode* node2) const override {
    return node1 == node2;
  }

  const AXNode* GetNull() const override { return nullptr; }

  void SerializeNode(const AXNode* node, AXNodeData* out_data) const override {
    *out_data = node->data();
  }

 private:
  AXTree* tree_;
};

AXSerializableTree::AXSerializableTree()
    : AXTree() {}

AXSerializableTree::AXSerializableTree(
    const AXTreeUpdate& initial_state)
    : AXTree(initial_state) {
}

AXSerializableTree::~AXSerializableTree() {
}

AXTreeSource<const AXNode*, AXNodeData, AXTreeData>*
AXSerializableTree::CreateTreeSource() {
  return new AXTreeSourceAdapter(this);
}

}  // namespace ui
