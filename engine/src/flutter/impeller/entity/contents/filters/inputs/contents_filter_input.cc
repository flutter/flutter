// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/inputs/contents_filter_input.h"

#include <optional>
#include <utility>

#include "impeller/base/strings.h"

namespace impeller {

ContentsFilterInput::ContentsFilterInput(std::shared_ptr<Contents> contents,
                                         bool msaa_enabled)
    : contents_(std::move(contents)), msaa_enabled_(msaa_enabled) {}

ContentsFilterInput::~ContentsFilterInput() = default;

FilterInput::Variant ContentsFilterInput::GetInput() const {
  return contents_;
}

std::optional<Snapshot> ContentsFilterInput::GetSnapshot(
    const std::string& label,
    const ContentContext& renderer,
    const Entity& entity,
    std::optional<Rect> coverage_limit) const {
  if (!coverage_limit.has_value() && entity.GetContents()) {
    coverage_limit = entity.GetContents()->GetCoverageHint();
  }
  if (!snapshot_.has_value()) {
    snapshot_ = contents_->RenderToSnapshot(
        renderer,        // renderer
        entity,          // entity
        coverage_limit,  // coverage_limit
        std::nullopt,    // sampler_descriptor
        msaa_enabled_,   // msaa_enabled
        SPrintF("Contents to %s Filter Snapshot", label.c_str()));  // label
  }
  return snapshot_;
}

std::optional<Rect> ContentsFilterInput::GetCoverage(
    const Entity& entity) const {
  return contents_->GetCoverage(entity);
}

void ContentsFilterInput::PopulateGlyphAtlas(
    const std::shared_ptr<LazyGlyphAtlas>& lazy_glyph_atlas,
    Scalar scale) {
  contents_->PopulateGlyphAtlas(lazy_glyph_atlas, scale);
}

}  // namespace impeller
