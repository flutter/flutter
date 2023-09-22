// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_SKIA_DL_SK_CANVAS_H_
#define FLUTTER_DISPLAY_LIST_SKIA_DL_SK_CANVAS_H_

#include "flutter/display_list/dl_canvas.h"
#include "flutter/display_list/skia/dl_sk_types.h"
#include "impeller/typographer/text_frame.h"

namespace flutter {

// -----------------------------------------------------------------------------
/// @brief      Backend implementation of |DlCanvas| for |SkCanvas|.
///
/// @see        DlCanvas
class DlSkCanvasAdapter final : public virtual DlCanvas {
 public:
  DlSkCanvasAdapter() : delegate_(nullptr) {}
  explicit DlSkCanvasAdapter(SkCanvas* canvas) : delegate_(canvas) {}
  ~DlSkCanvasAdapter() override = default;

  void set_canvas(SkCanvas* canvas);
  SkCanvas* canvas() { return delegate_; }

  SkISize GetBaseLayerSize() const override;
  SkImageInfo GetImageInfo() const override;

  void Save() override;
  void SaveLayer(const SkRect* bounds,
                 const DlPaint* paint = nullptr,
                 const DlImageFilter* backdrop = nullptr) override;
  void Restore() override;
  int GetSaveCount() const override;
  void RestoreToCount(int restore_count) override;

  void Translate(SkScalar tx, SkScalar ty) override;
  void Scale(SkScalar sx, SkScalar sy) override;
  void Rotate(SkScalar degrees) override;
  void Skew(SkScalar sx, SkScalar sy) override;

  // clang-format off

  // 2x3 2D affine subset of a 4x4 transform in row major order
  void Transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                         SkScalar myx, SkScalar myy, SkScalar myt) override;
  // full 4x4 transform in row major order
  void TransformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) override;
  // clang-format on
  void TransformReset() override;
  void Transform(const SkMatrix* matrix) override;
  void Transform(const SkM44* matrix44) override;
  void SetTransform(const SkMatrix* matrix) override;
  void SetTransform(const SkM44* matrix44) override;
  using DlCanvas::SetTransform;
  using DlCanvas::Transform;

  /// Returns the 4x4 full perspective transform representing all transform
  /// operations executed so far in this DisplayList within the enclosing
  /// save stack.
  SkM44 GetTransformFullPerspective() const override;
  /// Returns the 3x3 partial perspective transform representing all transform
  /// operations executed so far in this DisplayList within the enclosing
  /// save stack.
  SkMatrix GetTransform() const override;

  void ClipRect(const SkRect& rect, ClipOp clip_op, bool is_aa) override;
  void ClipRRect(const SkRRect& rrect, ClipOp clip_op, bool is_aa) override;
  void ClipPath(const SkPath& path, ClipOp clip_op, bool is_aa) override;

  /// Conservative estimate of the bounds of all outstanding clip operations
  /// measured in the coordinate space within which this DisplayList will
  /// be rendered.
  SkRect GetDestinationClipBounds() const override;
  /// Conservative estimate of the bounds of all outstanding clip operations
  /// transformed into the local coordinate space in which currently
  /// recorded rendering operations are interpreted.
  SkRect GetLocalClipBounds() const override;

  /// Return true iff the supplied bounds are easily shown to be outside
  /// of the current clip bounds. This method may conservatively return
  /// false if it cannot make the determination.
  bool QuickReject(const SkRect& bounds) const override;

  void DrawPaint(const DlPaint& paint) override;
  void DrawColor(DlColor color, DlBlendMode mode) override;
  void DrawLine(const SkPoint& p0,
                const SkPoint& p1,
                const DlPaint& paint) override;
  void DrawRect(const SkRect& rect, const DlPaint& paint) override;
  void DrawOval(const SkRect& bounds, const DlPaint& paint) override;
  void DrawCircle(const SkPoint& center,
                  SkScalar radius,
                  const DlPaint& paint) override;
  void DrawRRect(const SkRRect& rrect, const DlPaint& paint) override;
  void DrawDRRect(const SkRRect& outer,
                  const SkRRect& inner,
                  const DlPaint& paint) override;
  void DrawPath(const SkPath& path, const DlPaint& paint) override;
  void DrawArc(const SkRect& bounds,
               SkScalar start,
               SkScalar sweep,
               bool useCenter,
               const DlPaint& paint) override;
  void DrawPoints(PointMode mode,
                  uint32_t count,
                  const SkPoint pts[],
                  const DlPaint& paint) override;
  void DrawVertices(const DlVertices* vertices,
                    DlBlendMode mode,
                    const DlPaint& paint) override;
  void DrawImage(const sk_sp<DlImage>& image,
                 const SkPoint point,
                 DlImageSampling sampling,
                 const DlPaint* paint = nullptr) override;
  void DrawImageRect(
      const sk_sp<DlImage>& image,
      const SkRect& src,
      const SkRect& dst,
      DlImageSampling sampling,
      const DlPaint* paint = nullptr,
      SrcRectConstraint constraint = SrcRectConstraint::kFast) override;
  void DrawImageNine(const sk_sp<DlImage>& image,
                     const SkIRect& center,
                     const SkRect& dst,
                     DlFilterMode filter,
                     const DlPaint* paint = nullptr) override;
  void DrawAtlas(const sk_sp<DlImage>& atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const DlColor colors[],
                 int count,
                 DlBlendMode mode,
                 DlImageSampling sampling,
                 const SkRect* cullRect,
                 const DlPaint* paint = nullptr) override;
  void DrawDisplayList(const sk_sp<DisplayList> display_list,
                       SkScalar opacity = SK_Scalar1) override;
  void DrawTextBlob(const sk_sp<SkTextBlob>& blob,
                    SkScalar x,
                    SkScalar y,
                    const DlPaint& paint) override;
  void DrawTextFrame(const std::shared_ptr<impeller::TextFrame>& text_frame,
                     SkScalar x,
                     SkScalar y,
                     const DlPaint& paint) override;
  void DrawShadow(const SkPath& path,
                  const DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

  void Flush() override;

 private:
  SkCanvas* delegate_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_SKIA_DL_SK_CANVAS_H_
