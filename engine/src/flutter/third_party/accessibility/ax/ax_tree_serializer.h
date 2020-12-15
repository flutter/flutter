// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_TREE_SERIALIZER_H_
#define UI_ACCESSIBILITY_AX_TREE_SERIALIZER_H_

#include <stddef.h>
#include <stdint.h>

#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "base/logging.h"
#include "ui/accessibility/ax_export.h"
#include "ui/accessibility/ax_tree_source.h"
#include "ui/accessibility/ax_tree_update.h"

namespace ui {

struct ClientTreeNode;

// AXTreeSerializer is a helper class that serializes incremental
// updates to an AXTreeSource as a AXTreeUpdate struct.
// These structs can be unserialized by a client object such as an
// AXTree. An AXTreeSerializer keeps track of the tree of node ids that its
// client is aware of so that it will never generate an AXTreeUpdate that
// results in an invalid tree.
//
// Every node in the source tree must have an id that's a unique positive
// integer, the same node must not appear twice.
//
// Usage:
//
// You must call SerializeChanges() every time a node in the tree changes,
// and send the generated AXTreeUpdate to the client. Changes to the
// AXTreeData, if any, are also automatically included in the AXTreeUpdate.
//
// If a node is added, call SerializeChanges on its parent.
// If a node is removed, call SerializeChanges on its parent.
// If a whole new subtree is added, just call SerializeChanges on its root.
// If the root of the tree changes, call SerializeChanges on the new root.
//
// AXTreeSerializer will avoid re-serializing nodes that do not change.
// For example, if node 1 has children 2, 3, 4, 5 and then child 2 is
// removed and a new child 6 is added, the AXTreeSerializer will only
// update nodes 1 and 6 (and any children of node 6 recursively). It will
// assume that nodes 3, 4, and 5 are not modified unless you explicitly
// call SerializeChanges() on them.
//
// As long as the source tree has unique ids for every node and no loops,
// and as long as every update is applied to the client tree, AXTreeSerializer
// will continue to work. If the source tree makes a change but fails to
// call SerializeChanges properly, the trees may get out of sync - but
// because AXTreeSerializer always keeps track of what updates it's sent,
// it will never send an invalid update and the client tree will not break,
// it just may not contain all of the changes.
template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
class AXTreeSerializer {
 public:
  explicit AXTreeSerializer(
      AXTreeSource<AXSourceNode, AXNodeData, AXTreeData>* tree);
  ~AXTreeSerializer();

  // Throw out the internal state that keeps track of the nodes the client
  // knows about. This has the effect that the next update will send the
  // entire tree over because it assumes the client knows nothing.
  void Reset();

  // Sets the maximum number of nodes that will be serialized, or zero
  // for no maximum. This is not a hard maximum - once it hits or
  // exceeds this maximum it stops walking the children of nodes, but
  // it may exceed this value a bit in order to create a consistent
  // tree.
  void set_max_node_count(size_t max_node_count) {
    max_node_count_ = max_node_count;
  }

  // Serialize all changes to |node| and append them to |out_update|.
  // Returns true on success. On failure, returns false and calls Reset();
  // this only happens when the source tree has a problem like duplicate
  // ids or changing during serialization.
  bool SerializeChanges(AXSourceNode node,
                        AXTreeUpdateBase<AXNodeData, AXTreeData>* out_update);

  // Invalidate the subtree rooted at this node, ensuring that the whole
  // subtree is re-serialized the next time any of those nodes end up
  // being serialized.
  void InvalidateSubtree(AXSourceNode node);

  // Return whether or not this node is in the client tree. If you call
  // this immediately after serializing, this indicates whether a given
  // node is in the set of nodes that the client (the recipient of
  // the AXTreeUpdates) is aware of.
  //
  // For example, you could use this to determine if a given node is
  // reachable. If one of its ancestors is hidden and it was pruned
  // from the accessibility tree, this would return false.
  bool IsInClientTree(AXSourceNode node);

  // Only for unit testing. Normally this class relies on getting a call
  // to SerializeChanges() every time the source tree changes. For unit
  // testing, it's convenient to create a static AXTree for the initial
  // state and then call ChangeTreeSourceForTesting and then SerializeChanges
  // to simulate the changes you'd get if a tree changed from the initial
  // state to the second tree's state.
  void ChangeTreeSourceForTesting(
      AXTreeSource<AXSourceNode, AXNodeData, AXTreeData>* new_tree);

