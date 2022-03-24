// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/geometry/matrix.h"

namespace impeller {

class DirectionalGaussianBlurFilterContents final : public FilterContents {
 public:
  DirectionalGaussianBlurFilterContents();

  ~DirectionalGaussianBlurFilterContents() override;

  void SetBlurVector(Vector2 blur_vector);

  // |Contents|
  Rect GetBounds(const Entity& entity) const override;

 private:
  // |FilterContents|
  bool RenderFilter(const std::vector<Snapshot>& input_textures,
                    const ContentContext& renderer,
                    RenderPass& pass,
                    const Matrix& transform) const override;

  Vector2 blur_vector_;

  FML_DISALLOW_COPY_AND_ASSIGN(DirectionalGaussianBlurFilterContents);
};

}  // namespace impeller
