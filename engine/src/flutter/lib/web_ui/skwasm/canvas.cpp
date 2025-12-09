// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "canvas_text.h"
#include "export.h"
#include "helpers.h"
#include "text/text_types.h"
#include "wrappers.h"

#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPathBuilder.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_text_skia.h"

using namespace Skwasm;
using namespace flutter;

namespace {
class SkwasmParagraphPainter : public skia::textlayout::ParagraphPainter {
 public:
  SkwasmParagraphPainter(DisplayListBuilder& builder,
                         const std::vector<DlPaint>& paints)
      : _builder(builder), _paints(paints) {}

  virtual void drawTextBlob(const sk_sp<SkTextBlob>& blob,
                            SkScalar x,
                            SkScalar y,
                            const SkPaintOrID& paint) override {
    if (!blob) {
      return;
    }

    const int* paintID = std::get_if<PaintID>(&paint);
    auto dlPaint = paintID ? _paints[*paintID] : DlPaint();
    _builder.DrawText(textFromBlob(blob), x, y, dlPaint);
  }

  virtual void drawTextShadow(const sk_sp<SkTextBlob>& blob,
                              SkScalar x,
                              SkScalar y,
                              SkColor color,
                              SkScalar blurSigma) override {
    if (!blob) {
      return;
    }

    DlPaint paint;
    paint.setColor(DlColor(color));
    if (blurSigma > 0.0) {
      DlBlurMaskFilter filter(DlBlurStyle::kNormal, blurSigma, false);
      paint.setMaskFilter(&filter);
    }
    _builder.DrawText(textFromBlob(blob), x, y, paint);
  }

  virtual void drawRect(const SkRect& rect, const SkPaintOrID& paint) override {
    const int* paintID = std::get_if<PaintID>(&paint);
    auto dlPaint = paintID ? _paints[*paintID] : DlPaint();
    _builder.DrawRect(ToDlRect(rect), dlPaint);
  }

  virtual void drawFilledRect(const SkRect& rect,
                              const DecorationStyle& decorStyle) override {
    DlPaint paint = toDlPaint(decorStyle, DlDrawStyle::kFill);
    _builder.DrawRect(ToDlRect(rect), paint);
  }

  virtual void drawPath(const SkPath& path,
                        const DecorationStyle& decorStyle) override {
    _builder.DrawPath(DlPath(path), toDlPaint(decorStyle));
  }

  virtual void drawLine(SkScalar x0,
                        SkScalar y0,
                        SkScalar x1,
                        SkScalar y1,
                        const DecorationStyle& decorStyle) override {
    auto paint = toDlPaint(decorStyle);
    auto dashPathEffect = decorStyle.getDashPathEffect();

    if (dashPathEffect) {
      _builder.DrawDashedLine(DlPoint(x0, y0), DlPoint(x1, y1),
                              dashPathEffect->fOnLength,
                              dashPathEffect->fOffLength, paint);
    } else {
      _builder.DrawLine(DlPoint(x0, y0), DlPoint(x1, y1), paint);
    }
  }

  virtual void clipRect(const SkRect& rect) override {
    _builder.ClipRect(ToDlRect(rect));
  }

  virtual void translate(SkScalar dx, SkScalar dy) override {
    _builder.Translate(dx, dy);
  }

  virtual void save() override { _builder.Save(); }

  virtual void restore() override { _builder.Restore(); }

 private:
  DisplayListBuilder& _builder;
  const std::vector<DlPaint>& _paints;

  DlPaint toDlPaint(const DecorationStyle& decor_style,
                    DlDrawStyle draw_style = DlDrawStyle::kStroke) {
    DlPaint paint;
    paint.setDrawStyle(draw_style);
    paint.setAntiAlias(true);
    paint.setColor(DlColor(decor_style.getColor()));
    paint.setStrokeWidth(decor_style.getStrokeWidth());
    return paint;
  }
};
}  // namespace

SKWASM_EXPORT void canvas_saveLayer(DisplayListBuilder* canvas,
                                    DlRect* rect,
                                    DlPaint* paint,
                                    sp_wrapper<DlImageFilter>* backdrop) {
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

SKWASM_EXPORT void canvas_clear(DisplayListBuilder* canvas, uint32_t color) {
  canvas->DrawColor(DlColor(color), DlBlendMode::kSrc);
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
                                   SkPathBuilder* path,
                                   bool antialias) {
  canvas->ClipPath(DlPath(path->snapshot()), DlClipOp::kIntersect, antialias);
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
  canvas->DrawArc(*rect, startAngleDegrees, sweepAngleDegrees, useCenter,
                  paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawPath(DisplayListBuilder* canvas,
                                   SkPathBuilder* path,
                                   DlPaint* paint) {
  canvas->DrawPath(DlPath(path->snapshot()), paint ? *paint : DlPaint());
}

SKWASM_EXPORT void canvas_drawShadow(DisplayListBuilder* canvas,
                                     SkPathBuilder* path,
                                     DlScalar elevation,
                                     DlScalar devicePixelRatio,
                                     uint32_t color,
                                     bool transparentOccluder) {
  canvas->DrawShadow(DlPath(path->snapshot()), DlColor(color), elevation,
                     transparentOccluder, devicePixelRatio);
}

SKWASM_EXPORT void canvas_drawParagraph(DisplayListBuilder* canvas,
                                        Paragraph* paragraph,
                                        DlScalar x,
                                        DlScalar y) {
  auto painter = SkwasmParagraphPainter(*canvas, paragraph->paints);
  paragraph->skiaParagraph->paint(&painter, x, y);
}

SKWASM_EXPORT void canvas_drawPicture(DisplayListBuilder* canvas,
                                      DisplayList* picture) {
  canvas->DrawDisplayList(sk_ref_sp(picture));
}

SKWASM_EXPORT void canvas_drawImage(DisplayListBuilder* canvas,
                                    DlImage* image,
                                    DlScalar offsetX,
                                    DlScalar offsetY,
                                    DlPaint* paint,
                                    FilterQuality quality) {
  canvas->DrawImage(sk_ref_sp(image), DlPoint{offsetX, offsetY},
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
                        DlSrcRectConstraint::kStrict);
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
                                       sp_wrapper<DlVertices>* vertices,
                                       DlBlendMode mode,
                                       DlPaint* paint) {
  canvas->DrawVertices(vertices->shared(), mode, paint ? *paint : DlPaint());
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

SKWASM_EXPORT bool canvas_quickReject(DisplayListBuilder* canvas,
                                      DlRect* rect) {
  return canvas->QuickReject(*rect);
}
