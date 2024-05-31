// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint_pass_delegate.h"

#include "impeller/core/formats.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity_pass.h"
#include "impeller/geometry/color.h"

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
  return paint_.WithImageFilter(
      input, effect_transform,
      Entity::RenderingMode::kSubpassPrependSnapshotTransform);
}

}  // namespace impeller
