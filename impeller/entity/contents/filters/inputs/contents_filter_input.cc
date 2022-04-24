// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/inputs/contents_filter_input.h"

namespace impeller {

ContentsFilterInput::ContentsFilterInput(std::shared_ptr<Contents> contents)
    : contents_(contents) {}

ContentsFilterInput::~ContentsFilterInput() = default;

FilterInput::Variant ContentsFilterInput::GetInput() const {
  return contents_;
}

std::optional<Snapshot> ContentsFilterInput::GetSnapshot(
    const ContentContext& renderer,
    const Entity& entity) const {
  if (!snapshot_.has_value()) {
    snapshot_ = contents_->RenderToSnapshot(renderer, entity);
  }
  return snapshot_;
}

std::optional<Rect> ContentsFilterInput::GetCoverage(
    const Entity& entity) const {
  return contents_->GetCoverage(entity);
}

}  // namespace impeller
