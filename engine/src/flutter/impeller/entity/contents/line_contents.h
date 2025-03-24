// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_LINE_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_LINE_CONTENTS_H_

#include <memory>

#include "flutter/impeller/entity/contents/contents.h"
#include "flutter/impeller/entity/geometry/line_geometry.h"

namespace impeller {
class LineContents : public Contents {
 public:
  static std::unique_ptr<LineContents> Make(
      std::unique_ptr<LineGeometry> geometry,
      Color color);

  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  std::optional<Rect> GetCoverage(const Entity& entity) const override;

 private:
  explicit LineContents(std::unique_ptr<LineGeometry> geometry, Color color);

  std::unique_ptr<LineGeometry> geometry_;
  Color color_;
};
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_LINE_CONTENTS_H_
