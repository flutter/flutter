// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Provides an implementation the parts of the RTree data structure that don't
// require knowledge of the generic key type. Don't use these objects directly,
// rather specialize the RTree<> object in r_tree.h. This file defines the
// internal objects of an RTree, namely Nodes (internal nodes of the tree) and
// Records, which hold (key, rectangle) pairs.

#ifndef UI_GFX_GEOMETRY_R_TREE_BASE_H_
#define UI_GFX_GEOMETRY_R_TREE_BASE_H_

#include <list>
#include <vector>

#include "base/containers/hash_tables.h"
#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/scoped_vector.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

class GFX_EXPORT RTreeBase {
 protected:
  class NodeBase;
  class RecordBase;

  typedef std::vector<const RecordBase*> Records;
  typedef ScopedVector<NodeBase> Nodes;

  RTreeBase(size_t min_children, size_t max_children);
  ~RTreeBase();

  // Protected data structure class for storing internal Nodes or leaves with
  // Records.
  class GFX_EXPORT NodeBase {
   public:
    virtual ~NodeBase();

    // Appends to |records_out| the set of Records in this subtree with rects
    // that intersect |query_rect|.  Avoids clearing |records_out| so that it
    // can be called recursively.
    virtual void AppendIntersectingRecords(const Rect& query_rect,
                                           Records* records_out) const = 0;

    // Returns all records stored in the subtree rooted at this node. Appends to
    // |matches_out| without clearing.
    virtual void AppendAllRecords(Records* records_out) const = 0;

    // Returns NULL if no children. Does not recompute bounds.
    virtual scoped_ptr<NodeBase> RemoveAndReturnLastChild() = 0;

    // Returns -1 for Records, or the height of this subtree for Nodes.  The
    // height of a leaf Node (a Node containing only Records) is 0, a leaf's
    // parent is 1, etc. Note that in an R*-Tree, all branches from the root
    // Node will be the same height.
    virtual int Level() const = 0;

    // Recomputes our bounds by taking the union of all child rects, then calls
    // recursively on our parent so that ultimately all nodes up to the root
    // recompute their bounds.
    void RecomputeBoundsUpToRoot();

    NodeBase* parent() { return parent_; }
    const NodeBase* parent() const { return parent_; }
    void set_parent(NodeBase* parent) { parent_ = parent; }
    const Rect& rect() const { return rect_; }
    void set_rect(const Rect& rect) { rect_ = rect; }

   protected:
    NodeBase(const Rect& rect, NodeBase* parent);

    // Bounds recomputation without calling parents to do the same.
    virtual void RecomputeLocalBounds();

   private:
    friend class RTreeTest;
    friend class RTreeNodeTest;

    // This Node's bounding rectangle.
    Rect rect_;

    // A weak pointer to our parent Node in the RTree. The root node will have a
    // NULL value for |parent_|.
    NodeBase* parent_;

    DISALLOW_COPY_AND_ASSIGN(NodeBase);
  };

  class GFX_EXPORT RecordBase : public NodeBase {
   public:
    explicit RecordBase(const Rect& rect);
    ~RecordBase() override;

    void AppendIntersectingRecords(const Rect& query_rect,
                                   Records* records_out) const override;
    void AppendAllRecords(Records* records_out) const override;
    scoped_ptr<NodeBase> RemoveAndReturnLastChild() override;
    int Level() const override;

   private:
    friend class RTreeTest;
    friend class RTreeNodeTest;

    DISALLOW_COPY_AND_ASSIGN(RecordBase);
  };

  class GFX_EXPORT Node : public NodeBase {
   public:
    // Constructs an empty Node with |level_| of 0.
    Node();
    ~Node() override;

    void AppendIntersectingRecords(const Rect& query_rect,
                                   Records* records_out) const override;
    scoped_ptr<NodeBase> RemoveAndReturnLastChild() override;
    int Level() const override;
    void AppendAllRecords(Records* matches_out) const override;

