// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/filter_input.h"

#include <cstdarg>
#include <initializer_list>
#include <memory>
#include <optional>

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

std::optional<Rect> FilterInput::GetCoverage(const Entity& entity) const {
  if (snapshot_) {
    return snapshot_->GetCoverage();
  }

  if (auto contents = std::get_if<std::shared_ptr<Contents>>(&input_)) {
    return contents->get()->GetCoverage(entity);
  }

  if (auto texture = std::get_if<std::shared_ptr<Texture>>(&input_)) {
    return entity.GetPathCoverage();
  }

  FML_UNREACHABLE();
}

std::optional<Snapshot> FilterInput::GetSnapshot(const ContentContext& renderer,
                                                 const Entity& entity) const {
  if (snapshot_) {
    return snapshot_;
  }
  snapshot_ = MakeSnapshot(renderer, entity);

  return snapshot_;
}

FilterInput::FilterInput(Variant input) : input_(input) {}

FilterInput::~FilterInput() = default;

std::optional<Snapshot> FilterInput::MakeSnapshot(
    const ContentContext& renderer,
    const Entity& entity) const {
  if (auto contents = std::get_if<std::shared_ptr<Contents>>(&input_)) {
    return contents->get()->RenderToSnapshot(renderer, entity);
  }

  if (auto texture = std::get_if<std::shared_ptr<Texture>>(&input_)) {
    // Rendered textures stretch to fit the entity path coverage, so we
    // incorporate this behavior by translating and scaling the snapshot
    // transform.
    auto path_bounds = entity.GetPath().GetBoundingBox();
    if (!path_bounds.has_value()) {
      return std::nullopt;
    }
    auto transform = entity.GetTransformation() *
                     Matrix::MakeTranslation(path_bounds->origin) *
                     Matrix::MakeScale(Vector2(path_bounds->size) /
                                       texture->get()->GetSize());
    return Snapshot{.texture = *texture, .transform = transform};
  }

  FML_UNREACHABLE();
}

}  // namespace impeller
