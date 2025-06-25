// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "helpers.h"
#include "wrappers.h"

#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

#include "flutter/display_list/dl_builder.h"

using namespace skia::textlayout;
using namespace Skwasm;
using namespace flutter;

namespace {
// These numbers have been chosen empirically to give a result closest to the
// material spec.
// These values are also used by the CanvasKit renderer and the native engine.
// See:
//   flutter/display_list/skia/dl_sk_dispatcher.cc
//   flutter/lib/web_ui/lib/src/engine/canvaskit/util.dart
constexpr SkScalar kShadowAmbientAlpha = 0.039;
constexpr SkScalar kShadowSpotAlpha = 0.25;
constexpr SkScalar kShadowLightRadius = 1.1;
constexpr SkScalar kShadowLightHeight = 600.0;
constexpr SkScalar kShadowLightXOffset = 0;
constexpr SkScalar kShadowLightYOffset = -450;
}  // namespace

SKWASM_EXPORT void canvas_saveLayer(DisplayListBuilder* canvas,
                                    DlRect* rect,
                                    DlPaint* paint,
                                    DlImageFilter* backdrop,
                                    DlTileMode backdropTileMode) {
  // TODO(jacksongardner): make sure the tile mode is handled properly
  canvas->SaveLayer(rect ? std::optional(*rect) : std::nullopt, paint,
                    backdrop);
}

SKWASM_EXPORT void canvas_save(DisplayListBuilder* canvas) {
  canvas->Save();
}

SKWASM_EXPORT void canvas_restore(DisplayListBuilder* canvas) {
  canvas->Restore();
}

SKWASM_EXPORT void canvas_restoreToCount(DisplayListBuilder* canvas,
                                         int count) {
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
  canvas->ClipRoundRect(createRRect(rrectValues), DlClipOp::kIntersect,
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
  canvas->DrawLine(DlPoint{x1, y1}, DlPoint{x2, y2}, *paint);
}

SKWASM_EXPORT void canvas_drawPaint(DisplayListBuilder* canvas,
                                    DlPaint* paint) {
  canvas->DrawPaint(*paint);
}

SKWASM_EXPORT void canvas_drawRect(DisplayListBuilder* canvas,
                                   DlRect* rect,
                                   DlPaint* paint) {
  canvas->DrawRect(*rect, *paint);
}

SKWASM_EXPORT void canvas_drawRRect(DisplayListBuilder* canvas,
                                    const DlScalar* rrectValues,
                                    DlPaint* paint) {
  canvas->DrawRoundRect(createRRect(rrectValues), *paint);
}

SKWASM_EXPORT void canvas_drawDRRect(DisplayListBuilder* canvas,
                                     const DlScalar* outerRrectValues,
                                     const DlScalar* innerRrectValues,
                                     DlPaint* paint) {
  canvas->DrawDiffRoundRect(createRRect(outerRrectValues),
                            createRRect(innerRrectValues), *paint);
}

SKWASM_EXPORT void canvas_drawOval(DisplayListBuilder* canvas,
                                   const DlRect* rect,
                                   DlPaint* paint) {
  canvas->DrawOval(*rect, *paint);
}

SKWASM_EXPORT void canvas_drawCircle(DisplayListBuilder* canvas,
                                     DlScalar x,
                                     DlScalar y,
                                     DlScalar radius,
                                     DlPaint* paint) {
  canvas->DrawCircle(DlPoint{x, y}, radius, *paint);
}

SKWASM_EXPORT void canvas_drawArc(DisplayListBuilder* canvas,
                                  const DlRect* rect,
                                  DlScalar startAngleDegrees,
                                  DlScalar sweepAngleDegrees,
                                  bool useCenter,
                                  DlPaint* paint) {
  // TODO(jacksongardner): Double check the units here (radians vs degrees)
  canvas->DrawArc(*rect, startAngleDegrees, sweepAngleDegrees, useCenter,
                  *paint);
}

SKWASM_EXPORT void canvas_drawPath(DisplayListBuilder* canvas,
                                   SkPath* path,
                                   DlPaint* paint) {
  canvas->DrawPath(DlPath(*path), *paint);
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
  paragraph->paint(canvas, x, y);
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
  canvas->DrawVertices(vertices->shared_from_this(), mode, *paint);
}

SKWASM_EXPORT void canvas_drawPoints(DisplayListBuilder* canvas,
                                     DlPointMode mode,
                                     DlPoint* points,
                                     int pointCount,
                                     DlPaint* paint) {
  canvas->DrawPoints(mode, pointCount, points, *paint);
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
  canvas->DrawAtlas(sk_ref_sp(atlas), transforms, rects, colors, spriteCount,
                    mode, samplingOptionsForQuality(FilterQuality::medium),
                    cullRect, paint);
}

SKWASM_EXPORT void canvas_getTransform(SkCanvas* canvas, SkM44* outTransform) {
  *outTransform = canvas->getLocalToDevice();
}

SKWASM_EXPORT void canvas_getLocalClipBounds(SkCanvas* canvas,
                                             SkRect* outRect) {
  *outRect = canvas->getLocalClipBounds();
}

SKWASM_EXPORT void canvas_getDeviceClipBounds(SkCanvas* canvas,
                                              SkIRect* outRect) {
  *outRect = canvas->getDeviceClipBounds();
}
