// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/filter_contents.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <memory>
#include <optional>
#include <tuple>
#include <utility>

#include "flutter/fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/border_mask_blur_filter_contents.h"
#include "impeller/entity/contents/filters/directional_gaussian_blur_filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/filters/local_matrix_filter_contents.h"
#include "impeller/entity/contents/filters/matrix_filter_contents.h"
#include "impeller/entity/contents/filters/morphology_filter_contents.h"
#include "impeller/entity/contents/filters/yuv_to_rgb_filter_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

std::shared_ptr<FilterContents> FilterContents::MakeDirectionalGaussianBlur(
    FilterInput::Ref input,
    Sigma sigma,
    Vector2 direction,
    BlurStyle blur_style,
    Entity::TileMode tile_mode,
    bool is_second_pass,
    Sigma secondary_sigma) {
  auto blur = std::make_shared<DirectionalGaussianBlurFilterContents>();
  blur->SetInputs({std::move(input)});
  blur->SetSigma(sigma);
  blur->SetDirection(direction);
  blur->SetBlurStyle(blur_style);
  blur->SetTileMode(tile_mode);
  blur->SetIsSecondPass(is_second_pass);
  blur->SetSecondarySigma(secondary_sigma);
  return blur;
}

std::shared_ptr<FilterContents> FilterContents::MakeGaussianBlur(
    const FilterInput::Ref& input,
    Sigma sigma_x,
    Sigma sigma_y,
    BlurStyle blur_style,
    Entity::TileMode tile_mode) {
  std::shared_ptr<FilterContents> x_blur = MakeDirectionalGaussianBlur(
      /*input=*/input,
      /*sigma=*/sigma_x,
      /*direction=*/Point(1, 0),
      /*blur_style=*/BlurStyle::kNormal,
      /*tile_mode=*/tile_mode,
      /*is_second_pass=*/false,
      /*secondary_sigma=*/{});
  std::shared_ptr<FilterContents> y_blur = MakeDirectionalGaussianBlur(
      /*input=*/FilterInput::Make(x_blur),
      /*sigma=*/sigma_y,
      /*direction=*/Point(0, 1),
      /*blur_style=*/blur_style,
      /*tile_mode=*/tile_mode,
      /*is_second_pass=*/true,
      /*secondary_sigma=*/sigma_x);
  return y_blur;
}

std::shared_ptr<FilterContents> FilterContents::MakeBorderMaskBlur(
    FilterInput::Ref input,
    Sigma sigma_x,
    Sigma sigma_y,
    BlurStyle blur_style) {
  auto filter = std::make_shared<BorderMaskBlurFilterContents>();
  filter->SetInputs({std::move(input)});
  filter->SetSigma(sigma_x, sigma_y);
  filter->SetBlurStyle(blur_style);
  return filter;
}

std::shared_ptr<FilterContents> FilterContents::MakeDirectionalMorphology(
    FilterInput::Ref input,
    Radius radius,
    Vector2 direction,
    MorphType morph_type) {
  auto filter = std::make_shared<DirectionalMorphologyFilterContents>();
  filter->SetInputs({std::move(input)});
  filter->SetRadius(radius);
  filter->SetDirection(direction);
  filter->SetMorphType(morph_type);
  return filter;
}

std::shared_ptr<FilterContents> FilterContents::MakeMorphology(
    FilterInput::Ref input,
    Radius radius_x,
    Radius radius_y,
    MorphType morph_type) {
  auto x_morphology = MakeDirectionalMorphology(std::move(input), radius_x,
                                                Point(1, 0), morph_type);
  auto y_morphology = MakeDirectionalMorphology(
      FilterInput::Make(x_morphology), radius_y, Point(0, 1), morph_type);
  return y_morphology;
}

std::shared_ptr<FilterContents> FilterContents::MakeMatrixFilter(
    FilterInput::Ref input,
    const Matrix& matrix,
    const SamplerDescriptor& desc) {
  auto filter = std::make_shared<MatrixFilterContents>();
  filter->SetInputs({std::move(input)});
  filter->SetMatrix(matrix);
  filter->SetSamplerDescriptor(desc);
  return filter;
}

std::shared_ptr<FilterContents> FilterContents::MakeLocalMatrixFilter(
    FilterInput::Ref input,
    const Matrix& matrix) {
  auto filter = std::make_shared<LocalMatrixFilterContents>();
  filter->SetInputs({std::move(input)});
  filter->SetMatrix(matrix);
  return filter;
}

std::shared_ptr<FilterContents> FilterContents::MakeYUVToRGBFilter(
    std::shared_ptr<Texture> y_texture,
    std::shared_ptr<Texture> uv_texture,
    YUVColorSpace yuv_color_space) {
  auto filter = std::make_shared<impeller::YUVToRGBFilterContents>();
  filter->SetInputs({impeller::FilterInput::Make(y_texture),
                     impeller::FilterInput::Make(uv_texture)});
  filter->SetYUVColorSpace(yuv_color_space);
  return filter;
}

FilterContents::FilterContents() = default;

FilterContents::~FilterContents() = default;

void FilterContents::SetInputs(FilterInput::Vector inputs) {
  inputs_ = std::move(inputs);
}

void FilterContents::SetEffectTransform(const Matrix& effect_transform) {
  effect_transform_ = effect_transform;

  for (auto& input : inputs_) {
    input->SetEffectTransform(effect_transform);
  }
}

