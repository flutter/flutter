// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/vector3d_f.h"

#include <cmath>

#include "base/strings/stringprintf.h"

namespace gfx {

Vector3dF::Vector3dF()
    : x_(0),
      y_(0),
      z_(0) {
}

Vector3dF::Vector3dF(float x, float y, float z)
    : x_(x),
      y_(y),
      z_(z) {
}

Vector3dF::Vector3dF(const Vector2dF& other)
    : x_(other.x()),
      y_(other.y()),
      z_(0) {
}

std::string Vector3dF::ToString() const {
  return base::StringPrintf("[%f %f %f]", x_, y_, z_);
}

bool Vector3dF::IsZero() const {
  return x_ == 0 && y_ == 0 && z_ == 0;
}

void Vector3dF::Add(const Vector3dF& other) {
  x_ += other.x_;
  y_ += other.y_;
  z_ += other.z_;
}

void Vector3dF::Subtract(const Vector3dF& other) {
  x_ -= other.x_;
  y_ -= other.y_;
  z_ -= other.z_;
}

double Vector3dF::LengthSquared() const {
  return static_cast<double>(x_) * x_ + static_cast<double>(y_) * y_ +
      static_cast<double>(z_) * z_;
}

float Vector3dF::Length() const {
  return static_cast<float>(std::sqrt(LengthSquared()));
}

void Vector3dF::Scale(float x_scale, float y_scale, float z_scale) {
  x_ *= x_scale;
  y_ *= y_scale;
  z_ *= z_scale;
}

void Vector3dF::Cross(const Vector3dF& other) {
  float x = y_ * other.z() - z_ * other.y();
  float y = z_ * other.x() - x_ * other.z();
  float z = x_ * other.y() - y_ * other.x();
  x_ = x;
  y_ = y;
  z_ = z;
}

float DotProduct(const Vector3dF& lhs, const Vector3dF& rhs) {
  return lhs.x() * rhs.x() + lhs.y() * rhs.y() + lhs.z() * rhs.z();
}

Vector3dF ScaleVector3d(const Vector3dF& v,
                        float x_scale,
                        float y_scale,
                        float z_scale) {
  Vector3dF scaled_v(v);
  scaled_v.Scale(x_scale, y_scale, z_scale);
  return scaled_v;
}

}  // namespace gfx
