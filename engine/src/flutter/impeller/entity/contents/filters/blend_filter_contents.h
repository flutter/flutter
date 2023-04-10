// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"

namespace impeller {

class BlendFilterContents : public ColorFilterContents {
 public:
  using AdvancedBlendProc =
      std::function<std::optional<Entity>(const FilterInput::Vector& inputs,
                                          const ContentContext& renderer,
                                          const Entity& entity,
                                          const Rect& coverage,
                                          std::optional<Color> foreground_color,
                                          bool absorb_opacity,
                                          std::optional<Scalar> alpha)>;

  BlendFilterContents();

  ~BlendFilterContents() override;

  void SetBlendMode(BlendMode blend_mode);

  /// @brief  Sets a source color which is blended after all of the inputs have
  ///         been blended.
  void SetForegroundColor(std::optional<Color> color);

 private:
  // |FilterContents|
  std::optional<Entity> RenderFilter(const FilterInput::Vector& inputs,
                                     const ContentContext& renderer,
                                     const Entity& entity,
                                     const Matrix& effect_transform,
                                     const Rect& coverage) const override;

  /// @brief Optimized advanced blend that avoids a second subpass when there is
  ///        only a single input and a foreground color.
  ///
  /// These contents cannot absorb opacity.
  std::optional<Entity> CreateForegroundBlend(
      const std::shared_ptr<FilterInput>& input,
      const ContentContext& renderer,
      const Entity& entity,
      const Rect& coverage,
      Color foreground_color,
      BlendMode blend_mode,
      std::optional<Scalar> alpha,
      bool absorb_opacity) const;

  BlendMode blend_mode_ = BlendMode::kSourceOver;
  AdvancedBlendProc advanced_blend_proc_;
  std::optional<Color> foreground_color_;

  FML_DISALLOW_COPY_AND_ASSIGN(BlendFilterContents);
};

}  // namespace impeller
