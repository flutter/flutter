// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_CIRCLE_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_CIRCLE_CONTENTS_H_

#include <memory>
#include <optional>

#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/contents.h"
#include "impeller/entity/geometry/rect_geometry.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/scalar.h"

namespace impeller {
class CircleContents : public ColorSourceContents {
 public:
  static std::unique_ptr<CircleContents> Make(
      Color color,
      const Point& center,
      Scalar radius,
      std::optional<Scalar> stroke_width);

  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  const Geometry* GetGeometry() const override;

 private:
  explicit CircleContents(Color color,
                          const Point& center,
                          Scalar radius,
                          std::optional<Scalar> stroke_width,
                          std::unique_ptr<FillRectGeometry> geometry);

  Color color_;
  Point center_;
  Scalar radius_;
  std::optional<Scalar> stroke_width_;
  std::unique_ptr<FillRectGeometry> geometry_;
};
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_CIRCLE_CONTENTS_H_
