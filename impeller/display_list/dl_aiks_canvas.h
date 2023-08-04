// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/display_list/dl_canvas.h"
#include "flutter/display_list/geometry/dl_rtree.h"
#include "flutter/display_list/utils/dl_bounds_accumulator.h"
#include "flutter/fml/macros.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/paint.h"
#include "impeller/display_list/skia_conversions.h"

namespace impeller {

class DlAiksCanvas final : public flutter::DlCanvas {
 public:
  DlAiksCanvas();

  explicit DlAiksCanvas(const SkRect& cull_rect, bool prepare_tree = false);

  explicit DlAiksCanvas(const SkIRect& cull_rect, bool prepare_rtree = false);

  ~DlAiksCanvas();

  Picture EndRecordingAsPicture();

  // |DlCanvas|
  SkISize GetBaseLayerSize() const override;
  // |DlCanvas|
  SkImageInfo GetImageInfo() const override;

  // |DlCanvas|
  void Save() override;

  // |DlCanvas|
  void SaveLayer(const SkRect* bounds,
                 const flutter::DlPaint* paint = nullptr,
                 const flutter::DlImageFilter* backdrop = nullptr) override;
  // |DlCanvas|
  void Restore() override;
  // |DlCanvas|
  int GetSaveCount() const override { return canvas_.GetSaveCount(); }
  // |DlCanvas|
  void RestoreToCount(int restore_count) override;

  // |DlCanvas|
  void Translate(SkScalar tx, SkScalar ty) override;
  // |DlCanvas|
  void Scale(SkScalar sx, SkScalar sy) override;
  // |DlCanvas|
  void Rotate(SkScalar degrees) override;
  // |DlCanvas|
  void Skew(SkScalar sx, SkScalar sy) override;

