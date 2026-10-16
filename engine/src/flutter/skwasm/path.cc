// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <unordered_map>

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/helpers.h"
#include "flutter/skwasm/live_objects.h"
#include "third_party/skia/include/core/SkPathBuilder.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/skia/include/pathops/SkPathOps.h"
#include "third_party/skia/include/utils/SkParsePath.h"

namespace {
std::unordered_map<const SkPathBuilder*, flutter::DlPath>&
GetPathSnapshotCache() {
  static auto* cache =
      new std::unordered_map<const SkPathBuilder*, flutter::DlPath>();
  return *cache;
}

void InvalidatePathSnapshot(const SkPathBuilder* path) {
  GetPathSnapshotCache().erase(path);
}
}  // namespace

namespace Skwasm {
flutter::DlPath SnapshotPath(const SkPathBuilder* path) {
  auto& cache = GetPathSnapshotCache();
  auto it = cache.find(path);
  if (it != cache.end()) {
    return it->second;
  }
  flutter::DlPath dl_path(path->snapshot());
  dl_path.IsConvex();
  cache.emplace(path, dl_path);
  return dl_path;
}
}  // namespace Skwasm

SKWASM_EXPORT SkPathBuilder* path_create() {
  Skwasm::live_path_count++;
  auto* path = new SkPathBuilder();
  InvalidatePathSnapshot(path);
  return path;
}

SKWASM_EXPORT void path_dispose(SkPathBuilder* path) {
  Skwasm::live_path_count--;
  InvalidatePathSnapshot(path);
  delete path;
}

SKWASM_EXPORT SkPathBuilder* path_copy(SkPathBuilder* path) {
  Skwasm::live_path_count++;
  auto* copy = new SkPathBuilder(Skwasm::SnapshotPath(path).GetSkPath());
  InvalidatePathSnapshot(copy);
  return copy;
}

SKWASM_EXPORT void path_setFillType(SkPathBuilder* path,
                                    SkPathFillType fill_type) {
  InvalidatePathSnapshot(path);
  path->setFillType(fill_type);
}

SKWASM_EXPORT SkPathFillType path_getFillType(SkPathBuilder* path) {
  return path->fillType();
}

SKWASM_EXPORT void path_moveTo(SkPathBuilder* path, SkScalar x, SkScalar y) {
  InvalidatePathSnapshot(path);
  path->moveTo({x, y});
}

SKWASM_EXPORT void path_relativeMoveTo(SkPathBuilder* path,
                                       SkScalar x,
                                       SkScalar y) {
  InvalidatePathSnapshot(path);
  path->rMoveTo({x, y});
}

SKWASM_EXPORT void path_lineTo(SkPathBuilder* path, SkScalar x, SkScalar y) {
  InvalidatePathSnapshot(path);
  path->lineTo({x, y});
}

SKWASM_EXPORT void path_relativeLineTo(SkPathBuilder* path,
                                       SkScalar x,
                                       SkScalar y) {
  InvalidatePathSnapshot(path);
  path->rLineTo({x, y});
}

SKWASM_EXPORT void path_quadraticBezierTo(SkPathBuilder* path,
                                          SkScalar x1,
                                          SkScalar y1,
                                          SkScalar x2,
                                          SkScalar y2) {
  InvalidatePathSnapshot(path);
  path->quadTo({x1, y1}, {x2, y2});
}

SKWASM_EXPORT void path_relativeQuadraticBezierTo(SkPathBuilder* path,
                                                  SkScalar x1,
                                                  SkScalar y1,
                                                  SkScalar x2,
                                                  SkScalar y2) {
  InvalidatePathSnapshot(path);
  path->rQuadTo({x1, y1}, {x2, y2});
}

SKWASM_EXPORT void path_cubicTo(SkPathBuilder* path,
                                SkScalar x1,
                                SkScalar y1,
                                SkScalar x2,
                                SkScalar y2,
                                SkScalar x3,
                                SkScalar y3) {
  InvalidatePathSnapshot(path);
  path->cubicTo({x1, y1}, {x2, y2}, {x3, y3});
}

SKWASM_EXPORT void path_relativeCubicTo(SkPathBuilder* path,
                                        SkScalar x1,
                                        SkScalar y1,
                                        SkScalar x2,
                                        SkScalar y2,
                                        SkScalar x3,
                                        SkScalar y3) {
  InvalidatePathSnapshot(path);
  path->rCubicTo({x1, y1}, {x2, y2}, {x3, y3});
}

SKWASM_EXPORT void path_conicTo(SkPathBuilder* path,
                                SkScalar x1,
                                SkScalar y1,
                                SkScalar x2,
                                SkScalar y2,
                                SkScalar w) {
  InvalidatePathSnapshot(path);
  path->conicTo({x1, y1}, {x2, y2}, w);
}

