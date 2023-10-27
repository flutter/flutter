// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>
#include <variant>
#include <vector>

#include "impeller/core/formats.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/sigma.h"

namespace impeller {

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

  enum class MorphType { kDilate, kErode };

  /// Creates a gaussian blur that operates in one direction.
  /// See also: `MakeGaussianBlur`
  static std::shared_ptr<FilterContents> MakeDirectionalGaussianBlur(
      FilterInput::Ref input,
      Sigma sigma,
      Vector2 direction,
      BlurStyle blur_style = BlurStyle::kNormal,
      Entity::TileMode tile_mode = Entity::TileMode::kDecal,
      bool is_second_pass = false,
      Sigma secondary_sigma = {});

  /// Creates a gaussian blur that operates in 2 dimensions.
  /// See also: `MakeDirectionalGaussianBlur`
  static std::shared_ptr<FilterContents> MakeGaussianBlur(
      const FilterInput::Ref& input,
      Sigma sigma_x,
      Sigma sigma_y,
      BlurStyle blur_style = BlurStyle::kNormal,
      Entity::TileMode tile_mode = Entity::TileMode::kDecal);

  static std::shared_ptr<FilterContents> MakeBorderMaskBlur(
      FilterInput::Ref input,
      Sigma sigma_x,
      Sigma sigma_y,
      BlurStyle blur_style = BlurStyle::kNormal);

  static std::shared_ptr<FilterContents> MakeDirectionalMorphology(
      FilterInput::Ref input,
      Radius radius,
      Vector2 direction,
      MorphType morph_type);

  static std::shared_ptr<FilterContents> MakeMorphology(FilterInput::Ref input,
                                                        Radius radius_x,
                                                        Radius radius_y,
                                                        MorphType morph_type);

  static std::shared_ptr<FilterContents> MakeMatrixFilter(
      FilterInput::Ref input,
      const Matrix& matrix,
      const SamplerDescriptor& desc);

  static std::shared_ptr<FilterContents> MakeLocalMatrixFilter(
      FilterInput::Ref input,
      const Matrix& matrix);

  static std::shared_ptr<FilterContents> MakeYUVToRGBFilter(
      std::shared_ptr<Texture> y_texture,
      std::shared_ptr<Texture> uv_texture,
      YUVColorSpace yuv_color_space);

  FilterContents();

  ~FilterContents() override;

  /// @brief  The input texture sources for this filter. Each input's emitted
  ///         texture is expected to have premultiplied alpha colors.
  ///
  ///         The number of required or optional textures depends on the
  ///         particular filter's implementation.
  void SetInputs(FilterInput::Vector inputs);

  /// @brief  Sets the transform which gets appended to the effect of this
  ///         filter. Note that this is in addition to the entity's transform.
  ///
  ///         This is useful for subpass rendering scenarios where it's
  ///         difficult to encode the current transform of the layer into the
  ///         Entity being rendered.
  void SetEffectTransform(const Matrix& effect_transform);

  /// @brief  Create an Entity that renders this filter's output.
  std::optional<Entity> GetEntity(
      const ContentContext& renderer,
      const Entity& entity,
      const std::optional<Rect>& coverage_hint) const;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  void PopulateGlyphAtlas(
      const std::shared_ptr<LazyGlyphAtlas>& lazy_glyph_atlas,
      Scalar scale) override;

  // |Contents|
  std::optional<Snapshot> RenderToSnapshot(
      const ContentContext& renderer,
      const Entity& entity,
      std::optional<Rect> coverage_limit = std::nullopt,
      const std::optional<SamplerDescriptor>& sampler_descriptor = std::nullopt,
      bool msaa_enabled = true,
      const std::string& label = "Filter Snapshot") const override;

  // |Contents|
  const FilterContents* AsFilter() const override;

  /// @brief Determines the coverage of source pixels that will be needed
  ///        to apply this filter under the given transform and produce
  ///        results anywhere within the indicated coverage limit.
  ///
  ///        This is useful for subpass rendering scenarios where a filter
  ///        will be applied to the output of the subpass and we need to
  ///        determine how large of a render target to allocate in order
  ///        to collect all pixels that might affect the supplied output
  ///        coverage limit. While we might clip the rendering of the subpass,
  ///        we want to avoid clipping out any pixels that contribute to
  ///        the output limit via the filtering operation.
  std::optional<Rect> GetSourceCoverage(const Matrix& effect_transform,
                                        const Rect& output_limit) const;

  virtual Matrix GetLocalTransform(const Matrix& parent_transform) const;

  Matrix GetTransform(const Matrix& parent_transform) const;

  /// @brief  Returns true if this filter graph doesn't perform any basis
  ///         transformations to the filtered content. For example: Rotating,
  ///         scaling, and skewing are all basis transformations, but
  ///         translating is not.
  ///
  ///         This is useful for determining whether a filtered object's space
  ///         is compatible enough with the parent pass space to perform certain
  ///         subpass clipping optimizations.
  virtual bool IsTranslationOnly() const;

  /// @brief  Returns `true` if this filter does not have any `FilterInput`
  ///         children.
  bool IsLeaf() const;

  /// @brief  Replaces the set of all leaf `FilterContents` with a new set
  ///         of `FilterInput`s.
  /// @see    `FilterContents::IsLeaf`
  void SetLeafInputs(const FilterInput::Vector& inputs);

  /// @brief  Marks this filter chain as applying in a subpass scenario.
  ///
  ///         Subpasses render in screenspace, and this setting informs filters
  ///         that the current transformation matrix of the entity is not stored
  ///         in the Entity transformation matrix. Instead, the effect transform
  ///         is used in this case.
  virtual void SetRenderingMode(Entity::RenderingMode rendering_mode);

 private:
  virtual std::optional<Rect> GetFilterCoverage(
      const FilterInput::Vector& inputs,
      const Entity& entity,
      const Matrix& effect_transform) const;

  virtual std::optional<Rect> GetFilterSourceCoverage(
      const Matrix& effect_transform,
      const Rect& output_limit) const = 0;

  /// @brief  Converts zero or more filter inputs into a render instruction.
  virtual std::optional<Entity> RenderFilter(
      const FilterInput::Vector& inputs,
      const ContentContext& renderer,
      const Entity& entity,
      const Matrix& effect_transform,
      const Rect& coverage,
      const std::optional<Rect>& coverage_hint) const = 0;

  std::optional<Rect> GetLocalCoverage(const Entity& local_entity) const;

  FilterInput::Vector inputs_;
  Matrix effect_transform_;

  FilterContents(const FilterContents&) = delete;

  FilterContents& operator=(const FilterContents&) = delete;
};

}  // namespace impeller
