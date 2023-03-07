// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_UTILS_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_UTILS_H_

#include <optional>

#include "flutter/display_list/display_list_rtree.h"
#include "flutter/display_list/dl_op_receiver.h"
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

// A utility class that will ignore all DlOpReceiver methods relating
// to the setting of attributes.
class IgnoreAttributeDispatchHelper : public virtual DlOpReceiver {
 public:
  void setAntiAlias(bool aa) override {}
  void setDither(bool dither) override {}
  void setInvertColors(bool invert) override {}
  void setStrokeCap(DlStrokeCap cap) override {}
  void setStrokeJoin(DlStrokeJoin join) override {}
  void setStyle(DlDrawStyle style) override {}
  void setStrokeWidth(float width) override {}
  void setStrokeMiter(float limit) override {}
  void setColor(DlColor color) override {}
  void setBlendMode(DlBlendMode mode) override {}
  void setColorSource(const DlColorSource* source) override {}
  void setImageFilter(const DlImageFilter* filter) override {}
  void setColorFilter(const DlColorFilter* filter) override {}
  void setPathEffect(const DlPathEffect* effect) override {}
  void setMaskFilter(const DlMaskFilter* filter) override {}
};

// A utility class that will ignore all DlOpReceiver methods relating
// to setting a clip.
class IgnoreClipDispatchHelper : public virtual DlOpReceiver {
  void clipRect(const SkRect& rect,
                DlCanvas::ClipOp clip_op,
                bool is_aa) override {}
  void clipRRect(const SkRRect& rrect,
                 DlCanvas::ClipOp clip_op,
                 bool is_aa) override {}
  void clipPath(const SkPath& path,
                DlCanvas::ClipOp clip_op,
                bool is_aa) override {}
};

// A utility class that will ignore all DlOpReceiver methods relating
// to modifying the transform.
class IgnoreTransformDispatchHelper : public virtual DlOpReceiver {
 public:
  void translate(SkScalar tx, SkScalar ty) override {}
  void scale(SkScalar sx, SkScalar sy) override {}
  void rotate(SkScalar degrees) override {}
  void skew(SkScalar sx, SkScalar sy) override {}
  // clang-format off
  // 2x3 2D affine subset of a 4x4 transform in row major order
  void transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                         SkScalar myx, SkScalar myy, SkScalar myt) override {}
  // full 4x4 transform in row major order
  void transformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) override {}
  // clang-format on
  void transformReset() override {}
};

class IgnoreDrawDispatchHelper : public virtual DlOpReceiver {
 public:
  void save() override {}
  void saveLayer(const SkRect* bounds,
                 const SaveLayerOptions options,
                 const DlImageFilter* backdrop) override {}
  void restore() override {}
  void drawColor(DlColor color, DlBlendMode mode) override {}
  void drawPaint() override {}
  void drawLine(const SkPoint& p0, const SkPoint& p1) override {}
  void drawRect(const SkRect& rect) override {}
  void drawOval(const SkRect& bounds) override {}
  void drawCircle(const SkPoint& center, SkScalar radius) override {}
  void drawRRect(const SkRRect& rrect) override {}
  void drawDRRect(const SkRRect& outer, const SkRRect& inner) override {}
  void drawPath(const SkPath& path) override {}
  void drawArc(const SkRect& oval_bounds,
               SkScalar start_degrees,
               SkScalar sweep_degrees,
               bool use_center) override {}
  void drawPoints(DlCanvas::PointMode mode,
                  uint32_t count,
                  const SkPoint points[]) override {}
  void drawVertices(const DlVertices* vertices, DlBlendMode mode) override {}
  void drawImage(const sk_sp<DlImage> image,
                 const SkPoint point,
                 DlImageSampling sampling,
                 bool render_with_attributes) override {}
  void drawImageRect(const sk_sp<DlImage> image,
                     const SkRect& src,
                     const SkRect& dst,
                     DlImageSampling sampling,
                     bool render_with_attributes,
                     SrcRectConstraint constraint) override {}
  void drawImageNine(const sk_sp<DlImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     DlFilterMode filter,
                     bool render_with_attributes) override {}
  void drawAtlas(const sk_sp<DlImage> atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const DlColor colors[],
                 int count,
                 DlBlendMode mode,
                 DlImageSampling sampling,
                 const SkRect* cull_rect,
                 bool render_with_attributes) override {}
  void drawDisplayList(const sk_sp<DisplayList> display_list,
                       SkScalar opacity) override {}
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override {}
  void drawShadow(const SkPath& path,
                  const DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override {}
};

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

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_UTILS_H_
