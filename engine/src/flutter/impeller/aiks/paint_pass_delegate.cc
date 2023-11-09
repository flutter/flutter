// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint_pass_delegate.h"

#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity_pass.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/path_builder.h"

namespace impeller {

/// PaintPassDelegate
/// ----------------------------------------------

PaintPassDelegate::PaintPassDelegate(Paint paint) : paint_(std::move(paint)) {}

// |EntityPassDelgate|
PaintPassDelegate::~PaintPassDelegate() = default;

// |EntityPassDelgate|
bool PaintPassDelegate::CanElide() {
  return paint_.blend_mode == BlendMode::kDestination;
}

// |EntityPassDelgate|
bool PaintPassDelegate::CanCollapseIntoParentPass(EntityPass* entity_pass) {
  return false;
}

// |EntityPassDelgate|
std::shared_ptr<Contents> PaintPassDelegate::CreateContentsForSubpassTarget(
    std::shared_ptr<Texture> target,
    const Matrix& effect_transform) {
  auto contents = TextureContents::MakeRect(Rect::MakeSize(target->GetSize()));
  contents->SetTexture(target);
  contents->SetLabel("Subpass");
  contents->SetSourceRect(Rect::MakeSize(target->GetSize()));
  contents->SetOpacity(paint_.color.alpha);
  contents->SetDeferApplyingOpacity(true);

  return paint_.WithFiltersForSubpassTarget(std::move(contents),
                                            effect_transform);
}

// |EntityPassDelgate|
std::shared_ptr<FilterContents> PaintPassDelegate::WithImageFilter(
    const FilterInput::Variant& input,
    const Matrix& effect_transform) const {
  return paint_.WithImageFilter(input, effect_transform,
                                Entity::RenderingMode::kSubpass);
}

/// OpacityPeepholePassDelegate
/// ----------------------------------------------

OpacityPeepholePassDelegate::OpacityPeepholePassDelegate(Paint paint)
    : paint_(std::move(paint)) {}

// |EntityPassDelgate|
OpacityPeepholePassDelegate::~OpacityPeepholePassDelegate() = default;

// |EntityPassDelgate|
bool OpacityPeepholePassDelegate::CanElide() {
  return paint_.blend_mode == BlendMode::kDestination;
}

// |EntityPassDelgate|
bool OpacityPeepholePassDelegate::CanCollapseIntoParentPass(
    EntityPass* entity_pass) {
  // Passes with absorbed clips can not be safely collapsed.
  if (entity_pass->GetBoundsLimit().has_value()) {
    return false;
  }

  // OpacityPeepholePassDelegate will only get used if the pass's blend mode is
  // SourceOver, so no need to check here.
  if (paint_.color.alpha <= 0.0 || paint_.color.alpha >= 1.0 ||
      paint_.image_filter || paint_.color_filter) {
    return false;
  }

  // Note: determing whether any coverage intersects has quadradic complexity in
  // the number of rectangles, and depending on whether or not we cache at
  // different levels of the entity tree may end up cubic. In the interest of
  // proving whether or not this optimization is valuable, we only consider very
  // simple peephole optimizations here - where there is a single drawing
  // command wrapped in save layer. This would indicate something like an
  // Opacity or FadeTransition wrapping a very simple widget, like in the
  // CupertinoPicker.
  if (entity_pass->GetElementCount() > 3) {
    // Single paint command with a save layer would be:
    // 1. clip
    // 2. draw command
    // 3. restore.
    return false;
  }
  bool all_can_accept = true;
  std::vector<Rect> all_coverages;
  auto had_subpass = entity_pass->IterateUntilSubpass(
      [&all_coverages, &all_can_accept](Entity& entity) {
        const auto& contents = entity.GetContents();
        if (!entity.CanInheritOpacity()) {
          all_can_accept = false;
          return false;
        }
        auto maybe_coverage = contents->GetCoverage(entity);
        if (maybe_coverage.has_value()) {
          auto coverage = maybe_coverage.value();
          for (const auto& cv : all_coverages) {
            if (cv.IntersectsWithRect(coverage)) {
              all_can_accept = false;
              return false;
            }
          }
          all_coverages.push_back(coverage);
        }
        return true;
      });
  if (had_subpass || !all_can_accept) {
    return false;
  }
  auto alpha = paint_.color.alpha;
  entity_pass->IterateUntilSubpass([&alpha](Entity& entity) {
    entity.SetInheritedOpacity(alpha);
    return true;
  });
  return true;
}

// |EntityPassDelgate|
std::shared_ptr<Contents>
OpacityPeepholePassDelegate::CreateContentsForSubpassTarget(
    std::shared_ptr<Texture> target,
    const Matrix& effect_transform) {
  auto contents = TextureContents::MakeRect(Rect::MakeSize(target->GetSize()));
  contents->SetLabel("Subpass");
  contents->SetTexture(target);
  contents->SetSourceRect(Rect::MakeSize(target->GetSize()));
  contents->SetOpacity(paint_.color.alpha);
  contents->SetDeferApplyingOpacity(true);

  return paint_.WithFiltersForSubpassTarget(std::move(contents),
                                            effect_transform);
}

// |EntityPassDelgate|
std::shared_ptr<FilterContents> OpacityPeepholePassDelegate::WithImageFilter(
    const FilterInput::Variant& input,
    const Matrix& effect_transform) const {
  return paint_.WithImageFilter(input, effect_transform,
                                Entity::RenderingMode::kSubpass);
}

}  // namespace impeller
