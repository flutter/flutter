// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_text_skia.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/skwasm/canvas_text.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/helpers.h"
#include "flutter/skwasm/text/text_types.h"
#include "flutter/skwasm/wrappers.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPathBuilder.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

namespace {
class SkwasmParagraphPainter : public skia::textlayout::ParagraphPainter {
 public:
  SkwasmParagraphPainter(flutter::DisplayListBuilder& builder,
                         const std::vector<flutter::DlPaint>& paints)
      : builder_(builder), paints_(paints) {}

  virtual void drawTextBlob(const sk_sp<SkTextBlob>& blob,
                            SkScalar x,
                            SkScalar y,
                            const SkPaintOrID& paint) override {
    if (!blob) {
      return;
    }

    const int* paintID = std::get_if<PaintID>(&paint);
    auto dlPaint = paintID ? paints_[*paintID] : flutter::DlPaint();
    builder_.DrawText(flutter::textFromBlob(blob), x, y, dlPaint);
  }

  virtual void drawTextShadow(const sk_sp<SkTextBlob>& blob,
                              SkScalar x,
                              SkScalar y,
                              SkColor color,
                              SkScalar blurSigma) override {
    if (!blob) {
      return;
    }

    flutter::DlPaint paint;
    paint.setColor(flutter::DlColor(color));
    if (blurSigma > 0.0) {
      flutter::DlBlurMaskFilter filter(flutter::DlBlurStyle::kNormal, blurSigma,
                                       false);
      paint.setMaskFilter(&filter);
    }
    builder_.DrawText(flutter::textFromBlob(blob), x, y, paint);
  }

  virtual void drawRect(const SkRect& rect, const SkPaintOrID& paint) override {
    const int* paintID = std::get_if<PaintID>(&paint);
    auto dlPaint = paintID ? paints_[*paintID] : flutter::DlPaint();
    builder_.DrawRect(flutter::ToDlRect(rect), dlPaint);
  }

  virtual void drawFilledRect(const SkRect& rect,
                              const DecorationStyle& decorStyle) override {
    flutter::DlPaint paint = ToDlPaint(decorStyle, flutter::DlDrawStyle::kFill);
    builder_.DrawRect(flutter::ToDlRect(rect), paint);
  }

  virtual void drawPath(const SkPath& path,
                        const DecorationStyle& decorStyle) override {
    builder_.DrawPath(flutter::DlPath(path), this->ToDlPaint(decorStyle));
  }

  virtual void drawLine(SkScalar x0,
                        SkScalar y0,
                        SkScalar x1,
                        SkScalar y1,
                        const DecorationStyle& decorStyle) override {
    auto paint = this->ToDlPaint(decorStyle);
    auto dashPathEffect = decorStyle.getDashPathEffect();

    if (dashPathEffect) {
      builder_.DrawDashedLine(
          flutter::DlPoint(x0, y0), flutter::DlPoint(x1, y1),
          dashPathEffect->fOnLength, dashPathEffect->fOffLength, paint);
    } else {
      builder_.DrawLine(flutter::DlPoint(x0, y0), flutter::DlPoint(x1, y1),
                        paint);
    }
  }

  virtual void clipRect(const SkRect& rect) override {
    builder_.ClipRect(flutter::ToDlRect(rect));
  }

  virtual void translate(SkScalar dx, SkScalar dy) override {
    builder_.Translate(dx, dy);
  }

  virtual void save() override { builder_.Save(); }

  virtual void restore() override { builder_.Restore(); }

 private:
  const std::vector<flutter::DlPaint>& paints_;
  flutter::DisplayListBuilder& builder_;

  flutter::DlPaint ToDlPaint(
      const DecorationStyle& decor_style,
      flutter::DlDrawStyle draw_style = flutter::DlDrawStyle::kStroke) {
    flutter::DlPaint paint;
    paint.setDrawStyle(draw_style);
    paint.setAntiAlias(true);
    paint.setColor(flutter::DlColor(decor_style.getColor()));
    paint.setStrokeWidth(decor_style.getStrokeWidth());
    return paint;
  }
};
}  // namespace

SKWASM_EXPORT void canvas_saveLayer(
    flutter::DisplayListBuilder* canvas,
    flutter::DlRect* rect,
    flutter::DlPaint* paint,
    Skwasm::sp_wrapper<flutter::DlImageFilter>* backdrop) {
  canvas->SaveLayer(rect ? std::optional(*rect) : std::nullopt, paint,
                    backdrop ? backdrop->Raw() : nullptr);
}

SKWASM_EXPORT void canvas_save(flutter::DisplayListBuilder* canvas) {
  canvas->Save();
}

SKWASM_EXPORT void canvas_restore(flutter::DisplayListBuilder* canvas) {
  canvas->Restore();
}

SKWASM_EXPORT void canvas_restoreToCount(flutter::DisplayListBuilder* canvas,
                                         int count) {
  if (count > canvas->GetSaveCount()) {
    // According to the docs:
    // "If count is greater than the current getSaveCount then nothing happens."
    return;
  }
  canvas->RestoreToCount(count);
}

