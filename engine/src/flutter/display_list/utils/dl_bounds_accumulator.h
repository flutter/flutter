// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_UTILS_DL_BOUNDS_ACCUMULATOR_H_
#define FLUTTER_DISPLAY_LIST_UTILS_DL_BOUNDS_ACCUMULATOR_H_

#include <functional>

#include "flutter/display_list/geometry/dl_rtree.h"
#include "flutter/fml/logging.h"

// This file contains various utility classes to ease implementing
// a Flutter DisplayList DlOpReceiver, including:
//
// IgnoreAttributeDispatchHelper:
// IgnoreClipDispatchHelper:
// IgnoreTransformDispatchHelper
//     Empty overrides of all of the associated methods of DlOpReceiver
//     for receivers that only track some of the rendering operations

namespace flutter {

enum class BoundsAccumulatorType {
  kRect,
  kRTree,
};

class BoundsAccumulator {
 public:
  /// function definition for modifying the bounds of a rectangle
  /// during a restore operation. The function is used primarily
  /// to account for the bounds impact of an ImageFilter on a
  /// saveLayer on a per-rect basis. The implementation may apply
  /// this function at whatever granularity it can manage easily
  /// (for example, a Rect accumulator might apply it to the entire
  /// local bounds being restored, whereas an RTree accumulator might
  /// apply it individually to each element in the local RTree).
  ///
  /// The function will do a best faith attempt at determining the
  /// modified bounds and store the results in the supplied |dest|
  /// rectangle and return true. If the function is unable to
  /// accurately determine the modifed bounds, it will set the
  /// |dest| rectangle to a copy of the input bounds (or a best
  /// guess) and return false to indicate that the bounds should not
  /// be trusted.
  typedef bool BoundsModifier(const SkRect& original, SkRect* dest);

  virtual ~BoundsAccumulator() = default;

  virtual void accumulate(const SkRect& r, int index = 0) = 0;

  /// Save aside the rects/bounds currently being accumulated and start
  /// accumulating a new set of rects/bounds. When restore is called,
  /// some additional modifications may be applied to these new bounds
  /// before they are accumulated back into the surrounding bounds.
  virtual void save() = 0;

  /// Restore to the previous accumulation and incorporate the bounds of
  /// the primitives that were recorded since the last save (if needed).
  virtual void restore() = 0;

  /// Restore the previous set of accumulation rects/bounds and accumulate
  /// the current rects/bounds that were accumulated since the most recent
  /// call to |save| into them with modifications specified by the |map|
  /// parameter and clipping to the clip parameter if it is not null.
  ///
  /// The indicated map function is applied to the various rects and bounds
  /// that have been accumulated in this save/restore cycle before they
  /// are then accumulated into the previous accumulations. The granularity
  /// of the application of the map function to the rectangles that were
  /// accumulated during the save period is left up to the implementation.
  ///
  /// This method will return true if the map function returned true on
  /// every single invocation. A false return value means that the
  /// bounds accumulated during this restore may not be trusted (as
  /// determined by the map function).
  ///
  /// If there are no saved accumulations to restore to, this method will
  /// NOP ignoring the map function and the optional clip entirely.
  virtual bool restore(
      std::function<bool(const SkRect& original, SkRect& modified)> map,
      const SkRect* clip = nullptr) = 0;

  virtual SkRect bounds() const = 0;

  virtual sk_sp<DlRTree> rtree() const = 0;

  virtual BoundsAccumulatorType type() const = 0;
};

class RectBoundsAccumulator final : public virtual BoundsAccumulator {
 public:
  void accumulate(SkScalar x, SkScalar y) { rect_.accumulate(x, y); }
  void accumulate(const SkPoint& p) { rect_.accumulate(p.fX, p.fY); }
  void accumulate(const SkRect& r, int index) override;

  bool is_empty() const { return rect_.is_empty(); }
  bool is_not_empty() const { return rect_.is_not_empty(); }

  void save() override;
  void restore() override;
  bool restore(std::function<bool(const SkRect&, SkRect&)> mapper,
               const SkRect* clip) override;

  SkRect bounds() const override {
    FML_DCHECK(saved_rects_.empty());
    return rect_.bounds();
  }

  BoundsAccumulatorType type() const override {
    return BoundsAccumulatorType::kRect;
  }

  sk_sp<DlRTree> rtree() const override { return nullptr; }

 private:
  class AccumulationRect {
   public:
    AccumulationRect();

    void accumulate(SkScalar x, SkScalar y);

    bool is_empty() const { return min_x_ >= max_x_ || min_y_ >= max_y_; }
    bool is_not_empty() const { return min_x_ < max_x_ && min_y_ < max_y_; }

    SkRect bounds() const;

   private:
    SkScalar min_x_;
    SkScalar min_y_;
    SkScalar max_x_;
    SkScalar max_y_;
  };

  void pop_and_accumulate(SkRect& layer_bounds, const SkRect* clip);

  AccumulationRect rect_;
  std::vector<AccumulationRect> saved_rects_;
};

class RTreeBoundsAccumulator final : public virtual BoundsAccumulator {
 public:
  void accumulate(const SkRect& r, int index) override;
  void save() override;
  void restore() override;

  bool restore(
      std::function<bool(const SkRect& original, SkRect& modified)> map,
      const SkRect* clip = nullptr) override;

  SkRect bounds() const override;

  sk_sp<DlRTree> rtree() const override;

  BoundsAccumulatorType type() const override {
    return BoundsAccumulatorType::kRTree;
  }

 private:
  std::vector<SkRect> rects_;
  std::vector<int> rect_indices_;
  std::vector<size_t> saved_offsets_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_UTILS_DL_BOUNDS_ACCUMULATOR_H_
