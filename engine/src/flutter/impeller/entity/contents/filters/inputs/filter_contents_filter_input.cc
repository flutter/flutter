// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/inputs/filter_contents_filter_input.h"

#include <utility>

#include "impeller/base/strings.h"
#include "impeller/entity/contents/filters/filter_contents.h"

namespace impeller {

FilterContentsFilterInput::FilterContentsFilterInput(
    std::shared_ptr<FilterContents> filter)
    : filter_(std::move(filter)) {}

FilterContentsFilterInput::~FilterContentsFilterInput() = default;

FilterInput::Variant FilterContentsFilterInput::GetInput() const {
  return filter_;
}

std::optional<Snapshot> FilterContentsFilterInput::GetSnapshot(
    const std::string& label,
    const ContentContext& renderer,
    const Entity& entity,
    std::optional<Rect> coverage_limit) const {
  if (!snapshot_.has_value()) {
    snapshot_ = filter_->RenderToSnapshot(
        renderer,        // renderer
        entity,          // entity
        coverage_limit,  // coverage_limit
        std::nullopt,    // sampler_descriptor
        true,            // msaa_enabled
        SPrintF("Filter to %s Filter Snapshot", label.c_str()));  // label
  }
  return snapshot_;
}

std::optional<Rect> FilterContentsFilterInput::GetCoverage(
    const Entity& entity) const {
  return filter_->GetCoverage(entity);
}

Matrix FilterContentsFilterInput::GetLocalTransform(
    const Entity& entity) const {
  return filter_->GetLocalTransform(entity.GetTransformation());
}

Matrix FilterContentsFilterInput::GetTransform(const Entity& entity) const {
  return filter_->GetTransform(entity.GetTransformation());
}

void FilterContentsFilterInput::PopulateGlyphAtlas(
    const std::shared_ptr<LazyGlyphAtlas>& lazy_glyph_atlas,
    Scalar scale) {
  filter_->PopulateGlyphAtlas(lazy_glyph_atlas, scale);
}

bool FilterContentsFilterInput::IsTranslationOnly() const {
  return filter_->IsTranslationOnly();
}

bool FilterContentsFilterInput::IsLeaf() const {
  return false;
}

void FilterContentsFilterInput::SetLeafInputs(
    const FilterInput::Vector& inputs) {
  filter_->SetLeafInputs(inputs);
}

void FilterContentsFilterInput::SetEffectTransform(const Matrix& matrix) {
  filter_->SetEffectTransform(matrix);
}

void FilterContentsFilterInput::SetRenderingMode(
    Entity::RenderingMode rendering_mode) {
  filter_->SetRenderingMode(rendering_mode);
}

}  // namespace impeller
