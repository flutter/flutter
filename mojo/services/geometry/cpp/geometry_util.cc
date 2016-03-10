// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/geometry/cpp/geometry_util.h"

#include <string.h>

#include <limits>

namespace mojo {

static const float kIdentityMatrix[]{
    1.f, 0.f, 0.f, 0.f,  // comments to prevent
    0.f, 1.f, 0.f, 0.f,  // auto formatter reflow
    0.f, 0.f, 1.f, 0.f,  //
    0.f, 0.f, 0.f, 1.f};

void SetIdentityTransform(Transform* transform) {
  transform->matrix.resize(16u);
  memcpy(transform->matrix.data(), kIdentityMatrix, sizeof(kIdentityMatrix));
}

void SetTranslationTransform(Transform* transform, float x, float y, float z) {
  SetIdentityTransform(transform);
  transform->matrix[3] = x;
  transform->matrix[7] = y;
  transform->matrix[11] = z;
}

PointF TransformPoint(const Transform& transform, const PointF& point) {
  PointF result;
  float w = transform.matrix[12] * point.x + transform.matrix[13] * point.y +
            transform.matrix[15];
  if (w) {
    w = 1.f / w;
    result.x = (transform.matrix[0] * point.x + transform.matrix[1] * point.y +
                transform.matrix[3]) *
               w;
    result.y = (transform.matrix[4] * point.x + transform.matrix[5] * point.y +
                transform.matrix[7]) *
               w;
  } else {
    result.x = std::numeric_limits<float>::infinity();
    result.y = std::numeric_limits<float>::infinity();
  }
  return result;
}

}  // namespace mojo