SKWASM_EXPORT int canvas_getSaveCount(flutter::DisplayListBuilder* canvas) {
  return canvas->GetSaveCount();
}

SKWASM_EXPORT void canvas_translate(flutter::DisplayListBuilder* canvas,
                                    float dx,
                                    float dy) {
  canvas->Translate(dx, dy);
}

SKWASM_EXPORT void canvas_scale(flutter::DisplayListBuilder* canvas,
                                float sx,
                                float sy) {
  canvas->Scale(sx, sy);
}

SKWASM_EXPORT void canvas_rotate(flutter::DisplayListBuilder* canvas,
                                 flutter::DlScalar degrees) {
  canvas->Rotate(degrees);
}

SKWASM_EXPORT void canvas_skew(flutter::DisplayListBuilder* canvas,
                               flutter::DlScalar sx,
                               flutter::DlScalar sy) {
  canvas->Skew(sx, sy);
}

SKWASM_EXPORT void canvas_transform(flutter::DisplayListBuilder* canvas,
                                    const flutter::DlMatrix* matrix44) {
  canvas->Transform(*matrix44);
}

SKWASM_EXPORT void canvas_clear(flutter::DisplayListBuilder* canvas,
                                uint32_t color) {
  canvas->DrawColor(flutter::DlColor(color), flutter::DlBlendMode::kSrc);
}

SKWASM_EXPORT void canvas_clipRect(flutter::DisplayListBuilder* canvas,
                                   const flutter::DlRect* rect,
                                   flutter::DlClipOp op,
                                   bool antialias) {
  canvas->ClipRect(*rect, op);
}

SKWASM_EXPORT void canvas_clipRRect(flutter::DisplayListBuilder* canvas,
                                    const SkScalar* rrectValues,
                                    bool antialias) {
  canvas->ClipRoundRect(Skwasm::createDlRRect(rrectValues),
                        flutter::DlClipOp::kIntersect, antialias);
}

SKWASM_EXPORT void canvas_clipPath(flutter::DisplayListBuilder* canvas,
                                   SkPathBuilder* path,
                                   bool antialias) {
  canvas->ClipPath(flutter::DlPath(path->snapshot()),
                   flutter::DlClipOp::kIntersect, antialias);
}

SKWASM_EXPORT void canvas_drawColor(flutter::DisplayListBuilder* canvas,
                                    uint32_t color,
                                    flutter::DlBlendMode blendMode) {
  canvas->DrawColor(flutter::DlColor(color), blendMode);
}

