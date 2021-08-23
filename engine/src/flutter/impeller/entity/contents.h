// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/point.h"

namespace impeller {

class ContentRenderer;
class Entity;
class Surface;
class RenderPass;

class Contents {
 public:
  Contents();

  ~Contents();

  virtual bool Render(const ContentRenderer& renderer,
                      const Entity& entity,
                      const Surface& surface,
                      RenderPass& pass) const = 0;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Contents);
};

class LinearGradientContents final : public Contents {
 public:
  LinearGradientContents();

  ~LinearGradientContents();

  // |Contents|
  bool Render(const ContentRenderer& renderer,
              const Entity& entity,
              const Surface& surface,
              RenderPass& pass) const override;

  void SetEndPoints(Point start_point, Point end_point);

  void SetColors(std::vector<Color> colors);

  const std::vector<Color>& GetColors() const;

 private:
  Point start_point_;
  Point end_point_;
  std::vector<Color> colors_;

  FML_DISALLOW_COPY_AND_ASSIGN(LinearGradientContents);
};

}  // namespace impeller
