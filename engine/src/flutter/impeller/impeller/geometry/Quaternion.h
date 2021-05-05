// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "Vector.h"

namespace rl {
namespace geom {

struct Quaternion {
  union {
    struct {
      double x;
      double y;
      double z;
      double w;
    };
    double e[4];
  };

  Quaternion() : x(0.0), y(0.0), z(0.0), w(1.0) {}

  Quaternion(double px, double py, double pz, double pw)
      : x(px), y(py), z(pz), w(pw) {}

  Quaternion(const Vector3& axis, double angle) {
    const auto sine = sin(angle * 0.5);
    x = sine * axis.x;
    y = sine * axis.y;
    z = sine * axis.z;
    w = cos(angle * 0.5);
  }

  double dot(const Quaternion& q) const {
    return x * q.x + y * q.y + z * q.z + w * q.w;
  }

  double length() const { return sqrt(x * x + y * y + z * z + w * w); }

  Quaternion normalize() const {
    auto m = 1.0 / length();
    return {x * m, y * m, z * m, w * m};
  }

  Quaternion slerp(const Quaternion& to, double time) const;

  Quaternion operator*(const Quaternion& o) const {
    return {
        w * o.x + x * o.w + y * o.z - z * o.y,
        w * o.y + y * o.w + z * o.x - x * o.z,
        w * o.z + z * o.w + x * o.y - y * o.x,
        w * o.w - x * o.x - y * o.y - z * o.z,
    };
  }

  Quaternion operator*(double scale) const {
    return {scale * x, scale * y, scale * z, scale * w};
  }

  Quaternion operator+(const Quaternion& o) const {
    return {x + o.x, y + o.y, z + o.z, w + o.w};
  }

  Quaternion operator-(const Quaternion& o) const {
    return {x - o.x, y - o.y, z - o.z, w - o.w};
  }

  bool operator==(const Quaternion& o) const {
    return x == o.x && y == o.y && z == o.z && w == o.w;
  }

  bool operator!=(const Quaternion& o) const {
    return x != o.x || y != o.y || z != o.z || w != o.w;
  }

  std::string toString() const;
};

}  // namespace geom
}  // namespace rl
