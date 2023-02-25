// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_canvas_dispatcher.h"

#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

const SkScalar kLightHeight = 600;
const SkScalar kLightRadius = 800;

static SkClipOp ToSk(DlCanvas::ClipOp op) {
  return static_cast<SkClipOp>(op);
}

static SkCanvas::PointMode ToSk(DlCanvas::PointMode mode) {
  return static_cast<SkCanvas::PointMode>(mode);
}

const SkPaint* DisplayListCanvasDispatcher::safe_paint(bool use_attributes) {
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

void DisplayListCanvasDispatcher::save() {
  canvas_->save();
  // save has no impact on attributes, but it needs to register a record
  // on the restore stack so that the eventual call to restore() will
  // know what to do at that time. We could annotate the restore record
  // with a flag that the record came from a save call, but it is simpler
  // to just pass in the current opacity value as the value to be used by
  // the children and let the utility calls notice that it didn't change.
  save_opacity(opacity());
}
void DisplayListCanvasDispatcher::restore() {
  canvas_->restore();
  restore_opacity();
}
void DisplayListCanvasDispatcher::saveLayer(const SkRect* bounds,
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
    const sk_sp<SkImageFilter> sk_backdrop =
        backdrop ? backdrop->skia_object() : nullptr;
    canvas_->saveLayer(
        SkCanvas::SaveLayerRec(bounds, paint, sk_backdrop.get(), 0));
    // saveLayer will apply the current opacity on behalf of the children
    // so they will inherit an opaque opacity.
    save_opacity(SK_Scalar1);
  }
}

