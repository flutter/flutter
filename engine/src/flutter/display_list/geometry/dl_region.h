// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_GEOMETRY_REGION_H_
#define FLUTTER_DISPLAY_LIST_GEOMETRY_REGION_H_

#include "third_party/skia/include/core/SkRect.h"

#include <vector>

namespace flutter {

/// Represents a region as a collection of non-overlapping rectangles.
/// Implements a subset of SkRegion functionality optimized for quickly
/// converting set of overlapping rectangles to non-overlapping rectangles.
class DlRegion {
 public:
  /// Creates region by bulk adding the rectangles./// Matches
  /// SkRegion::op(rect, SkRegion::kUnion_Op) behavior.
  explicit DlRegion(std::vector<SkIRect>&& rects);
  ~DlRegion();

  /// Returns list of non-overlapping rectangles that cover current region.
  /// If |deband| is false, each span line will result in separate rectangles,
  /// closely matching SkRegion::Iterator behavior.
  /// If |deband| is true, matching rectangles from adjacent span lines will be
  /// merged into single rectange.
  std::vector<SkIRect> getRects(bool deband = true) const;

 private:
  void addRects(std::vector<SkIRect>&& rects);

  struct Span {
    int32_t left;
    int32_t right;
  };
  typedef std::vector<Span> SpanVec;
  struct SpanLine {
    int32_t top;
    int32_t bottom;
    SpanVec* spans;

    void insertSpan(int32_t left, int32_t right);
    bool spansEqual(const SpanLine& l2) const;
  };

  typedef std::vector<SpanLine> LineVec;

  std::vector<SpanLine> lines_;
  std::vector<SpanVec*> spanvec_pool_;

  void insertLine(size_t position, SpanLine line);
  LineVec::iterator removeLine(LineVec::iterator position);

  SpanLine makeLine(int32_t top,
                    int32_t bottom,
                    int32_t spanLeft,
                    int32_t spanRight);
  SpanLine makeLine(int32_t top, int32_t bottom, const SpanVec& spans);
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_GEOMETRY_REGION_H_
