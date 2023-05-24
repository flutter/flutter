// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/geometry/color.h"

namespace impeller {

class Path;
class HostBuffer;
struct VertexBuffer;

/// @brief  Draws a fast solid color blur of an rounded rectangle. Only supports
/// RRects with fully symmetrical radii. Also produces correct results for
/// rectangles (corner_radius=0) and circles (corner_radius=width/2=height/2).
class SolidRRectBlurContents final : public Contents {
 public:
  SolidRRectBlurContents();

  ~SolidRRectBlurContents() override;

  void SetRRect(std::optional<Rect> rect, Scalar corner_radius = 0);

  void SetSigma(Sigma sigma);

  void SetColor(Color color);

  Color GetColor() const;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  std::optional<Rect> rect_;
  Scalar corner_radius_;
  Sigma sigma_;

  Color color_;

  FML_DISALLOW_COPY_AND_ASSIGN(SolidRRectBlurContents);
};

}  // namespace impeller
