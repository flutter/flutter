// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "helpers.h"
#include "wrappers.h"

#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_text_skia.h"

using namespace skia::textlayout;
using namespace Skwasm;
using namespace flutter;

namespace {
// TODO(jacksongardner): Implement this properly
class SkwasmParagraphPainter : public ParagraphPainter {
 public:
  SkwasmParagraphPainter(DisplayListBuilder& builder) : _builder(builder) {}

  virtual void drawTextBlob(const sk_sp<SkTextBlob>& blob,
                            SkScalar x,
                            SkScalar y,
                            const SkPaintOrID& paint) {
    _builder.DrawText(DlTextSkia::Make(blob), x, y, flutter::DlPaint());
  }

  virtual void drawTextShadow(const sk_sp<SkTextBlob>& blob,
                              SkScalar x,
                              SkScalar y,
                              SkColor color,
                              SkScalar blurSigma) {}
  virtual void drawRect(const SkRect& rect, const SkPaintOrID& paint) {}
  virtual void drawFilledRect(const SkRect& rect,
                              const DecorationStyle& decorStyle) {}
  virtual void drawPath(const SkPath& path, const DecorationStyle& decorStyle) {
  }
  virtual void drawLine(SkScalar x0,
                        SkScalar y0,
                        SkScalar x1,
                        SkScalar y1,
                        const DecorationStyle& decorStyle) {}
  virtual void clipRect(const SkRect& rect) {}
  virtual void translate(SkScalar dx, SkScalar dy) {}

  virtual void save() {}
  virtual void restore() {}

 private:
  DisplayListBuilder& _builder;
};
}  // namespace

SKWASM_EXPORT void canvas_saveLayer(DisplayListBuilder* canvas,
                                    DlRect* rect,
                                    DlPaint* paint,
                                    sp_wrapper<DlImageFilter>* backdrop,
                                    DlTileMode backdropTileMode) {
  // TODO(jacksongardner): make sure the tile mode is handled properly
  canvas->SaveLayer(rect ? std::optional(*rect) : std::nullopt, paint,
                    backdrop ? backdrop->raw() : nullptr);
}

SKWASM_EXPORT void canvas_save(DisplayListBuilder* canvas) {
  canvas->Save();
}

SKWASM_EXPORT void canvas_restore(DisplayListBuilder* canvas) {
  canvas->Restore();
}

SKWASM_EXPORT void canvas_restoreToCount(DisplayListBuilder* canvas,
                                         int count) {
  if (count > canvas->GetSaveCount()) {
    // According to the docs:
    // "If count is greater than the current getSaveCount then nothing happens."
    return;
  }
  canvas->RestoreToCount(count);
}

SKWASM_EXPORT int canvas_getSaveCount(DisplayListBuilder* canvas) {
  return canvas->GetSaveCount();
}

SKWASM_EXPORT void canvas_translate(DisplayListBuilder* canvas,
                                    float dx,
                                    float dy) {
  canvas->Translate(dx, dy);
}

SKWASM_EXPORT void canvas_scale(DisplayListBuilder* canvas,
                                float sx,
                                float sy) {
  canvas->Scale(sx, sy);
}

SKWASM_EXPORT void canvas_rotate(DisplayListBuilder* canvas, DlScalar degrees) {
  canvas->Rotate(degrees);
}

SKWASM_EXPORT void canvas_skew(DisplayListBuilder* canvas,
                               DlScalar sx,
                               DlScalar sy) {
  canvas->Skew(sx, sy);
}

SKWASM_EXPORT void canvas_transform(DisplayListBuilder* canvas,
                                    const DlMatrix* matrix44) {
  canvas->Transform(*matrix44);
}

SKWASM_EXPORT void canvas_clipRect(DisplayListBuilder* canvas,
                                   const DlRect* rect,
                                   DlClipOp op,
                                   bool antialias) {
  canvas->ClipRect(*rect, op);
}

SKWASM_EXPORT void canvas_clipRRect(DisplayListBuilder* canvas,
                                    const SkScalar* rrectValues,
                                    bool antialias) {
  canvas->ClipRoundRect(createDlRRect(rrectValues), DlClipOp::kIntersect,
                        antialias);
}

SKWASM_EXPORT void canvas_clipPath(DisplayListBuilder* canvas,
                                   SkPath* path,
                                   bool antialias) {
  // TODO(jacksongardner): probably use DlPath directly everywhere?
  canvas->ClipPath(DlPath(*path), DlClipOp::kIntersect, antialias);
}

SKWASM_EXPORT void canvas_drawColor(DisplayListBuilder* canvas,
                                    uint32_t color,
                                    DlBlendMode blendMode) {
  canvas->DrawColor(DlColor(color), blendMode);
}

