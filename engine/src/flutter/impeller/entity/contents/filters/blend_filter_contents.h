// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"

namespace impeller {

class BlendFilterContents : public FilterContents {
 public:
  using AdvancedBlendProc =
      std::function<bool(const FilterInput::Vector& inputs,
                         const ContentContext& renderer,
                         const Entity& entity,
                         RenderPass& pass,
                         const Rect& coverage,
                         std::optional<Color> foreground_color)>;

  BlendFilterContents();

  ~BlendFilterContents() override;

  void SetBlendMode(Entity::BlendMode blend_mode);

  /// @brief  Sets a source color which is blended after all of the inputs have
  ///         been blended.
  void SetForegroundColor(std::optional<Color> color);

 private:
  // |FilterContents|
  bool RenderFilter(const FilterInput::Vector& inputs,
                    const ContentContext& renderer,
                    const Entity& entity,
                    RenderPass& pass,
                    const Rect& coverage) const override;

  Entity::BlendMode blend_mode_ = Entity::BlendMode::kSourceOver;
  AdvancedBlendProc advanced_blend_proc_;
  std::optional<Color> foreground_color_;

  FML_DISALLOW_COPY_AND_ASSIGN(BlendFilterContents);
};

}  // namespace impeller
