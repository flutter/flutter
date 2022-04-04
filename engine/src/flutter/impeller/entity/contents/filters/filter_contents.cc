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
#include "impeller/entity/contents/filters/filter_input.h"
#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

std::shared_ptr<FilterContents> FilterContents::MakeBlend(
    Entity::BlendMode blend_mode,
    FilterInput::Vector inputs) {
  if (blend_mode > Entity::BlendMode::kLastAdvancedBlendMode) {
    VALIDATION_LOG << "Invalid blend mode " << static_cast<int>(blend_mode)
                   << " passed to FilterContents::MakeBlend.";
    return nullptr;
  }

  if (inputs.size() < 2 ||
      blend_mode <= Entity::BlendMode::kLastPipelineBlendMode) {
    auto blend = std::make_shared<BlendFilterContents>();
    blend->SetInputs(inputs);
    blend->SetBlendMode(blend_mode);
    return blend;
  }

  if (blend_mode <= Entity::BlendMode::kLastAdvancedBlendMode) {
    auto blend_input = inputs[0];
    std::shared_ptr<BlendFilterContents> new_blend;
    for (auto in_i = inputs.begin() + 1; in_i < inputs.end(); in_i++) {
      new_blend = std::make_shared<BlendFilterContents>();
      new_blend->SetInputs({blend_input, *in_i});
      new_blend->SetBlendMode(blend_mode);
      blend_input = FilterInput::Make(new_blend);
    }
    // new_blend will always be assigned because inputs.size() >= 2.
    return new_blend;
  }

  FML_UNREACHABLE();
}

std::shared_ptr<FilterContents> FilterContents::MakeDirectionalGaussianBlur(
    FilterInput::Ref input,
    Vector2 blur_vector,
    BlurStyle blur_style,
    FilterInput::Ref source_override) {
  auto blur = std::make_shared<DirectionalGaussianBlurFilterContents>();
  blur->SetInputs({input});
  blur->SetBlurVector(blur_vector);
  blur->SetBlurStyle(blur_style);
  blur->SetSourceOverride(source_override);
  return blur;
}

std::shared_ptr<FilterContents> FilterContents::MakeGaussianBlur(
    FilterInput::Ref input,
    Scalar sigma_x,
    Scalar sigma_y,
    BlurStyle blur_style) {
  auto x_blur =
      MakeDirectionalGaussianBlur(input, Point(sigma_x, 0), BlurStyle::kNormal);
  auto y_blur = MakeDirectionalGaussianBlur(
      FilterInput::Make(x_blur), Point(0, sigma_y), blur_style, input);
  return y_blur;
}

FilterContents::FilterContents() = default;

FilterContents::~FilterContents() = default;

void FilterContents::SetInputs(FilterInput::Vector inputs) {
  inputs_ = std::move(inputs);
}

bool FilterContents::Render(const ContentContext& renderer,
                            const Entity& entity,
                            RenderPass& pass) const {
  // Run the filter.

  auto maybe_snapshot = RenderToTexture(renderer, entity);
  if (!maybe_snapshot.has_value()) {
    return false;
  }
  auto& snapshot = maybe_snapshot.value();

  // Draw the result texture, respecting the transform and clip stack.

  auto contents = std::make_shared<TextureContents>();
  contents->SetTexture(snapshot.texture);
  contents->SetSourceRect(Rect::MakeSize(Size(snapshot.texture->GetSize())));

  Entity e;
  e.SetPath(PathBuilder{}.AddRect(GetBounds(entity)).GetCurrentPath());
  e.SetBlendMode(entity.GetBlendMode());
  e.SetStencilDepth(entity.GetStencilDepth());
  return contents->Render(renderer, e, pass);
}

Rect FilterContents::GetBounds(const Entity& entity) const {
  // The default bounds of FilterContents is just the union of its inputs.
  // FilterContents implementations may choose to increase the bounds in any
  // direction, but it should never

  if (inputs_.empty()) {
    return Rect();
  }

  Rect result = inputs_.front()->GetBounds(entity);
  for (auto input_i = inputs_.begin() + 1; input_i < inputs_.end(); input_i++) {
    result.Union(input_i->get()->GetBounds(entity));
  }

  return result;
}

std::optional<Snapshot> FilterContents::RenderToTexture(
    const ContentContext& renderer,
    const Entity& entity) const {
  auto bounds = GetBounds(entity);
  if (bounds.IsZero()) {
    return std::nullopt;
  }

  // Render the filter into a new texture.
  auto texture = renderer.MakeSubpass(
      ISize(GetBounds(entity).size),
      [=](const ContentContext& renderer, RenderPass& pass) -> bool {
        return RenderFilter(inputs_, renderer, entity, pass, bounds);
      });

  if (!texture) {
    return std::nullopt;
  }

  return Snapshot{.texture = texture, .position = bounds.origin};
}

}  // namespace impeller
