// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_GAUSSIAN_BLUR_FILTER_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_GAUSSIAN_BLUR_FILTER_CONTENTS_H_

#include <optional>
#include "impeller/entity/contents/filters/filter_contents.h"

namespace impeller {

/// Performs a bidirectional Gaussian blur.
///
/// This is accomplished by rendering multiple passes in multiple directions.
/// Note: This will replace `DirectionalGaussianBlurFilterContents`.
class GaussianBlurFilterContents final : public FilterContents {
 public:
  explicit GaussianBlurFilterContents(Scalar sigma, Entity::TileMode tile_mode);

  Scalar GetSigma() const { return sigma_; }

  // |FilterContents|
  std::optional<Rect> GetFilterSourceCoverage(
      const Matrix& effect_transform,
      const Rect& output_limit) const override;

  // |FilterContents|
  std::optional<Rect> GetFilterCoverage(
      const FilterInput::Vector& inputs,
      const Entity& entity,
      const Matrix& effect_transform) const override;

  /// Given a sigma (standard deviation) calculate the blur radius (1/2 the
  /// kernel size).
  static Scalar CalculateBlurRadius(Scalar sigma);

  /// Calculate the UV coordinates for rendering the filter_input.
  /// @param filter_input The FilterInput that should be rendered.
  /// @param entity The associated entity for the filter_input.
  /// @param texture_size The size of the texture_size the uvs will be used for.
  static Quad CalculateUVs(const std::shared_ptr<FilterInput>& filter_input,
                           const Entity& entity,
                           const ISize& pass_size);

  /// Calculate the scale factor for the downsample pass given a sigma value.
  ///
  /// Visible for testing.
  static Scalar CalculateScale(Scalar sigma);

  /// Scales down the sigma value to match Skia's behavior.
  ///
  /// effective_blur_radius = CalculateBlurRadius(ScaleSigma(sigma_));
  ///
  /// This function was calculated by observing Skia's behavior. Its blur at
  /// 500 seemed to be 0.15.  Since we clamp at 500 I solved the quadratic
  /// equation that puts the minima there and a f(0)=1.
  static Scalar ScaleSigma(Scalar sigma);

 private:
  // |FilterContents|
  std::optional<Entity> RenderFilter(
      const FilterInput::Vector& input_textures,
      const ContentContext& renderer,
      const Entity& entity,
      const Matrix& effect_transform,
      const Rect& coverage,
      const std::optional<Rect>& coverage_hint) const override;

  const Scalar sigma_ = 0.0;
  const Entity::TileMode tile_mode_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_GAUSSIAN_BLUR_FILTER_CONTENTS_H_
