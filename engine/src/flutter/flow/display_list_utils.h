// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_UTILS_H_
#define FLUTTER_FLOW_DISPLAY_LIST_UTILS_H_

#include "flutter/flow/display_list.h"

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
// SkMatrixTransformDispatchHelper:
//     Tracks the transform methods and maintains their state in a
//     (save/restore stack of) SkMatrix object.
// ClipBoundsDispatchHelper:
//     Tracks the clip methods and maintains a culling box in a
//     (save/restore stack of) SkRect culling rectangle.
//
// DisplayListBoundsCalculator:
//     A class that can traverse an entire display list and compute
//     a conservative estimate of the bounds of all of the rendering
//     operations.

namespace flutter {

// A utility class that will ignore all Dispatcher methods relating
// to the setting of attributes.
class IgnoreAttributeDispatchHelper : public virtual Dispatcher {
 public:
  void setAA(bool aa) override {}
  void setDither(bool dither) override {}
  void setInvertColors(bool invert) override {}
  void setCaps(SkPaint::Cap cap) override {}
  void setJoins(SkPaint::Join join) override {}
  void setDrawStyle(SkPaint::Style style) override {}
  void setStrokeWidth(SkScalar width) override {}
  void setMiterLimit(SkScalar limit) override {}
  void setColor(SkColor color) override {}
  void setBlendMode(SkBlendMode mode) override {}
  void setShader(sk_sp<SkShader> shader) override {}
  void setImageFilter(sk_sp<SkImageFilter> filter) override {}
  void setColorFilter(sk_sp<SkColorFilter> filter) override {}
  void setPathEffect(sk_sp<SkPathEffect> effect) override {}
  void setMaskFilter(sk_sp<SkMaskFilter> filter) override {}
  void setMaskBlurFilter(SkBlurStyle style, SkScalar sigma) override {}
};

// A utility class that will ignore all Dispatcher methods relating
// to setting a clip.
class IgnoreClipDispatchHelper : public virtual Dispatcher {
  void clipRect(const SkRect& rect, bool isAA, SkClipOp clip_op) override {}
  void clipRRect(const SkRRect& rrect, bool isAA, SkClipOp clip_op) override {}
  void clipPath(const SkPath& path, bool isAA, SkClipOp clip_op) override {}
};

// A utility class that will ignore all Dispatcher methods relating
// to modifying the transform.
class IgnoreTransformDispatchHelper : public virtual Dispatcher {
 public:
  void translate(SkScalar tx, SkScalar ty) override {}
  void scale(SkScalar sx, SkScalar sy) override {}
  void rotate(SkScalar degrees) override {}
  void skew(SkScalar sx, SkScalar sy) override {}
  void transform2x3(SkScalar mxx,
                    SkScalar mxy,
                    SkScalar mxt,
                    SkScalar myx,
                    SkScalar myy,
                    SkScalar myt) override {}
  void transform3x3(SkScalar mxx,
                    SkScalar mxy,
                    SkScalar mxt,
                    SkScalar myx,
                    SkScalar myy,
                    SkScalar myt,
                    SkScalar px,
                    SkScalar py,
                    SkScalar pt) override {}
};

// A utility class that will monitor the Dispatcher methods relating
// to the rendering attributes and accumulate them into an SkPaint
// which can be accessed at any time via paint().
class SkPaintDispatchHelper : public virtual Dispatcher {
 public:
  void setAA(bool aa) override;
  void setDither(bool dither) override;
  void setInvertColors(bool invert) override;
  void setCaps(SkPaint::Cap cap) override;
  void setJoins(SkPaint::Join join) override;
  void setDrawStyle(SkPaint::Style style) override;
  void setStrokeWidth(SkScalar width) override;
  void setMiterLimit(SkScalar limit) override;
  void setColor(SkColor color) override;
  void setBlendMode(SkBlendMode mode) override;
  void setShader(sk_sp<SkShader> shader) override;
  void setImageFilter(sk_sp<SkImageFilter> filter) override;
  void setColorFilter(sk_sp<SkColorFilter> filter) override;
  void setPathEffect(sk_sp<SkPathEffect> effect) override;
  void setMaskFilter(sk_sp<SkMaskFilter> filter) override;
  void setMaskBlurFilter(SkBlurStyle style, SkScalar sigma) override;

  const SkPaint& paint() { return paint_; }

