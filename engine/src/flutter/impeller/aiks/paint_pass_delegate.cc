// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint_pass_delegate.h"

#include "impeller/entity/contents.h"

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
  return paint_.color.IsTransparent();
}

// |EntityPassDelgate|
bool PaintPassDelegate::CanCollapseIntoParentPass() {
  return paint_.color.IsOpaque();
}

// |EntityPassDelgate|
std::shared_ptr<Contents> PaintPassDelegate::CreateContentsForSubpassTarget(
    std::shared_ptr<Texture> target) {
  auto contents = std::make_shared<TextureContents>();
  contents->SetTexture(target);
  contents->SetSourceRect(IRect::MakeSize(target->GetSize()));
  contents->SetOpacity(paint_.color.alpha);
  return contents;
}

}  // namespace impeller
