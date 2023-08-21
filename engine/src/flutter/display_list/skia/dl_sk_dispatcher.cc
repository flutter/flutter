// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/skia/dl_sk_dispatcher.h"

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/skia/dl_sk_conversions.h"
#include "flutter/display_list/skia/dl_sk_types.h"
#include "flutter/fml/trace_event.h"

#include "third_party/skia/include/utils/SkShadowUtils.h"

namespace flutter {

const SkPaint* DlSkCanvasDispatcher::safe_paint(bool use_attributes) {
  if (use_attributes) {
    // The accumulated SkPaint object will already have incorporated
    // any attribute overrides.
    return &paint();
  } else if (has_opacity()) {
    temp_paint_.setAlphaf(opacity());
    return &temp_paint_;
  } else {
    return nullptr;
  }
}

void DlSkCanvasDispatcher::save() {
  canvas_->save();
  // save has no impact on attributes, but it needs to register a record
  // on the restore stack so that the eventual call to restore() will
  // know what to do at that time. We could annotate the restore record
  // with a flag that the record came from a save call, but it is simpler
  // to just pass in the current opacity value as the value to be used by
  // the children and let the utility calls notice that it didn't change.
  save_opacity(opacity());
}
void DlSkCanvasDispatcher::restore() {
  canvas_->restore();
  restore_opacity();
}
void DlSkCanvasDispatcher::saveLayer(const SkRect* bounds,
                                     const SaveLayerOptions options,
                                     const DlImageFilter* backdrop) {
  if (bounds == nullptr && options.can_distribute_opacity() &&
      backdrop == nullptr) {
    // We know that:
    // - no bounds is needed for clipping here
    // - no backdrop filter is used to initialize the layer
    // - the current attributes only have an alpha
    // - the children are compatible with individually rendering with
    //   an inherited opacity
    // Therefore we can just use a save instead of a saveLayer and pass the
    // intended opacity to the children.
    canvas_->save();
    // If the saveLayer does not use attributes, the children should continue
    // to render with the inherited opacity unmodified. If attributes are to
    // be applied, the children should render with the combination of the
    // inherited opacity combined with the alpha from the current color.
    save_opacity(options.renders_with_attributes() ? combined_opacity()
                                                   : opacity());
  } else {
    TRACE_EVENT0("flutter", "Canvas::saveLayer");
    const SkPaint* paint = safe_paint(options.renders_with_attributes());
    const sk_sp<SkImageFilter> sk_backdrop = ToSk(backdrop);
    canvas_->saveLayer(
        SkCanvas::SaveLayerRec(bounds, paint, sk_backdrop.get(), 0));
    // saveLayer will apply the current opacity on behalf of the children
    // so they will inherit an opaque opacity.
    save_opacity(SK_Scalar1);
  }
}

void DlSkCanvasDispatcher::translate(SkScalar tx, SkScalar ty) {
  canvas_->translate(tx, ty);
}
void DlSkCanvasDispatcher::scale(SkScalar sx, SkScalar sy) {
  canvas_->scale(sx, sy);
}
void DlSkCanvasDispatcher::rotate(SkScalar degrees) {
  canvas_->rotate(degrees);
}
void DlSkCanvasDispatcher::skew(SkScalar sx, SkScalar sy) {
  canvas_->skew(sx, sy);
}
// clang-format off
// 2x3 2D affine subset of a 4x4 transform in row major order
void DlSkCanvasDispatcher::transform2DAffine(
    SkScalar mxx, SkScalar mxy, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myt) {
  // Internally concat(SkMatrix) gets redirected to concat(SkM44)
  // so we just jump directly to the SkM44 version
  canvas_->concat(SkM44(mxx, mxy, 0, mxt,
                        myx, myy, 0, myt,
                         0,   0,  1,  0,
                         0,   0,  0,  1));
}
// full 4x4 transform in row major order
void DlSkCanvasDispatcher::transformFullPerspective(
    SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
    SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
    SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
  canvas_->concat(SkM44(mxx, mxy, mxz, mxt,
                        myx, myy, myz, myt,
                        mzx, mzy, mzz, mzt,
                        mwx, mwy, mwz, mwt));
}
// clang-format on
void DlSkCanvasDispatcher::transformReset() {
  canvas_->setMatrix(original_transform_);
}

void DlSkCanvasDispatcher::clipRect(const SkRect& rect,
                                    ClipOp clip_op,
                                    bool is_aa) {
  canvas_->clipRect(rect, ToSk(clip_op), is_aa);
}
void DlSkCanvasDispatcher::clipRRect(const SkRRect& rrect,
                                     ClipOp clip_op,
                                     bool is_aa) {
  canvas_->clipRRect(rrect, ToSk(clip_op), is_aa);
}
void DlSkCanvasDispatcher::clipPath(const SkPath& path,
                                    ClipOp clip_op,
                                    bool is_aa) {
  canvas_->clipPath(path, ToSk(clip_op), is_aa);
}

void DlSkCanvasDispatcher::drawPaint() {
  const SkPaint& sk_paint = paint();
  SkImageFilter* filter = sk_paint.getImageFilter();
  if (filter && !filter->asColorFilter(nullptr)) {
    // drawPaint does an implicit saveLayer if an SkImageFilter is
    // present that cannot be replaced by an SkColorFilter.
    TRACE_EVENT0("flutter", "Canvas::saveLayer");
  }
  canvas_->drawPaint(sk_paint);
}
void DlSkCanvasDispatcher::drawColor(DlColor color, DlBlendMode mode) {
  // SkCanvas::drawColor(SkColor) does the following conversion anyway
  // We do it here manually to increase precision on applying opacity
  SkColor4f color4f = SkColor4f::FromColor(color);
  color4f.fA *= opacity();
  canvas_->drawColor(color4f, ToSk(mode));
}
void DlSkCanvasDispatcher::drawLine(const SkPoint& p0, const SkPoint& p1) {
  canvas_->drawLine(p0, p1, paint());
}
void DlSkCanvasDispatcher::drawRect(const SkRect& rect) {
  canvas_->drawRect(rect, paint());
}
void DlSkCanvasDispatcher::drawOval(const SkRect& bounds) {
  canvas_->drawOval(bounds, paint());
}
void DlSkCanvasDispatcher::drawCircle(const SkPoint& center, SkScalar radius) {
  canvas_->drawCircle(center, radius, paint());
}
void DlSkCanvasDispatcher::drawRRect(const SkRRect& rrect) {
  canvas_->drawRRect(rrect, paint());
}
void DlSkCanvasDispatcher::drawDRRect(const SkRRect& outer,
                                      const SkRRect& inner) {
  canvas_->drawDRRect(outer, inner, paint());
}
void DlSkCanvasDispatcher::drawPath(const SkPath& path) {
  canvas_->drawPath(path, paint());
}
void DlSkCanvasDispatcher::drawArc(const SkRect& bounds,
                                   SkScalar start,
                                   SkScalar sweep,
                                   bool useCenter) {
  canvas_->drawArc(bounds, start, sweep, useCenter, paint());
}
void DlSkCanvasDispatcher::drawPoints(PointMode mode,
                                      uint32_t count,
                                      const SkPoint pts[]) {
  canvas_->drawPoints(ToSk(mode), count, pts, paint());
}
void DlSkCanvasDispatcher::drawVertices(const DlVertices* vertices,
                                        DlBlendMode mode) {
  canvas_->drawVertices(ToSk(vertices), ToSk(mode), paint());
}
void DlSkCanvasDispatcher::drawImage(const sk_sp<DlImage>& image,
                                     const SkPoint point,
                                     DlImageSampling sampling,
                                     bool render_with_attributes) {
  canvas_->drawImage(image ? image->skia_image() : nullptr, point.fX, point.fY,
                     ToSk(sampling), safe_paint(render_with_attributes));
}
void DlSkCanvasDispatcher::drawImageRect(const sk_sp<DlImage>& image,
                                         const SkRect& src,
                                         const SkRect& dst,
                                         DlImageSampling sampling,
                                         bool render_with_attributes,
                                         SrcRectConstraint constraint) {
  canvas_->drawImageRect(image ? image->skia_image() : nullptr, src, dst,
                         ToSk(sampling), safe_paint(render_with_attributes),
                         ToSk(constraint));
}
void DlSkCanvasDispatcher::drawImageNine(const sk_sp<DlImage>& image,
                                         const SkIRect& center,
                                         const SkRect& dst,
                                         DlFilterMode filter,
                                         bool render_with_attributes) {
  if (!image) {
    return;
  }
  auto skia_image = image->skia_image();
  if (!skia_image) {
    return;
  }
  canvas_->drawImageNine(skia_image.get(), center, dst, ToSk(filter),
                         safe_paint(render_with_attributes));
}
void DlSkCanvasDispatcher::drawAtlas(const sk_sp<DlImage>& atlas,
                                     const SkRSXform xform[],
                                     const SkRect tex[],
                                     const DlColor colors[],
                                     int count,
                                     DlBlendMode mode,
                                     DlImageSampling sampling,
                                     const SkRect* cullRect,
                                     bool render_with_attributes) {
  if (!atlas) {
    return;
  }
  auto skia_atlas = atlas->skia_image();
  if (!skia_atlas) {
    return;
  }
  const SkColor* sk_colors = reinterpret_cast<const SkColor*>(colors);
  canvas_->drawAtlas(skia_atlas.get(), xform, tex, sk_colors, count, ToSk(mode),
                     ToSk(sampling), cullRect,
                     safe_paint(render_with_attributes));
}
void DlSkCanvasDispatcher::drawDisplayList(
    const sk_sp<DisplayList>& display_list,
    SkScalar opacity) {
  const int restore_count = canvas_->getSaveCount();

  // Compute combined opacity and figure out whether we can apply it
  // during dispatch or if we need a saveLayer.
  SkScalar combined_opacity = opacity * this->opacity();
  if (combined_opacity < SK_Scalar1 &&
      !display_list->can_apply_group_opacity()) {
    TRACE_EVENT0("flutter", "Canvas::saveLayer");
    canvas_->saveLayerAlphaf(&display_list->bounds(), combined_opacity);
    combined_opacity = SK_Scalar1;
  } else {
    canvas_->save();
  }

  // Create a new CanvasDispatcher to isolate the actions of the
  // display_list from the current environment.
  DlSkCanvasDispatcher dispatcher(canvas_, combined_opacity);
  if (display_list->rtree()) {
    display_list->Dispatch(dispatcher, canvas_->getLocalClipBounds());
  } else {
    display_list->Dispatch(dispatcher);
  }

  // Restore canvas state to what it was before dispatching.
  canvas_->restoreToCount(restore_count);
}
void DlSkCanvasDispatcher::drawTextBlob(const sk_sp<SkTextBlob>& blob,
                                        SkScalar x,
                                        SkScalar y) {
  canvas_->drawTextBlob(blob, x, y, paint());
}

void DlSkCanvasDispatcher::DrawShadow(SkCanvas* canvas,
                                      const SkPath& path,
                                      DlColor color,
                                      float elevation,
                                      bool transparentOccluder,
                                      SkScalar dpr) {
  const SkScalar kAmbientAlpha = 0.039f;
  const SkScalar kSpotAlpha = 0.25f;

  uint32_t flags = transparentOccluder
                       ? SkShadowFlags::kTransparentOccluder_ShadowFlag
                       : SkShadowFlags::kNone_ShadowFlag;
  flags |= SkShadowFlags::kDirectionalLight_ShadowFlag;
  SkColor in_ambient = SkColorSetA(color, kAmbientAlpha * SkColorGetA(color));
  SkColor in_spot = SkColorSetA(color, kSpotAlpha * SkColorGetA(color));
  SkColor ambient_color, spot_color;
  SkShadowUtils::ComputeTonalColors(in_ambient, in_spot, &ambient_color,
                                    &spot_color);
  SkShadowUtils::DrawShadow(
      canvas, path, SkPoint3::Make(0, 0, dpr * elevation),
      SkPoint3::Make(0, -1, 1),
      DlCanvas::kShadowLightRadius / DlCanvas::kShadowLightHeight,
      ambient_color, spot_color, flags);
}

void DlSkCanvasDispatcher::drawShadow(const SkPath& path,
                                      const DlColor color,
                                      const SkScalar elevation,
                                      bool transparent_occluder,
                                      SkScalar dpr) {
  DrawShadow(canvas_, path, color, elevation, transparent_occluder, dpr);
}

}  // namespace flutter
