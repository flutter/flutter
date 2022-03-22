// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents/filters/filter_contents.h"

namespace impeller {

class DirectionalGaussianBlurFilterContents final : public FilterContents {
 public:
  DirectionalGaussianBlurFilterContents();

  ~DirectionalGaussianBlurFilterContents() override;

  void SetRadius(Scalar radius);

  void SetDirection(Vector2 direction);

  void SetClipBorder(bool clip);

 private:
  // |FilterContents|
  bool RenderFilter(const std::vector<std::shared_ptr<Texture>>& input_textures,
                    const ContentContext& renderer,
                    RenderPass& pass) const override;

  // |FilterContents|
  virtual ISize GetOutputSize(
      const InputTextures& input_textures) const override;

  Scalar radius_ = 0;
  Vector2 direction_;
  bool clip_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(DirectionalGaussianBlurFilterContents);
};

}  // namespace impeller