    // Constructs a new Node that is the parent of this Node and already has
    // this Node as its sole child. Valid to call only on root Nodes, meaning
    // Nodes with |parent_| NULL. Note that ownership of this Node is
    // transferred to the parent returned by this function.
    scoped_ptr<Node> ConstructParent();

    // Removes |number_to_remove| children from this Node, and appends them to
    // the supplied list. Does not repair bounds upon completion. Nodes are
    // selected in the manner suggested in the Beckmann et al. paper, which
    // suggests that the children should be sorted by the distance from the
    // center of their bounding rectangle to their parent's bounding rectangle,
    // and then the n closest children should be removed for re-insertion. This
    // removal occurs at most once on each level of the tree when overflowing
    // nodes that have exceeded the maximum number of children during an Insert.
    void RemoveNodesForReinsert(size_t number_to_remove, Nodes* nodes);

    // Given a pointer to a child node within this Node, removes it from our
    // list. If that child had any children, appends them to the supplied orphan
    // list. Returns the removed child. Does not recompute bounds, as the caller
    // might subsequently remove this node as well, meaning the recomputation
    // would be wasted work.
    scoped_ptr<NodeBase> RemoveChild(NodeBase* child_node, Nodes* orphans);

    // Returns the best parent for insertion of the provided |node| as a child.
    Node* ChooseSubtree(NodeBase* node);

    // Adds |node| as a child of this Node, and recomputes the bounds of this
    // node after the addition of the child. Returns the new count of children
    // stored in this Node. This node becomes the owner of |node|.
    size_t AddChild(scoped_ptr<NodeBase> node);

    // Returns a sibling to this Node with at least min_children and no greater
    // than max_children of this Node's children assigned to it, and having the
    // same parent. Bounds will be valid on both Nodes after this call.
    scoped_ptr<NodeBase> Split(size_t min_children, size_t max_children);

    size_t count() const { return children_.size(); }
    const NodeBase* child(size_t i) const { return children_[i]; }
    NodeBase* child(size_t i) { return children_[i]; }

   private:
    typedef std::vector<Rect> Rects;

    explicit Node(int level);

    // Given two arrays of bounds rectangles as computed by BuildLowBounds()
    // and BuildHighBounds(), returns the index of the element in those arrays
    // along which a split of the arrays would result in a minimum amount of
    // overlap (area of intersection) in the two groups.
    static size_t ChooseSplitIndex(size_t start_index,
                                   size_t end_index,
                                   const Rects& low_bounds,
                                   const Rects& high_bounds);

    // R*-Tree attempts to keep groups of rectangles that are roughly square
    // in shape. It does this by comparing the "margins" of different bounding
    // boxes, where margin is defined as the sum of the length of all four sides
    // of a rectangle. For two rectangles of equal area, the one with the
    // smallest margin will be the rectangle whose width and height differ the
    // least. When splitting we decide to split along an axis chosen from the
    // rectangles either sorted vertically or horizontally by finding the axis
    // that would result in the smallest sum of margins between the two bounding
    // boxes of the resulting split. Returns the smallest sum computed given the
    // sorted bounding boxes and a range to look within.
    static int SmallestMarginSum(size_t start_index,
                                 size_t end_index,
                                 const Rects& low_bounds,
                                 const Rects& high_bounds);

    // Sorts nodes primarily by increasing y coordinates, and secondarily by
    // increasing height.
    static bool CompareVertical(const NodeBase* a, const NodeBase* b);

    // Sorts nodes primarily by increasing x coordinates, and secondarily by
    // increasing width.
    static bool CompareHorizontal(const NodeBase* a, const NodeBase* b);

    // Sorts nodes by the distance of the center of their rectangles to the
    // center of their parent's rectangles.
    static bool CompareCenterDistanceFromParent(
        const NodeBase* a, const NodeBase* b);

    // Given two vectors of Nodes sorted by vertical or horizontal bounds,
    // populates two vectors of Rectangles in which the ith element is the union
    // of all bounding rectangles [0,i] in the associated sorted array of Nodes.
    static void BuildLowBounds(const std::vector<NodeBase*>& vertical_sort,
                               const std::vector<NodeBase*>& horizontal_sort,
                               Rects* vertical_bounds,
                               Rects* horizontal_bounds);

