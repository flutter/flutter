// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>

#include "impeller/geometry/matrix.h"

namespace impeller {
namespace scene {

class Camera {
 public:
  static Camera MakePerspective(Radians fov_y, Vector3 position);

  Camera LookAt(Vector3 target, Vector3 up = Vector3(0, -1, 0)) const;

  Matrix GetTransform(ISize target_size) const;

 private:
  Radians fov_y_ = Degrees(60);
  Vector3 position_ = Vector3();
  Vector3 target_ = Vector3(0, 0, -1);
  Vector3 up_ = Vector3(0, -1, 0);
  Scalar z_near_ = 0.1f;
  Scalar z_far_ = 1000.0f;

  mutable std::optional<Matrix> transform_;
};

}  // namespace scene
}  // namespace impeller
