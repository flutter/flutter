// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path.h"
#include "impeller/renderer/sampler_descriptor.h"

namespace impeller {

class TiledTextureContents final : public ColorSourceContents {
 public:
  TiledTextureContents();

  ~TiledTextureContents() override;

  using ColorFilterProc =
      std::function<std::shared_ptr<ColorFilterContents>(FilterInput::Ref)>;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  void SetTexture(std::shared_ptr<Texture> texture);

  void SetTileModes(Entity::TileMode x_tile_mode, Entity::TileMode y_tile_mode);

  void SetSamplerDescriptor(SamplerDescriptor desc);

  /// @brief Set a color filter to apply directly to this tiled texture
  /// @param color_filter
  ///
  /// When applying a color filter to a tiled texture, we can reduce the
  /// size and number of the subpasses required and the shader workloadby
  /// applying the filter to the untiled image and absorbing the opacity before
  /// tiling it into the final location.
  ///
  /// This may not be a performance improvement if the image is tiled into a
  /// much smaller size that its original texture size.
  void SetColorFilter(std::optional<ColorFilterProc> color_filter);

 private:
  std::optional<std::shared_ptr<Texture>> CreateFilterTexture(
      const ContentContext& renderer) const;

  bool RenderVertices(const ContentContext& renderer,
                      const Entity& entity,
                      RenderPass& pass) const;

  SamplerDescriptor CreateDescriptor() const;

  std::shared_ptr<Texture> texture_;
  SamplerDescriptor sampler_descriptor_ = {};
  Entity::TileMode x_tile_mode_ = Entity::TileMode::kClamp;
  Entity::TileMode y_tile_mode_ = Entity::TileMode::kClamp;
  std::optional<ColorFilterProc> color_filter_;

  FML_DISALLOW_COPY_AND_ASSIGN(TiledTextureContents);
};

}  // namespace impeller
