// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DL_CANVAS_H_
#define FLUTTER_DISPLAY_LIST_DL_CANVAS_H_

#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_image.h"
#include "flutter/display_list/display_list_paint.h"
#include "flutter/display_list/display_list_vertices.h"

namespace flutter {

// The primary class used to express rendering operations in the
// DisplayList ecosystem. This class is an API-only virtual class and
// can be used to talk to a DisplayListBuilder to record a series of
// rendering operations, or it could be the public facing API of an
// adapter that forwards the calls to another rendering module, like
// Skia.
//
// Developers familiar with Skia's SkCanvas API will be immediately
// familiar with the methods below as they follow that API closely
// but with DisplayList objects and values used as data instead.
class DlCanvas {
 public:
  enum class ClipOp {
    kDifference,
    kIntersect,
  };

  enum class PointMode {
    kPoints,   //!< draw each point separately
    kLines,    //!< draw each separate pair of points as a line segment
    kPolygon,  //!< draw each pair of overlapping points as a line segment
  };

  virtual ~DlCanvas() = default;

  virtual SkISize GetBaseLayerSize() const = 0;
  virtual SkImageInfo GetImageInfo() const = 0;

  virtual void Save() = 0;
  virtual void SaveLayer(const SkRect* bounds,
                         const DlPaint* paint = nullptr,
                         const DlImageFilter* backdrop = nullptr) = 0;
  virtual void Restore() = 0;
  virtual int GetSaveCount() const = 0;
  virtual void RestoreToCount(int restore_count) = 0;

  virtual void Translate(SkScalar tx, SkScalar ty) = 0;
  virtual void Scale(SkScalar sx, SkScalar sy) = 0;
  virtual void Rotate(SkScalar degrees) = 0;
  virtual void Skew(SkScalar sx, SkScalar sy) = 0;

  // clang-format off

