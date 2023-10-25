// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"

namespace impeller {

/// A special Contents that renders a translucent checkerboard pattern with a
/// random color over the entire pass texture. This is useful for visualizing
/// offscreen textures.
class CheckerboardContents final : public Contents {
 public:
  CheckerboardContents();

  // |Contents|
  ~CheckerboardContents() override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  void SetColor(Color color);

  void SetSquareSize(Scalar square_size);

 private:
  Color color_ = Color::Red().WithAlpha(0.25);
  Scalar square_size_ = 12;

  CheckerboardContents(const CheckerboardContents&) = delete;

  CheckerboardContents& operator=(const CheckerboardContents&) = delete;
};

}  // namespace impeller
