// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/tiled_texture_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/solid_fill_utils.h"
#include "impeller/entity/tiled_texture_fill.frag.h"
#include "impeller/entity/tiled_texture_fill.vert.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

TiledTextureContents::TiledTextureContents() = default;

TiledTextureContents::~TiledTextureContents() = default;

void TiledTextureContents::SetTexture(std::shared_ptr<Texture> texture) {
  texture_ = std::move(texture);
}

void TiledTextureContents::SetTileModes(Entity::TileMode x_tile_mode,
                                        Entity::TileMode y_tile_mode) {
  x_tile_mode_ = x_tile_mode;
  y_tile_mode_ = y_tile_mode;
}

void TiledTextureContents::SetSamplerDescriptor(SamplerDescriptor desc) {
  sampler_descriptor_ = std::move(desc);
}

bool TiledTextureContents::Render(const ContentContext& renderer,
                                  const Entity& entity,
                                  RenderPass& pass) const {
  if (texture_ == nullptr) {
    return true;
  }

  using VS = TiledTextureFillVertexShader;
  using FS = TiledTextureFillFragmentShader;

  const auto texture_size = texture_->GetSize();
  if (texture_size.IsEmpty()) {
    return true;
  }

  auto& host_buffer = pass.GetTransientsBuffer();

  VS::VertInfo vert_info;
  vert_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                  entity.GetTransformation();
  vert_info.matrix = GetInverseMatrix();
  vert_info.texture_size = Vector2{static_cast<Scalar>(texture_size.width),
                                   static_cast<Scalar>(texture_size.height)};

  FS::FragInfo frag_info;
  frag_info.texture_sampler_y_coord_scale = texture_->GetYCoordScale();
  frag_info.x_tile_mode = static_cast<Scalar>(x_tile_mode_);
  frag_info.y_tile_mode = static_cast<Scalar>(y_tile_mode_);
  frag_info.alpha = GetAlpha();

  Command cmd;
  cmd.label = "TiledTextureFill";
  cmd.pipeline =
      renderer.GetTiledTexturePipeline(OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(CreateSolidFillVertices<VS::PerVertexData>(
      GetCover()
          ? PathBuilder{}.AddRect(Size(pass.GetRenderTargetSize())).TakePath()
          : GetPath(),
      pass.GetTransientsBuffer()));
  VS::BindVertInfo(cmd, host_buffer.EmplaceUniform(vert_info));
  FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));
  FS::BindTextureSampler(cmd, texture_,
                         renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                             sampler_descriptor_));
  pass.AddCommand(std::move(cmd));

  return true;
}

}  // namespace impeller
