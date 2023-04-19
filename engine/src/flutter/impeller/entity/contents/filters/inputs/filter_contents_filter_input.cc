// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/inputs/filter_contents_filter_input.h"

#include <utility>

#include "impeller/base/strings.h"
#include "impeller/entity/contents/filters/filter_contents.h"

namespace impeller {

FilterContentsFilterInput::FilterContentsFilterInput(
    std::shared_ptr<FilterContents> filter)
    : filter_(std::move(filter)) {}

FilterContentsFilterInput::~FilterContentsFilterInput() = default;

FilterInput::Variant FilterContentsFilterInput::GetInput() const {
  return filter_;
}

std::optional<Snapshot> FilterContentsFilterInput::GetSnapshot(
    const std::string& label,
    const ContentContext& renderer,
    const Entity& entity) const {
  if (!snapshot_.has_value()) {
    snapshot_ = filter_->RenderToSnapshot(
        renderer, entity, std::nullopt, true,
        SPrintF("Filter to %s Filter Snapshot", label.c_str()));
  }
  return snapshot_;
}

std::optional<Rect> FilterContentsFilterInput::GetCoverage(
    const Entity& entity) const {
  return filter_->GetCoverage(entity);
}

Matrix FilterContentsFilterInput::GetLocalTransform(
    const Entity& entity) const {
  return filter_->GetLocalTransform(entity.GetTransformation());
}

Matrix FilterContentsFilterInput::GetTransform(const Entity& entity) const {
  return filter_->GetTransform(entity.GetTransformation());
}

}  // namespace impeller
