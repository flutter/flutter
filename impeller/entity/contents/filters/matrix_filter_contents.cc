// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/matrix_filter_contents.h"

namespace impeller {

MatrixFilterContents::MatrixFilterContents() = default;

MatrixFilterContents::~MatrixFilterContents() = default;

void MatrixFilterContents::SetMatrix(Matrix matrix) {
  matrix_ = matrix;
}

void MatrixFilterContents::SetIsForSubpass(bool is_subpass) {
  is_for_subpass_ = is_subpass;
  FilterContents::SetIsForSubpass(is_subpass);
}

void MatrixFilterContents::SetSamplerDescriptor(SamplerDescriptor desc) {
  sampler_descriptor_ = std::move(desc);
}

std::optional<Entity> MatrixFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Matrix& effect_transform,
    const Rect& coverage,
    const std::optional<Rect>& coverage_hint) const {
  auto snapshot = inputs[0]->GetSnapshot("Matrix", renderer, entity);
  if (!snapshot.has_value()) {
    return std::nullopt;
  }

  // The filter's matrix needs to be applied within the space defined by the
  // scene's current transformation matrix (CTM). For example: If the CTM is
  // scaled up, then translations applied by the matrix should be magnified
  // accordingly.
  //
  // To accomplish this, we sandwitch the filter's matrix within the CTM in both
  // cases. But notice that for the subpass backdrop filter case, we use the
  // "effect transform" instead of the Entity's transform!
  //
  // That's because in the subpass backdrop filter case, the Entity's transform
  // isn't actually the captured CTM of the scene like it usually is; instead,
  // it's just a screen space translation that offsets the backdrop texture (as
  // mentioned above). And so we sneak the subpass's captured CTM in through the
  // effect transform.

  auto transform =
      is_for_subpass_ ? effect_transform : entity.GetTransformation();
  snapshot->transform = transform *           //
                        matrix_ *             //
                        transform.Invert() *  //
                        snapshot->transform;

  snapshot->sampler_descriptor = sampler_descriptor_;
  return Entity::FromSnapshot(snapshot, entity.GetBlendMode(),
                              entity.GetStencilDepth());
}

std::optional<Rect> MatrixFilterContents::GetFilterCoverage(
    const FilterInput::Vector& inputs,
    const Entity& entity,
    const Matrix& effect_transform) const {
  if (inputs.empty()) {
    return std::nullopt;
  }

  auto coverage = inputs[0]->GetCoverage(entity);
  if (!coverage.has_value()) {
    return std::nullopt;
  }
  auto& m =
      is_for_subpass_ ? effect_transform : inputs[0]->GetTransform(entity);
  auto transform = m *          //
                   matrix_ *    //
                   m.Invert();  //
  return coverage->TransformBounds(transform);
}

}  // namespace impeller
