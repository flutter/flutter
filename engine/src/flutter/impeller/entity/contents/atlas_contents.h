// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/entity.h"

namespace impeller {

struct SubAtlasResult {
  // Sub atlas values.
  std::vector<Rect> sub_texture_coords;
  std::vector<Color> sub_colors;
  std::vector<Matrix> sub_transforms;

  // Result atlas values.
  std::vector<Rect> result_texture_coords;
  std::vector<Matrix> result_transforms;

  // Size of the sub-atlass.
  ISize size;
};

class AtlasContents final : public Contents {
 public:
  explicit AtlasContents();

  ~AtlasContents() override;

  void SetTexture(std::shared_ptr<Texture> texture);

  std::shared_ptr<Texture> GetTexture() const;

  void SetTransforms(std::vector<Matrix> transforms);

  void SetBlendMode(BlendMode blend_mode);

  void SetTextureCoordinates(std::vector<Rect> texture_coords);

  void SetColors(std::vector<Color> colors);

  void SetCullRect(std::optional<Rect> cull_rect);

  void SetSamplerDescriptor(SamplerDescriptor desc);

  void SetAlpha(Scalar alpha);

  const SamplerDescriptor& GetSamplerDescriptor() const;

  const std::vector<Matrix>& GetTransforms() const;

  const std::vector<Rect>& GetTextureCoordinates() const;

  const std::vector<Color>& GetColors() const;

  /// @brief Compress a drawAtlas call with blending into a smaller sized atlas.
  ///        This atlas has no overlapping to ensure
  ///        blending behaves as if it were done in the fragment shader.
  std::shared_ptr<SubAtlasResult> GenerateSubAtlas() const;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  Rect ComputeBoundingBox() const;

  std::shared_ptr<Texture> texture_;
  std::vector<Rect> texture_coords_;
  std::vector<Color> colors_;
  std::vector<Matrix> transforms_;
  BlendMode blend_mode_;
  std::optional<Rect> cull_rect_;
  Scalar alpha_ = 1.0;
  SamplerDescriptor sampler_descriptor_ = {};
  mutable std::optional<Rect> bounding_box_cache_;

  AtlasContents(const AtlasContents&) = delete;

  AtlasContents& operator=(const AtlasContents&) = delete;
};

class AtlasTextureContents final : public Contents {
 public:
  explicit AtlasTextureContents(const AtlasContents& parent);

  ~AtlasTextureContents() override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  void SetAlpha(Scalar alpha);

  void SetCoverage(Rect coverage);

  void SetTexture(std::shared_ptr<Texture> texture);

  void SetUseDestination(bool value);

  void SetSubAtlas(const std::shared_ptr<SubAtlasResult>& subatlas);

 private:
  const AtlasContents& parent_;
  Scalar alpha_ = 1.0;
  Rect coverage_;
  std::shared_ptr<Texture> texture_;
  bool use_destination_ = false;
  std::shared_ptr<SubAtlasResult> subatlas_;

  AtlasTextureContents(const AtlasTextureContents&) = delete;

  AtlasTextureContents& operator=(const AtlasTextureContents&) = delete;
};

class AtlasColorContents final : public Contents {
 public:
  explicit AtlasColorContents(const AtlasContents& parent);

  ~AtlasColorContents() override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  void SetAlpha(Scalar alpha);

  void SetCoverage(Rect coverage);

  void SetSubAtlas(const std::shared_ptr<SubAtlasResult>& subatlas);

 private:
  const AtlasContents& parent_;
  Scalar alpha_ = 1.0;
  Rect coverage_;
  std::shared_ptr<SubAtlasResult> subatlas_;

  AtlasColorContents(const AtlasColorContents&) = delete;

  AtlasColorContents& operator=(const AtlasColorContents&) = delete;
};

}  // namespace impeller