bool FilterContents::Render(const ContentContext& renderer,
                            const Entity& entity,
                            RenderPass& pass) const {
  auto filter_coverage = GetCoverage(entity);
  if (!filter_coverage.has_value()) {
    return true;
  }

  // Run the filter.

  auto maybe_entity = GetEntity(renderer, entity, GetCoverageHint());
  if (!maybe_entity.has_value()) {
    return true;
  }
  return maybe_entity->Render(renderer, pass);
}

std::optional<Rect> FilterContents::GetLocalCoverage(
    const Entity& local_entity) const {
  auto coverage = GetFilterCoverage(inputs_, local_entity, effect_transform_);
  auto coverage_hint = GetCoverageHint();
  if (coverage_hint.has_value() && coverage.has_value()) {
    coverage = coverage->Intersection(coverage_hint.value());
  }

  return coverage;
}

std::optional<Rect> FilterContents::GetCoverage(const Entity& entity) const {
  Entity entity_with_local_transform = entity;
  entity_with_local_transform.SetTransformation(
      GetTransform(entity.GetTransformation()));

  return GetLocalCoverage(entity_with_local_transform);
}

void FilterContents::PopulateGlyphAtlas(
    const std::shared_ptr<LazyGlyphAtlas>& lazy_glyph_atlas,
    Scalar scale) {
  for (auto& input : inputs_) {
    input->PopulateGlyphAtlas(lazy_glyph_atlas, scale);
  }
}

std::optional<Rect> FilterContents::GetFilterCoverage(
    const FilterInput::Vector& inputs,
    const Entity& entity,
    const Matrix& effect_transform) const {
  // The default coverage of FilterContents is just the union of its inputs'
  // coverage. FilterContents implementations may choose to adjust this
  // coverage depending on the use case.

  if (inputs_.empty()) {
    return std::nullopt;
  }

  std::optional<Rect> result;
  for (const auto& input : inputs) {
    auto coverage = input->GetCoverage(entity);
    if (!coverage.has_value()) {
      continue;
    }
    if (!result.has_value()) {
      result = coverage;
      continue;
    }
    result = result->Union(coverage.value());
  }
  return result;
}

std::optional<Rect> FilterContents::GetSourceCoverage(
    const Matrix& effect_transform,
    const Rect& output_limit) const {
  auto filter_input_coverage =
      GetFilterSourceCoverage(effect_transform_, output_limit);

  if (!filter_input_coverage.has_value()) {
    return std::nullopt;
  }

  std::optional<Rect> inputs_coverage;
  for (auto input : inputs_) {
    auto input_coverage = input->GetSourceCoverage(
        effect_transform, filter_input_coverage.value());
    if (!input_coverage.has_value()) {
      return std::nullopt;
    }
    inputs_coverage = Rect::Union(inputs_coverage, input_coverage.value());
  }
  return inputs_coverage;
}

std::optional<Entity> FilterContents::GetEntity(
    const ContentContext& renderer,
    const Entity& entity,
    const std::optional<Rect>& coverage_hint) const {
  Entity entity_with_local_transform = entity;
  entity_with_local_transform.SetTransformation(
      GetTransform(entity.GetTransformation()));

  auto coverage = GetLocalCoverage(entity_with_local_transform);
  if (!coverage.has_value() || coverage->IsEmpty()) {
    return std::nullopt;
  }

  return RenderFilter(inputs_, renderer, entity_with_local_transform,
                      effect_transform_, coverage.value(), coverage_hint);
}

std::optional<Snapshot> FilterContents::RenderToSnapshot(
    const ContentContext& renderer,
    const Entity& entity,
    std::optional<Rect> coverage_limit,
    const std::optional<SamplerDescriptor>& sampler_descriptor,
    bool msaa_enabled,
    const std::string& label) const {
  // Resolve the render instruction (entity) from the filter and render it to a
  // snapshot.
  if (std::optional<Entity> result =
          GetEntity(renderer, entity, coverage_limit);
      result.has_value()) {
    return result->GetContents()->RenderToSnapshot(
        renderer,        // renderer
        result.value(),  // entity
        coverage_limit,  // coverage_limit
        std::nullopt,    // sampler_descriptor
        true,            // msaa_enabled
        label);          // label
  }

  return std::nullopt;
}

const FilterContents* FilterContents::AsFilter() const {
  return this;
}

Matrix FilterContents::GetLocalTransform(const Matrix& parent_transform) const {
  return Matrix();
}

Matrix FilterContents::GetTransform(const Matrix& parent_transform) const {
  return parent_transform * GetLocalTransform(parent_transform);
}
bool FilterContents::IsTranslationOnly() const {
  for (auto& input : inputs_) {
    if (!input->IsTranslationOnly()) {
      return false;
    }
  }
  return true;
}

bool FilterContents::IsLeaf() const {
  for (auto& input : inputs_) {
    if (!input->IsLeaf()) {
      return false;
    }
  }
  return true;
}

void FilterContents::SetLeafInputs(const FilterInput::Vector& inputs) {
  if (IsLeaf()) {
    inputs_ = inputs;
    return;
  }
  for (auto& input : inputs_) {
    input->SetLeafInputs(inputs);
  }
}

void FilterContents::SetRenderingMode(Entity::RenderingMode rendering_mode) {
  for (auto& input : inputs_) {
    input->SetRenderingMode(rendering_mode);
  }
}

}  // namespace impeller
