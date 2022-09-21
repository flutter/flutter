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

#include "flutter/fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/blend_filter_contents.h"
#include "impeller/entity/contents/filters/border_mask_blur_filter_contents.h"
#include "impeller/entity/contents/filters/color_matrix_filter_contents.h"
#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/filters/linear_to_srgb_filter_contents.h"
#include "impeller/entity/contents/filters/local_matrix_filter_contents.h"
#include "impeller/entity/contents/filters/matrix_filter_contents.h"
#include "impeller/entity/contents/filters/morphology_filter_contents.h"
#include "impeller/entity/contents/filters/srgb_to_linear_filter_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

std::shared_ptr<FilterContents> FilterContents::MakeBlend(
    BlendMode blend_mode,
    FilterInput::Vector inputs,
    std::optional<Color> foreground_color) {
  if (blend_mode > Entity::kLastAdvancedBlendMode) {
    VALIDATION_LOG << "Invalid blend mode " << static_cast<int>(blend_mode)
                   << " passed to FilterContents::MakeBlend.";
    return nullptr;
  }

  size_t total_inputs = inputs.size() + (foreground_color.has_value() ? 1 : 0);
  if (total_inputs < 2 || blend_mode <= Entity::kLastPipelineBlendMode) {
    auto blend = std::make_shared<BlendFilterContents>();
    blend->SetInputs(inputs);
    blend->SetBlendMode(blend_mode);
    blend->SetForegroundColor(foreground_color);
    return blend;
  }

  auto blend_input = inputs[0];
  std::shared_ptr<BlendFilterContents> new_blend;
  for (auto in_i = inputs.begin() + 1; in_i < inputs.end(); in_i++) {
    new_blend = std::make_shared<BlendFilterContents>();
    new_blend->SetInputs({*in_i, blend_input});
    new_blend->SetBlendMode(blend_mode);
    if (in_i < inputs.end() - 1 || foreground_color.has_value()) {
      blend_input = FilterInput::Make(
          std::static_pointer_cast<FilterContents>(new_blend));
    }
  }

  if (foreground_color.has_value()) {
    new_blend = std::make_shared<BlendFilterContents>();
    new_blend->SetInputs({blend_input});
    new_blend->SetBlendMode(blend_mode);
    new_blend->SetForegroundColor(foreground_color);
  }

  return new_blend;
}

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
  blur->SetInputs({input});
  blur->SetSigma(sigma);
  blur->SetDirection(direction);
  blur->SetBlurStyle(blur_style);
  blur->SetTileMode(tile_mode);
  blur->SetSourceOverride(source_override);
  blur->SetSecondarySigma(secondary_sigma);
  blur->SetEffectTransform(effect_transform);
  return blur;
}

std::shared_ptr<FilterContents> FilterContents::MakeGaussianBlur(
    FilterInput::Ref input,
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
  filter->SetInputs({input});
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
  filter->SetInputs({input});
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
  auto x_morphology = MakeDirectionalMorphology(input, radius_x, Point(1, 0),
                                                morph_type, effect_transform);
  auto y_morphology =
      MakeDirectionalMorphology(FilterInput::Make(x_morphology), radius_y,
                                Point(0, 1), morph_type, effect_transform);
  return y_morphology;
}

std::shared_ptr<FilterContents> FilterContents::MakeColorMatrix(
    FilterInput::Ref input,
    const ColorMatrix& color_matrix) {
  auto filter = std::make_shared<ColorMatrixFilterContents>();
  filter->SetInputs({input});
  filter->SetMatrix(color_matrix);
  return filter;
}

std::shared_ptr<FilterContents> FilterContents::MakeLinearToSrgbFilter(
    FilterInput::Ref input) {
  auto filter = std::make_shared<LinearToSrgbFilterContents>();
  filter->SetInputs({input});
  return filter;
}

std::shared_ptr<FilterContents> FilterContents::MakeSrgbToLinearFilter(
    FilterInput::Ref input) {
  auto filter = std::make_shared<SrgbToLinearFilterContents>();
  filter->SetInputs({input});
  return filter;
}

std::shared_ptr<FilterContents> FilterContents::MakeMatrixFilter(
    FilterInput::Ref input,
    const Matrix& matrix,
    const SamplerDescriptor& desc) {
  auto filter = std::make_shared<MatrixFilterContents>();
  filter->SetInputs({input});
  filter->SetMatrix(matrix);
  filter->SetSamplerDescriptor(desc);
  return filter;
}

std::shared_ptr<FilterContents> FilterContents::MakeLocalMatrixFilter(
    FilterInput::Ref input,
    const Matrix& matrix) {
  auto filter = std::make_shared<LocalMatrixFilterContents>();
  filter->SetInputs({input});
  filter->SetMatrix(matrix);
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
  effect_transform_ = effect_transform.Basis();
}

bool FilterContents::Render(const ContentContext& renderer,
                            const Entity& entity,
                            RenderPass& pass) const {
  auto filter_coverage = GetCoverage(entity);
  if (!filter_coverage.has_value()) {
    return true;
  }

  // Run the filter.

  auto maybe_snapshot = RenderToSnapshot(renderer, entity);
  if (!maybe_snapshot.has_value()) {
    return false;
  }
  auto& snapshot = maybe_snapshot.value();

  // Draw the result texture, respecting the transform and clip stack.

  auto texture_rect = Rect::MakeSize(snapshot.texture->GetSize());
  auto contents = TextureContents::MakeRect(texture_rect);
  contents->SetTexture(snapshot.texture);
  contents->SetSamplerDescriptor(snapshot.sampler_descriptor);
  contents->SetSourceRect(texture_rect);

  Entity e;
  e.SetBlendMode(entity.GetBlendMode());
  e.SetStencilDepth(entity.GetStencilDepth());
  e.SetTransformation(snapshot.transform);
  return contents->Render(renderer, e, pass);
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

std::optional<Snapshot> FilterContents::RenderToSnapshot(
    const ContentContext& renderer,
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

Matrix FilterContents::GetLocalTransform(const Matrix& parent_transform) const {
  return Matrix();
}

Matrix FilterContents::GetTransform(const Matrix& parent_transform) const {
  return parent_transform * GetLocalTransform(parent_transform);
}

}  // namespace impeller
