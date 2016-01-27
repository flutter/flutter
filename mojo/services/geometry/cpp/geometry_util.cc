// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/geometry/cpp/geometry_util.h"

#include <string.h>

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

}  // namespace mojo
