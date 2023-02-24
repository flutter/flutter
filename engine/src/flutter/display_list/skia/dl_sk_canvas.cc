// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/skia/dl_sk_canvas.h"

#include "flutter/display_list/display_list_canvas_dispatcher.h"

namespace flutter {

static sk_sp<SkShader> ToSk(const DlColorSource* source) {
  return source ? source->skia_object() : nullptr;
}

static sk_sp<SkImageFilter> ToSk(const DlImageFilter* filter) {
  return filter ? filter->skia_object() : nullptr;
}

static sk_sp<SkColorFilter> ToSk(const DlColorFilter* filter) {
  return filter ? filter->skia_object() : nullptr;
}

static sk_sp<SkMaskFilter> ToSk(const DlMaskFilter* filter) {
  return filter ? filter->skia_object() : nullptr;
}

static sk_sp<SkPathEffect> ToSk(const DlPathEffect* effect) {
  return effect ? effect->skia_object() : nullptr;
}

static SkCanvas::SrcRectConstraint ToSkConstraint(bool enforce_edges) {
  return enforce_edges ? SkCanvas::kStrict_SrcRectConstraint
                       : SkCanvas::kFast_SrcRectConstraint;
}

static SkClipOp ToSk(DlCanvas::ClipOp op) {
  return static_cast<SkClipOp>(op);
}

static SkCanvas::PointMode ToSk(DlCanvas::PointMode mode) {
  return static_cast<SkCanvas::PointMode>(mode);
}

static SkPaint ToSk(const DlPaint& paint) {
  SkPaint sk_paint;

  sk_paint.setColor(paint.getColor());
  sk_paint.setBlendMode(ToSk(paint.getBlendMode()));
  sk_paint.setStyle(ToSk(paint.getDrawStyle()));
  sk_paint.setStrokeWidth(paint.getStrokeWidth());
  sk_paint.setStrokeMiter(paint.getStrokeMiter());
  sk_paint.setStrokeCap(ToSk(paint.getStrokeCap()));
  sk_paint.setStrokeJoin(ToSk(paint.getStrokeJoin()));

  sk_paint.setShader(ToSk(paint.getColorSourcePtr()));
  sk_paint.setImageFilter(ToSk(paint.getImageFilterPtr()));
  sk_paint.setColorFilter(ToSk(paint.getColorFilterPtr()));
  sk_paint.setMaskFilter(ToSk(paint.getMaskFilterPtr()));
  sk_paint.setPathEffect(ToSk(paint.getPathEffectPtr()));

  return sk_paint;
}

class SkOptionalPaint {
 public:
  explicit SkOptionalPaint(const DlPaint* paint) {
    if (paint) {
      paint_ = ToSk(*paint);
      ptr_ = &paint_;
    } else {
      ptr_ = nullptr;
    }
  }

  SkPaint* operator()() { return ptr_; }

 private:
  SkPaint paint_;
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
  sk_sp<SkImageFilter> sk_filter = backdrop ? backdrop->skia_object() : nullptr;
  SkOptionalPaint sk_paint(paint);
  delegate_->saveLayer(
      SkCanvas::SaveLayerRec{bounds, sk_paint(), sk_filter.get(), 0});
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
  delegate_->drawColor(color, ToSk(mode));
}

void DlSkCanvasAdapter::DrawLine(const SkPoint& p0,
                                 const SkPoint& p1,
                                 const DlPaint& paint) {
  delegate_->drawLine(p0, p1, ToSk(paint));
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
  delegate_->drawPoints(ToSk(mode), count, pts, ToSk(paint));
}

void DlSkCanvasAdapter::DrawVertices(const DlVertices* vertices,
                                     DlBlendMode mode,
                                     const DlPaint& paint) {
  delegate_->drawVertices(vertices->skia_object(), ToSk(mode), ToSk(paint));
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
                                      bool enforce_src_edges) {
  SkOptionalPaint sk_paint(paint);
  sk_sp<SkImage> sk_image = image->skia_image();
  delegate_->drawImageRect(sk_image.get(), src, dst, ToSk(sampling), sk_paint(),
                           ToSkConstraint(enforce_src_edges));
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
  display_list->RenderTo(delegate_, opacity);
}

void DlSkCanvasAdapter::DrawTextBlob(const sk_sp<SkTextBlob>& blob,
                                     SkScalar x,
                                     SkScalar y,
                                     const DlPaint& paint) {
  delegate_->drawTextBlob(blob, x, y, ToSk(paint));
}

void DlSkCanvasAdapter::DrawShadow(const SkPath& path,
                                   const DlColor color,
                                   const SkScalar elevation,
                                   bool transparent_occluder,
                                   SkScalar dpr) {
  DisplayListCanvasDispatcher::DrawShadow(delegate_, path, color, elevation,
                                          SkColorGetA(color) != 0xff, dpr);
}

void DlSkCanvasAdapter::Flush() {
  delegate_->flush();
}

}  // namespace flutter
