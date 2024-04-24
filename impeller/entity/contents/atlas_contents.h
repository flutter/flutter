// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_ATLAS_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_ATLAS_CONTENTS_H_

#include <functional>
#include <memory>
#include <vector>

#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/entity.h"

namespace impeller {

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

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_ATLAS_CONTENTS_H_
