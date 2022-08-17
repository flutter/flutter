// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "color_source_contents.h"

#include "impeller/entity/entity.h"
#include "impeller/geometry/matrix.h"

namespace impeller {

ColorSourceContents::ColorSourceContents() = default;

ColorSourceContents::~ColorSourceContents() = default;

void ColorSourceContents::SetPath(Path path) {
  path_ = path;
}

const Path& ColorSourceContents::GetPath() const {
  return path_;
}

void ColorSourceContents::SetMatrix(Matrix matrix) {
  inverse_matrix_ = matrix.Invert();
}

const Matrix& ColorSourceContents::GetInverseMatrix() const {
  return inverse_matrix_;
}

std::optional<Rect> ColorSourceContents::GetCoverage(
    const Entity& entity) const {
  return path_.GetTransformedBoundingBox(entity.GetTransformation());
};

}  // namespace impeller
