// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_CIRCLE_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_CIRCLE_CONTENTS_H_

#include <memory>

#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/contents.h"
#include "impeller/entity/geometry/circle_geometry.h"

namespace impeller {
class CircleContents : public ColorSourceContents {
 public:
  static std::unique_ptr<CircleContents>
  Make(std::unique_ptr<CircleGeometry> geometry, Color color, bool stroked);

  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  std::optional<Rect> GetCoverage(const Entity& entity) const override;

 private:
  explicit CircleContents(std::unique_ptr<CircleGeometry> geometry,
                          Color color,
                          bool stroked);

  std::unique_ptr<CircleGeometry> geometry_;
  Color color_;
  bool stroked_;
};
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_CIRCLE_CONTENTS_H_
