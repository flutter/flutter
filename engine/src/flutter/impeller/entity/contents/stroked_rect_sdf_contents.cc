// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/stroked_rect_sdf_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

std::unique_ptr<StrokedRectSDFContents> StrokedRectSDFContents::Make(
    Color color,
    std::unique_ptr<StrokeRectGeometry> geometry) {
  return std::make_unique<StrokedRectSDFContents>(color, std::move(geometry));
}

StrokedRectSDFContents::StrokedRectSDFContents(
    Color color,
    std::unique_ptr<StrokeRectGeometry> geometry)
    : UberSDFContents(color), geometry_(std::move(geometry)) {}

StrokedRectSDFContents::~StrokedRectSDFContents() = default;

const Geometry* StrokedRectSDFContents::GetGeometry() const {
  return geometry_.get();
}

bool StrokedRectSDFContents::BindData(const ContentContext& renderer,
                                      const Entity& entity,
                                      RenderPass& pass,
                                      FS::FragInfo& frag_info) const {
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.stroked = 1.0f;
  frag_info.stroke_width = geometry_->GetStrokeWidth();
  switch (geometry_->GetStrokeJoin()) {
    case Join::kMiter:
      frag_info.stroke_join = 0.0f;
      break;
    case Join::kBevel:
      frag_info.stroke_join = 1.0f;
      break;
    case Join::kRound:
      frag_info.stroke_join = 2.0f;
      break;
  }
  frag_info.type = 1.0f;  // kRect
  Rect rect = geometry_->GetRect();
  frag_info.center = rect.GetCenter();
  frag_info.size = Point(rect.GetWidth() / 2.0f, rect.GetHeight() / 2.0f);
  frag_info.aa_pixels = 1.0f;
  return true;
}

}  // namespace impeller
