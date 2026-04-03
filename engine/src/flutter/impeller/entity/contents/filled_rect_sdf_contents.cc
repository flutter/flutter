// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filled_rect_sdf_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

std::unique_ptr<FilledRectSDFContents> FilledRectSDFContents::Make(
    Color color,
    std::unique_ptr<FillRectGeometry> geometry) {
  return std::make_unique<FilledRectSDFContents>(color, std::move(geometry));
}

FilledRectSDFContents::FilledRectSDFContents(
    Color color,
    std::unique_ptr<FillRectGeometry> geometry)
    : UberSDFContents(color), geometry_(std::move(geometry)) {}

FilledRectSDFContents::~FilledRectSDFContents() = default;

const Geometry* FilledRectSDFContents::GetGeometry() const {
  return geometry_.get();
}

bool FilledRectSDFContents::BindData(const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass,
                                     FS::FragInfo& frag_info) const {
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.stroked = 0.0f;
  frag_info.stroke_width = 0.0f;
  frag_info.stroke_join = 0.0f;  // kMiter
  frag_info.type = 1.0f;         // kRect
  Rect rect = geometry_->GetRect();
  frag_info.center = rect.GetCenter();
  frag_info.size = Point(rect.GetWidth() / 2.0f, rect.GetHeight() / 2.0f);
  frag_info.aa_pixels = 1.0f;
  return true;
}

}  // namespace impeller
