// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/circle_sdf_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/circle_geometry.h"
#include "impeller/entity/geometry/rect_geometry.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/scalar.h"

namespace impeller {

std::unique_ptr<CircleSDFContents> CircleSDFContents::Make(
    Color color,
    const Point& center,
    Scalar radius,
    Scalar stroke_width,
    Scalar padding_pixels,
    std::unique_ptr<FillRectGeometry> geometry) {
  return std::make_unique<CircleSDFContents>(
      color, center, radius, stroke_width, padding_pixels, std::move(geometry));
}

CircleSDFContents::CircleSDFContents(Color color,
                                     const Point& center,
                                     Scalar radius,
                                     Scalar stroke_width,
                                     Scalar padding_pixels,
                                     std::unique_ptr<FillRectGeometry> geometry)
    : UberSDFContents(color),

      center_(center),
      radius_(radius),
      stroke_width_(stroke_width),
      padding_pixels_(padding_pixels),
      geometry_(std::move(geometry)) {}

CircleSDFContents::~CircleSDFContents() = default;

const Geometry* CircleSDFContents::GetGeometry() const {
  return geometry_.get();
}

bool CircleSDFContents::BindData(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass,
                                 FS::FragInfo& frag_info) const {
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.stroked = stroke_width_ != 0 ? 1.0 : 0.0;
  frag_info.stroke_width = stroke_width_;
  frag_info.stroke_join = 0.0f;  // kMiter
  frag_info.type = 0.0f;         // kCircle
  frag_info.center = center_;
  frag_info.size = Point(radius_, radius_);
  frag_info.aa_pixels = padding_pixels_;
  return true;
}

}  // namespace impeller
