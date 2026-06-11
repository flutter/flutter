// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_PATH_SDF_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_PATH_SDF_CONTENTS_H_

#include <memory>

#include "flutter/display_list/geometry/dl_path.h"
#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/contents.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {
class PathSdfContents : public ColorSourceContents {
 public:
  static std::unique_ptr<PathSdfContents> Make(
      const flutter::DlPath& path,
      std::unique_ptr<Geometry> geometry,
      Color color,
      Scalar stroke_width);

  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  const Geometry* GetGeometry() const override;

 private:
  explicit PathSdfContents(const flutter::DlPath& path,
                           std::unique_ptr<Geometry> geometry,
                           Color color,
                           Scalar stroke_width);

  const flutter::DlPath path_;
  std::unique_ptr<Geometry> geometry_;
  Color color_;
  Scalar stroke_width_;
};
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_PATH_SDF_CONTENTS_H_
