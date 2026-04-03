// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/circle_sdf_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/circle_geometry.h"

namespace impeller {

std::unique_ptr<CircleSDFContents> CircleSDFContents::Make(
    Color color,
    bool stroked,
    std::unique_ptr<CircleGeometry> geometry) {
  return std::make_unique<CircleSDFContents>(color, stroked,
                                             std::move(geometry));
}

CircleSDFContents::CircleSDFContents(Color color,
                                     bool stroked,
                                     std::unique_ptr<CircleGeometry> geometry)
    : UberSDFContents(color), stroked_(stroked), geometry_(std::move(geometry)) {}

CircleSDFContents::~CircleSDFContents() = default;

const Geometry* CircleSDFContents::GetGeometry() const {
  return geometry_.get();
}

bool CircleSDFContents::BindData(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass,
                                 FS::FragInfo& frag_info) const {
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.stroked = stroked_ ? 1.0f : 0.0f;
  frag_info.stroke_width = geometry_->GetStrokeWidth();
  frag_info.stroke_join = 0.0f;  // kMiter
  frag_info.type = 0.0f;         // kCircle
  frag_info.center = geometry_->GetCenter();
  Scalar radius = geometry_->GetRadius();
  frag_info.size = Point(radius, radius);
  frag_info.aa_pixels = geometry_->GetAntialiasPadding();
  return true;
}

}  // namespace impeller
