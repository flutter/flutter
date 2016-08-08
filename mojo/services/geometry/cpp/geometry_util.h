// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_GEOMETRY_CPP_GEOMETRY_UTIL_H_
#define MOJO_SERVICES_GEOMETRY_CPP_GEOMETRY_UTIL_H_

#include "mojo/services/geometry/interfaces/geometry.mojom.h"

namespace mojo {

inline bool operator==(const Rect& lhs, const Rect& rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y && lhs.width == rhs.width &&
         lhs.height == lhs.height;
}

inline bool operator!=(const Rect& lhs, const Rect& rhs) {
  return !(lhs == rhs);
}

inline bool operator==(const Size& lhs, const Size& rhs) {
  return lhs.width == rhs.width && lhs.height == rhs.height;
}

inline bool operator!=(const Size& lhs, const Size& rhs) {
  return !(lhs == rhs);
}

inline bool operator==(const Point& lhs, const Point& rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y;
}

inline bool operator!=(const Point& lhs, const Point& rhs) {
  return !(lhs == rhs);
}

void SetIdentityTransform(Transform* transform);
void SetTranslationTransform(Transform* transform,
                             float x,
                             float y,
                             float z = 0.0f);
void SetScaleTransform(Transform* transform, float x, float y, float z = 1.0f);

void Translate(Transform* transform, float x, float y, float z = 0.0f);
void Scale(Transform* transform, float x, float y, float z = 1.0f);

TransformPtr CreateIdentityTransform();
TransformPtr CreateTranslationTransform(float x, float y, float z = 0.0f);
TransformPtr CreateScaleTransform(float x, float y, float z = 1.0f);

TransformPtr Translate(TransformPtr transform,
                       float x,
                       float y,
                       float z = 0.0f);
TransformPtr Scale(TransformPtr transform, float x, float y, float z = 1.0f);

PointF TransformPoint(const Transform& transform, const PointF& point);

}  // namespace mojo

#endif  // MOJO_SERVICES_GEOMETRY_CPP_GEOMETRY_UTIL_H_
