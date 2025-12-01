// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "helpers.h"
#include "live_objects.h"
#include "third_party/skia/include/core/SkPathBuilder.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/skia/include/pathops/SkPathOps.h"
#include "third_party/skia/include/utils/SkParsePath.h"

using namespace Skwasm;

SKWASM_EXPORT SkPathBuilder* path_create() {
  livePathCount++;
  return new SkPathBuilder();
}

SKWASM_EXPORT void path_dispose(SkPathBuilder* path) {
  livePathCount--;
  delete path;
}

SKWASM_EXPORT SkPathBuilder* path_copy(SkPathBuilder* path) {
  livePathCount++;
  return new SkPathBuilder(path->snapshot());
}

SKWASM_EXPORT void path_setFillType(SkPathBuilder* path,
                                    SkPathFillType fillType) {
  path->setFillType(fillType);
}

SKWASM_EXPORT SkPathFillType path_getFillType(SkPathBuilder* path) {
  return path->fillType();
}

SKWASM_EXPORT void path_moveTo(SkPathBuilder* path, SkScalar x, SkScalar y) {
  path->moveTo({x, y});
}

SKWASM_EXPORT void path_relativeMoveTo(SkPathBuilder* path,
                                       SkScalar x,
                                       SkScalar y) {
  path->rMoveTo({x, y});
}

SKWASM_EXPORT void path_lineTo(SkPathBuilder* path, SkScalar x, SkScalar y) {
  path->lineTo({x, y});
}

SKWASM_EXPORT void path_relativeLineTo(SkPathBuilder* path,
                                       SkScalar x,
                                       SkScalar y) {
  path->rLineTo({x, y});
}

SKWASM_EXPORT void path_quadraticBezierTo(SkPathBuilder* path,
                                          SkScalar x1,
                                          SkScalar y1,
                                          SkScalar x2,
                                          SkScalar y2) {
  path->quadTo({x1, y1}, {x2, y2});
}

SKWASM_EXPORT void path_relativeQuadraticBezierTo(SkPathBuilder* path,
                                                  SkScalar x1,
                                                  SkScalar y1,
                                                  SkScalar x2,
                                                  SkScalar y2) {
  path->rQuadTo({x1, y1}, {x2, y2});
}

SKWASM_EXPORT void path_cubicTo(SkPathBuilder* path,
                                SkScalar x1,
                                SkScalar y1,
                                SkScalar x2,
                                SkScalar y2,
                                SkScalar x3,
                                SkScalar y3) {
  path->cubicTo({x1, y1}, {x2, y2}, {x3, y3});
}

SKWASM_EXPORT void path_relativeCubicTo(SkPathBuilder* path,
                                        SkScalar x1,
                                        SkScalar y1,
                                        SkScalar x2,
                                        SkScalar y2,
                                        SkScalar x3,
                                        SkScalar y3) {
  path->rCubicTo({x1, y1}, {x2, y2}, {x3, y3});
}

SKWASM_EXPORT void path_conicTo(SkPathBuilder* path,
                                SkScalar x1,
                                SkScalar y1,
                                SkScalar x2,
                                SkScalar y2,
                                SkScalar w) {
  path->conicTo({x1, y1}, {x2, y2}, w);
}

SKWASM_EXPORT void path_relativeConicTo(SkPathBuilder* path,
                                        SkScalar x1,
                                        SkScalar y1,
                                        SkScalar x2,
                                        SkScalar y2,
                                        SkScalar w) {
  path->rConicTo({x1, y1}, {x2, y2}, w);
}

SKWASM_EXPORT void path_arcToOval(SkPathBuilder* path,
                                  const SkRect* rect,
                                  SkScalar startAngle,
                                  SkScalar sweepAngle,
                                  bool forceMoveTo) {
  path->arcTo(*rect, startAngle, sweepAngle, forceMoveTo);
}

SKWASM_EXPORT void path_arcToRotated(SkPathBuilder* path,
                                     SkScalar rx,
                                     SkScalar ry,
                                     SkScalar xAxisRotate,
                                     SkPathBuilder::ArcSize arcSize,
                                     SkPathDirection pathDirection,
                                     SkScalar x,
                                     SkScalar y) {
  path->arcTo({rx, ry}, xAxisRotate, arcSize, pathDirection, {x, y});
}

SKWASM_EXPORT void path_relativeArcToRotated(SkPathBuilder* path,
                                             SkScalar rx,
                                             SkScalar ry,
                                             SkScalar xAxisRotate,
                                             SkPathBuilder::ArcSize arcSize,
                                             SkPathDirection pathDirection,
                                             SkScalar x,
                                             SkScalar y) {
  path->rArcTo({rx, ry}, xAxisRotate, arcSize, pathDirection, {x, y});
}

SKWASM_EXPORT void path_addRect(SkPathBuilder* path, const SkRect* rect) {
  path->addRect(*rect);
}

SKWASM_EXPORT void path_addOval(SkPathBuilder* path, const SkRect* oval) {
  path->addOval(*oval, SkPathDirection::kCW, 1);
}

SKWASM_EXPORT void path_addArc(SkPathBuilder* path,
                               const SkRect* oval,
                               SkScalar startAngle,
                               SkScalar sweepAngle) {
  path->addArc(*oval, startAngle, sweepAngle);
}

SKWASM_EXPORT void path_addPolygon(SkPathBuilder* path,
                                   const SkPoint* points,
                                   int count,
                                   bool close) {
  path->addPolygon({points, count}, close);
}

SKWASM_EXPORT void path_addRRect(SkPathBuilder* path,
                                 const SkScalar* rrectValues) {
  path->addRRect(createSkRRect(rrectValues), SkPathDirection::kCW);
}

SKWASM_EXPORT void path_addPath(SkPathBuilder* path,
                                const SkPathBuilder* other,
                                const SkScalar* matrix33,
                                SkPath::AddPathMode extendPath) {
  path->addPath(other->snapshot(), createSkMatrix(matrix33), extendPath);
}

SKWASM_EXPORT void path_close(SkPathBuilder* path) {
  path->close();
}

SKWASM_EXPORT void path_reset(SkPathBuilder* path) {
  path->reset();
}

SKWASM_EXPORT bool path_contains(SkPathBuilder* path, SkScalar x, SkScalar y) {
  return path->contains({x, y});
}

SKWASM_EXPORT void path_transform(SkPathBuilder* path,
                                  const SkScalar* matrix33) {
  path->transform(createSkMatrix(matrix33));
}

SKWASM_EXPORT void path_getBounds(SkPathBuilder* path, SkRect* rect) {
  *rect = path->computeFiniteBounds().value_or(SkRect());
}

SKWASM_EXPORT SkPathBuilder* path_combine(SkPathOp operation,
                                          const SkPathBuilder* path1,
                                          const SkPathBuilder* path2) {
  if (auto result = Op(path1->snapshot(), path2->snapshot(), operation)) {
    livePathCount++;
    SkPathBuilder* output = new SkPathBuilder(result.value());
    output->setFillType(path1->fillType());
    return output;
  } else {
    return nullptr;
  }
}

SKWASM_EXPORT SkString* path_getSvgString(SkPathBuilder* path) {
  liveStringCount++;
  SkString* string = new SkString(SkParsePath::ToSVGString(path->snapshot()));
  return string;
}