SKWASM_EXPORT void canvas_drawLine(DisplayListBuilder* canvas,
                                   DlScalar x1,
                                   DlScalar y1,
                                   DlScalar x2,
                                   DlScalar y2,
                                   DlPaint* paint) {
  canvas->DrawLine(DlPoint{x1, y1}, DlPoint{x2, y2},
                   paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawPaint(DisplayListBuilder* canvas,
                                    DlPaint* paint) {
  canvas->DrawPaint(paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawRect(DisplayListBuilder* canvas,
                                   DlRect* rect,
                                   DlPaint* paint) {
  canvas->DrawRect(*rect, paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawRRect(DisplayListBuilder* canvas,
                                    const DlScalar* rrectValues,
                                    DlPaint* paint) {
  canvas->DrawRoundRect(createDlRRect(rrectValues), paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawDRRect(DisplayListBuilder* canvas,
                                     const DlScalar* outerRrectValues,
                                     const DlScalar* innerRrectValues,
                                     DlPaint* paint) {
  canvas->DrawDiffRoundRect(createDlRRect(outerRrectValues),
                            createDlRRect(innerRrectValues),
                            paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawOval(DisplayListBuilder* canvas,
                                   const DlRect* rect,
                                   DlPaint* paint) {
  canvas->DrawOval(*rect, paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawCircle(DisplayListBuilder* canvas,
                                     DlScalar x,
                                     DlScalar y,
                                     DlScalar radius,
                                     DlPaint* paint) {
  canvas->DrawCircle(DlPoint{x, y}, radius, paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawArc(DisplayListBuilder* canvas,
                                  const DlRect* rect,
                                  DlScalar startAngleDegrees,
                                  DlScalar sweepAngleDegrees,
                                  bool useCenter,
                                  DlPaint* paint) {
  // TODO(jacksongardner): Double check the units here (radians vs degrees)
  canvas->DrawArc(*rect, startAngleDegrees, sweepAngleDegrees, useCenter,
                  paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawPath(DisplayListBuilder* canvas,
                                   SkPath* path,
                                   DlPaint* paint) {
  canvas->DrawPath(DlPath(*path), paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawShadow(DisplayListBuilder* canvas,
                                     SkPath* path,
                                     DlScalar elevation,
                                     DlScalar devicePixelRatio,
                                     uint32_t color,
                                     bool transparentOccluder) {
  canvas->DrawShadow(DlPath(*path), DlColor(color), elevation,
                     transparentOccluder, devicePixelRatio);
}

SKWASM_EXPORT void canvas_drawParagraph(DisplayListBuilder* canvas,
                                        Paragraph* paragraph,
                                        DlScalar x,
                                        DlScalar y) {
  // TODO(jacksongardner): Paint the paragraph
  auto painter = SkwasmParagraphPainter(*canvas);
  paragraph->paint(&painter, x, y);
}

SKWASM_EXPORT void canvas_drawPicture(DisplayListBuilder* canvas,
                                      DisplayList* picture) {
  canvas->DrawDisplayList(sk_ref_sp(picture));
}

SKWASM_EXPORT void canvas_drawImage(DisplayListBuilder* canvas,
                                    SkImage* image,
                                    DlScalar offsetX,
                                    DlScalar offsetY,
                                    DlPaint* paint,
                                    FilterQuality quality) {
  canvas->DrawImage(DlImage::Make(image), DlPoint{offsetX, offsetY},
                    samplingOptionsForQuality(quality), paint);
}

SKWASM_EXPORT void canvas_drawImageRect(DisplayListBuilder* canvas,
                                        DlImage* image,
                                        DlRect* sourceRect,
                                        DlRect* destRect,
                                        DlPaint* paint,
                                        FilterQuality quality) {
  canvas->DrawImageRect(sk_ref_sp(image), *sourceRect, *destRect,
                        samplingOptionsForQuality(quality), paint,
                        DlSrcRectConstraint::kFast);
}

SKWASM_EXPORT void canvas_drawImageNine(DisplayListBuilder* canvas,
                                        DlImage* image,
                                        DlIRect* centerRect,
                                        DlRect* destinationRect,
                                        DlPaint* paint,
                                        FilterQuality quality) {
  canvas->DrawImageNine(sk_ref_sp(image), *centerRect, *destinationRect,
                        filterModeForQuality(quality), paint);
}

SKWASM_EXPORT void canvas_drawVertices(DisplayListBuilder* canvas,
                                       DlVertices* vertices,
                                       DlBlendMode mode,
                                       DlPaint* paint) {
  canvas->DrawVertices(vertices->shared_from_this(), mode,
                       paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawPoints(DisplayListBuilder* canvas,
                                     DlPointMode mode,
                                     DlPoint* points,
                                     int pointCount,
                                     DlPaint* paint) {
  canvas->DrawPoints(mode, pointCount, points, paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawAtlas(DisplayListBuilder* canvas,
                                    DlImage* atlas,
                                    DlRSTransform* transforms,
                                    DlRect* rects,
                                    uint32_t* colors,
                                    int spriteCount,
                                    DlBlendMode mode,
                                    DlRect* cullRect,
                                    DlPaint* paint) {
  std::vector<DlColor> dlColors(spriteCount);
  for (int i = 0; i < spriteCount; i++) {
    dlColors[i] = DlColor(colors[i]);
  }
  // TODO(jacksongardner): Check on the sampling quality. Is this passed in?
  canvas->DrawAtlas(
      sk_ref_sp(atlas), transforms, rects, dlColors.data(), spriteCount, mode,
      samplingOptionsForQuality(FilterQuality::medium), cullRect, paint);
}

SKWASM_EXPORT void canvas_getTransform(DisplayListBuilder* canvas,
                                       DlMatrix* outTransform) {
  *outTransform = canvas->GetMatrix();
}

SKWASM_EXPORT void canvas_getLocalClipBounds(DisplayListBuilder* canvas,
                                             DlRect* outRect) {
  *outRect = canvas->GetLocalClipCoverage();
}

SKWASM_EXPORT void canvas_getDeviceClipBounds(DisplayListBuilder* canvas,
                                              DlIRect* outRect) {
  *outRect = DlIRect::RoundOut(canvas->GetDestinationClipCoverage());
}
