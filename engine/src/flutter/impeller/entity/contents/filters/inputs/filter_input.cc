// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/inputs/filter_input.h"

#include <memory>

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/inputs/contents_filter_input.h"
#include "impeller/entity/contents/filters/inputs/filter_contents_filter_input.h"
#include "impeller/entity/contents/filters/inputs/texture_filter_input.h"

namespace impeller {

FilterInput::Ref FilterInput::Make(Variant input) {
  if (auto filter = std::get_if<std::shared_ptr<FilterContents>>(&input)) {
    return std::static_pointer_cast<FilterInput>(
        std::shared_ptr<FilterContentsFilterInput>(
            new FilterContentsFilterInput(*filter)));
  }

  if (auto contents = std::get_if<std::shared_ptr<Contents>>(&input)) {
    return std::static_pointer_cast<FilterInput>(
        std::shared_ptr<ContentsFilterInput>(
            new ContentsFilterInput(*contents)));
  }

  if (auto texture = std::get_if<std::shared_ptr<Texture>>(&input)) {
    return Make(*texture, Matrix());
  }

  FML_UNREACHABLE();
}

FilterInput::Ref FilterInput::Make(std::shared_ptr<Texture> texture,
                                   Matrix local_transform) {
  return std::shared_ptr<TextureFilterInput>(
      new TextureFilterInput(texture, local_transform));
}

FilterInput::Vector FilterInput::Make(std::initializer_list<Variant> inputs) {
  FilterInput::Vector result;
  result.reserve(inputs.size());
  for (const auto& input : inputs) {
    result.push_back(Make(input));
  }
  return result;
}

Matrix FilterInput::GetLocalTransform(const Entity& entity) const {
  return Matrix();
}

Matrix FilterInput::GetTransform(const Entity& entity) const {
  return entity.GetTransformation() * GetLocalTransform(entity);
}

FilterInput::~FilterInput() = default;

}  // namespace impeller