    // Given two vectors of Nodes sorted by vertical or horizontal bounds,
    // populates two vectors of Rectangles in which the ith element is the
    // union of all bounding rectangles [i, count()) in the associated sorted
    // array of Nodes.
    static void BuildHighBounds(const std::vector<NodeBase*>& vertical_sort,
                                const std::vector<NodeBase*>& horizontal_sort,
                                Rects* vertical_bounds,
                                Rects* horizontal_bounds);

    void RecomputeLocalBounds() override;

    // Returns the increase in overlap value, as defined in Beckmann et al. as
    // the sum of the areas of the intersection of all child rectangles
    // (excepting the candidate child) with the argument rectangle. Here the
    // |candidate_node| is one of our |children_|, and |expanded_rect| is the
    // already-computed union of the candidate's rect and |rect|.
    int OverlapIncreaseToAdd(const Rect& rect,
                             const NodeBase* candidate_node,
                             const Rect& expanded_rect) const;

    // Returns a new node containing children [split_index, count()) within
    // |sorted_children|.  Children before |split_index| remain with |this|.
    scoped_ptr<NodeBase> DivideChildren(
        const Rects& low_bounds,
        const Rects& high_bounds,
        const std::vector<NodeBase*>& sorted_children,
        size_t split_index);

    // Returns a pointer to the child node that will result in the least overlap
    // increase with the addition of node_rect, or NULL if there's a tie found.
    // Requires a precomputed vector of expanded rectangles where the ith
    // rectangle in the vector is the union of |children_|[i] and node_rect.
    // Overlap is defined in Beckmann et al. as the sum of the areas of
    // intersection of all child rectangles with the |node_rect| argument
    // rectangle.  This heuristic attempts to choose the node for which adding
    // the new rectangle to their bounding box will result in the least overlap
    // with the other rectangles, thus trying to preserve the usefulness of the
    // bounding rectangle by keeping it from covering too much redundant area.
    Node* LeastOverlapIncrease(const Rect& node_rect,
                               const Rects& expanded_rects);

    // Returns a pointer to the child node that will result in the least area
    // enlargement if the argument node rectangle were to be added to that
    // node's bounding box. Requires a precomputed vector of expanded rectangles
    // where the ith rectangle in the vector is the union of children_[i] and
    // |node_rect|.
    Node* LeastAreaEnlargement(const Rect& node_rect,
                               const Rects& expanded_rects);

    const int level_;

    Nodes children_;

    friend class RTreeTest;
    friend class RTreeNodeTest;

    DISALLOW_COPY_AND_ASSIGN(Node);
  };

  // Inserts |node| into the tree. The |highest_reinsert_level| supports
  // re-insertion as described by Beckmann et al. As Node overflows progagate
  // up the tree the algorithm performs a reinsertion of the overflow Nodes
  // (instead of a split) at most once per level of the tree. A starting value
  // of -1 for |highest_reinsert_level| means that reinserts are permitted for
  // every level of the tree. This should always be set to -1 except by
  // recursive calls from within InsertNode().
  void InsertNode(scoped_ptr<NodeBase> node, int* highest_reinsert_level);

  // Removes |node| from the tree without deleting it.
  scoped_ptr<NodeBase> RemoveNode(NodeBase* node);

  // If |root_| has only one child, deletes the |root_| Node and replaces it
  // with its only descendant child. Otherwise does nothing.
  void PruneRootIfNecessary();

  // Deletes the entire current tree and replaces it with an empty Node.
  void ResetRoot();

  const Node* root() const { return root_.get(); }

 private:
  friend class RTreeTest;
  friend class RTreeNodeTest;

  // A pointer to the root node in the RTree.
  scoped_ptr<Node> root_;

  // The parameters used to define the shape of the RTree.
  const size_t min_children_;
  const size_t max_children_;

  DISALLOW_COPY_AND_ASSIGN(RTreeBase);
};

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_R_TREE_BASE_H_
