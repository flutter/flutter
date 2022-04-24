// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"

namespace impeller {

class DirectionalGaussianBlurFilterContents final : public FilterContents {
 public:
  DirectionalGaussianBlurFilterContents();

  ~DirectionalGaussianBlurFilterContents() override;

  void SetSigma(Sigma sigma);

  void SetDirection(Vector2 direction);

  void SetBlurStyle(BlurStyle blur_style);

  void SetSourceOverride(FilterInput::Ref alpha_mask);

  // |FilterContents|
  std::optional<Rect> GetFilterCoverage(const FilterInput::Vector& inputs,
                                        const Entity& entity) const override;

 private:
  // |FilterContents|
  bool RenderFilter(const FilterInput::Vector& input_textures,
                    const ContentContext& renderer,
                    const Entity& entity,
                    RenderPass& pass,
                    const Rect& coverage) const override;
  Sigma blur_sigma_;
  Vector2 blur_direction_;
  BlurStyle blur_style_ = BlurStyle::kNormal;
  bool src_color_factor_ = false;
  bool inner_blur_factor_ = true;
  bool outer_blur_factor_ = true;
  FilterInput::Ref source_override_;

  FML_DISALLOW_COPY_AND_ASSIGN(DirectionalGaussianBlurFilterContents);
};

}  // namespace impeller
