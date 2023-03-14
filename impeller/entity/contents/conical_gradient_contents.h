// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/gradient.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"

namespace impeller {

class ConicalGradientContents final : public ColorSourceContents {
 public:
  ConicalGradientContents();

  ~ConicalGradientContents() override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  void SetCenterAndRadius(Point center, Scalar radius);

  void SetColors(std::vector<Color> colors);

  void SetStops(std::vector<Scalar> stops);

  const std::vector<Color>& GetColors() const;

  const std::vector<Scalar>& GetStops() const;

  void SetTileMode(Entity::TileMode tile_mode);

  void SetFocus(std::optional<Point> focus, Scalar radius);

 private:
  bool RenderTexture(const ContentContext& renderer,
                     const Entity& entity,
                     RenderPass& pass) const;

  bool RenderSSBO(const ContentContext& renderer,
                  const Entity& entity,
                  RenderPass& pass) const;
  Point center_;
  Scalar radius_ = 0.0f;
  std::vector<Color> colors_;
  std::vector<Scalar> stops_;
  Entity::TileMode tile_mode_;
  std::optional<Point> focus_;
  Scalar focus_radius_ = 0.0f;

  FML_DISALLOW_COPY_AND_ASSIGN(ConicalGradientContents);
};

}  // namespace impeller
