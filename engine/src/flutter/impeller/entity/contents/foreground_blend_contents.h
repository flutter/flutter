// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/impeller/core/texture.h"
#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/filters/inputs/filter_input.h"
#include "flutter/impeller/entity/entity.h"

namespace impeller {

/// @brief Optimized advanced blend that avoids a second subpass when there is
///        only a single input and a foreground color.
///
/// These contents cannot absorb opacity.
class AdvancedForegroundBlendContents : public Contents {
 public:
  AdvancedForegroundBlendContents();

  ~AdvancedForegroundBlendContents();

  void SetBlendMode(BlendMode blend_mode);

  void SetSrcInput(std::shared_ptr<FilterInput> input);

  void SetForegroundColor(Color color);

  void SetCoverage(Rect rect);

 private:
  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  Color foreground_color_;
  BlendMode blend_mode_;
  std::shared_ptr<FilterInput> input_;
  Rect rect_;

  FML_DISALLOW_COPY_AND_ASSIGN(AdvancedForegroundBlendContents);
};

}  // namespace impeller
