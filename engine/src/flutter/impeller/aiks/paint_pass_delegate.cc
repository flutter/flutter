// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint_pass_delegate.h"

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/geometry/path_builder.h"

namespace impeller {

PaintPassDelegate::PaintPassDelegate(Paint paint, std::optional<Rect> coverage)
    : paint_(std::move(paint)), coverage_(std::move(coverage)) {}

// |EntityPassDelgate|
PaintPassDelegate::~PaintPassDelegate() = default;

// |EntityPassDelgate|
std::optional<Rect> PaintPassDelegate::GetCoverageRect() {
  return coverage_;
}

// |EntityPassDelgate|
bool PaintPassDelegate::CanElide() {
  return paint_.blend_mode == BlendMode::kDestination;
}

// |EntityPassDelgate|
bool PaintPassDelegate::CanCollapseIntoParentPass() {
  return false;
}

// |EntityPassDelgate|
std::shared_ptr<Contents> PaintPassDelegate::CreateContentsForSubpassTarget(
    std::shared_ptr<Texture> target,
    const Matrix& effect_transform) {
  auto contents = TextureContents::MakeRect(Rect::MakeSize(target->GetSize()));
  contents->SetTexture(target);
  contents->SetSourceRect(Rect::MakeSize(target->GetSize()));
  contents->SetOpacity(paint_.color.alpha);

  return paint_.WithFilters(std::move(contents), false, effect_transform);
}

}  // namespace impeller