SKWASM_EXPORT void path_relativeConicTo(SkPathBuilder* path,
                                        SkScalar x1,
                                        SkScalar y1,
                                        SkScalar x2,
                                        SkScalar y2,
                                        SkScalar w) {
  InvalidatePathSnapshot(path);
  path->rConicTo({x1, y1}, {x2, y2}, w);
}

SKWASM_EXPORT void path_arcToOval(SkPathBuilder* path,
                                  const SkRect* rect,
                                  SkScalar start_angle,
                                  SkScalar sweep_angle,
                                  bool force_move_to) {
  InvalidatePathSnapshot(path);
  path->arcTo(*rect, start_angle, sweep_angle, force_move_to);
}

SKWASM_EXPORT void path_arcToRotated(SkPathBuilder* path,
                                     SkScalar rx,
                                     SkScalar ry,
                                     SkScalar x_axis_rotate,
                                     SkPathBuilder::ArcSize arc_size,
                                     SkPathDirection path_direction,
                                     SkScalar x,
                                     SkScalar y) {
  InvalidatePathSnapshot(path);
  path->arcTo({rx, ry}, x_axis_rotate, arc_size, path_direction, {x, y});
}

SKWASM_EXPORT void path_relativeArcToRotated(SkPathBuilder* path,
                                             SkScalar rx,
                                             SkScalar ry,
                                             SkScalar x_axis_rotate,
                                             SkPathBuilder::ArcSize arc_size,
                                             SkPathDirection path_direction,
                                             SkScalar x,
                                             SkScalar y) {
  InvalidatePathSnapshot(path);
  path->rArcTo({rx, ry}, x_axis_rotate, arc_size, path_direction, {x, y});
}

SKWASM_EXPORT void path_addRect(SkPathBuilder* path, const SkRect* rect) {
  InvalidatePathSnapshot(path);
  path->addRect(*rect);
}

SKWASM_EXPORT void path_addOval(SkPathBuilder* path, const SkRect* oval) {
  InvalidatePathSnapshot(path);
  path->addOval(*oval, SkPathDirection::kCW, 1);
}

SKWASM_EXPORT void path_addArc(SkPathBuilder* path,
                               const SkRect* oval,
                               SkScalar start_angle,
                               SkScalar sweep_angle) {
  InvalidatePathSnapshot(path);
  path->addArc(*oval, start_angle, sweep_angle);
}

SKWASM_EXPORT void path_addPolygon(SkPathBuilder* path,
                                   const SkPoint* points,
                                   int count,
                                   bool close) {
  InvalidatePathSnapshot(path);
  path->addPolygon({points, count}, close);
}

SKWASM_EXPORT void path_addRRect(SkPathBuilder* path,
                                 const SkScalar* rrect_values) {
  InvalidatePathSnapshot(path);
  path->addRRect(Skwasm::CreateSkRRect(rrect_values), SkPathDirection::kCW);
}

SKWASM_EXPORT void path_addPath(SkPathBuilder* path,
                                const SkPathBuilder* other,
                                const SkScalar* matrix_33,
                                SkPath::AddPathMode extend_path) {
  InvalidatePathSnapshot(path);
  path->addPath(Skwasm::SnapshotPath(other).GetSkPath(),
                Skwasm::CreateSkMatrix(matrix_33), extend_path);
}

SKWASM_EXPORT void path_close(SkPathBuilder* path) {
  InvalidatePathSnapshot(path);
  path->close();
}

SKWASM_EXPORT void path_reset(SkPathBuilder* path) {
  InvalidatePathSnapshot(path);
  path->reset();
}

SKWASM_EXPORT bool path_contains(SkPathBuilder* path, SkScalar x, SkScalar y) {
  return path->contains({x, y});
}

SKWASM_EXPORT void path_transform(SkPathBuilder* path,
                                  const SkScalar* matrix_33) {
  InvalidatePathSnapshot(path);
  path->transform(Skwasm::CreateSkMatrix(matrix_33));
}

SKWASM_EXPORT void path_getBounds(SkPathBuilder* path, SkRect* rect) {
  *rect = path->computeFiniteBounds().value_or(SkRect());
}

SKWASM_EXPORT SkPathBuilder* path_combine(SkPathOp operation,
                                          const SkPathBuilder* path1,
                                          const SkPathBuilder* path2) {
  if (auto result = Op(path1->snapshot(), path2->snapshot(), operation)) {
    Skwasm::live_path_count++;
    SkPathBuilder* output = new SkPathBuilder(result.value());
    output->setFillType(path1->fillType());
    return output;
  } else {
    return nullptr;
  }
}

SKWASM_EXPORT SkString* path_getSvgString(SkPathBuilder* path) {
  Skwasm::live_string_count++;
  SkString* string = new SkString(SkParsePath::ToSVGString(path->snapshot()));
  return string;
}
