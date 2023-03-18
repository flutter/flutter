// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/local_matrix_filter_contents.h"

namespace impeller {

LocalMatrixFilterContents::LocalMatrixFilterContents() = default;

LocalMatrixFilterContents::~LocalMatrixFilterContents() = default;

void LocalMatrixFilterContents::SetMatrix(Matrix matrix) {
  matrix_ = matrix;
}

Matrix LocalMatrixFilterContents::GetLocalTransform(
    const Matrix& parent_transform) const {
  return matrix_;
}

std::optional<Entity> LocalMatrixFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Matrix& effect_transform,
    const Rect& coverage) const {
  return Entity::FromSnapshot(inputs[0]->GetSnapshot(renderer, entity),
                              entity.GetBlendMode(), entity.GetStencilDepth());
}

}  // namespace impeller