  // clang-format off
  // 2x3 2D affine subset of a 4x4 transform in row major order
  // |DlCanvas|
  void Transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                         SkScalar myx, SkScalar myy, SkScalar myt) override;
  // full 4x4 transform in row major order
  // |DlCanvas|
  void TransformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) override;
  // clang-format on
  // |DlCanvas|
  void TransformReset() override;
  // |DlCanvas|
  void Transform(const SkMatrix* matrix) override;
  // |DlCanvas|
  void Transform(const SkM44* matrix44) override;
  // |DlCanvas|
  void SetTransform(const SkMatrix* matrix) override {
    TransformReset();
    Transform(matrix);
  }
  // |DlCanvas|
  void SetTransform(const SkM44* matrix44) override {
    TransformReset();
    Transform(matrix44);
  }
  using flutter::DlCanvas::Transform;

  /// Returns the 4x4 full perspective transform representing all transform
  /// operations executed so far in this DisplayList within the enclosing
  /// save stack.
  // |DlCanvas|
  SkM44 GetTransformFullPerspective() const override {
    return skia_conversions::ToSkM44(canvas_.GetCurrentTransformation());
  }
  /// Returns the 3x3 partial perspective transform representing all transform
  /// operations executed so far in this DisplayList within the enclosing
  /// save stack.
  // |DlCanvas|
  SkMatrix GetTransform() const override {
    return skia_conversions::ToSkMatrix(canvas_.GetCurrentTransformation());
  }

  // |DlCanvas|
  void ClipRect(const SkRect& rect,
                ClipOp clip_op = ClipOp::kIntersect,
                bool is_aa = false) override;
  // |DlCanvas|
  void ClipRRect(const SkRRect& rrect,
                 ClipOp clip_op = ClipOp::kIntersect,
                 bool is_aa = false) override;
  // |DlCanvas|
  void ClipPath(const SkPath& path,
                ClipOp clip_op = ClipOp::kIntersect,
                bool is_aa = false) override;

  /// Conservative estimate of the bounds of all outstanding clip operations
  /// measured in the coordinate space within which this DisplayList will
  /// be rendered.
  // |DlCanvas|
  SkRect GetDestinationClipBounds() const override {
    auto rect = canvas_.GetCurrentLocalCullingBounds().value_or(Rect::Giant());
    return SkRect::MakeLTRB(rect.GetLeft(), rect.GetTop(), rect.GetRight(),
                            rect.GetBottom());
  }
  /// Conservative estimate of the bounds of all outstanding clip operations
  /// transformed into the local coordinate space in which currently
  /// recorded rendering operations are interpreted.
  // |DlCanvas|
  SkRect GetLocalClipBounds() const override {
    auto rect = canvas_.GetCurrentLocalCullingBounds().value_or(Rect::Giant());
    return SkRect::MakeLTRB(rect.GetLeft(), rect.GetTop(), rect.GetRight(),
                            rect.GetBottom());
  }

  /// Return true iff the supplied bounds are easily shown to be outside
  /// of the current clip bounds. This method may conservatively return
  /// false if it cannot make the determination.
  // |DlCanvas|
  bool QuickReject(const SkRect& bounds) const override;

  // |DlCanvas|
  void DrawPaint(const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawColor(flutter::DlColor color, flutter::DlBlendMode mode) override;
  // |DlCanvas|
  void DrawLine(const SkPoint& p0,
                const SkPoint& p1,
                const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawRect(const SkRect& rect, const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawOval(const SkRect& bounds, const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawCircle(const SkPoint& center,
                  SkScalar radius,
                  const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawRRect(const SkRRect& rrect, const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawDRRect(const SkRRect& outer,
                  const SkRRect& inner,
                  const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawPath(const SkPath& path, const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawArc(const SkRect& bounds,
               SkScalar start,
               SkScalar sweep,
               bool useCenter,
               const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawPoints(PointMode mode,
                  uint32_t count,
                  const SkPoint pts[],
                  const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawVertices(const flutter::DlVertices* vertices,
                    flutter::DlBlendMode mode,
                    const flutter::DlPaint& paint) override;
  using flutter::DlCanvas::DrawVertices;
  // |DlCanvas|
  void DrawImage(const sk_sp<flutter::DlImage>& image,
                 const SkPoint point,
                 flutter::DlImageSampling sampling,
                 const flutter::DlPaint* paint = nullptr) override;
  // |DlCanvas|
  void DrawImageRect(
      const sk_sp<flutter::DlImage>& image,
      const SkRect& src,
      const SkRect& dst,
      flutter::DlImageSampling sampling,
      const flutter::DlPaint* paint = nullptr,
      SrcRectConstraint constraint = SrcRectConstraint::kFast) override;
  using flutter::DlCanvas::DrawImageRect;
  // |DlCanvas|
  void DrawImageNine(const sk_sp<flutter::DlImage>& image,
                     const SkIRect& center,
                     const SkRect& dst,
                     flutter::DlFilterMode filter,
                     const flutter::DlPaint* paint = nullptr) override;
  // |DlCanvas|
  void DrawAtlas(const sk_sp<flutter::DlImage>& atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const flutter::DlColor colors[],
                 int count,
                 flutter::DlBlendMode mode,
                 flutter::DlImageSampling sampling,
                 const SkRect* cullRect,
                 const flutter::DlPaint* paint = nullptr) override;
  // |DlCanvas|
  void DrawDisplayList(const sk_sp<flutter::DisplayList> display_list,
                       SkScalar opacity = SK_Scalar1) override;

  // |DlCanvas|
  void DrawImpellerPicture(
      const std::shared_ptr<const impeller::Picture>& picture,
      SkScalar opacity = SK_Scalar1) override;

  // |DlCanvas|
  void DrawTextBlob(const sk_sp<SkTextBlob>& blob,
                    SkScalar x,
                    SkScalar y,
                    const flutter::DlPaint& paint) override;
  // |DlCanvas|
  void DrawShadow(const SkPath& path,
                  const flutter::DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

  // |DlCanvas|
  void Flush() override {}

 private:
  Canvas canvas_;
  std::unique_ptr<flutter::BoundsAccumulator> accumulator_;

  FML_DISALLOW_COPY_AND_ASSIGN(DlAiksCanvas);
};

}  // namespace impeller