  // Returns the number of nodes in the client tree. After a serialization
  // operation this should be an accurate representation of the tree source
  // as explored by the serializer.
  size_t ClientTreeNodeCount() const;

 private:
  // Return the least common ancestor of a node in the source tree
  // and a node in the client tree, or nullptr if there is no such node.
  // The least common ancestor is the closest ancestor to |node| (which
  // may be |node| itself) that's in both the source tree and client tree,
  // and for which both the source and client tree agree on their ancestor
  // chain up to the root.
  //
  // Example 1:
  //
  //    Client Tree    Source tree |
  //        1              1       |
  //       / \            / \      |
  //      2   3          2   4     |
  //
  // LCA(source node 2, client node 2) is node 2.
  // LCA(source node 3, client node 4) is node 1.
  //
  // Example 2:
  //
  //    Client Tree    Source tree |
  //        1              1       |
  //       / \            / \      |
  //      2   3          2   3     |
  //     / \            /   /      |
  //    4   7          8   4       |
  //   / \                / \      |
  //  5   6              5   6     |
  //
  // LCA(source node 8, client node 7) is node 2.
  // LCA(source node 5, client node 5) is node 1.
  // It's not node 5, because the two trees disagree on the parent of
  // node 4, so the LCA is the first ancestor both trees agree on.
  AXSourceNode LeastCommonAncestor(AXSourceNode node,
                                   ClientTreeNode* client_node);

  // Return the least common ancestor of |node| that's in the client tree.
  // This just walks up the ancestors of |node| until it finds a node that's
  // also in the client tree and not inside an invalid subtree, and then calls
  // LeastCommonAncestor on the source node and client node.
  AXSourceNode LeastCommonAncestor(AXSourceNode node);

  // Walk the subtree rooted at |node| and return true if any nodes that
  // would be updated are being reparented. If so, update |out_lca| to point
  // to the least common ancestor of the previous LCA and the previous
  // parent of the node being reparented.
  bool AnyDescendantWasReparented(AXSourceNode node,
                                  AXSourceNode* out_lca);

  ClientTreeNode* ClientTreeNodeById(int32_t id);

  // Invalidate the subtree rooted at this node.
  void InvalidateClientSubtree(ClientTreeNode* client_node);

  // Delete all descendants of this node.
  void DeleteDescendants(ClientTreeNode* client_node);

  // Delete the client subtree rooted at this node.
  void DeleteClientSubtree(ClientTreeNode* client_node);

  // Helper function, called recursively with each new node to serialize.
  bool SerializeChangedNodes(
      AXSourceNode node,
      AXTreeUpdateBase<AXNodeData, AXTreeData>* out_update);

  // Delete the entire client subtree but don't set the did_reset_ flag
  // like when Reset() is called.
  void InternalReset();

  ClientTreeNode* GetClientTreeNodeParent(ClientTreeNode* obj);

  // The tree source.
  AXTreeSource<AXSourceNode, AXNodeData, AXTreeData>* tree_;

  // The tree data most recently sent to the client.
  AXTreeData client_tree_data_;

  // Our representation of the client tree.
  ClientTreeNode* client_root_ = nullptr;

  // A map from IDs to nodes in the client tree.
  std::unordered_map<int32_t, ClientTreeNode*> client_id_map_;

  // The maximum number of nodes to serialize in a given call to
  // SerializeChanges, or 0 if there's no maximum.
  size_t max_node_count_ = 0;

