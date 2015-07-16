// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Defines a hierarchical bounding rectangle data structure for Rect objects,
// associated with a generic unique key K for efficient spatial queries. The
// R*-tree algorithm is used to build the trees. Based on the papers:
//
// A Guttman 'R-trees:  a dynamic index structure for spatial searching', Proc
// ACM SIGMOD Int Conf on Management of Data, 47-57, 1984
//
// N Beckmann, H-P Kriegel, R Schneider, B Seeger 'The R*-tree: an efficient and
// robust access method for points and rectangles', Proc ACM SIGMOD Int Conf on
// Management of Data, 322-331, 1990

#ifndef UI_GFX_GEOMETRY_R_TREE_H_
#define UI_GFX_GEOMETRY_R_TREE_H_

#include "r_tree_base.h"

namespace gfx {

template <typename Key>
class RTree : public RTreeBase {
 public:
  typedef base::hash_set<Key> Matches;

  // RTrees organize pairs of keys and rectangles in a hierarchical bounding
  // box structure. This allows for queries of the tree within logarithmic time.
  // |min_children| and |max_children| allows for adjustment of the average size
  // of the nodes within RTree, which adjusts the base of the logarithm in the
  // algorithm runtime. Some parts of insertion and deletion are polynomial
  // in the size of the individual node, so the trade-off with larger nodes is
  // potentially faster queries but slower insertions and deletions. Generally
  // it is worth considering how much overlap between rectangles of different
  // keys will occur in the tree, and trying to set |max_children| as a
  // reasonable upper bound to the number of overlapping rectangles expected.
  // Then |min_children| can bet set to a quantity slightly less than half of
  // that.
  RTree(size_t min_children, size_t max_children);
  ~RTree();

  // Insert a new rect into the tree, associated with provided key. Note that if
  // |rect| is empty, the |key| will not actually be inserted. Duplicate keys
  // overwrite old entries.
  void Insert(const Rect& rect, Key key);

  // If present, remove the supplied |key| from the tree.
  void Remove(Key key);

  // Fills |matches_out| with all keys having bounding rects intersecting
  // |query_rect|.
  void AppendIntersectingRecords(const Rect& query_rect,
                                 Matches* matches_out) const;

  void Clear();

 private:
  friend class RTreeTest;
  friend class RTreeNodeTest;

  class Record : public RecordBase {
   public:
    Record(const Rect& rect, const Key& key);
    virtual ~Record();
    const Key& key() const { return key_; }

   private:
    Key key_;

    DISALLOW_COPY_AND_ASSIGN(Record);
  };

  // A map of supplied keys to their Node representation within the RTree, for
  // efficient retrieval of keys without requiring a bounding rect.
  typedef base::hash_map<Key, Record*> RecordMap;
  RecordMap record_map_;

  DISALLOW_COPY_AND_ASSIGN(RTree);
};

template <typename Key>
RTree<Key>::RTree(size_t min_children, size_t max_children)
    : RTreeBase(min_children, max_children) {
}

template <typename Key>
RTree<Key>::~RTree() {
}

template <typename Key>
void RTree<Key>::Insert(const Rect& rect, Key key) {
  scoped_ptr<NodeBase> record;
  // Check if this key is already present in the tree.
  typename RecordMap::iterator it(record_map_.find(key));

  if (it != record_map_.end()) {
    // We will re-use this node structure, regardless of re-insert or return.
    Record* existing_record = it->second;
    // If the new rect and the current rect are identical we can skip the rest
    // of Insert() as nothing has changed.
    if (existing_record->rect() == rect)
      return;

    // Remove the node from the tree in its current position.
    record = RemoveNode(existing_record);

    PruneRootIfNecessary();

    // If we are replacing this key with an empty rectangle we just remove the
    // old node from the list and return, thus preventing insertion of empty
    // rectangles into our spatial database.
    if (rect.IsEmpty()) {
      record_map_.erase(it);
      return;
    }

    // Reset the rectangle to the new value.
    record->set_rect(rect);
  } else {
    if (rect.IsEmpty())
      return;

    record.reset(new Record(rect, key));
    record_map_.insert(std::make_pair(key, static_cast<Record*>(record.get())));
  }

  int highest_reinsert_level = -1;
  InsertNode(record.Pass(), &highest_reinsert_level);
}

template <typename Key>
void RTree<Key>::Clear() {
  record_map_.clear();
  ResetRoot();
}

template <typename Key>
void RTree<Key>::Remove(Key key) {
  // Search the map for the leaf parent that has the provided record.
  typename RecordMap::iterator it = record_map_.find(key);
  if (it == record_map_.end())
    return;

  Record* record = it->second;
  record_map_.erase(it);
  RemoveNode(record);

  // Lastly check the root. If it has only one non-leaf child, delete it and
  // replace it with its child.
  PruneRootIfNecessary();
}

template <typename Key>
void RTree<Key>::AppendIntersectingRecords(
      const Rect& query_rect, Matches* matches_out) const {
  RTreeBase::Records matching_records;
  root()->AppendIntersectingRecords(query_rect, &matching_records);
  for (RTreeBase::Records::const_iterator it = matching_records.begin();
       it != matching_records.end();
       ++it) {
    const Record* record = static_cast<const Record*>(*it);
    matches_out->insert(record->key());
  }
}


// RTree::Record --------------------------------------------------------------

template <typename Key>
RTree<Key>::Record::Record(const Rect& rect, const Key& key)
    : RecordBase(rect),
      key_(key) {
}

template <typename Key>
RTree<Key>::Record::~Record() {
}

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_R_TREE_H_
