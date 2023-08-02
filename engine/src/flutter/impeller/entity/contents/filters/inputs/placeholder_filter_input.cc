// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/inputs/placeholder_filter_input.h"

#include <optional>
#include <utility>

#include "impeller/base/strings.h"

namespace impeller {

PlaceholderFilterInput::PlaceholderFilterInput(Rect coverage_rect)
    : coverage_rect_(coverage_rect) {}

PlaceholderFilterInput::~PlaceholderFilterInput() = default;

FilterInput::Variant PlaceholderFilterInput::GetInput() const {
  return coverage_rect_;
}

std::optional<Snapshot> PlaceholderFilterInput::GetSnapshot(
    const std::string& label,
    const ContentContext& renderer,
    const Entity& entity,
    std::optional<Rect> coverage_limit) const {
  return std::nullopt;
}

std::optional<Rect> PlaceholderFilterInput::GetCoverage(
    const Entity& entity) const {
  return coverage_rect_;
}

void PlaceholderFilterInput::PopulateGlyphAtlas(
    const std::shared_ptr<LazyGlyphAtlas>& lazy_glyph_atlas,
    Scalar scale) {}

}  // namespace impeller
