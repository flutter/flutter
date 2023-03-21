// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_GEOMETRY_DL_RTREE_H_
#define FLUTTER_DISPLAY_LIST_GEOMETRY_DL_RTREE_H_

#include <list>
#include <vector>

#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkRefCnt.h"

namespace flutter {

/// An R-Tree that stores a list of bounding rectangles with optional
/// associated IDs.
///
/// The R-Tree can be searched in one of two ways:
/// - Query for a list of hits among the original rectangles
///   @see |search|
/// - Query for a set of non-overlapping rectangles that are joined
///   from the original rectangles that intersect a query rect
///   @see |searchAndConsolidateRects|
class DlRTree : public SkRefCnt {
 private:
  static constexpr int kMaxChildren = 11;

  // Leaf nodes at start of vector have an ID,
  // Internal nodes after that have child index and count.
  struct Node {
    SkRect bounds;
    union {
      struct {
        uint32_t index;
        uint32_t count;
      } child;
      int id;
    };
  };

 public:
  /// Construct an R-Tree from the list of rectangles respecting the
  /// order in which they appear in the list. An optional array of
  /// IDs can be provided to tag each rectangle with information needed
  /// by the caller as well as an optional predicate that can filter
  /// out rectangles with IDs that should not be stored in the R-Tree.
  ///
  /// If an array of IDs is not specified then all leaf nodes will be
  /// represented by the |invalid_id| (which defaults to -1).
  ///
  /// Invallid rects that are empty or contain a NaN value will not be
  /// stored in the R-Tree. And, if a |predicate| function is provided,
  /// that function will be called to query if the rectangle associated
  /// with the ID should be included.
  ///
  /// Duplicate rectangles and IDs are allowed and not processed in any
  /// way except to eliminate invalid rectangles and IDs that are rejected
  /// by the optional predicate function.
  DlRTree(
      const SkRect rects[],
      int N,
      const int ids[] = nullptr,
      bool predicate(int id) = [](int) { return true; },
      int invalid_id = -1);

  /// Search the rectangles and return a vector of leaf node indices for
  /// rectangles that intersect the query.
  ///
  /// Note that the indices are internal indices of the stored data
  /// and not the index of the rectangles or ids in the constructor.
  /// The returned indices may not themselves be in numerical order,
  /// but they will represent the rectangles and IDs in the order in
  /// which they were passed into the constructor. The actual rectangle
  /// and ID associated with each index can be retreived using the
  /// |DlRTree::id| and |DlRTree::bouds| methods.
  void search(const SkRect& query, std::vector<int>* results) const;

  /// Return the ID for the indicated result of a query or
  /// invalid_id if the index is not a valid leaf node index.
  int id(int result_index) const {
    return (result_index >= 0 && result_index < leaf_count_)
               ? nodes_[result_index].id
               : invalid_id_;
  }

  /// Return the rectangle bounds for the indicated result of a query
  /// or an empty rect if the index is not a valid leaf node index.
  const SkRect& bounds(int result_index) const {
    return (result_index >= 0 && result_index < leaf_count_)
               ? nodes_[result_index].bounds
               : empty_;
  }

  /// Returns the bytes used by the object and all of its node data.
  size_t bytes_used() const {
    return sizeof(DlRTree) + sizeof(Node) * nodes_.size();
  }

  /// Returns the number of leaf nodes corresponding to non-empty
  /// rectangles that were passed in the constructor and not filtered
  /// out by the predicate.
  int leaf_count() const { return leaf_count_; }

  /// Return the total number of nodes used in the R-Tree, both leaf
  /// and internal consolidation nodes.
  int node_count() const { return nodes_.size(); }

  /// Finds the rects in the tree that intersect with the query rect.
  ///
  /// When two matching query results intersect with each other, they are
  /// joined into a single rect which also intersects with the query rect.
  /// In other words, the bounds of each rect in the result list are mutually
  /// exclusive.
  std::list<SkRect> searchAndConsolidateRects(const SkRect& query) const;

 private:
  static constexpr SkRect empty_ = SkRect::MakeEmpty();

  void search(const Node& parent,
              const SkRect& query,
              std::vector<int>* results) const;

  std::vector<Node> nodes_;
  int leaf_count_;
  int invalid_id_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_GEOMETRY_DL_RTREE_H_
