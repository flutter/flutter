// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/line_contents.h"

namespace impeller {

std::unique_ptr<LineContents> LineContents::Make(
    std::unique_ptr<LineGeometry> geometry) {
  return std::unique_ptr<LineContents>(new LineContents(std::move(geometry)));
}

LineContents::LineContents(std::unique_ptr<LineGeometry> geometry)
    : geometry_(std::move(geometry)) {}

bool LineContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  return true;
}

std::optional<Rect> LineContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
}

}  // namespace impeller
