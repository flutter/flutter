// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint_pass_delegate.h"

#include "impeller/entity/contents.h"

namespace impeller {

PaintPassDelegate::PaintPassDelegate(Paint paint) : paint_(std::move(paint)) {}

// |EntityPassDelgate|
PaintPassDelegate::~PaintPassDelegate() = default;

// |EntityPassDelgate|
bool PaintPassDelegate::CanCollapseIntoParentPass() {
  if (paint_.color.IsOpaque()) {
    return true;
  }

  return false;
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
