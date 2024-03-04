// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_GAUSSIAN_BLUR_FILTER_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_GAUSSIAN_BLUR_FILTER_CONTENTS_H_

#include <optional>
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

struct BlurParameters {
  Point blur_uv_offset;
  Scalar blur_sigma;
  int blur_radius;
  int step_size;
};

KernelPipeline::FragmentShader::KernelSamples GenerateBlurInfo(
    BlurParameters parameters);

/// This will shrink the size of a kernel by roughly half by sampling between
/// samples and relying on linear interpolation between the samples.
KernelPipeline::FragmentShader::KernelSamples LerpHackKernelSamples(
    KernelPipeline::FragmentShader::KernelSamples samples);

/// Performs a bidirectional Gaussian blur.
///
/// This is accomplished by rendering multiple passes in multiple directions.
/// Note: This will replace `DirectionalGaussianBlurFilterContents`.
class GaussianBlurFilterContents final : public FilterContents {
 public:
  static std::string_view kNoMipsError;
  static const int32_t kBlurFilterRequiredMipCount;

  explicit GaussianBlurFilterContents(
      Scalar sigma_x,
      Scalar sigma_y,
      Entity::TileMode tile_mode,
      BlurStyle mask_blur_style,
      const std::shared_ptr<Geometry>& mask_geometry);

  Scalar GetSigmaX() const { return sigma_x_; }
  Scalar GetSigmaY() const { return sigma_y_; }

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
  /// @param source_rect The rect in source coordinates to convert to uvs.
  /// @param texture_size The rect to convert in source coordinates.
  static Quad CalculateUVs(const std::shared_ptr<FilterInput>& filter_input,
                           const Entity& entity,
                           const Rect& source_rect,
                           const ISize& texture_size);

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

  const Scalar sigma_x_ = 0.0;
  const Scalar sigma_y_ = 0.0;
  const Entity::TileMode tile_mode_;
  const BlurStyle mask_blur_style_;
  std::shared_ptr<Geometry> mask_geometry_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_GAUSSIAN_BLUR_FILTER_CONTENTS_H_
