// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>
#include <variant>
#include <vector>

#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/formats.h"

namespace impeller {

class Pipeline;

class FilterContents : public Contents {
 public:
  enum class BlurStyle {
    /// Blurred inside and outside.
    kNormal,
    /// Solid inside, blurred outside.
    kSolid,
    /// Nothing inside, blurred outside.
    kOuter,
    /// Blurred inside, nothing outside.
    kInner,
  };

  /// For filters that use a Gaussian distribution, this is the `Radius` size to
  /// use per `Sigma` (standard deviation).
  ///
  /// This cutoff (sqrt(3)) is taken from Flutter and Skia (where the
  /// multiplicative inverse of this constant is used (1 / sqrt(3)):
  /// https://api.flutter.dev/flutter/dart-ui/Shadow/convertRadiusToSigma.html
  ///
  /// In practice, this value is somewhat arbitrary, and can be changed to a
  /// higher number to integrate more of the Gaussian function and render higher
  /// quality blurs (with exponentially diminishing returns for the same sigma
  /// input). Making this value any lower results in a noticable loss of
  /// quality in the blur.
  constexpr static float kKernelRadiusPerSigma = 1.73205080757;

  struct Radius;

  /// @brief  In filters that use Gaussian distributions, "sigma" is a size of
  ///         one standard deviation in terms of the local space pixel grid of
  ///         the filter input. In other words, this determines how wide the
  ///         distribution stretches.
  struct Sigma {
    Scalar sigma = 0.0;

    constexpr Sigma() = default;

    explicit constexpr Sigma(Scalar p_sigma) : sigma(p_sigma) {}

    constexpr operator Radius() const {
      return Radius{sigma > 0.5f ? (sigma - 0.5f) * kKernelRadiusPerSigma
                                 : 0.0f};
    };
  };

  /// @brief  For convolution filters, the "radius" is the size of the
  ///         convolution kernel to use on the local space pixel grid of the
  ///         filter input.
  ///         For Gaussian blur kernels, this unit has a linear
  ///         relationship with `Sigma`. See `kKernelRadiusPerSigma` for
  ///         details on how this relationship works.
  struct Radius {
    Scalar radius = 0.0;

    constexpr Radius() = default;

    explicit constexpr Radius(Scalar p_radius) : radius(p_radius) {}

    constexpr operator Sigma() const {
      return Sigma{radius > 0 ? radius / kKernelRadiusPerSigma + 0.5f : 0.0f};
    };
  };

  static std::shared_ptr<FilterContents> MakeBlend(
      Entity::BlendMode blend_mode,
      FilterInput::Vector inputs,
      std::optional<Color> foreground_color = std::nullopt);

  static std::shared_ptr<FilterContents> MakeDirectionalGaussianBlur(
      FilterInput::Ref input,
      Sigma sigma,
      Vector2 direction,
      BlurStyle blur_style = BlurStyle::kNormal,
      FilterInput::Ref alpha_mask = nullptr);

  static std::shared_ptr<FilterContents> MakeGaussianBlur(
      FilterInput::Ref input,
      Sigma sigma_x,
      Sigma sigma_y,
      BlurStyle blur_style = BlurStyle::kNormal);

  static std::shared_ptr<FilterContents> MakeBorderMaskBlur(
      FilterInput::Ref input,
      Sigma sigma_x,
      Sigma sigma_y,
      BlurStyle blur_style = BlurStyle::kNormal);

  FilterContents();

  ~FilterContents() override;

  /// @brief  The input texture sources for this filter. Each input's emitted
  ///         texture is expected to have premultiplied alpha colors.
  ///
  ///         The number of required or optional textures depends on the
  ///         particular filter's implementation.
  void SetInputs(FilterInput::Vector inputs);

  /// @brief  Screen space bounds to use for cropping the filter output.
  void SetCoverageCrop(std::optional<Rect> coverage_crop);

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  std::optional<Snapshot> RenderToSnapshot(const ContentContext& renderer,
                                           const Entity& entity) const override;

  virtual Matrix GetLocalTransform() const;

  Matrix GetTransform(const Matrix& parent_transform) const;

 private:
  virtual std::optional<Rect> GetFilterCoverage(
      const FilterInput::Vector& inputs,
      const Entity& entity) const;

  /// @brief  Takes a set of zero or more input textures and writes to an output
  ///         texture.
  virtual bool RenderFilter(const FilterInput::Vector& inputs,
                            const ContentContext& renderer,
                            const Entity& entity,
                            RenderPass& pass,
                            const Rect& coverage) const = 0;

  std::optional<Rect> GetLocalCoverage(const Entity& local_entity) const;

  FilterInput::Vector inputs_;
  std::optional<Rect> coverage_crop_;

  FML_DISALLOW_COPY_AND_ASSIGN(FilterContents);
};

}  // namespace impeller
