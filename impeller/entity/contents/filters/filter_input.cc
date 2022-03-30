// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/filter_input.h"

#include <cstdarg>
#include <initializer_list>
#include <memory>

#include "impeller/entity/contents/snapshot.h"
#include "impeller/entity/entity.h"

namespace impeller {

FilterInput::Ref FilterInput::Make(Variant input) {
  return std::shared_ptr<FilterInput>(new FilterInput(input));
}

FilterInput::Vector FilterInput::Make(std::initializer_list<Variant> inputs) {
  FilterInput::Vector result;
  result.reserve(inputs.size());
  for (const auto& input : inputs) {
    result.push_back(Make(input));
  }
  return result;
}

FilterInput::Variant FilterInput::GetInput() const {
  return input_;
}

Rect FilterInput::GetBounds(const Entity& entity) const {
  if (snapshot_) {
    return Rect(snapshot_->position, Size(snapshot_->texture->GetSize()));
  }

  if (auto contents = std::get_if<std::shared_ptr<Contents>>(&input_)) {
    return contents->get()->GetBounds(entity);
  }

  if (auto texture = std::get_if<std::shared_ptr<Texture>>(&input_)) {
    return entity.GetTransformedPathBounds();
  }

  FML_UNREACHABLE();
}

std::optional<Snapshot> FilterInput::GetSnapshot(const ContentContext& renderer,
                                                 const Entity& entity) const {
  if (snapshot_) {
    return snapshot_;
  }
  snapshot_ = RenderToTexture(renderer, entity);

  return snapshot_;
}

FilterInput::FilterInput(Variant input) : input_(input) {}

FilterInput::~FilterInput() = default;

std::optional<Snapshot> FilterInput::RenderToTexture(
    const ContentContext& renderer,
    const Entity& entity) const {
  if (auto contents = std::get_if<std::shared_ptr<Contents>>(&input_)) {
    return contents->get()->RenderToTexture(renderer, entity);
  }

  if (auto texture = std::get_if<std::shared_ptr<Texture>>(&input_)) {
    return Snapshot::FromTransformedTexture(renderer, entity, *texture);
  }

  FML_UNREACHABLE();
}

}  // namespace impeller
