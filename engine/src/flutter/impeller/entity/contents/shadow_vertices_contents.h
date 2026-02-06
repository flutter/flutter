// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_SHADOW_VERTICES_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_SHADOW_VERTICES_CONTENTS_H_

#include <memory>

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/solid_rrect_blur_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry/shadow_path_geometry.h"
#include "impeller/geometry/color.h"

namespace impeller {

/// A vertices contents for (optional) per-color vertices + texture and any
/// blend mode.
class ShadowVerticesContents final : public SolidBlurContents {
 public:
  static std::shared_ptr<ShadowVerticesContents> Make(
      const std::shared_ptr<ShadowVertices>& geometry);

  // |SolidBlurContents|
  void SetColor(Color color) override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  explicit ShadowVerticesContents(
      const std::shared_ptr<ShadowVertices>& geometry);

  ~ShadowVerticesContents() override;

 private:
  const std::shared_ptr<ShadowVertices> geometry_;
  Color shadow_color_;

  ShadowVerticesContents(const ShadowVerticesContents&) = delete;

  ShadowVerticesContents& operator=(const ShadowVerticesContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_SHADOW_VERTICES_CONTENTS_H_
