// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path.h"
#include "impeller/renderer/sampler_descriptor.h"

namespace impeller {

class TiledTextureContents final : public ColorSourceContents {
 public:
  TiledTextureContents();

  ~TiledTextureContents() override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  void SetTexture(std::shared_ptr<Texture> texture);

  void SetTileModes(Entity::TileMode x_tile_mode, Entity::TileMode y_tile_mode);

  void SetSamplerDescriptor(SamplerDescriptor desc);

 private:
  std::shared_ptr<Texture> texture_;
  SamplerDescriptor sampler_descriptor_ = {};
  Entity::TileMode x_tile_mode_;
  Entity::TileMode y_tile_mode_;

  FML_DISALLOW_COPY_AND_ASSIGN(TiledTextureContents);
};

}  // namespace impeller
