// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tessellator.h"

#include <vector>

namespace impeller {
PathBuilder* CreatePathBuilder() {
  return new PathBuilder();
}

void DestroyPathBuilder(PathBuilder* builder) {
  delete builder;
}

void MoveTo(PathBuilder* builder, Scalar x, Scalar y) {
  builder->MoveTo(Point(x, y));
}

void LineTo(PathBuilder* builder, Scalar x, Scalar y) {
  builder->LineTo(Point(x, y));
}

void CubicTo(PathBuilder* builder,
             Scalar x1,
             Scalar y1,
             Scalar x2,
             Scalar y2,
             Scalar x3,
             Scalar y3) {
  builder->CubicCurveTo(Point(x1, y1), Point(x2, y2), Point(x3, y3));
}

void Close(PathBuilder* builder) {
  builder->Close();
}

struct Vertices* Tessellate(PathBuilder* builder,
                            int fill_type,
                            Scalar scale,
                            Scalar angle_tolerance,
                            Scalar cusp_limit) {
  auto path = builder->CopyPath(static_cast<FillType>(fill_type));
  auto smoothing = SmoothingApproximation(scale, angle_tolerance, cusp_limit);
  auto polyline = path.CreatePolyline(smoothing);

  std::vector<float> points;
  if (Tessellator{}.Tessellate(path.GetFillType(), polyline,
                               [&points](Point vertex) {
                                 points.push_back(vertex.x);
                                 points.push_back(vertex.y);
                               }) != Tessellator::Result::kSuccess) {
    return nullptr;
  }

  Vertices* vertices = new Vertices();
  vertices->points = new float[points.size()];
  if (!vertices->points) {
    return nullptr;
  }
  vertices->length = points.size();
  std::copy(points.begin(), points.end(), vertices->points);
  return vertices;
}

void DestroyVertices(Vertices* vertices) {
  delete vertices->points;
  delete vertices;
}

}  // namespace impeller
