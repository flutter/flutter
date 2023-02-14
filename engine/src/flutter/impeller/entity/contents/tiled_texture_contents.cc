// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/tiled_texture_contents.h"

#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry.h"
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

void TiledTextureContents::SetColorFilter(
    std::optional<ColorFilterProc> color_filter) {
  color_filter_ = std::move(color_filter);
}

std::optional<std::shared_ptr<Texture>>
TiledTextureContents::CreateFilterTexture(
    const ContentContext& renderer) const {
  const ColorFilterProc& filter = color_filter_.value();
  auto color_filter_contents = filter(FilterInput::Make(texture_));
  auto snapshot = color_filter_contents->RenderToSnapshot(renderer, Entity());
  if (snapshot.has_value()) {
    return snapshot.value().texture;
  }
  return std::nullopt;
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

  auto geometry = GetGeometry();
  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);

  // TODO(bdero): The geometry should be fetched from GetPositionUVBuffer and
  //              contain coverage-mapped UVs, and this should use
  //              position_uv.vert.
  //              https://github.com/flutter/flutter/issues/118553

  VS::VertInfo vert_info;
  vert_info.mvp = geometry_result.transform;
  vert_info.effect_transform = GetInverseMatrix();
  vert_info.bounds_origin = geometry->GetCoverage(Matrix())->origin;
  vert_info.texture_size = Vector2(static_cast<Scalar>(texture_size.width),
                                   static_cast<Scalar>(texture_size.height));

  FS::FragInfo frag_info;
  frag_info.texture_sampler_y_coord_scale = texture_->GetYCoordScale();
  frag_info.x_tile_mode = static_cast<Scalar>(x_tile_mode_);
  frag_info.y_tile_mode = static_cast<Scalar>(y_tile_mode_);
  frag_info.alpha = GetAlpha();

  Command cmd;
  cmd.label = "TiledTextureFill";
  cmd.stencil_reference = entity.GetStencilDepth();

  auto options = OptionsFromPassAndEntity(pass, entity);
  if (geometry_result.prevent_overdraw) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  options.primitive_type = geometry_result.type;
  cmd.pipeline = renderer.GetTiledTexturePipeline(options);

  cmd.BindVertices(geometry_result.vertex_buffer);
  VS::BindVertInfo(cmd, host_buffer.EmplaceUniform(vert_info));
  FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));
  if (color_filter_.has_value()) {
    auto filtered_texture = CreateFilterTexture(renderer);
    if (!filtered_texture.has_value()) {
      return false;
    }
    FS::BindTextureSampler(
        cmd, filtered_texture.value(),
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(
            sampler_descriptor_));
  } else {
    FS::BindTextureSampler(
        cmd, texture_,
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(
            sampler_descriptor_));
  }

  if (!pass.AddCommand(std::move(cmd))) {
    return false;
  }

  if (geometry_result.prevent_overdraw) {
    auto restore = ClipRestoreContents();
    restore.SetRestoreCoverage(GetCoverage(entity));
    return restore.Render(renderer, entity, pass);
  }
  return true;
}

}  // namespace impeller
