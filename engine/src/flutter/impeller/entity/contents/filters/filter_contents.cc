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
#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"
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
    FilterInput::Ref source_override,
    Sigma secondary_sigma,
    const Matrix& effect_transform) {
  auto blur = std::make_shared<DirectionalGaussianBlurFilterContents>();
  blur->SetInputs({std::move(input)});
  blur->SetSigma(sigma);
  blur->SetDirection(direction);
  blur->SetBlurStyle(blur_style);
  blur->SetTileMode(tile_mode);
  blur->SetSourceOverride(std::move(source_override));
  blur->SetSecondarySigma(secondary_sigma);
  blur->SetEffectTransform(effect_transform);
  return blur;
}

std::shared_ptr<FilterContents> FilterContents::MakeGaussianBlur(
    const FilterInput::Ref& input,
    Sigma sigma_x,
    Sigma sigma_y,
    BlurStyle blur_style,
    Entity::TileMode tile_mode,
    const Matrix& effect_transform) {
  auto x_blur = MakeDirectionalGaussianBlur(input, sigma_x, Point(1, 0),
                                            BlurStyle::kNormal, tile_mode,
                                            nullptr, {}, effect_transform);
  auto y_blur = MakeDirectionalGaussianBlur(FilterInput::Make(x_blur), sigma_y,
                                            Point(0, 1), blur_style, tile_mode,
                                            input, sigma_x, effect_transform);
  return y_blur;
}

std::shared_ptr<FilterContents> FilterContents::MakeBorderMaskBlur(
    FilterInput::Ref input,
    Sigma sigma_x,
    Sigma sigma_y,
    BlurStyle blur_style,
    const Matrix& effect_transform) {
  auto filter = std::make_shared<BorderMaskBlurFilterContents>();
  filter->SetInputs({std::move(input)});
  filter->SetSigma(sigma_x, sigma_y);
  filter->SetBlurStyle(blur_style);
  filter->SetEffectTransform(effect_transform);
  return filter;
}

std::shared_ptr<FilterContents> FilterContents::MakeDirectionalMorphology(
    FilterInput::Ref input,
    Radius radius,
    Vector2 direction,
    MorphType morph_type,
    const Matrix& effect_transform) {
  auto filter = std::make_shared<DirectionalMorphologyFilterContents>();
  filter->SetInputs({std::move(input)});
  filter->SetRadius(radius);
  filter->SetDirection(direction);
  filter->SetMorphType(morph_type);
  filter->SetEffectTransform(effect_transform);
  return filter;
}

std::shared_ptr<FilterContents> FilterContents::MakeMorphology(
    FilterInput::Ref input,
    Radius radius_x,
    Radius radius_y,
    MorphType morph_type,
    const Matrix& effect_transform) {
  auto x_morphology = MakeDirectionalMorphology(
      std::move(input), radius_x, Point(1, 0), morph_type, effect_transform);
  auto y_morphology =
      MakeDirectionalMorphology(FilterInput::Make(x_morphology), radius_y,
                                Point(0, 1), morph_type, effect_transform);
  return y_morphology;
}

std::shared_ptr<FilterContents> FilterContents::MakeMatrixFilter(
    FilterInput::Ref input,
    const Matrix& matrix,
    const SamplerDescriptor& desc,
    const Matrix& effect_transform,
    bool is_subpass) {
  auto filter = std::make_shared<MatrixFilterContents>();
  filter->SetInputs({std::move(input)});
  filter->SetMatrix(matrix);
  filter->SetSamplerDescriptor(desc);
  filter->SetEffectTransform(effect_transform);
  filter->SetIsSubpass(is_subpass);
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

void FilterContents::SetCoverageCrop(std::optional<Rect> coverage_crop) {
  coverage_crop_ = coverage_crop;
}

void FilterContents::SetEffectTransform(Matrix effect_transform) {
  effect_transform_ = effect_transform;
}

bool FilterContents::Render(const ContentContext& renderer,
                            const Entity& entity,
                            RenderPass& pass) const {
  auto filter_coverage = GetCoverage(entity);
  if (!filter_coverage.has_value()) {
    return true;
  }

  // Run the filter.

  auto maybe_entity = GetEntity(renderer, entity);
  if (!maybe_entity.has_value()) {
    return true;
  }
  return maybe_entity->Render(renderer, pass);
}

std::optional<Rect> FilterContents::GetLocalCoverage(
    const Entity& local_entity) const {
  auto coverage = GetFilterCoverage(inputs_, local_entity, effect_transform_);
  if (coverage_crop_.has_value() && coverage.has_value()) {
    coverage = coverage->Intersection(coverage_crop_.value());
  }

  return coverage;
}

std::optional<Rect> FilterContents::GetCoverage(const Entity& entity) const {
  Entity entity_with_local_transform = entity;
  entity_with_local_transform.SetTransformation(
      GetTransform(entity.GetTransformation()));

  return GetLocalCoverage(entity_with_local_transform);
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

std::optional<Entity> FilterContents::GetEntity(const ContentContext& renderer,
                                                const Entity& entity) const {
  Entity entity_with_local_transform = entity;
  entity_with_local_transform.SetTransformation(
      GetTransform(entity.GetTransformation()));

  auto coverage = GetLocalCoverage(entity_with_local_transform);
  if (!coverage.has_value() || coverage->IsEmpty()) {
    return std::nullopt;
  }

  return RenderFilter(inputs_, renderer, entity_with_local_transform,
                      effect_transform_, coverage.value());
}

std::optional<Snapshot> FilterContents::RenderToSnapshot(
    const ContentContext& renderer,
    const Entity& entity,
    const std::optional<SamplerDescriptor>& sampler_descriptor,
    bool msaa_enabled) const {
  // Resolve the render instruction (entity) from the filter and render it to a
  // snapshot.
  if (std::optional<Entity> result = GetEntity(renderer, entity);
      result.has_value()) {
    return result->GetContents()->RenderToSnapshot(renderer, result.value());
  }

  return std::nullopt;
}

Matrix FilterContents::GetLocalTransform(const Matrix& parent_transform) const {
  return Matrix();
}

Matrix FilterContents::GetTransform(const Matrix& parent_transform) const {
  return parent_transform * GetLocalTransform(parent_transform);
}

}  // namespace impeller
