// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/inputs/texture_filter_input.h"

namespace impeller {

TextureFilterInput::TextureFilterInput(std::shared_ptr<Texture> texture)
    : texture_(texture) {}

TextureFilterInput::~TextureFilterInput() = default;

FilterInput::Variant TextureFilterInput::GetInput() const {
  return texture_;
}

std::optional<Snapshot> TextureFilterInput::GetSnapshot(
    const ContentContext& renderer,
    const Entity& entity) const {
  return Snapshot{.texture = texture_, .transform = GetTransform(entity)};
}

std::optional<Rect> TextureFilterInput::GetCoverage(
    const Entity& entity) const {
  return Rect::MakeSize(Size(texture_->GetSize()))
      .TransformBounds(GetTransform(entity));
}

}  // namespace impeller
