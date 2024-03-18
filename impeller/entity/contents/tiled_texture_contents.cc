// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/tiled_texture_contents.h"

#include "fml/logging.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/entity/tiled_texture_fill.frag.h"
#include "impeller/entity/tiled_texture_fill_external.frag.h"
#include "impeller/renderer/render_pass.h"

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
      renderer,      // renderer
      Entity(),      // entity
      std::nullopt,  // coverage_limit
      std::nullopt,  // sampler_descriptor
      true,          // msaa_enabled
      /*mip_count=*/1,
      "TiledTextureContents Snapshot");  // label
  if (snapshot.has_value()) {
    return snapshot.value().texture;
  }
  return nullptr;
}

SamplerDescriptor TiledTextureContents::CreateSamplerDescriptor(
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
  using FSExternal = TiledTextureFillExternalFragmentShader;

  const auto texture_size = texture_->GetSize();
  if (texture_size.IsEmpty()) {
    return true;
  }

  bool is_external_texture =
      texture_->GetTextureDescriptor().type == TextureType::kTextureExternalOES;

  bool uses_emulated_tile_mode =
      UsesEmulatedTileMode(renderer.GetDeviceCapabilities());

  VS::FrameInfo frame_info;
  frame_info.texture_sampler_y_coord_scale = texture_->GetYCoordScale();
  frame_info.alpha = GetOpacityFactor();

  PipelineBuilderMethod pipeline_method;

#ifdef IMPELLER_ENABLE_OPENGLES
  if (is_external_texture) {
    pipeline_method = &ContentContext::GetTiledTextureExternalPipeline;
  } else {
    pipeline_method = uses_emulated_tile_mode
                          ? &ContentContext::GetTiledTexturePipeline
                          : &ContentContext::GetTexturePipeline;
  }
#else
  pipeline_method = uses_emulated_tile_mode
                        ? &ContentContext::GetTiledTexturePipeline
                        : &ContentContext::GetTexturePipeline;
#endif  // IMPELLER_ENABLE_OPENGLES

  PipelineBuilderCallback pipeline_callback =
      [&renderer, &pipeline_method](ContentContextOptions options) {
        return (renderer.*pipeline_method)(options);
      };
  return ColorSourceContents::DrawGeometry<VS>(
      renderer, entity, pass, pipeline_callback, frame_info,
      [this, &renderer, &is_external_texture,
       &uses_emulated_tile_mode](RenderPass& pass) {
        auto& host_buffer = renderer.GetTransientsBuffer();

        if (uses_emulated_tile_mode) {
          pass.SetCommandLabel("TiledTextureFill");
        } else {
          pass.SetCommandLabel("TextureFill");
        }

        if (is_external_texture) {
          FSExternal::FragInfo frag_info;
          frag_info.x_tile_mode = static_cast<Scalar>(x_tile_mode_);
          frag_info.y_tile_mode = static_cast<Scalar>(y_tile_mode_);
          FSExternal::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));
        } else if (uses_emulated_tile_mode) {
          FS::FragInfo frag_info;
          frag_info.x_tile_mode = static_cast<Scalar>(x_tile_mode_);
          frag_info.y_tile_mode = static_cast<Scalar>(y_tile_mode_);
          FS::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));
        }

        if (is_external_texture) {
          SamplerDescriptor sampler_desc;
          // OES_EGL_image_external states that only CLAMP_TO_EDGE is valid, so
          // we emulate all other tile modes here by remapping the texture
          // coordinates.
          sampler_desc.width_address_mode = SamplerAddressMode::kClampToEdge;
          sampler_desc.height_address_mode = SamplerAddressMode::kClampToEdge;

          // Also, external textures cannot be bound to color filters, so ignore
          // this case for now.
          FML_DCHECK(!color_filter_) << "Color filters are not currently "
                                        "supported for external textures.";

          FSExternal::BindSAMPLEREXTERNALOESTextureSampler(
              pass, texture_,
              renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                  sampler_desc));
        } else {
          if (color_filter_) {
            auto filtered_texture = CreateFilterTexture(renderer);
            if (!filtered_texture) {
              return false;
            }
            FS::BindTextureSampler(
                pass, filtered_texture,
                renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                    CreateSamplerDescriptor(renderer.GetDeviceCapabilities())));
          } else {
            FS::BindTextureSampler(
                pass, texture_,
                renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                    CreateSamplerDescriptor(renderer.GetDeviceCapabilities())));
          }
        }

        return true;
      },
      /*enable_uvs=*/true,
      /*texture_coverage=*/Rect::MakeSize(texture_size),
      /*effect_transform=*/GetInverseEffectTransform());
}

std::optional<Snapshot> TiledTextureContents::RenderToSnapshot(
    const ContentContext& renderer,
    const Entity& entity,
    std::optional<Rect> coverage_limit,
    const std::optional<SamplerDescriptor>& sampler_descriptor,
    bool msaa_enabled,
    int32_t mip_count,
    const std::string& label) const {
  std::optional<Rect> geometry_coverage = GetGeometry()->GetCoverage({});
  if (GetInverseEffectTransform().IsIdentity() &&
      GetGeometry()->IsAxisAlignedRect() &&
      (!geometry_coverage.has_value() ||
       Rect::MakeSize(texture_->GetSize())
           .Contains(geometry_coverage.value()))) {
    auto coverage = GetCoverage(entity);
    if (!coverage.has_value()) {
      return std::nullopt;
    }
    auto scale = Vector2(coverage->GetSize() / Size(texture_->GetSize()));

    return Snapshot{
        .texture = texture_,
        .transform = Matrix::MakeTranslation(coverage->GetOrigin()) *
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
      /*mip_count=*/1,
      label);  // label
}

}  // namespace impeller
