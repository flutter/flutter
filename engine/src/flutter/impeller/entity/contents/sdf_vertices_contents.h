// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_SDF_VERTICES_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_SDF_VERTICES_CONTENTS_H_

#include <memory>

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry/shadow_path_geometry.h"
#include "impeller/geometry/color.h"

namespace impeller {

using SDFVertices = ShadowVertices;

/// A contents for vertices with an SDF parameter.
class SDFVerticesContents final : public Contents {
 public:
  static std::shared_ptr<SDFVerticesContents> Make(
      const std::shared_ptr<SDFVertices>& geometry);

  // |SolidBlurContents|
  void SetColor(Color color);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  explicit SDFVerticesContents(
      const std::shared_ptr<SDFVertices>& geometry);

  ~SDFVerticesContents() override;

 private:
  const std::shared_ptr<SDFVertices> geometry_;
  Color path_color_;

  SDFVerticesContents(const SDFVerticesContents&) = delete;

  SDFVerticesContents& operator=(const SDFVerticesContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_SDF_VERTICES_CONTENTS_H_