SKWASM_EXPORT void canvas_drawLine(flutter::DisplayListBuilder* canvas,
                                   flutter::DlScalar x1,
                                   flutter::DlScalar y1,
                                   flutter::DlScalar x2,
                                   flutter::DlScalar y2,
                                   flutter::DlPaint* paint) {
  canvas->DrawLine(flutter::DlPoint{x1, y1}, flutter::DlPoint{x2, y2},
                   paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawPaint(flutter::DisplayListBuilder* canvas,
                                    flutter::DlPaint* paint) {
  canvas->DrawPaint(paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawRect(flutter::DisplayListBuilder* canvas,
                                   flutter::DlRect* rect,
                                   flutter::DlPaint* paint) {
  canvas->DrawRect(*rect, paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawRRect(flutter::DisplayListBuilder* canvas,
                                    const SkScalar* rrectValues,
                                    flutter::DlPaint* paint) {
  canvas->DrawRoundRect(Skwasm::createDlRRect(rrectValues),
                        paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawDRRect(flutter::DisplayListBuilder* canvas,
                                     const SkScalar* outerRrectValues,
                                     const SkScalar* innerRrectValues,
                                     flutter::DlPaint* paint) {
  canvas->DrawDiffRoundRect(Skwasm::createDlRRect(outerRrectValues),
                            Skwasm::createDlRRect(innerRrectValues),
                            paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawOval(flutter::DisplayListBuilder* canvas,
                                   const flutter::DlRect* rect,
                                   flutter::DlPaint* paint) {
  canvas->DrawOval(*rect, paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawCircle(flutter::DisplayListBuilder* canvas,
                                     flutter::DlScalar x,
                                     flutter::DlScalar y,
                                     flutter::DlScalar radius,
                                     flutter::DlPaint* paint) {
  canvas->DrawCircle(flutter::DlPoint{x, y}, radius,
                     paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawArc(flutter::DisplayListBuilder* canvas,
                                  const flutter::DlRect* rect,
                                  flutter::DlScalar startAngleDegrees,
                                  flutter::DlScalar sweepAngleDegrees,
                                  bool useCenter,
                                  flutter::DlPaint* paint) {
  canvas->DrawArc(*rect, startAngleDegrees, sweepAngleDegrees, useCenter,
                  paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawPath(flutter::DisplayListBuilder* canvas,
                                   SkPathBuilder* path,
                                   flutter::DlPaint* paint) {
  canvas->DrawPath(flutter::DlPath(path->snapshot()),
                   paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawShadow(flutter::DisplayListBuilder* canvas,
                                     SkPathBuilder* path,
                                     flutter::DlScalar elevation,
                                     flutter::DlScalar devicePixelRatio,
                                     uint32_t color,
                                     bool transparentOccluder) {
  canvas->DrawShadow(flutter::DlPath(path->snapshot()), flutter::DlColor(color),
                     elevation, transparentOccluder, devicePixelRatio);
}

SKWASM_EXPORT void canvas_drawParagraph(flutter::DisplayListBuilder* canvas,
                                        Skwasm::Paragraph* paragraph,
                                        flutter::DlScalar x,
                                        flutter::DlScalar y) {
  auto painter = SkwasmParagraphPainter(*canvas, paragraph->paints);
  paragraph->skia_paragraph->paint(&painter, x, y);
}

SKWASM_EXPORT void canvas_drawPicture(flutter::DisplayListBuilder* canvas,
                                      flutter::DisplayList* picture) {
  canvas->DrawDisplayList(sk_ref_sp(picture));
}

SKWASM_EXPORT void canvas_drawImage(flutter::DisplayListBuilder* canvas,
                                    flutter::DlImage* image,
                                    flutter::DlScalar offsetX,
                                    flutter::DlScalar offsetY,
                                    flutter::DlPaint* paint,
                                    Skwasm::FilterQuality quality) {
  canvas->DrawImage(sk_ref_sp(image), flutter::DlPoint{offsetX, offsetY},
                    Skwasm::samplingOptionsForQuality(quality), paint);
}

SKWASM_EXPORT void canvas_drawImageRect(flutter::DisplayListBuilder* canvas,
                                        flutter::DlImage* image,
                                        flutter::DlRect* sourceRect,
                                        flutter::DlRect* destRect,
                                        flutter::DlPaint* paint,
                                        Skwasm::FilterQuality quality) {
  canvas->DrawImageRect(sk_ref_sp(image), *sourceRect, *destRect,
                        Skwasm::samplingOptionsForQuality(quality), paint,
                        flutter::DlSrcRectConstraint::kStrict);
}

SKWASM_EXPORT void canvas_drawImageNine(flutter::DisplayListBuilder* canvas,
                                        flutter::DlImage* image,
                                        flutter::DlIRect* centerRect,
                                        flutter::DlRect* destinationRect,
                                        flutter::DlPaint* paint,
                                        Skwasm::FilterQuality quality) {
  canvas->DrawImageNine(sk_ref_sp(image), *centerRect, *destinationRect,
                        filterModeForQuality(quality), paint);
}

SKWASM_EXPORT void canvas_drawVertices(
    flutter::DisplayListBuilder* canvas,
    Skwasm::sp_wrapper<flutter::DlVertices>* vertices,
    flutter::DlBlendMode mode,
    flutter::DlPaint* paint) {
  canvas->DrawVertices(vertices->Shared(), mode,
                       paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawPoints(flutter::DisplayListBuilder* canvas,
                                     flutter::DlPointMode mode,
                                     flutter::DlPoint* points,
                                     int pointCount,
                                     flutter::DlPaint* paint) {
  canvas->DrawPoints(mode, pointCount, points,
                     paint ? *paint : flutter::DlPaint());
}

SKWASM_EXPORT void canvas_drawAtlas(flutter::DisplayListBuilder* canvas,
                                    flutter::DlImage* atlas,
                                    flutter::DlRSTransform* transforms,
                                    flutter::DlRect* rects,
                                    uint32_t* colors,
                                    int spriteCount,
                                    flutter::DlBlendMode mode,
                                    flutter::DlRect* cullRect,
                                    flutter::DlPaint* paint) {
  std::vector<flutter::DlColor> dl_colors(spriteCount);
  for (int i = 0; i < spriteCount; i++) {
    dl_colors[i] = flutter::DlColor(colors[i]);
  }
  canvas->DrawAtlas(
      sk_ref_sp(atlas), transforms, rects, dl_colors.data(), spriteCount, mode,
      Skwasm::samplingOptionsForQuality(Skwasm::FilterQuality::medium),
      cullRect, paint);
}

SKWASM_EXPORT void canvas_getTransform(flutter::DisplayListBuilder* canvas,
                                       flutter::DlMatrix* outTransform) {
  *outTransform = canvas->GetMatrix();
}

SKWASM_EXPORT void canvas_getLocalClipBounds(
    flutter::DisplayListBuilder* canvas,
    flutter::DlRect* outRect) {
  *outRect = canvas->GetLocalClipCoverage();
}

SKWASM_EXPORT void canvas_getDeviceClipBounds(
    flutter::DisplayListBuilder* canvas,
    flutter::DlIRect* outRect) {
  *outRect = flutter::DlIRect::RoundOut(canvas->GetDestinationClipCoverage());
}

SKWASM_EXPORT bool canvas_quickReject(flutter::DisplayListBuilder* canvas,
                                      flutter::DlRect* rect) {
  return canvas->QuickReject(*rect);
}
