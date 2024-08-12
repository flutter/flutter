// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/camera.h"

namespace impeller {
namespace scene {

Camera Camera::MakePerspective(Radians fov_y, Vector3 position) {
  Camera camera;
  camera.fov_y_ = fov_y;
  camera.position_ = position;
  return camera;
}

Camera Camera::LookAt(Vector3 target, Vector3 up) const {
  Camera camera = *this;
  camera.target_ = target;
  camera.up_ = up;
  return camera;
}

Matrix Camera::GetTransform(ISize target_size) const {
  if (transform_.has_value()) {
    return transform_.value();
  }

  transform_ = Matrix::MakePerspective(fov_y_, target_size, z_near_, z_far_) *
               Matrix::MakeLookAt(position_, target_, up_);

  return transform_.value();
}

}  // namespace scene
}  // namespace impeller
