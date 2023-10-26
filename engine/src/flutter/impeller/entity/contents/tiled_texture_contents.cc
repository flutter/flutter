// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/tiled_texture_contents.h"

#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/texture_fill.frag.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/entity/tiled_texture_fill.frag.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

static std::optional<SamplerAddressMode> TileModeToAddressMode(
    Entity::TileMode tile_mode,
    const Capabilities& capabilities) {
  switch (tile_mode) {
    case Entity::TileMode::kClamp:
      return SamplerAddressMode::kClampToEdge;
      break;
    case Entity::TileMode::kMirror:
      return SamplerAddressMode::kMirror;
      break;
    case Entity::TileMode::kRepeat:
      return SamplerAddressMode::kRepeat;
      break;
    case Entity::TileMode::kDecal:
      if (capabilities.SupportsDecalSamplerAddressMode()) {
        return SamplerAddressMode::kDecal;
      }
      return std::nullopt;
  }
}

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

void TiledTextureContents::SetColorFilter(ColorFilterProc color_filter) {
  color_filter_ = std::move(color_filter);
}

std::shared_ptr<Texture> TiledTextureContents::CreateFilterTexture(
    const ContentContext& renderer) const {
  if (!color_filter_) {
    return nullptr;
  }
  auto color_filter_contents = color_filter_(FilterInput::Make(texture_));
  auto snapshot = color_filter_contents->RenderToSnapshot(
      renderer,                          // renderer
      Entity(),                          // entity
      std::nullopt,                      // coverage_limit
      std::nullopt,                      // sampler_descriptor
      true,                              // msaa_enabled
      "TiledTextureContents Snapshot");  // label
  if (snapshot.has_value()) {
    return snapshot.value().texture;
  }
  return nullptr;
}

SamplerDescriptor TiledTextureContents::CreateDescriptor(
    const Capabilities& capabilities) const {
  SamplerDescriptor descriptor = sampler_descriptor_;
  auto width_mode = TileModeToAddressMode(x_tile_mode_, capabilities);
  auto height_mode = TileModeToAddressMode(y_tile_mode_, capabilities);
  if (width_mode.has_value()) {
    descriptor.width_address_mode = width_mode.value();
  }
  if (height_mode.has_value()) {
    descriptor.height_address_mode = height_mode.value();
  }
  return descriptor;
}

bool TiledTextureContents::UsesEmulatedTileMode(
    const Capabilities& capabilities) const {
  return !TileModeToAddressMode(x_tile_mode_, capabilities).has_value() ||
         !TileModeToAddressMode(y_tile_mode_, capabilities).has_value();
}

// |Contents|
bool TiledTextureContents::IsOpaque() const {
  if (GetOpacityFactor() < 1 || x_tile_mode_ == Entity::TileMode::kDecal ||
      y_tile_mode_ == Entity::TileMode::kDecal) {
    return false;
  }
  if (color_filter_) {
    return false;
  }
  return texture_->IsOpaque();
}

bool TiledTextureContents::Render(const ContentContext& renderer,
                                  const Entity& entity,
                                  RenderPass& pass) const {
  if (texture_ == nullptr) {
    return true;
  }

  using VS = TextureFillVertexShader;
  using FS = TiledTextureFillFragmentShader;

  const auto texture_size = texture_->GetSize();
  if (texture_size.IsEmpty()) {
    return true;
  }

  auto& host_buffer = pass.GetTransientsBuffer();

  auto geometry_result = GetGeometry()->GetPositionUVBuffer(
      Rect({0, 0}, Size(texture_size)), GetInverseEffectTransform(), renderer,
      entity, pass);
  bool uses_emulated_tile_mode =
      UsesEmulatedTileMode(renderer.GetDeviceCapabilities());

  VS::FrameInfo frame_info;
  frame_info.mvp = geometry_result.transform;
  frame_info.texture_sampler_y_coord_scale = texture_->GetYCoordScale();
  frame_info.alpha = GetOpacityFactor();

  Command cmd;
  if (uses_emulated_tile_mode) {
    DEBUG_COMMAND_INFO(cmd, "TiledTextureFill");
  } else {
    DEBUG_COMMAND_INFO(cmd, "TextureFill");
  }

  cmd.stencil_reference = entity.GetClipDepth();

  auto options = OptionsFromPassAndEntity(pass, entity);
  if (geometry_result.prevent_overdraw) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  options.primitive_type = geometry_result.type;
  cmd.pipeline = uses_emulated_tile_mode
                     ? renderer.GetTiledTexturePipeline(options)
                     : renderer.GetTexturePipeline(options);

  cmd.BindVertices(geometry_result.vertex_buffer);
  VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));

  if (uses_emulated_tile_mode) {
    FS::FragInfo frag_info;
    frag_info.x_tile_mode = static_cast<Scalar>(x_tile_mode_);
    frag_info.y_tile_mode = static_cast<Scalar>(y_tile_mode_);
    FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));
  }

  if (color_filter_) {
    auto filtered_texture = CreateFilterTexture(renderer);
    if (!filtered_texture) {
      return false;
    }
    FS::BindTextureSampler(
        cmd, filtered_texture,
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(
            CreateDescriptor(renderer.GetDeviceCapabilities())));
  } else {
    FS::BindTextureSampler(
        cmd, texture_,
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(
            CreateDescriptor(renderer.GetDeviceCapabilities())));
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

std::optional<Snapshot> TiledTextureContents::RenderToSnapshot(
    const ContentContext& renderer,
    const Entity& entity,
    std::optional<Rect> coverage_limit,
    const std::optional<SamplerDescriptor>& sampler_descriptor,
    bool msaa_enabled,
    const std::string& label) const {
  if (GetInverseEffectTransform().IsIdentity() &&
      GetGeometry()->IsAxisAlignedRect()) {
    auto coverage = GetCoverage(entity);
    if (!coverage.has_value()) {
      return std::nullopt;
    }
    auto scale = Vector2(coverage->size / Size(texture_->GetSize()));

    return Snapshot{
        .texture = texture_,
        .transform = Matrix::MakeTranslation(coverage->origin) *
                     Matrix::MakeScale(scale),
        .sampler_descriptor = sampler_descriptor.value_or(sampler_descriptor_),
        .opacity = GetOpacityFactor(),
    };
  }

  return Contents::RenderToSnapshot(
      renderer,                                          // renderer
      entity,                                            // entity
      std::nullopt,                                      // coverage_limit
      sampler_descriptor.value_or(sampler_descriptor_),  // sampler_descriptor
      true,                                              // msaa_enabled
      label);                                            // label
}

}  // namespace impeller
