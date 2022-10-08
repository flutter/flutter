// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "color_source_contents.h"

#include "impeller/entity/entity.h"
#include "impeller/geometry/matrix.h"

namespace impeller {

ColorSourceContents::ColorSourceContents() = default;

ColorSourceContents::~ColorSourceContents() = default;

void ColorSourceContents::SetGeometry(std::unique_ptr<Geometry> geometry) {
  geometry_ = std::move(geometry);
}

const std::unique_ptr<Geometry>& ColorSourceContents::GetGeometry() const {
  return geometry_;
}

void ColorSourceContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

Scalar ColorSourceContents::GetAlpha() const {
  return alpha_;
}

void ColorSourceContents::SetMatrix(Matrix matrix) {
  inverse_matrix_ = matrix.Invert();
}

const Matrix& ColorSourceContents::GetInverseMatrix() const {
  return inverse_matrix_;
}

std::optional<Rect> ColorSourceContents::GetCoverage(
    const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransformation());
};

bool ColorSourceContents::ShouldRender(
    const Entity& entity,
    const std::optional<Rect>& stencil_coverage) const {
  if (!stencil_coverage.has_value()) {
    return false;
  }
  return Contents::ShouldRender(entity, stencil_coverage);
}

}  // namespace impeller