  // 2x3 2D affine subset of a 4x4 transform in row major order
  virtual void Transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                                 SkScalar myx, SkScalar myy, SkScalar myt) = 0;
  // full 4x4 transform in row major order
  virtual void TransformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) = 0;
  // clang-format on
  virtual void TransformReset() = 0;
  virtual void Transform(const SkMatrix* matrix) = 0;
  virtual void Transform(const SkM44* matrix44) = 0;
  virtual void Transform(const SkMatrix& matrix) { Transform(&matrix); }
  virtual void Transform(const SkM44& matrix44) { Transform(&matrix44); }
  virtual void SetTransform(const SkMatrix* matrix) = 0;
  virtual void SetTransform(const SkM44* matrix44) = 0;
  virtual void SetTransform(const SkMatrix& matrix) { SetTransform(&matrix); }
  virtual void SetTransform(const SkM44& matrix44) { SetTransform(&matrix44); }

  /// Returns the 4x4 full perspective transform representing all transform
  /// operations executed so far in this DisplayList within the enclosing
  /// save stack.
  virtual SkM44 GetTransformFullPerspective() const = 0;
  /// Returns the 3x3 partial perspective transform representing all transform
  /// operations executed so far in this DisplayList within the enclosing
  /// save stack.
  virtual SkMatrix GetTransform() const = 0;

  virtual void ClipRect(const SkRect& rect,
                        ClipOp clip_op = ClipOp::kIntersect,
                        bool is_aa = false) = 0;
  virtual void ClipRRect(const SkRRect& rrect,
                         ClipOp clip_op = ClipOp::kIntersect,
                         bool is_aa = false) = 0;
  virtual void ClipPath(const SkPath& path,
                        ClipOp clip_op = ClipOp::kIntersect,
                        bool is_aa = false) = 0;

  /// Conservative estimate of the bounds of all outstanding clip operations
  /// measured in the coordinate space within which this DisplayList will
  /// be rendered.
  virtual SkRect GetDestinationClipBounds() const = 0;
  /// Conservative estimate of the bounds of all outstanding clip operations
  /// transformed into the local coordinate space in which currently
  /// recorded rendering operations are interpreted.
  virtual SkRect GetLocalClipBounds() const = 0;

  /// Return true iff the supplied bounds are easily shown to be outside
  /// of the current clip bounds. This method may conservatively return
  /// false if it cannot make the determination.
  virtual bool QuickReject(const SkRect& bounds) const = 0;

  virtual void DrawPaint(const DlPaint& paint) = 0;
  virtual void DrawColor(DlColor color, DlBlendMode mode) = 0;
  void Clear(DlColor color) { DrawColor(color, DlBlendMode::kSrc); }
  virtual void DrawLine(const SkPoint& p0,
                        const SkPoint& p1,
                        const DlPaint& paint) = 0;
  virtual void DrawRect(const SkRect& rect, const DlPaint& paint) = 0;
  virtual void DrawOval(const SkRect& bounds, const DlPaint& paint) = 0;
  virtual void DrawCircle(const SkPoint& center,
                          SkScalar radius,
                          const DlPaint& paint) = 0;
  virtual void DrawRRect(const SkRRect& rrect, const DlPaint& paint) = 0;
  virtual void DrawDRRect(const SkRRect& outer,
                          const SkRRect& inner,
                          const DlPaint& paint) = 0;
  virtual void DrawPath(const SkPath& path, const DlPaint& paint) = 0;
  virtual void DrawArc(const SkRect& bounds,
                       SkScalar start,
                       SkScalar sweep,
                       bool useCenter,
                       const DlPaint& paint) = 0;
  virtual void DrawPoints(PointMode mode,
                          uint32_t count,
                          const SkPoint pts[],
                          const DlPaint& paint) = 0;
  virtual void DrawVertices(const DlVertices* vertices,
                            DlBlendMode mode,
                            const DlPaint& paint) = 0;
  void DrawVertices(const std::shared_ptr<const DlVertices> vertices,
                    DlBlendMode mode,
                    const DlPaint& paint) {
    DrawVertices(vertices.get(), mode, paint);
  }
  virtual void DrawImage(const sk_sp<DlImage>& image,
                         const SkPoint point,
                         DlImageSampling sampling,
                         const DlPaint* paint = nullptr) = 0;
  virtual void DrawImageRect(const sk_sp<DlImage>& image,
                             const SkRect& src,
                             const SkRect& dst,
                             DlImageSampling sampling,
                             const DlPaint* paint = nullptr,
                             bool enforce_src_edges = false) = 0;
  virtual void DrawImageRect(const sk_sp<DlImage>& image,
                             const SkIRect& src,
                             const SkRect& dst,
                             DlImageSampling sampling,
                             const DlPaint* paint = nullptr,
                             bool enforce_src_edges = false) {
    DrawImageRect(image, SkRect::Make(src), dst, sampling, paint,
                  enforce_src_edges);
  }
  virtual void DrawImageRect(const sk_sp<DlImage>& image,
                             const SkRect& dst,
                             DlImageSampling sampling,
                             const DlPaint* paint = nullptr,
                             bool enforce_src_edges = false) {
    DrawImageRect(image, image->bounds(), dst, sampling, paint,
                  enforce_src_edges);
  }
  virtual void DrawImageNine(const sk_sp<DlImage>& image,
                             const SkIRect& center,
                             const SkRect& dst,
                             DlFilterMode filter,
                             const DlPaint* paint = nullptr) = 0;
  virtual void DrawAtlas(const sk_sp<DlImage>& atlas,
                         const SkRSXform xform[],
                         const SkRect tex[],
                         const DlColor colors[],
                         int count,
                         DlBlendMode mode,
                         DlImageSampling sampling,
                         const SkRect* cullRect,
                         const DlPaint* paint = nullptr) = 0;
  virtual void DrawDisplayList(const sk_sp<DisplayList> display_list,
                               SkScalar opacity = SK_Scalar1) = 0;
  virtual void DrawTextBlob(const sk_sp<SkTextBlob>& blob,
                            SkScalar x,
                            SkScalar y,
                            const DlPaint& paint) = 0;
  virtual void DrawShadow(const SkPath& path,
                          const DlColor color,
                          const SkScalar elevation,
                          bool transparent_occluder,
                          SkScalar dpr) = 0;

  virtual void Flush() = 0;
};

class DlAutoCanvasRestore {
 public:
  DlAutoCanvasRestore(DlCanvas* canvas, bool do_save) : canvas_(canvas) {
    if (canvas) {
      canvas_ = canvas;
      restore_count_ = canvas->GetSaveCount();
      if (do_save) {
        canvas_->Save();
      }
    } else {
      canvas_ = nullptr;
      restore_count_ = 0;
    }
  }

  ~DlAutoCanvasRestore() { Restore(); }

  void Restore() {
    if (canvas_) {
      canvas_->RestoreToCount(restore_count_);
      canvas_ = nullptr;
    }
  }

 private:
  DlCanvas* canvas_;
  int restore_count_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlAutoCanvasRestore);
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DL_CANVAS_H_
