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
#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

std::shared_ptr<FilterContents> FilterContents::MakeBlend(
    Entity::BlendMode blend_mode,
    FilterInput::Vector inputs,
    std::optional<Color> foreground_color) {
  if (blend_mode > Entity::BlendMode::kLastAdvancedBlendMode) {
    VALIDATION_LOG << "Invalid blend mode " << static_cast<int>(blend_mode)
                   << " passed to FilterContents::MakeBlend.";
    return nullptr;
  }

  size_t total_inputs = inputs.size() + (foreground_color.has_value() ? 1 : 0);
  if (total_inputs < 2 ||
      blend_mode <= Entity::BlendMode::kLastPipelineBlendMode) {
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
    FilterInput::Ref source_override) {
  auto blur = std::make_shared<DirectionalGaussianBlurFilterContents>();
  blur->SetInputs({input});
  blur->SetSigma(sigma);
  blur->SetDirection(direction);
  blur->SetBlurStyle(blur_style);
  blur->SetSourceOverride(source_override);
  return blur;
}

std::shared_ptr<FilterContents> FilterContents::MakeGaussianBlur(
    FilterInput::Ref input,
    Sigma sigma_x,
    Sigma sigma_y,
    BlurStyle blur_style) {
  auto x_blur = MakeDirectionalGaussianBlur(input, sigma_x, Point(1, 0),
                                            BlurStyle::kNormal);
  auto y_blur = MakeDirectionalGaussianBlur(FilterInput::Make(x_blur), sigma_y,
                                            Point(0, 1), blur_style, input);
  return y_blur;
}

std::shared_ptr<FilterContents> FilterContents::MakeBorderMaskBlur(
    FilterInput::Ref input,
    Sigma sigma_x,
    Sigma sigma_y,
    BlurStyle blur_style) {
  auto filter = std::make_shared<BorderMaskBlurFilterContents>();
  filter->SetInputs({input});
  filter->SetSigma(sigma_x, sigma_y);
  filter->SetBlurStyle(blur_style);
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

  auto contents = std::make_shared<TextureContents>();
  contents->SetPath(
      PathBuilder{}.AddRect(filter_coverage.value()).GetCurrentPath());
  contents->SetTexture(snapshot.texture);
  contents->SetSourceRect(Rect::MakeSize(Size(snapshot.texture->GetSize())));

  Entity e;
  e.SetBlendMode(entity.GetBlendMode());
  e.SetStencilDepth(entity.GetStencilDepth());
  return contents->Render(renderer, e, pass);
}

std::optional<Rect> FilterContents::GetLocalCoverage(
    const Entity& local_entity) const {
  auto coverage = GetFilterCoverage(inputs_, local_entity);
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
    const Entity& entity) const {
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

  // Render the filter into a new texture.
  auto texture = renderer.MakeSubpass(
      ISize(coverage->size),
      [=](const ContentContext& renderer, RenderPass& pass) -> bool {
        return RenderFilter(inputs_, renderer, entity_with_local_transform,
                            pass, coverage.value());
      });

  if (!texture) {
    return std::nullopt;
  }

  return Snapshot{.texture = texture,
                  .transform = Matrix::MakeTranslation(coverage->origin)};
}

Matrix FilterContents::GetLocalTransform() const {
  return Matrix();
}

Matrix FilterContents::GetTransform(const Matrix& parent_transform) const {
  return parent_transform * GetLocalTransform();
}

}  // namespace impeller
