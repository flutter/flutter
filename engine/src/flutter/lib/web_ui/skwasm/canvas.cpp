// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <emscripten.h>
#include "export.h"
#include "helpers.h"
#include "wrappers.h"

using namespace Skwasm;

SKWASM_EXPORT void canvas_destroy(CanvasWrapper* wrapper) {
  delete wrapper;
}

SKWASM_EXPORT void canvas_saveLayer(CanvasWrapper* wrapper,
                                    SkRect* rect,
                                    SkPaint* paint) {
  wrapper->canvas->saveLayer(SkCanvas::SaveLayerRec(rect, paint, 0));
}

SKWASM_EXPORT void canvas_save(CanvasWrapper* wrapper) {
  wrapper->canvas->save();
}

SKWASM_EXPORT void canvas_restore(CanvasWrapper* wrapper) {
  wrapper->canvas->restore();
}

SKWASM_EXPORT void canvas_restoreToCount(CanvasWrapper* wrapper, int count) {
  wrapper->canvas->restoreToCount(count);
}

SKWASM_EXPORT int canvas_getSaveCount(CanvasWrapper* wrapper) {
  return wrapper->canvas->getSaveCount();
}

SKWASM_EXPORT void canvas_translate(CanvasWrapper* wrapper,
                                    SkScalar dx,
                                    SkScalar dy) {
  wrapper->canvas->translate(dx, dy);
}

SKWASM_EXPORT void canvas_scale(CanvasWrapper* wrapper,
                                SkScalar sx,
                                SkScalar sy) {
  wrapper->canvas->scale(sx, sy);
}

SKWASM_EXPORT void canvas_rotate(CanvasWrapper* wrapper, SkScalar degrees) {
  wrapper->canvas->rotate(degrees);
}

SKWASM_EXPORT void canvas_skew(CanvasWrapper* wrapper,
                               SkScalar sx,
                               SkScalar sy) {
  wrapper->canvas->skew(sx, sy);
}

SKWASM_EXPORT void canvas_transform(CanvasWrapper* wrapper,
                                    const SkM44* matrix44) {
  wrapper->canvas->concat(*matrix44);
}

SKWASM_EXPORT void canvas_clipRect(CanvasWrapper* wrapper,
                                   const SkRect* rect,
                                   SkClipOp op,
                                   bool antialias) {
  wrapper->canvas->clipRect(*rect, op, antialias);
}

SKWASM_EXPORT void canvas_clipRRect(CanvasWrapper* wrapper,
                                    const SkScalar* rrectValues,
                                    bool antialias) {
  wrapper->canvas->clipRRect(createRRect(rrectValues), antialias);
}

SKWASM_EXPORT void canvas_clipPath(CanvasWrapper* wrapper,
                                   SkPath* path,
                                   bool antialias) {
  wrapper->canvas->clipPath(*path, antialias);
}

SKWASM_EXPORT void canvas_drawColor(CanvasWrapper* wrapper,
                                    SkColor color,
                                    SkBlendMode blendMode) {
  makeCurrent(wrapper->context);
  wrapper->canvas->drawColor(color, blendMode);
}

SKWASM_EXPORT void canvas_drawLine(CanvasWrapper* wrapper,
                                   SkScalar x1,
                                   SkScalar y1,
                                   SkScalar x2,
                                   SkScalar y2,
                                   SkPaint* paint) {
  makeCurrent(wrapper->context);
  wrapper->canvas->drawLine(x1, y1, x2, y2, *paint);
}

SKWASM_EXPORT void canvas_drawPaint(CanvasWrapper* wrapper, SkPaint* paint) {
  makeCurrent(wrapper->context);
  wrapper->canvas->drawPaint(*paint);
}

SKWASM_EXPORT void canvas_drawRect(CanvasWrapper* wrapper,
                                   SkRect* rect,
                                   SkPaint* paint) {
  makeCurrent(wrapper->context);
  wrapper->canvas->drawRect(*rect, *paint);
}

SKWASM_EXPORT void canvas_drawRRect(CanvasWrapper* wrapper,
                                    const SkScalar* rrectValues,
                                    SkPaint* paint) {
  makeCurrent(wrapper->context);
  wrapper->canvas->drawRRect(createRRect(rrectValues), *paint);
}

SKWASM_EXPORT void canvas_drawDRRect(CanvasWrapper* wrapper,
                                     const SkScalar* outerRrectValues,
                                     const SkScalar* innerRrectValues,
                                     SkPaint* paint) {
  makeCurrent(wrapper->context);
  wrapper->canvas->drawDRRect(createRRect(outerRrectValues),
                              createRRect(innerRrectValues), *paint);
}

SKWASM_EXPORT void canvas_drawOval(CanvasWrapper* wrapper,
                                   const SkRect* rect,
                                   SkPaint* paint) {
  makeCurrent(wrapper->context);
  wrapper->canvas->drawOval(*rect, *paint);
}

SKWASM_EXPORT void canvas_drawCircle(CanvasWrapper* wrapper,
                                     SkScalar x,
                                     SkScalar y,
                                     SkScalar radius,
                                     SkPaint* paint) {
  makeCurrent(wrapper->context);

  wrapper->canvas->drawCircle(x, y, radius, *paint);
}

SKWASM_EXPORT void canvas_drawArc(CanvasWrapper* wrapper,
                                  const SkRect* rect,
                                  SkScalar startAngleDegrees,
                                  SkScalar sweepAngleDegrees,
                                  bool useCenter,
                                  SkPaint* paint) {
  makeCurrent(wrapper->context);
  wrapper->canvas->drawArc(*rect, startAngleDegrees, sweepAngleDegrees,
                           useCenter, *paint);
}

SKWASM_EXPORT void canvas_drawPath(CanvasWrapper* wrapper,
                                   SkPath* path,
                                   SkPaint* paint) {
  makeCurrent(wrapper->context);

  wrapper->canvas->drawPath(*path, *paint);
}

SKWASM_EXPORT void canvas_drawPicture(CanvasWrapper* wrapper,
                                      SkPicture* picture) {
  makeCurrent(wrapper->context);

  wrapper->canvas->drawPicture(picture);
}

SKWASM_EXPORT void canvas_getTransform(CanvasWrapper* wrapper,
                                       SkM44* outTransform) {
  *outTransform = wrapper->canvas->getLocalToDevice();
}

SKWASM_EXPORT void canvas_getLocalClipBounds(CanvasWrapper* wrapper,
                                             SkRect* outRect) {
  *outRect = wrapper->canvas->getLocalClipBounds();
}

SKWASM_EXPORT void canvas_getDeviceClipBounds(CanvasWrapper* wrapper,
                                              SkIRect* outRect) {
  *outRect = wrapper->canvas->getDeviceClipBounds();
}
