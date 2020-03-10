// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "rtree.h"

#include <list>

#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkBBHFactory.h"

namespace flutter {

RTree::RTree() : bbh_{SkRTreeFactory{}()}, all_ops_count_(0) {}

void RTree::insert(const SkRect boundsArray[],
                   const SkBBoxHierarchy::Metadata metadata[],
                   int N) {
  FML_DCHECK(0 == all_ops_count_);
  bbh_->insert(boundsArray, metadata, N);
  for (int i = 0; i < N; i++) {
    if (metadata != nullptr && metadata[i].isDraw) {
      draw_op_[i] = boundsArray[i];
    }
  }
  all_ops_count_ = N;
}

void RTree::insert(const SkRect boundsArray[], int N) {
  insert(boundsArray, nullptr, N);
}

void RTree::search(const SkRect& query, std::vector<int>* results) const {
  bbh_->search(query, results);
}

std::list<SkRect> RTree::searchNonOverlappingDrawnRects(
    const SkRect& query) const {
  // Get the indexes for the operations that intersect with the query rect.
  std::vector<int> intermediary_results;
  search(query, &intermediary_results);

  std::list<SkRect> final_results;
  for (int index : intermediary_results) {
    auto draw_op = draw_op_.find(index);
    // Ignore records that don't draw anything.
    if (draw_op == draw_op_.end()) {
      continue;
    }
    auto current_record_rect = draw_op->second;
    auto replaced_existing_rect = false;
    // // If the current record rect intersects with any of the rects in the
    // // result list, then join them, and update the rect in final_results.
    std::list<SkRect>::iterator curr_rect_itr = final_results.begin();
    std::list<SkRect>::iterator first_intersecting_rect_itr;
    while (!replaced_existing_rect && curr_rect_itr != final_results.end()) {
      if (SkRect::Intersects(*curr_rect_itr, current_record_rect)) {
        replaced_existing_rect = true;
        first_intersecting_rect_itr = curr_rect_itr;
        curr_rect_itr->join(current_record_rect);
      }
      curr_rect_itr++;
    }
    // It's possible that the result contains duplicated rects at this point.
    // For example, consider a result list that contains rects A, B. If a
    // new rect C is a superset of A and B, then A and B are the same set after
    // the merge. As a result, find such cases and remove them from the result
    // list.
    while (replaced_existing_rect && curr_rect_itr != final_results.end()) {
      if (SkRect::Intersects(*curr_rect_itr, *first_intersecting_rect_itr)) {
        first_intersecting_rect_itr->join(*curr_rect_itr);
        curr_rect_itr = final_results.erase(curr_rect_itr);
      } else {
        curr_rect_itr++;
      }
    }
    if (!replaced_existing_rect) {
      final_results.push_back(current_record_rect);
    }
  }
  return final_results;
}

size_t RTree::bytesUsed() const {
  return bbh_->bytesUsed();
}

RTreeFactory::RTreeFactory() {
  r_tree_ = sk_make_sp<RTree>();
}

sk_sp<RTree> RTreeFactory::getInstance() {
  return r_tree_;
}

sk_sp<SkBBoxHierarchy> RTreeFactory::operator()() const {
  return r_tree_;
}

}  // namespace flutter
