// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/mipmap_generator.h"

#include "impeller/core/formats.h"
#include "impeller/entity/texture_fill.frag.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/pipeline_builder.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

fml::Status AddMipmapGeneration(
    const std::shared_ptr<CommandBuffer>& command_buffer,
    const std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture,
    RenderTargetAllocator& render_target_allocator,
    HostBuffer& data_host_buffer) {
  // TODO(bdero): Render cube and array mip chains too. Blit generation
  // remains corrupt for them on affected devices, but no engine path
  // generates mipmaps for anything but 2D textures today.
  if (context->GetCapabilities()->SupportsBlitMipmapGeneration() ||
      texture->GetTextureDescriptor().type != TextureType::kTexture2D) {
    std::shared_ptr<BlitPass> blit_pass = command_buffer->CreateBlitPass();
    if (!blit_pass->GenerateMipmap(texture) || !blit_pass->EncodeCommands()) {
      return fml::Status(fml::StatusCode::kUnknown, "");
    }
    return fml::Status();
  }
  return AddRenderPassMipmapGeneration(command_buffer, context, texture,
                                       render_target_allocator,
                                       data_host_buffer);
}

fml::Status AddRenderPassMipmapGeneration(
    const std::shared_ptr<CommandBuffer>& command_buffer,
    const std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture,
    RenderTargetAllocator& render_target_allocator,
    HostBuffer& data_host_buffer) {
  using VS = TextureFillVertexShader;
  using FS = TextureFillFragmentShader;

  const TextureDescriptor& desc = texture->GetTextureDescriptor();
  const uint32_t mip_count = desc.mip_count;
  if (mip_count < 2u) {
    return fml::Status();
  }
  if (desc.type != TextureType::kTexture2D) {
    return fml::Status(fml::StatusCode::kUnimplemented,
                       "Only 2D mip chains can be rendered.");
  }
  const ISize base_size = desc.size;
  auto level_size = [&](uint32_t mip) -> ISize {
    return ISize(std::max<int64_t>(base_size.width >> mip, 1),
                 std::max<int64_t>(base_size.height >> mip, 1));
  };

  std::optional<PipelineDescriptor> pipeline_desc =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  if (!pipeline_desc.has_value()) {
    return fml::Status(fml::StatusCode::kUnknown,
                       "Could not build the downsample pipeline descriptor.");
  }
  ColorAttachmentDescriptor color0;
  color0.format = desc.format;
  color0.blending_enabled = false;
  pipeline_desc->SetColorAttachmentDescriptor(0u, color0);
  pipeline_desc->ClearDepthAttachment();
  pipeline_desc->ClearStencilAttachments();
  pipeline_desc->SetSampleCount(SampleCount::kCount1);
  pipeline_desc->SetPrimitiveType(PrimitiveType::kTriangleStrip);
  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline =
      context->GetPipelineLibrary()
          ->GetPipeline(std::move(pipeline_desc), /*async=*/false)
          .Get();
  if (!pipeline || !pipeline->IsValid()) {
    return fml::Status(fml::StatusCode::kUnknown,
                       "Could not build the downsample pipeline.");
  }

  // Build the downsample chain in scratch offscreens. Each level samples a
  // separate texture, so no pass ever reads the image it is writing.
  std::vector<std::shared_ptr<Texture>> levels;
  levels.reserve(mip_count - 1u);
  std::shared_ptr<Texture> source = texture;
  for (uint32_t mip = 1u; mip < mip_count; mip++) {
    RenderTarget target = render_target_allocator.CreateOffscreen(
        *context, level_size(mip), /*mip_count=*/1, "Mipmap Downsample",
        RenderTarget::AttachmentConfig{
            .storage_mode = StorageMode::kDevicePrivate,
            .load_action = LoadAction::kDontCare,
            .store_action = StoreAction::kStore,
        },
        /*stencil_attachment_config=*/std::nullopt,
        /*existing_color_texture=*/nullptr,
        /*existing_depth_stencil_texture=*/nullptr,
        /*target_pixel_format=*/desc.format);
    if (!target.IsValid()) {
      return fml::Status(fml::StatusCode::kUnknown,
                         "Could not allocate a downsample target.");
    }
    std::shared_ptr<RenderPass> pass = command_buffer->CreateRenderPass(target);
    if (!pass) {
      return fml::Status(fml::StatusCode::kUnknown,
                         "Could not begin a downsample pass.");
    }
    pass->SetLabel("Mipmap Downsample");
    pass->SetPipeline(pipeline);

    // Drawing the source across the whole half-size target with a linear
    // filter performs a correct 2x2 box downsample.
    VS::FrameInfo frame_info;
    frame_info.mvp = Matrix::MakeOrthographic(ISize(1, 1));
    FS::FragInfo frag_info;
    frag_info.alpha = 1.0f;
    std::array<VS::PerVertexData, 4> vertices = {
        VS::PerVertexData{Point(0, 0), Point(0, 0)},
        VS::PerVertexData{Point(1, 0), Point(1, 0)},
        VS::PerVertexData{Point(0, 1), Point(0, 1)},
        VS::PerVertexData{Point(1, 1), Point(1, 1)},
    };
    pass->SetVertexBuffer(CreateVertexBuffer(vertices, data_host_buffer));

    SamplerDescriptor sampler_desc;
    sampler_desc.min_filter = MinMagFilter::kLinear;
    sampler_desc.mag_filter = MinMagFilter::kLinear;
    // Read only the base level of the still-mipped source; its higher levels
    // are the ones being generated and must not be sampled. Scratch levels
    // have a single level to read.
    sampler_desc.mip_filter =
        mip == 1u ? MipFilter::kBase : MipFilter::kNearest;

    VS::BindFrameInfo(*pass, data_host_buffer.EmplaceUniform(frame_info));
    FS::BindFragInfo(*pass, data_host_buffer.EmplaceUniform(frag_info));
    FS::BindTextureSampler(
        *pass, source, context->GetSamplerLibrary()->GetSampler(sampler_desc));
    if (!pass->Draw().ok() || !pass->EncodeCommands()) {
      return fml::Status(fml::StatusCode::kUnknown,
                         "Could not record a downsample pass.");
    }
    source = target.GetRenderTargetTexture();
    levels.push_back(source);
  }

  // Copy each downsampled level into the matching level of the target. Only
  // scaled blits corrupt on devices with broken generation; same-size copies
  // are safe.
  std::shared_ptr<BlitPass> blit_pass = command_buffer->CreateBlitPass();
  if (!blit_pass) {
    return fml::Status(fml::StatusCode::kUnknown,
                       "Could not begin the mip store pass.");
  }
  blit_pass->SetLabel("Mipmap Store");
  for (uint32_t mip = 1u; mip < mip_count; mip++) {
    if (!blit_pass->AddCopy(levels[mip - 1u], texture,
                            /*source_region=*/std::nullopt,
                            /*destination_origin=*/{}, "Mipmap Store",
                            /*destination_mip_level=*/mip)) {
      return fml::Status(fml::StatusCode::kUnknown,
                         "Could not record a mip store copy.");
    }
  }
  if (!blit_pass->EncodeCommands()) {
    return fml::Status(fml::StatusCode::kUnknown,
                       "Could not encode the mip store pass.");
  }
  texture->SetMipmapGenerated();
  return fml::Status();
}

}  // namespace impeller
