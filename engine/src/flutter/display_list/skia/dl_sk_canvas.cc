// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/skia/dl_sk_canvas.h"

#include "flutter/display_list/skia/dl_sk_conversions.h"
#include "flutter/display_list/skia/dl_sk_dispatcher.h"
#include "flutter/fml/trace_event.h"

#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/GrRecordingContext.h"

namespace flutter {

class SkOptionalPaint {
 public:
  explicit SkOptionalPaint(const DlPaint* dl_paint) {
    if (dl_paint && !dl_paint->isDefault()) {
      sk_paint_ = ToSk(*dl_paint);
      ptr_ = &sk_paint_;
    } else {
      ptr_ = nullptr;
    }
  }

  SkPaint* operator()() { return ptr_; }

 private:
  SkPaint sk_paint_;
  SkPaint* ptr_;
};

void DlSkCanvasAdapter::set_canvas(SkCanvas* canvas) {
  delegate_ = canvas;
}

SkISize DlSkCanvasAdapter::GetBaseLayerSize() const {
  return delegate_->getBaseLayerSize();
}

SkImageInfo DlSkCanvasAdapter::GetImageInfo() const {
  return delegate_->imageInfo();
}

void DlSkCanvasAdapter::Save() {
  delegate_->save();
}

void DlSkCanvasAdapter::SaveLayer(const SkRect* bounds,
                                  const DlPaint* paint,
                                  const DlImageFilter* backdrop) {
  sk_sp<SkImageFilter> sk_backdrop = ToSk(backdrop);
  SkOptionalPaint sk_paint(paint);
  TRACE_EVENT0("flutter", "Canvas::saveLayer");
  delegate_->saveLayer(
      SkCanvas::SaveLayerRec{bounds, sk_paint(), sk_backdrop.get(), 0});
}

void DlSkCanvasAdapter::Restore() {
  delegate_->restore();
}

int DlSkCanvasAdapter::GetSaveCount() const {
  return delegate_->getSaveCount();
}

void DlSkCanvasAdapter::RestoreToCount(int restore_count) {
  delegate_->restoreToCount(restore_count);
}

void DlSkCanvasAdapter::Translate(SkScalar tx, SkScalar ty) {
  delegate_->translate(tx, ty);
}

void DlSkCanvasAdapter::Scale(SkScalar sx, SkScalar sy) {
  delegate_->scale(sx, sy);
}

void DlSkCanvasAdapter::Rotate(SkScalar degrees) {
  delegate_->rotate(degrees);
}

void DlSkCanvasAdapter::Skew(SkScalar sx, SkScalar sy) {
  delegate_->skew(sx, sy);
}

// clang-format off

// 2x3 2D affine subset of a 4x4 transform in row major order
void DlSkCanvasAdapter::Transform2DAffine(
    SkScalar mxx, SkScalar mxy, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myt) {
  delegate_->concat(SkMatrix::MakeAll(mxx, mxy, mxt, myx, myy, myt, 0, 0, 1));
}

// full 4x4 transform in row major order
void DlSkCanvasAdapter::TransformFullPerspective(
    SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
    SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
    SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
  delegate_->concat(SkM44(mxx, mxy, mxz, mxt,
                          myx, myy, myz, myt,
                          mzx, mzy, mzz, mzt,
                          mwx, mwy, mwz, mwt));
}

// clang-format on

void DlSkCanvasAdapter::TransformReset() {
  delegate_->resetMatrix();
}

void DlSkCanvasAdapter::Transform(const SkMatrix* matrix) {
  delegate_->concat(*matrix);
}

void DlSkCanvasAdapter::Transform(const SkM44* matrix44) {
  delegate_->concat(*matrix44);
}

void DlSkCanvasAdapter::SetTransform(const SkMatrix* matrix) {
  delegate_->setMatrix(*matrix);
}

void DlSkCanvasAdapter::SetTransform(const SkM44* matrix44) {
  delegate_->setMatrix(*matrix44);
}

/// Returns the 4x4 full perspective transform representing all transform
/// operations executed so far in this DisplayList within the enclosing
/// save stack.
SkM44 DlSkCanvasAdapter::GetTransformFullPerspective() const {
  return delegate_->getLocalToDevice();
}

/// Returns the 3x3 partial perspective transform representing all transform
/// operations executed so far in this DisplayList within the enclosing
/// save stack.
SkMatrix DlSkCanvasAdapter::GetTransform() const {
  return delegate_->getTotalMatrix();
}

void DlSkCanvasAdapter::ClipRect(const SkRect& rect,
                                 ClipOp clip_op,
                                 bool is_aa) {
  delegate_->clipRect(rect, ToSk(clip_op), is_aa);
}

void DlSkCanvasAdapter::ClipRRect(const SkRRect& rrect,
                                  ClipOp clip_op,
                                  bool is_aa) {
  delegate_->clipRRect(rrect, ToSk(clip_op), is_aa);
}

void DlSkCanvasAdapter::ClipPath(const SkPath& path,
                                 ClipOp clip_op,
                                 bool is_aa) {
  delegate_->clipPath(path, ToSk(clip_op), is_aa);
}

/// Conservative estimate of the bounds of all outstanding clip operations
/// measured in the coordinate space within which this DisplayList will
/// be rendered.
SkRect DlSkCanvasAdapter::GetDestinationClipBounds() const {
  return SkRect::Make(delegate_->getDeviceClipBounds());
}

/// Conservative estimate of the bounds of all outstanding clip operations
/// transformed into the local coordinate space in which currently
/// recorded rendering operations are interpreted.
SkRect DlSkCanvasAdapter::GetLocalClipBounds() const {
  return delegate_->getLocalClipBounds();
}

/// Return true iff the supplied bounds are easily shown to be outside
/// of the current clip bounds. This method may conservatively return
/// false if it cannot make the determination.
bool DlSkCanvasAdapter::QuickReject(const SkRect& bounds) const {
  return delegate_->quickReject(bounds);
}

void DlSkCanvasAdapter::DrawPaint(const DlPaint& paint) {
  delegate_->drawPaint(ToSk(paint));
}

void DlSkCanvasAdapter::DrawColor(DlColor color, DlBlendMode mode) {
  delegate_->drawColor(ToSk(color), ToSk(mode));
}

void DlSkCanvasAdapter::DrawLine(const SkPoint& p0,
                                 const SkPoint& p1,
                                 const DlPaint& paint) {
  delegate_->drawLine(p0, p1, ToSk(paint, true));
}

void DlSkCanvasAdapter::DrawRect(const SkRect& rect, const DlPaint& paint) {
  delegate_->drawRect(rect, ToSk(paint));
}

void DlSkCanvasAdapter::DrawOval(const SkRect& bounds, const DlPaint& paint) {
  delegate_->drawOval(bounds, ToSk(paint));
}

void DlSkCanvasAdapter::DrawCircle(const SkPoint& center,
                                   SkScalar radius,
                                   const DlPaint& paint) {
  delegate_->drawCircle(center, radius, ToSk(paint));
}

void DlSkCanvasAdapter::DrawRRect(const SkRRect& rrect, const DlPaint& paint) {
  delegate_->drawRRect(rrect, ToSk(paint));
}

void DlSkCanvasAdapter::DrawDRRect(const SkRRect& outer,
                                   const SkRRect& inner,
                                   const DlPaint& paint) {
  delegate_->drawDRRect(outer, inner, ToSk(paint));
}

void DlSkCanvasAdapter::DrawPath(const SkPath& path, const DlPaint& paint) {
  delegate_->drawPath(path, ToSk(paint));
}

void DlSkCanvasAdapter::DrawArc(const SkRect& bounds,
                                SkScalar start,
                                SkScalar sweep,
                                bool useCenter,
                                const DlPaint& paint) {
  delegate_->drawArc(bounds, start, sweep, useCenter, ToSk(paint));
}

void DlSkCanvasAdapter::DrawPoints(PointMode mode,
                                   uint32_t count,
                                   const SkPoint pts[],
                                   const DlPaint& paint) {
  delegate_->drawPoints(ToSk(mode), count, pts, ToSk(paint, true));
}

void DlSkCanvasAdapter::DrawVertices(const DlVertices* vertices,
                                     DlBlendMode mode,
                                     const DlPaint& paint) {
  delegate_->drawVertices(ToSk(vertices), ToSk(mode), ToSk(paint));
}

void DlSkCanvasAdapter::DrawImage(const sk_sp<DlImage>& image,
                                  const SkPoint point,
                                  DlImageSampling sampling,
                                  const DlPaint* paint) {
  SkOptionalPaint sk_paint(paint);
  sk_sp<SkImage> sk_image = image->skia_image();
  delegate_->drawImage(sk_image.get(), point.fX, point.fY, ToSk(sampling),
                       sk_paint());
}

void DlSkCanvasAdapter::DrawImageRect(const sk_sp<DlImage>& image,
                                      const SkRect& src,
                                      const SkRect& dst,
                                      DlImageSampling sampling,
                                      const DlPaint* paint,
                                      SrcRectConstraint constraint) {
  SkOptionalPaint sk_paint(paint);
  sk_sp<SkImage> sk_image = image->skia_image();
  delegate_->drawImageRect(sk_image.get(), src, dst, ToSk(sampling), sk_paint(),
                           ToSk(constraint));
}

void DlSkCanvasAdapter::DrawImageNine(const sk_sp<DlImage>& image,
                                      const SkIRect& center,
                                      const SkRect& dst,
                                      DlFilterMode filter,
                                      const DlPaint* paint) {
  SkOptionalPaint sk_paint(paint);
  sk_sp<SkImage> sk_image = image->skia_image();
  delegate_->drawImageNine(sk_image.get(), center, dst, ToSk(filter),
                           sk_paint());
}

void DlSkCanvasAdapter::DrawAtlas(const sk_sp<DlImage>& atlas,
                                  const SkRSXform xform[],
                                  const SkRect tex[],
                                  const DlColor colors[],
                                  int count,
                                  DlBlendMode mode,
                                  DlImageSampling sampling,
                                  const SkRect* cullRect,
                                  const DlPaint* paint) {
  SkOptionalPaint sk_paint(paint);
  sk_sp<SkImage> sk_image = atlas->skia_image();
  const SkColor* sk_colors = reinterpret_cast<const SkColor*>(colors);
  delegate_->drawAtlas(sk_image.get(), xform, tex, sk_colors, count, ToSk(mode),
                       ToSk(sampling), cullRect, sk_paint());
}

void DlSkCanvasAdapter::DrawDisplayList(const sk_sp<DisplayList> display_list,
                                        SkScalar opacity) {
  const int restore_count = delegate_->getSaveCount();

  // Figure out whether we can apply the opacity during dispatch or
  // if we need a saveLayer.
  if (opacity < SK_Scalar1 && !display_list->can_apply_group_opacity()) {
    TRACE_EVENT0("flutter", "Canvas::saveLayer");
    delegate_->saveLayerAlphaf(&display_list->bounds(), opacity);
    opacity = SK_Scalar1;
  } else {
    delegate_->save();
  }

  DlSkCanvasDispatcher dispatcher(delegate_, opacity);
  if (display_list->has_rtree()) {
    display_list->Dispatch(dispatcher, delegate_->getLocalClipBounds());
  } else {
    display_list->Dispatch(dispatcher);
  }

  delegate_->restoreToCount(restore_count);
}

void DlSkCanvasAdapter::DrawTextBlob(const sk_sp<SkTextBlob>& blob,
                                     SkScalar x,
                                     SkScalar y,
                                     const DlPaint& paint) {
  delegate_->drawTextBlob(blob, x, y, ToSk(paint));
}

void DlSkCanvasAdapter::DrawTextFrame(
    const std::shared_ptr<impeller::TextFrame>& text_frame,
    SkScalar x,
    SkScalar y,
    const DlPaint& paint) {
  FML_CHECK(false);
}

void DlSkCanvasAdapter::DrawShadow(const SkPath& path,
                                   const DlColor color,
                                   const SkScalar elevation,
                                   bool transparent_occluder,
                                   SkScalar dpr) {
  DlSkCanvasDispatcher::DrawShadow(delegate_, path, color, elevation,
                                   transparent_occluder, dpr);
}

void DlSkCanvasAdapter::Flush() {
  auto dContext = GrAsDirectContext(delegate_->recordingContext());

  if (dContext) {
    dContext->flushAndSubmit();
  }
}

}  // namespace flutter