void DisplayListCanvasDispatcher::translate(SkScalar tx, SkScalar ty) {
  canvas_->translate(tx, ty);
}
void DisplayListCanvasDispatcher::scale(SkScalar sx, SkScalar sy) {
  canvas_->scale(sx, sy);
}
void DisplayListCanvasDispatcher::rotate(SkScalar degrees) {
  canvas_->rotate(degrees);
}
void DisplayListCanvasDispatcher::skew(SkScalar sx, SkScalar sy) {
  canvas_->skew(sx, sy);
}
// clang-format off
// 2x3 2D affine subset of a 4x4 transform in row major order
void DisplayListCanvasDispatcher::transform2DAffine(
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
void DisplayListCanvasDispatcher::transformFullPerspective(
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
void DisplayListCanvasDispatcher::transformReset() {
  canvas_->setMatrix(original_transform_);
}

void DisplayListCanvasDispatcher::clipRect(const SkRect& rect,
                                           ClipOp clip_op,
                                           bool is_aa) {
  canvas_->clipRect(rect, ToSk(clip_op), is_aa);
}
void DisplayListCanvasDispatcher::clipRRect(const SkRRect& rrect,
                                            ClipOp clip_op,
                                            bool is_aa) {
  canvas_->clipRRect(rrect, ToSk(clip_op), is_aa);
}
void DisplayListCanvasDispatcher::clipPath(const SkPath& path,
                                           ClipOp clip_op,
                                           bool is_aa) {
  canvas_->clipPath(path, ToSk(clip_op), is_aa);
}

void DisplayListCanvasDispatcher::drawPaint() {
  const SkPaint& sk_paint = paint();
  SkImageFilter* filter = sk_paint.getImageFilter();
  if (filter && !filter->asColorFilter(nullptr)) {
    // drawPaint does an implicit saveLayer if an SkImageFilter is
    // present that cannot be replaced by an SkColorFilter.
    TRACE_EVENT0("flutter", "Canvas::saveLayer");
  }
  canvas_->drawPaint(sk_paint);
}
void DisplayListCanvasDispatcher::drawColor(DlColor color, DlBlendMode mode) {
  // SkCanvas::drawColor(SkColor) does the following conversion anyway
  // We do it here manually to increase precision on applying opacity
  SkColor4f color4f = SkColor4f::FromColor(color);
  color4f.fA *= opacity();
  canvas_->drawColor(color4f, ToSk(mode));
}
void DisplayListCanvasDispatcher::drawLine(const SkPoint& p0,
                                           const SkPoint& p1) {
  canvas_->drawLine(p0, p1, paint());
}
void DisplayListCanvasDispatcher::drawRect(const SkRect& rect) {
  canvas_->drawRect(rect, paint());
}
void DisplayListCanvasDispatcher::drawOval(const SkRect& bounds) {
  canvas_->drawOval(bounds, paint());
}
void DisplayListCanvasDispatcher::drawCircle(const SkPoint& center,
                                             SkScalar radius) {
  canvas_->drawCircle(center, radius, paint());
}
void DisplayListCanvasDispatcher::drawRRect(const SkRRect& rrect) {
  canvas_->drawRRect(rrect, paint());
}
void DisplayListCanvasDispatcher::drawDRRect(const SkRRect& outer,
                                             const SkRRect& inner) {
  canvas_->drawDRRect(outer, inner, paint());
}
void DisplayListCanvasDispatcher::drawPath(const SkPath& path) {
  canvas_->drawPath(path, paint());
}
void DisplayListCanvasDispatcher::drawArc(const SkRect& bounds,
                                          SkScalar start,
                                          SkScalar sweep,
                                          bool useCenter) {
  canvas_->drawArc(bounds, start, sweep, useCenter, paint());
}
void DisplayListCanvasDispatcher::drawPoints(PointMode mode,
                                             uint32_t count,
                                             const SkPoint pts[]) {
  canvas_->drawPoints(ToSk(mode), count, pts, paint());
}
void DisplayListCanvasDispatcher::drawVertices(const DlVertices* vertices,
                                               DlBlendMode mode) {
  canvas_->drawVertices(vertices->skia_object(), ToSk(mode), paint());
}
void DisplayListCanvasDispatcher::drawImage(const sk_sp<DlImage> image,
                                            const SkPoint point,
                                            DlImageSampling sampling,
                                            bool render_with_attributes) {
  canvas_->drawImage(image ? image->skia_image() : nullptr, point.fX, point.fY,
                     ToSk(sampling), safe_paint(render_with_attributes));
}
void DisplayListCanvasDispatcher::drawImageRect(
    const sk_sp<DlImage> image,
    const SkRect& src,
    const SkRect& dst,
    DlImageSampling sampling,
    bool render_with_attributes,
    SkCanvas::SrcRectConstraint constraint) {
  canvas_->drawImageRect(image ? image->skia_image() : nullptr, src, dst,
                         ToSk(sampling), safe_paint(render_with_attributes),
                         constraint);
}
void DisplayListCanvasDispatcher::drawImageNine(const sk_sp<DlImage> image,
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
void DisplayListCanvasDispatcher::drawAtlas(const sk_sp<DlImage> atlas,
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
void DisplayListCanvasDispatcher::drawDisplayList(
    const sk_sp<DisplayList> display_list) {
  int save_count = canvas_->save();
  display_list->RenderTo(canvas_, opacity());
  canvas_->restoreToCount(save_count);
}
void DisplayListCanvasDispatcher::drawTextBlob(const sk_sp<SkTextBlob> blob,
                                               SkScalar x,
                                               SkScalar y) {
  canvas_->drawTextBlob(blob, x, y, paint());
}

SkRect DisplayListCanvasDispatcher::ComputeShadowBounds(const SkPath& path,
                                                        float elevation,
                                                        SkScalar dpr,
                                                        const SkMatrix& ctm) {
  SkRect shadow_bounds(path.getBounds());
  SkShadowUtils::GetLocalBounds(
      ctm, path, SkPoint3::Make(0, 0, dpr * elevation),
      SkPoint3::Make(0, -1, 1), kLightRadius / kLightHeight,
      SkShadowFlags::kDirectionalLight_ShadowFlag, &shadow_bounds);
  return shadow_bounds;
}

void DisplayListCanvasDispatcher::DrawShadow(SkCanvas* canvas,
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
  SkShadowUtils::DrawShadow(canvas, path, SkPoint3::Make(0, 0, dpr * elevation),
                            SkPoint3::Make(0, -1, 1),
                            kLightRadius / kLightHeight, ambient_color,
                            spot_color, flags);
}

void DisplayListCanvasDispatcher::drawShadow(const SkPath& path,
                                             const DlColor color,
                                             const SkScalar elevation,
                                             bool transparent_occluder,
                                             SkScalar dpr) {
  DrawShadow(canvas_, path, color, elevation, transparent_occluder, dpr);
}

}  // namespace flutter