 private:
  SkPaint paint_;
  bool invert_colors_ = false;
  sk_sp<SkColorFilter> color_filter_;

  sk_sp<SkColorFilter> makeColorFilter();
};

class SkMatrixSource {
 public:
  virtual const SkMatrix& matrix() const = 0;
};

// A utility class that will monitor the Dispatcher methods relating
// to the transform and accumulate them into an SkMatrix which can
// be accessed at any time via getMatrix().
//
// This class also implements an appropriate stack of transforms via
// its save() and restore() methods so those methods will need to be
// forwarded if overridden in more than one super class.
class SkMatrixDispatchHelper : public virtual Dispatcher,
                               public virtual SkMatrixSource {
 public:
  void translate(SkScalar tx, SkScalar ty) override;
  void scale(SkScalar sx, SkScalar sy) override;
  void rotate(SkScalar degrees) override;
  void skew(SkScalar sx, SkScalar sy) override;
  void transform2x3(SkScalar mxx,
                    SkScalar mxy,
                    SkScalar mxt,
                    SkScalar myx,
                    SkScalar myy,
                    SkScalar myt) override;
  void transform3x3(SkScalar mxx,
                    SkScalar mxy,
                    SkScalar mxt,
                    SkScalar myx,
                    SkScalar myy,
                    SkScalar myt,
                    SkScalar px,
                    SkScalar py,
                    SkScalar pt) override;

  void save() override;
  void restore() override;

  const SkMatrix& matrix() const override { return matrix_; }

 protected:
  void reset();

 private:
  SkMatrix matrix_;
  std::vector<SkMatrix> saved_;
};

// A utility class that will monitor the Dispatcher methods relating
// to the clip and accumulate a conservative bounds into an SkRect
// which can be accessed at any time via getCullingBounds().
//
// The subclass must implement a single virtual method matrix()
// which will happen automatically if the subclass also inherits
// from SkMatrixTransformDispatchHelper.
//
// This class also implements an appropriate stack of transforms via
// its save() and restore() methods so those methods will need to be
// forwarded if overridden in more than one super class.
class ClipBoundsDispatchHelper : public virtual Dispatcher,
                                 private virtual SkMatrixSource {
 public:
  void clipRect(const SkRect& rect, bool isAA, SkClipOp clip_op) override;
  void clipRRect(const SkRRect& rrect, bool isAA, SkClipOp clip_op) override;
  void clipPath(const SkPath& path, bool isAA, SkClipOp clip_op) override;

  void save() override;
  void restore() override;

  const SkRect& getCullingBounds() const { return bounds_; }

 private:
  SkRect bounds_;
  std::vector<SkRect> saved_;

  void intersect(const SkRect& clipBounds);
};

class BoundsAccumulator {
 public:
  void accumulate(const SkPoint& p) { accumulate(p.fX, p.fY); }
  void accumulate(SkScalar x, SkScalar y) {
    if (min_x_ > x)
      min_x_ = x;
    if (min_y_ > y)
      min_y_ = y;
    if (max_x_ < x)
      max_x_ = x;
    if (max_y_ < y)
      max_y_ = y;
  }
  void accumulate(const SkRect& r) {
    if (r.fLeft <= r.fRight && r.fTop <= r.fBottom) {
      accumulate(r.fLeft, r.fTop);
      accumulate(r.fRight, r.fBottom);
    }
  }

  bool isEmpty() const { return min_x_ >= max_x_ || min_y_ >= max_y_; }
  bool isNotEmpty() const { return min_x_ < max_x_ && min_y_ < max_y_; }

  SkRect getBounds() const {
    return (max_x_ > min_x_ && max_y_ > min_y_)
               ? SkRect::MakeLTRB(min_x_, min_y_, max_x_, max_y_)
               : SkRect::MakeEmpty();
  }

