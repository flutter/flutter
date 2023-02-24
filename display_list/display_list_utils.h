// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_UTILS_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_UTILS_H_

#include <optional>

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_dispatcher.h"
#include "flutter/display_list/display_list_flags.h"
#include "flutter/display_list/display_list_rtree.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkMaskFilter.h"

// This file contains various utility classes to ease implementing
// a Flutter DisplayList Dispatcher, including:
//
// IgnoreAttributeDispatchHelper:
// IgnoreClipDispatchHelper:
// IgnoreTransformDispatchHelper
//     Empty overrides of all of the associated methods of Dispatcher
//     for dispatchers that only track some of the rendering operations
//
// SkPaintAttributeDispatchHelper:
//     Tracks the attribute methods and maintains their state in an
//     SkPaint object.

namespace flutter {

// A utility class that will ignore all Dispatcher methods relating
// to the setting of attributes.
class IgnoreAttributeDispatchHelper : public virtual Dispatcher {
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
  void setBlender(sk_sp<SkBlender> blender) override {}
  void setColorSource(const DlColorSource* source) override {}
  void setImageFilter(const DlImageFilter* filter) override {}
  void setColorFilter(const DlColorFilter* filter) override {}
  void setPathEffect(const DlPathEffect* effect) override {}
  void setMaskFilter(const DlMaskFilter* filter) override {}
};

// A utility class that will ignore all Dispatcher methods relating
// to setting a clip.
class IgnoreClipDispatchHelper : public virtual Dispatcher {
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

// A utility class that will ignore all Dispatcher methods relating
// to modifying the transform.
class IgnoreTransformDispatchHelper : public virtual Dispatcher {
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

class IgnoreDrawDispatchHelper : public virtual Dispatcher {
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
  void drawSkVertices(const sk_sp<SkVertices> vertices,
                      SkBlendMode mode) override {}
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
                     SkCanvas::SrcRectConstraint constraint) override {}
  void drawImageNine(const sk_sp<DlImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     DlFilterMode filter,
                     bool render_with_attributes) override {}
  void drawImageLattice(const sk_sp<DlImage> image,
                        const SkCanvas::Lattice& lattice,
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
  void drawPicture(const sk_sp<SkPicture> picture,
                   const SkMatrix* matrix,
                   bool render_with_attributes) override {}
  void drawDisplayList(const sk_sp<DisplayList> display_list) override {}
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override {}
  void drawShadow(const SkPath& path,
                  const DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override {}
};

// A utility class that will monitor the Dispatcher methods relating
// to the rendering attributes and accumulate them into an SkPaint
// which can be accessed at any time via paint().
class SkPaintDispatchHelper : public virtual Dispatcher {
 public:
  SkPaintDispatchHelper(SkScalar opacity = SK_Scalar1)
      : current_color_(SK_ColorBLACK), opacity_(opacity) {
    if (opacity < SK_Scalar1) {
      paint_.setAlphaf(opacity);
    }
  }

  void setAntiAlias(bool aa) override;
  void setDither(bool dither) override;
  void setStyle(DlDrawStyle style) override;
  void setColor(DlColor color) override;
  void setStrokeWidth(SkScalar width) override;
  void setStrokeMiter(SkScalar limit) override;
  void setStrokeCap(DlStrokeCap cap) override;
  void setStrokeJoin(DlStrokeJoin join) override;
  void setColorSource(const DlColorSource* source) override;
  void setColorFilter(const DlColorFilter* filter) override;
  void setInvertColors(bool invert) override;
  void setBlendMode(DlBlendMode mode) override;
  void setBlender(sk_sp<SkBlender> blender) override;
  void setPathEffect(const DlPathEffect* effect) override;
  void setMaskFilter(const DlMaskFilter* filter) override;
  void setImageFilter(const DlImageFilter* filter) override;

  const SkPaint& paint() { return paint_; }

  /// Returns the current opacity attribute which is used to reduce
  /// the alpha of all setColor calls encountered in the streeam
  SkScalar opacity() { return opacity_; }
  /// Returns the combined opacity that includes both the current
  /// opacity attribute and the alpha of the most recent color.
  /// The most recently set color will have combined the two and
  /// stored the combined value in the alpha of the paint.
  SkScalar combined_opacity() { return paint_.getAlphaf(); }
  /// Returns true iff the current opacity attribute is not opaque,
  /// irrespective of the alpha of the current color
  bool has_opacity() { return opacity_ < SK_Scalar1; }

 protected:
  void save_opacity(SkScalar opacity_for_children);
  void restore_opacity();

 private:
  SkPaint paint_;
  bool invert_colors_ = false;
  std::shared_ptr<const DlColorFilter> color_filter_;

  sk_sp<SkColorFilter> makeColorFilter() const;

  struct SaveInfo {
    SaveInfo(SkScalar opacity) : opacity(opacity) {}

    SkScalar opacity;
  };
  std::vector<SaveInfo> save_stack_;

  void set_opacity(SkScalar opacity) {
    if (opacity_ != opacity) {
      opacity_ = opacity;
      setColor(current_color_);
    }
  }

  SkColor current_color_;
  SkScalar opacity_;
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