  // Keeps track of if Reset() was called. If so, we need to always
  // explicitly set node_id_to_clear to ensure that the next serialized
  // tree is treated as a completely new tree and not a partial update.
  bool did_reset_ = false;
};

// In order to keep track of what nodes the client knows about, we keep a
// representation of the client tree - just IDs and parent/child
// relationships, and a marker indicating whether it's been invalidated.
struct AX_EXPORT ClientTreeNode {
  ClientTreeNode();
  virtual ~ClientTreeNode();
  int32_t id;
  ClientTreeNode* parent;
  std::vector<ClientTreeNode*> children;
  bool ignored;
  bool invalid;
};

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::AXTreeSerializer(
    AXTreeSource<AXSourceNode, AXNodeData, AXTreeData>* tree)
    : tree_(tree) {}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::~AXTreeSerializer() {
  // Clear |tree_| to prevent any additional calls to the tree source
  // during teardown.
  tree_ = nullptr;
  Reset();
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
void AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::Reset() {
  InternalReset();
  did_reset_ = true;
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
void AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::InternalReset() {
  client_tree_data_ = AXTreeData();

  // Normally we use DeleteClientSubtree to remove nodes from the tree,
  // but Reset() needs to work even if the tree is in a broken state.
  // Instead, iterate over |client_id_map_| to ensure we clear all nodes and
  // start from scratch.
  for (auto&& item : client_id_map_) {
    if (tree_)
      tree_->SerializerClearedNode(item.first);
    delete item.second;
  }
  client_id_map_.clear();
  client_root_ = nullptr;
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
void AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::
    ChangeTreeSourceForTesting(
        AXTreeSource<AXSourceNode, AXNodeData, AXTreeData>* new_tree) {
  tree_ = new_tree;
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
size_t
AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::ClientTreeNodeCount()
    const {
  return client_id_map_.size();
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
AXSourceNode
AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::LeastCommonAncestor(
    AXSourceNode node,
    ClientTreeNode* client_node) {
  if (!tree_->IsValid(node) || client_node == nullptr)
    return tree_->GetNull();

  std::vector<AXSourceNode> ancestors;
  while (tree_->IsValid(node)) {
    ancestors.push_back(node);
    node = tree_->GetParent(node);
  }

  std::vector<ClientTreeNode*> client_ancestors;
  while (client_node) {
    client_ancestors.push_back(client_node);
    client_node = GetClientTreeNodeParent(client_node);
  }

  // Start at the root. Keep going until the source ancestor chain and
  // client ancestor chain disagree. The last node before they disagree
  // is the LCA.
  AXSourceNode lca = tree_->GetNull();
  int source_index = static_cast<int>(ancestors.size() - 1);
  int client_index = static_cast<int>(client_ancestors.size() - 1);
  while (source_index >= 0 && client_index >= 0) {
    if (tree_->GetId(ancestors[source_index]) !=
            client_ancestors[client_index]->id) {
      return lca;
    }
    lca = ancestors[source_index];
    source_index--;
    client_index--;
  }
  return lca;
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
AXSourceNode
AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::LeastCommonAncestor(
    AXSourceNode node) {
  // Walk up the tree until the source node's id also exists in the
  // client tree, whose parent is not invalid, then call LeastCommonAncestor
  // on those two nodes.
  //
  // Note that it's okay if |client_node| is invalid - the LCA can be the
  // root of an invalid subtree, since we're going to serialize the
  // LCA. But it's not okay if |client_node->parent| is invalid - that means
  // that we're inside of an invalid subtree that all needs to be
  // re-serialized, so the LCA should be higher.
  ClientTreeNode* client_node = ClientTreeNodeById(tree_->GetId(node));
  while (tree_->IsValid(node)) {
    if (client_node) {
      ClientTreeNode* parent = GetClientTreeNodeParent(client_node);
      if (!parent || !parent->invalid)
        break;
    }
    node = tree_->GetParent(node);
    if (tree_->IsValid(node))
      client_node = ClientTreeNodeById(tree_->GetId(node));
  }
  return LeastCommonAncestor(node, client_node);
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
bool AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::
    AnyDescendantWasReparented(AXSourceNode node, AXSourceNode* out_lca) {
  bool result = false;
  int id = tree_->GetId(node);
  std::vector<AXSourceNode> children;
  tree_->GetChildren(node, &children);
  for (size_t i = 0; i < children.size(); ++i) {
    AXSourceNode& child = children[i];
    int child_id = tree_->GetId(child);
    ClientTreeNode* client_child = ClientTreeNodeById(child_id);
    if (client_child) {
      ClientTreeNode* parent = client_child->parent;
      if (!parent) {
        // If the client child has no parent, it must have been the
        // previous root node, so there is no LCA and we can exit early.
        *out_lca = tree_->GetNull();
        return true;
      } else if (parent->id != id) {
        // If the client child's parent is not this node, update the LCA
        // and return true (reparenting was found).
        *out_lca = LeastCommonAncestor(*out_lca, client_child);
        result = true;
        continue;
      } else if (!client_child->invalid) {
        // This child is already in the client tree and valid, we won't
        // recursively serialize it so we don't need to check this
        // subtree recursively for reparenting.
        // However, if the child is ignored, the children may now be
        // considered as reparented, so continue recursion in that case.
        if (!client_child->ignored)
          continue;
      }
    }

    // This is a new child or reparented child, check it recursively.
    if (AnyDescendantWasReparented(child, out_lca))
      result = true;
  }
  return result;
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
ClientTreeNode*
AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::ClientTreeNodeById(
    int32_t id) {
  std::unordered_map<int32_t, ClientTreeNode*>::iterator iter =
      client_id_map_.find(id);
  if (iter != client_id_map_.end())
    return iter->second;
  return nullptr;
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
ClientTreeNode*
AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::GetClientTreeNodeParent(
    ClientTreeNode* obj) {
  ClientTreeNode* parent = obj->parent;
#if DCHECK_IS_ON()
  if (!parent)
    return nullptr;
  DCHECK(ClientTreeNodeById(parent->id)) << "Parent not in id map.";
#endif  // DCHECK_IS_ON()
  return parent;
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
bool AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::SerializeChanges(
    AXSourceNode node,
    AXTreeUpdateBase<AXNodeData, AXTreeData>* out_update) {
  // Send the tree data if it's changed since the last update, or if
  // out_update->has_tree_data is already set to true.
  AXTreeData new_tree_data;
  if (tree_->GetTreeData(&new_tree_data) &&
      (out_update->has_tree_data || new_tree_data != client_tree_data_)) {
    out_update->has_tree_data = true;
    out_update->tree_data = new_tree_data;
    client_tree_data_ = new_tree_data;
  }

  // If the node isn't in the client tree, we need to serialize starting
  // with the LCA.
  AXSourceNode lca = LeastCommonAncestor(node);

  // This loop computes the least common ancestor that includes the old
  // and new parents of any nodes that have been reparented, and clears the
  // whole client subtree of that LCA if necessary. If we do end up clearing
  // any client nodes, keep looping because we have to search for more
  // nodes that may have been reparented from this new LCA.
  bool need_delete;
  do {
    need_delete = false;
    if (client_root_) {
      if (tree_->IsValid(lca)) {
        // Check for any reparenting within this subtree - if there is
        // any, we need to delete and reserialize the whole subtree
        // that contains the old and new parents of the reparented node.
        if (AnyDescendantWasReparented(lca, &lca))
          need_delete = true;
      }

      if (!tree_->IsValid(lca)) {
        // If there's no LCA, just tell the client to destroy the whole
        // tree and then we'll serialize everything from the new root.
        out_update->node_id_to_clear = client_root_->id;
        InternalReset();
      } else if (need_delete) {
        // Otherwise, if we need to reserialize a subtree, first we need
        // to delete those nodes in our client tree so that
        // SerializeChangedNodes() will be sure to send them again.
        out_update->node_id_to_clear = tree_->GetId(lca);
        ClientTreeNode* client_lca = ClientTreeNodeById(tree_->GetId(lca));
        CHECK(client_lca);
        DeleteDescendants(client_lca);
      }
    }
  } while (need_delete);

  // Serialize from the LCA, or from the root if there isn't one.
  if (!tree_->IsValid(lca))
    lca = tree_->GetRoot();

  if (!SerializeChangedNodes(lca, out_update))
    return false;

  // If we had a reset, ensure that the old tree is cleared before the client
  // unserializes this update. If we didn't do this, there's a chance that
  // treating this update as an incremental update could result in some
  // reparenting.
  if (did_reset_) {
    out_update->node_id_to_clear = tree_->GetId(lca);
    did_reset_ = false;
  }

  return true;
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
void AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::InvalidateSubtree(
    AXSourceNode node) {
  ClientTreeNode* client_node = ClientTreeNodeById(tree_->GetId(node));
  if (client_node)
    InvalidateClientSubtree(client_node);
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
bool AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::IsInClientTree(
    AXSourceNode node) {
  ClientTreeNode* client_node = ClientTreeNodeById(tree_->GetId(node));
  return client_node ? !client_node->invalid : false;
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
void AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::
    InvalidateClientSubtree(ClientTreeNode* client_node) {
  client_node->invalid = true;
  for (size_t i = 0; i < client_node->children.size(); ++i)
    InvalidateClientSubtree(client_node->children[i]);
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
void AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::
    DeleteClientSubtree(ClientTreeNode* client_node) {
  if (client_node == client_root_) {
    Reset();  // Do not try to reuse a bad root later.
  } else {
    DeleteDescendants(client_node);
    tree_->SerializerClearedNode(client_node->id);
    client_id_map_.erase(client_node->id);
    delete client_node;
  }
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
void AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::DeleteDescendants(
    ClientTreeNode* client_node) {
  for (size_t i = 0; i < client_node->children.size(); ++i)
    DeleteClientSubtree(client_node->children[i]);
  client_node->children.clear();
}

template <typename AXSourceNode, typename AXNodeData, typename AXTreeData>
bool AXTreeSerializer<AXSourceNode, AXNodeData, AXTreeData>::
    SerializeChangedNodes(
        AXSourceNode node,
        AXTreeUpdateBase<AXNodeData, AXTreeData>* out_update) {
  // This method has three responsibilities:
  // 1. Serialize |node| into an AXNodeData, and append it to
  //    the AXTreeUpdate to be sent to the client.
  // 2. Determine if |node| has any new children that the client doesn't
  //    know about yet, and call SerializeChangedNodes recursively on those.
  // 3. Update our internal data structure that keeps track of what nodes
  //    the client knows about.

  // First, find the ClientTreeNode for this id in our data structure where
  // we keep track of what accessibility objects the client already knows
  // about. If we don't find it, then this must be the new root of the
  // accessibility tree.
  int id = tree_->GetId(node);
  ClientTreeNode* client_node = ClientTreeNodeById(id);
  if (!client_node) {
    if (client_root_)
      Reset();
    client_root_ = new ClientTreeNode();
    client_node = client_root_;
    client_node->id = id;
    client_node->parent = nullptr;
    client_id_map_[client_node->id] = client_node;
  }

  // We're about to serialize it, so mark it as valid.
  client_node->invalid = false;
  client_node->ignored = tree_->IsIgnored(node);

  // Iterate over the ids of the children of |node|.
  // Create a set of the child ids so we can quickly look
  // up which children are new and which ones were there before.
  // If we've hit the maximum number of serialized nodes, pretend
  // this node has no children but keep going so that we get
  // consistent results.
  std::unordered_set<int32_t> new_ignored_ids;
  std::unordered_set<int32_t> new_child_ids;
  std::vector<AXSourceNode> children;
  if (max_node_count_ == 0 || out_update->nodes.size() < max_node_count_) {
    tree_->GetChildren(node, &children);
  } else if (max_node_count_ > 0) {
    static bool logged_once = false;
    if (!logged_once) {
      LOG(WARNING) << "Warning: not serializing AX nodes after a max of "
                   << max_node_count_;
      logged_once = true;
    }
  }
  for (size_t i = 0; i < children.size(); ++i) {
    AXSourceNode& child = children[i];
    int new_child_id = tree_->GetId(child);
    new_child_ids.insert(new_child_id);
    if (tree_->IsIgnored(child))
      new_ignored_ids.insert(new_child_id);

    // There shouldn't be any reparenting because we've already handled it
    // above. If this happens, reset and return an error.

    ClientTreeNode* client_child = ClientTreeNodeById(new_child_id);
    if (client_child && GetClientTreeNodeParent(client_child) != client_node) {
      DVLOG(1) << "Illegal reparenting detected";
#if defined(ADDRESS_SANITIZER)
      // Wrapping this in ADDRESS_SANITIZER will cause it to run on
      // clusterfuzz, which should help us narrow down the issue.
      // TODO(accessibility) Remove all cases where this occurs and re-add
      // NOTREACHED(). This condition leads to performance problems. It will
      // also reset virtual buffers, causing users to lose their place.
      NOTREACHED() << "Illegal reparenting detected: "
                   << "\nPassed-in parent: "
                   << tree_->GetDebugString(tree_->GetFromId(client_node->id))
                   << "\nChild: " << tree_->GetDebugString(child)
                   << "\nChild's parent: "
                   << tree_->GetDebugString(
                          tree_->GetFromId(client_child->parent->id))
                   << "\n-----------------------------------------\n\n\n";
#endif
      Reset();
      return false;
    }
  }

  // Go through the old children and delete subtrees for child
  // ids that are no longer present, and create a map from
  // id to ClientTreeNode for the rest. It's important to delete
  // first in a separate pass so that nodes that are reparented
  // don't end up children of two different parents in the middle
  // of an update, which can lead to a double-free.
  std::unordered_map<int32_t, ClientTreeNode*> client_child_id_map;
  std::vector<ClientTreeNode*> old_children;
  old_children.swap(client_node->children);
  for (size_t i = 0; i < old_children.size(); ++i) {
    ClientTreeNode* old_child = old_children[i];
    int old_child_id = old_child->id;
    if (new_child_ids.find(old_child_id) == new_child_ids.end()) {
      DeleteClientSubtree(old_child);
    } else {
      client_child_id_map[old_child_id] = old_child;
    }
  }

  // Serialize this node. This fills in all of the fields in
  // AXNodeData except child_ids, which we handle below.
  size_t serialized_node_index = out_update->nodes.size();
  out_update->nodes.push_back(AXNodeData());
  {
    // Take the address of an element in a vector only within a limited
    // scope because otherwise the pointer can become invalid if the
    // vector is resized.
    AXNodeData* serialized_node = &out_update->nodes[serialized_node_index];

    tree_->SerializeNode(node, serialized_node);
    if (serialized_node->id == client_root_->id)
      out_update->root_id = serialized_node->id;
  }

  // Iterate over the children, serialize them, and update the ClientTreeNode
  // data structure to reflect the new tree.
  std::vector<int32_t> actual_serialized_node_child_ids;
  client_node->children.reserve(children.size());
  for (size_t i = 0; i < children.size(); ++i) {
    AXSourceNode& child = children[i];
    int child_id = tree_->GetId(child);

    // Skip if the child isn't valid.
    if (!tree_->IsValid(child))
      continue;

    // Skip if the same child is included more than once.
    if (new_child_ids.find(child_id) == new_child_ids.end())
      continue;

    new_child_ids.erase(child_id);
    actual_serialized_node_child_ids.push_back(child_id);
    ClientTreeNode* reused_child = nullptr;
    if (client_child_id_map.find(child_id) != client_child_id_map.end())
      reused_child = ClientTreeNodeById(child_id);
    if (reused_child) {
      client_node->children.push_back(reused_child);
      const bool ignored_state_changed =
          reused_child->ignored !=
          (new_ignored_ids.find(reused_child->id) != new_ignored_ids.end());
      // Re-serialize it if the child is marked as invalid, otherwise
      // we don't have to because the client already has it.
      if (reused_child->invalid || ignored_state_changed) {
        if (!SerializeChangedNodes(child, out_update))
          return false;
      }
    } else {
      ClientTreeNode* new_child = new ClientTreeNode();
      new_child->id = child_id;
      new_child->parent = client_node;
      new_child->ignored = tree_->IsIgnored(child);
      new_child->invalid = false;
      client_node->children.push_back(new_child);
      DCHECK(!ClientTreeNodeById(child_id))
          << "Child id " << child_id << " already exists in map."
          << "\nChild is " << tree_->GetDebugString(tree_->GetFromId(child_id))
          << " of parent " << tree_->GetDebugString(node);
      client_id_map_[child_id] = new_child;
      if (!SerializeChangedNodes(child, out_update))
        return false;
    }
  }

  // Finally, update the child ids of this node to reflect the actual child
  // ids that were valid during serialization.
  out_update->nodes[serialized_node_index].child_ids.swap(
      actual_serialized_node_child_ids);

  return true;
}

}  // namespace ui

#endif  // UI_ACCESSIBILITY_AX_TREE_SERIALIZER_H_
