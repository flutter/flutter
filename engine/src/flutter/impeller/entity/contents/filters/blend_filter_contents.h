// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_BLEND_FILTER_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_BLEND_FILTER_CONTENTS_H_

#include <array>
#include <optional>

#include "impeller/base/validation.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"

namespace impeller {

/// The coefficients that make the porter-duff blend shader
/// (porter_duff_blend.frag) implement each porter-duff blend mode, indexed by
/// `BlendMode`. The shader computes:
///
///   src * (src_coeff + dst.a * src_coeff_dst_alpha) +
///   dst * (dst_coeff + src.a * dst_coeff_src_alpha +
///          src * dst_coeff_src_color)
///
/// See also `SetPorterDuffCoefficients`.
constexpr std::array<std::array<Scalar, 5>,
                     static_cast<size_t>(Entity::kLastPipelineBlendMode) + 1>
    kPorterDuffCoefficients = {{
        {0, 0, 0, 0, 0},    // Clear
        {1, 0, 0, 0, 0},    // Source
        {0, 0, 1, 0, 0},    // Destination
        {1, 0, 1, -1, 0},   // SourceOver
        {1, -1, 1, 0, 0},   // DestinationOver
        {0, 1, 0, 0, 0},    // SourceIn
        {0, 0, 0, 1, 0},    // DestinationIn
        {1, -1, 0, 0, 0},   // SourceOut
        {0, 0, 1, -1, 0},   // DestinationOut
        {0, 1, 1, -1, 0},   // SourceATop
        {1, -1, 0, 1, 0},   // DestinationATop
        {1, -1, 1, -1, 0},  // Xor
        {1, 0, 1, 0, 0},    // Plus
        {0, 0, 0, 0, 1},    // Modulate
    }};

/// @brief  Sets the uniforms that select `blend_mode` in the porter-duff blend
///         shader, which draws every porter-duff blend mode with one pipeline.
///
///         `blend_mode` must be a porter-duff blend mode, that is at most
///         `Entity::kLastPipelineBlendMode`. Any other blend mode is a
///         validation error and draws as `BlendMode::kClear`.
///
/// @tparam FragInfo  The fragment uniforms of the porter-duff blend shader,
///                   `PorterDuffBlendPipeline::FragmentShader::FragInfo`.
template <typename FragInfo>
void SetPorterDuffCoefficients(BlendMode blend_mode, FragInfo& frag_info) {
  if (blend_mode > Entity::kLastPipelineBlendMode) {
    VALIDATION_LOG << "Invalid porter duff blend mode "
                   << BlendModeToString(blend_mode);
    blend_mode = BlendMode::kClear;
  }
  const std::array<Scalar, 5>& coefficients =
      kPorterDuffCoefficients[static_cast<size_t>(blend_mode)];
  frag_info.src_coeff = coefficients[0];
  frag_info.src_coeff_dst_alpha = coefficients[1];
  frag_info.dst_coeff = coefficients[2];
  frag_info.dst_coeff_src_alpha = coefficients[3];
  frag_info.dst_coeff_src_color = coefficients[4];
}

std::optional<BlendMode> InvertPorterDuffBlend(BlendMode blend_mode);

class BlendFilterContents : public ColorFilterContents {
 public:
  using AdvancedBlendProc = std::function<std::optional<Entity>(
      const FilterInput::Vector& inputs,
      const ContentContext& renderer,
      const Entity& entity,
      const Rect& coverage,
      BlendMode blend_mode,
      std::optional<Color> foreground_color,
      ColorFilterContents::AbsorbOpacity absorb_opacity,
      std::optional<Scalar> alpha)>;

  BlendFilterContents();

  ~BlendFilterContents() override;

  void SetBlendMode(BlendMode blend_mode);

  /// @brief  Sets a source color which is blended after all of the inputs have
  ///         been blended.
  void SetForegroundColor(std::optional<Color> color);

 private:
  // |FilterContents|
  std::optional<Entity> RenderFilter(
      const FilterInput::Vector& inputs,
      const ContentContext& renderer,
      const Entity& entity,
      const Matrix& effect_transform,
      const Rect& coverage,
      const std::optional<Rect>& coverage_hint) const override;

  /// @brief Optimized advanced blend that avoids a second subpass when there is
  ///        only a single input and a foreground color.
  ///
  /// These contents cannot absorb opacity.
  std::optional<Entity> CreateForegroundAdvancedBlend(
      const std::shared_ptr<FilterInput>& input,
      const ContentContext& renderer,
      const Entity& entity,
      const Rect& coverage,
      Color foreground_color,
      BlendMode blend_mode,
      std::optional<Scalar> alpha,
      ColorFilterContents::AbsorbOpacity absorb_opacity) const;

  /// @brief Implements the advanced blends filters in terms of the framebuffer
  ///        blend filters.
  ///
  ///        This requires device support for frameuffer fetch,
  ///        `Capabilities::SupportsFramebufferFetch` must be true
  ///        This allows a substantial reduction in the number of bootstrapped
  ///        shaders.
  std::optional<Entity> CreateFramebufferAdvancedBlend(
      const FilterInput::Vector& inputs,
      const ContentContext& renderer,
      const Entity& entity,
      const Rect& coverage,
      std::optional<Color> foreground_color,
      BlendMode blend_mode,
      std::optional<Scalar> alpha,
      ColorFilterContents::AbsorbOpacity absorb_opacity) const;

  /// @brief Optimized porter-duff blend that avoids a second subpass when there
  ///        is only a single input and a foreground color.
  ///
  /// These contents cannot absorb opacity.
  std::optional<Entity> CreateForegroundPorterDuffBlend(
      const std::shared_ptr<FilterInput>& input,
      const ContentContext& renderer,
      const Entity& entity,
      const Rect& coverage,
      Color foreground_color,
      BlendMode blend_mode,
      std::optional<Scalar> alpha,
      ColorFilterContents::AbsorbOpacity absorb_opacity) const;

  BlendMode blend_mode_ = BlendMode::kSrcOver;
  AdvancedBlendProc advanced_blend_proc_;
  std::optional<Color> foreground_color_;

  BlendFilterContents(const BlendFilterContents&) = delete;

  BlendFilterContents& operator=(const BlendFilterContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_BLEND_FILTER_CONTENTS_H_
