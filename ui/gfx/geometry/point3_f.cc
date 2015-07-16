// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/point3_f.h"

#include "base/strings/stringprintf.h"

namespace gfx {

std::string Point3F::ToString() const {
  return base::StringPrintf("%f,%f,%f", x_, y_, z_);
}

Point3F operator+(const Point3F& lhs, const Vector3dF& rhs) {
  float x = lhs.x() + rhs.x();
  float y = lhs.y() + rhs.y();
  float z = lhs.z() + rhs.z();
  return Point3F(x, y, z);
}

// Subtract a vector from a point, producing a new point offset by the vector's
// inverse.
Point3F operator-(const Point3F& lhs, const Vector3dF& rhs) {
  float x = lhs.x() - rhs.x();
  float y = lhs.y() - rhs.y();
  float z = lhs.z() - rhs.z();
  return Point3F(x, y, z);
}

// Subtract one point from another, producing a vector that represents the
// distances between the two points along each axis.
Vector3dF operator-(const Point3F& lhs, const Point3F& rhs) {
  float x = lhs.x() - rhs.x();
  float y = lhs.y() - rhs.y();
  float z = lhs.z() - rhs.z();
  return Vector3dF(x, y, z);
}

}  // namespace gfx
