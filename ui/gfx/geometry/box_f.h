// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_GEOMETRY_BOX_F_H_
#define UI_GFX_GEOMETRY_BOX_F_H_

#include <iosfwd>
#include <string>

#include "ui/gfx/geometry/point3_f.h"
#include "ui/gfx/geometry/vector3d_f.h"

namespace gfx {

// A 3d version of gfx::RectF, with the positive z-axis pointed towards
// the camera.
class GFX_EXPORT BoxF {
 public:
  BoxF()
      : width_(0.f),
        height_(0.f),
        depth_(0.f) {}

  BoxF(float width, float height, float depth)
      : width_(width < 0 ? 0 : width),
        height_(height < 0 ? 0 : height),
        depth_(depth < 0 ? 0 : depth) {}

  BoxF(float x, float y, float z, float width, float height, float depth)
      : origin_(x, y, z),
        width_(width < 0 ? 0 : width),
        height_(height < 0 ? 0 : height),
        depth_(depth < 0 ? 0 : depth) {}

  BoxF(const Point3F& origin, float width, float height, float depth)
      : origin_(origin),
        width_(width < 0 ? 0 : width),
        height_(height < 0 ? 0 : height),
        depth_(depth < 0 ? 0 : depth) {}

  ~BoxF() {}

  // Scales all three axes by the given scale.
  void Scale(float scale) {
    Scale(scale, scale, scale);
  }

  // Scales each axis by the corresponding given scale.
  void Scale(float x_scale, float y_scale, float z_scale) {
    origin_.Scale(x_scale, y_scale, z_scale);
    set_size(width_ * x_scale, height_ * y_scale, depth_ * z_scale);
  }

  // Moves the box by the specified distance in each dimension.
  void operator+=(const Vector3dF& offset) {
    origin_ += offset;
  }

  // Returns true if the box has no interior points.
  bool IsEmpty() const;

  // Computes the union of this box with the given box. The union is the
  // smallest box that contains both boxes.
  void Union(const BoxF& box);

  std::string ToString() const;

  float x() const { return origin_.x(); }
  void set_x(float x) { origin_.set_x(x); }

  float y() const { return origin_.y(); }
  void set_y(float y) { origin_.set_y(y); }

  float z() const { return origin_.z(); }
  void set_z(float z) { origin_.set_z(z); }

  float width() const { return width_; }
  void set_width(float width) { width_ = width < 0 ? 0 : width; }

  float height() const { return height_; }
  void set_height(float height) { height_ = height < 0 ? 0 : height; }

  float depth() const { return depth_; }
  void set_depth(float depth) { depth_ = depth < 0 ? 0 : depth; }

  float right() const { return x() + width(); }
  float bottom() const { return y() + height(); }
  float front() const { return z() + depth(); }

  void set_size(float width, float height, float depth) {
    width_ = width < 0 ? 0 : width;
    height_ = height < 0 ? 0 : height;
    depth_ = depth < 0 ? 0 : depth;
  }

  const Point3F& origin() const { return origin_; }
  void set_origin(const Point3F& origin) { origin_ = origin; }

  // Expands |this| to contain the given point, if necessary. Please note, even
  // if |this| is empty, after the function |this| will continue to contain its
  // |origin_|.
  void ExpandTo(const Point3F& point);

  // Expands |this| to contain the given box, if necessary. Please note, even
  // if |this| is empty, after the function |this| will continue to contain its
  // |origin_|.
  void ExpandTo(const BoxF& box);

 private:
  // Expands the box to contain the two given points. It is required that each
  // component of |min| is less than or equal to the corresponding component in
  // |max|. Precisely, what this function does is ensure that after the function
  // completes, |this| contains origin_, min, max, and origin_ + (width_,
  // height_, depth_), even if the box is empty. Emptiness checks are handled in
  // the public function Union.
  void ExpandTo(const Point3F& min, const Point3F& max);

  Point3F origin_;
  float width_;
  float height_;
  float depth_;
};

GFX_EXPORT BoxF UnionBoxes(const BoxF& a, const BoxF& b);

inline BoxF ScaleBox(const BoxF& b,
                     float x_scale,
                     float y_scale,
                     float z_scale) {
  return BoxF(b.x() * x_scale,
              b.y() * y_scale,
              b.z() * z_scale,
              b.width() * x_scale,
              b.height() * y_scale,
              b.depth() * z_scale);
}

inline BoxF ScaleBox(const BoxF& b, float scale) {
  return ScaleBox(b, scale, scale, scale);
}

inline bool operator==(const BoxF& a, const BoxF& b) {
  return a.origin() == b.origin() && a.width() == b.width() &&
         a.height() == b.height() && a.depth() == b.depth();
}

inline bool operator!=(const BoxF& a, const BoxF& b) {
  return !(a == b);
}

inline BoxF operator+(const BoxF& b, const Vector3dF& v) {
  return BoxF(b.x() + v.x(),
              b.y() + v.y(),
              b.z() + v.z(),
              b.width(),
              b.height(),
              b.depth());
}

// This is declared here for use in gtest-based unit tests but is defined in
// the gfx_test_support target. Depend on that to use this in your unit test.
// This should not be used in production code - call ToString() instead.
void PrintTo(const BoxF& box, ::std::ostream* os);

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_BOX_F_H_
