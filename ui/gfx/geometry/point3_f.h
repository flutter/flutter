// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_GEOMETRY_POINT3_F_H_
#define UI_GFX_GEOMETRY_POINT3_F_H_

#include <iosfwd>
#include <string>

#include "ui/gfx/geometry/point_f.h"
#include "ui/gfx/geometry/vector3d_f.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

// A point has an x, y and z coordinate.
class GFX_EXPORT Point3F {
 public:
  Point3F() : x_(0), y_(0), z_(0) {}

  Point3F(float x, float y, float z) : x_(x), y_(y), z_(z) {}

  explicit Point3F(const PointF& point) : x_(point.x()), y_(point.y()), z_(0) {}

  ~Point3F() {}

  void Scale(float scale) {
    Scale(scale, scale, scale);
  }

  void Scale(float x_scale, float y_scale, float z_scale) {
    SetPoint(x() * x_scale, y() * y_scale, z() * z_scale);
  }

  float x() const { return x_; }
  float y() const { return y_; }
  float z() const { return z_; }

  void set_x(float x) { x_ = x; }
  void set_y(float y) { y_ = y; }
  void set_z(float z) { z_ = z; }

  void SetPoint(float x, float y, float z) {
    x_ = x;
    y_ = y;
    z_ = z;
  }

  // Offset the point by the given vector.
  void operator+=(const Vector3dF& v) {
    x_ += v.x();
    y_ += v.y();
    z_ += v.z();
  }

  // Offset the point by the given vector's inverse.
  void operator-=(const Vector3dF& v) {
    x_ -= v.x();
    y_ -= v.y();
    z_ -= v.z();
  }

  // Returns the squared euclidean distance between two points.
  float SquaredDistanceTo(const Point3F& other) const {
    float dx = x_ - other.x_;
    float dy = y_ - other.y_;
    float dz = z_ - other.z_;
    return dx * dx + dy * dy + dz * dz;
  }

  PointF AsPointF() const { return PointF(x_, y_); }

  // Returns a string representation of 3d point.
  std::string ToString() const;

 private:
  float x_;
  float y_;
  float z_;

  // copy/assign are allowed.
};

inline bool operator==(const Point3F& lhs, const Point3F& rhs) {
  return lhs.x() == rhs.x() && lhs.y() == rhs.y() && lhs.z() == rhs.z();
}

inline bool operator!=(const Point3F& lhs, const Point3F& rhs) {
  return !(lhs == rhs);
}

// Add a vector to a point, producing a new point offset by the vector.
GFX_EXPORT Point3F operator+(const Point3F& lhs, const Vector3dF& rhs);

// Subtract a vector from a point, producing a new point offset by the vector's
// inverse.
GFX_EXPORT Point3F operator-(const Point3F& lhs, const Vector3dF& rhs);

// Subtract one point from another, producing a vector that represents the
// distances between the two points along each axis.
GFX_EXPORT Vector3dF operator-(const Point3F& lhs, const Point3F& rhs);

inline Point3F PointAtOffsetFromOrigin(const Vector3dF& offset) {
  return Point3F(offset.x(), offset.y(), offset.z());
}

inline Point3F ScalePoint(const Point3F& p,
                          float x_scale,
                          float y_scale,
                          float z_scale) {
  return Point3F(p.x() * x_scale, p.y() * y_scale, p.z() * z_scale);
}

inline Point3F ScalePoint(const Point3F& p, float scale) {
  return ScalePoint(p, scale, scale, scale);
}

// This is declared here for use in gtest-based unit tests but is defined in
// the gfx_test_support target. Depend on that to use this in your unit test.
// This should not be used in production code - call ToString() instead.
void PrintTo(const Point3F& point, ::std::ostream* os);

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_POINT3_F_H_
