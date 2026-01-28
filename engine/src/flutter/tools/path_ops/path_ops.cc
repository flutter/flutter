// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "path_ops.h"

#include "third_party/skia/include/core/SkPath.h"

namespace flutter {
SkPathBuilder* CreatePath(SkPathFillType fill_type) {
  return new SkPathBuilder(fill_type);
}

void DestroyPath(SkPathBuilder* path) {
  delete path;
}

void MoveTo(SkPathBuilder* path, SkScalar x, SkScalar y) {
  path->moveTo(x, y);
}

void LineTo(SkPathBuilder* path, SkScalar x, SkScalar y) {
  path->lineTo(x, y);
}

void CubicTo(SkPathBuilder* path,
             SkScalar x1,
             SkScalar y1,
             SkScalar x2,
             SkScalar y2,
             SkScalar x3,
             SkScalar y3) {
  path->cubicTo(x1, y1, x2, y2, x3, y3);
}

void Close(SkPathBuilder* path) {
  path->close();
}

void Reset(SkPathBuilder* path) {
  path->reset();
}

void Op(SkPathBuilder* one, SkPathBuilder* two, SkPathOp op) {
  SkPath p1 = one->snapshot();
  SkPath p2 = two->snapshot();
  if (std::optional<SkPath> result = Op(p1, p2, op)) {
    *one = result.value();
  }
}

int GetFillType(SkPathBuilder* path) {
  return static_cast<int>(path->fillType());
}

struct PathData* Data(SkPathBuilder* pb) {
  SkPath path = pb->snapshot();
  int point_count = path.countPoints();
  int verb_count = path.countVerbs();

  auto data = new PathData();
  data->points = new float[point_count * 2];
  data->point_count = point_count * 2;
  data->verbs = new uint8_t[verb_count];
  data->verb_count = verb_count;

  SkSpan<uint8_t> outVerbs(data->verbs, verb_count);
  path.getVerbs(outVerbs);
  SkSpan<SkPoint> outPoints(reinterpret_cast<SkPoint*>(data->points),
                            point_count);
  path.getPoints(outPoints);
  return data;
}

void DestroyData(PathData* data) {
  delete[] data->points;
  delete[] data->verbs;
  delete data;
}

}  // namespace flutter
