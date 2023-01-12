// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/geometry/matrix_decomposition.h"

namespace impeller {
namespace scene {

struct AnimationTransforms {
  MatrixDecomposition bind_pose;
  MatrixDecomposition animated_pose;
};

}  // namespace scene
}  // namespace impeller