 private:
  SkScalar min_x_ = std::numeric_limits<SkScalar>::infinity();
  SkScalar min_y_ = std::numeric_limits<SkScalar>::infinity();
  SkScalar max_x_ = -std::numeric_limits<SkScalar>::infinity();
  SkScalar max_y_ = -std::numeric_limits<SkScalar>::infinity();
};

// This class implements all rendering methods and computes a liberal
// bounds of the rendering operations.
class DisplayListBoundsCalculator final
    : public virtual Dispatcher,
      public virtual SkPaintDispatchHelper,
      public virtual SkMatrixDispatchHelper,
      public virtual ClipBoundsDispatchHelper {
 public:
  // Construct a Calculator to determine the bounds of a list of
  // DisplayList dispatcher method calls. Since 2 of the method calls
  // have no intrinsic size because they render to the entire available,
  // the |cullRect| provides a bounds for them to include.
  DisplayListBoundsCalculator(const SkRect& cull_rect = SkRect::MakeEmpty())
      : accumulator_(&root_accumulator_), bounds_cull_(cull_rect) {}

  void saveLayer(const SkRect* bounds, bool with_paint) override;
  void save() override;
  void restore() override;

  void drawPaint() override;
  void drawColor(SkColor color, SkBlendMode mode) override;
  void drawLine(const SkPoint& p0, const SkPoint& p1) override;
  void drawRect(const SkRect& rect) override;
  void drawOval(const SkRect& bounds) override;
  void drawCircle(const SkPoint& center, SkScalar radius) override;
  void drawRRect(const SkRRect& rrect) override;
  void drawDRRect(const SkRRect& outer, const SkRRect& inner) override;
  void drawPath(const SkPath& path) override;
  void drawArc(const SkRect& bounds,
               SkScalar start,
               SkScalar sweep,
               bool useCenter) override;
  void drawPoints(SkCanvas::PointMode mode,
                  uint32_t count,
                  const SkPoint pts[]) override;
  void drawVertices(const sk_sp<SkVertices> vertices,
                    SkBlendMode mode) override;
  void drawImage(const sk_sp<SkImage> image,
                 const SkPoint point,
                 const SkSamplingOptions& sampling) override;
  void drawImageRect(const sk_sp<SkImage> image,
                     const SkRect& src,
                     const SkRect& dst,
                     const SkSamplingOptions& sampling,
                     SkCanvas::SrcRectConstraint constraint) override;
  void drawImageNine(const sk_sp<SkImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     SkFilterMode filter) override;
  void drawImageLattice(const sk_sp<SkImage> image,
                        const SkCanvas::Lattice& lattice,
                        const SkRect& dst,
                        SkFilterMode filter,
                        bool with_paint) override;
  void drawAtlas(const sk_sp<SkImage> atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const SkColor colors[],
                 int count,
                 SkBlendMode mode,
                 const SkSamplingOptions& sampling,
                 const SkRect* cullRect) override;
  void drawPicture(const sk_sp<SkPicture> picture,
                   const SkMatrix* matrix,
                   bool with_save_layer) override;
  void drawDisplayList(const sk_sp<DisplayList> display_list) override;
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override;
  void drawShadow(const SkPath& path,
                  const SkColor color,
                  const SkScalar elevation,
                  bool occludes,
                  SkScalar dpr) override;

  SkRect getBounds() { return accumulator_->getBounds(); }

 private:
  // current accumulator based on saveLayer history
  BoundsAccumulator* accumulator_;

  // Only used for drawColor and drawPaint and paint objects that
  // cannot support fast bounds.
  SkRect bounds_cull_;
  BoundsAccumulator root_accumulator_;

  class SaveInfo {
   public:
    SaveInfo(BoundsAccumulator* accumulator);
    virtual ~SaveInfo() = default;

    virtual BoundsAccumulator* save();
    virtual BoundsAccumulator* restore();

   protected:
    BoundsAccumulator* saved_accumulator_;
  };

  class SaveLayerInfo : public SaveInfo {
   public:
    SaveLayerInfo(BoundsAccumulator* accumulator, const SkMatrix& matrix);
    virtual ~SaveLayerInfo() = default;

    BoundsAccumulator* save() override;
    BoundsAccumulator* restore() override;

   protected:
    BoundsAccumulator layer_accumulator_;
    const SkMatrix matrix_;
  };

  class SaveLayerWithPaintInfo : public SaveLayerInfo {
   public:
    SaveLayerWithPaintInfo(DisplayListBoundsCalculator* calculator,
                           BoundsAccumulator* accumulator,
                           const SkMatrix& save_matrix,
                           const SkPaint& save_paint);
    virtual ~SaveLayerWithPaintInfo() = default;

    BoundsAccumulator* restore() override;

   protected:
    DisplayListBoundsCalculator* calculator_;

    SkPaint paint_;
  };

  std::vector<SaveInfo> saved_infos_;

  void accumulateRect(const SkRect& rect, bool force_stroke = false);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_UTILS_H_
