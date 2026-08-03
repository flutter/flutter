// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_vulkan.h"

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/fml/logging.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_source_vulkan.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/context.h"
#include "include/core/SkCanvas.h"
#include "include/core/SkPaint.h"
#include "include/gpu/vk/VulkanTypes.h"
#include "third_party/skia/include/core/SkAlphaType.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkImageGanesh.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkTypes.h"

namespace flutter {

// Returns true if the given VkFormat is a multi-planar YUV format that
// requires a sampler YCbCr conversion.
static bool IsYuvFormat(VkFormat format) {
  switch (format) {
    // 8-bit multi-planar formats.
    case VK_FORMAT_G8_B8R8_2PLANE_420_UNORM:
    case VK_FORMAT_G8_B8R8_2PLANE_422_UNORM:
    case VK_FORMAT_G8_B8R8_2PLANE_444_UNORM:
    // 10-bit multi-planar formats.
    case VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16:
    case VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16:
    case VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16:
    case VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16:
    case VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16:
    case VK_FORMAT_G10X6_B10X6R10X6_2PLANE_444_UNORM_3PACK16:
    // 12-bit multi-planar formats.
    case VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16:
    case VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16:
    case VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16:
    case VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16:
    case VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16:
    case VK_FORMAT_G12X4_B12X4R12X4_2PLANE_444_UNORM_3PACK16:
    // 16-bit multi-planar formats.
    case VK_FORMAT_G16_B16R16_2PLANE_420_UNORM:
    case VK_FORMAT_G16_B16R16_2PLANE_422_UNORM:
    case VK_FORMAT_G16_B16R16_2PLANE_444_UNORM:
      return true;
    default:
      return false;
  }
}

EmbedderExternalTextureVulkan::EmbedderExternalTextureVulkan(

    int64_t texture_identifier,
    const ExternalTextureCallback& callback)
    : Texture(texture_identifier), external_texture_callback_(callback) {
  FML_DCHECK(external_texture_callback_);
}

// |flutter::Texture|
void EmbedderExternalTextureVulkan::Paint(PaintContext& context,
                                          const DlRect& bounds,
                                          bool freeze,
                                          const DlImageSampling sampling) {
  if (last_image_ == nullptr) {
    last_image_ =
        ResolveTexture(Id(), context.gr_context, context.aiks_context,
                       SkISize::Make(bounds.GetWidth(), bounds.GetHeight()));
  }

  DlCanvas* canvas = context.canvas;
  const DlPaint* paint = context.paint;

  if (last_image_) {
    DlRect image_bounds = DlRect::Make(last_image_->GetBounds());
    if (bounds != image_bounds) {
      canvas->DrawImageRect(last_image_, image_bounds, bounds, sampling, paint);
    } else {
      canvas->DrawImage(last_image_, bounds.GetOrigin(), sampling, paint);
    }
  }
}

sk_sp<DlImage> EmbedderExternalTextureVulkan::ResolveTexture(
    int64_t texture_id,
    GrDirectContext* context,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  if (!!aiks_context) {
    return ResolveTextureImpeller(texture_id, aiks_context, size);
  } else {
    return ResolveTextureSkia(texture_id, context, size);
  }
}

sk_sp<DlImage> EmbedderExternalTextureVulkan::ResolveTextureSkia(
    int64_t texture_id,
    GrDirectContext* context,
    const SkISize& size) {
  context->flushAndSubmit();
  context->resetContext(kAll_GrBackendState);
  std::unique_ptr<FlutterVulkanTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture) {
    return nullptr;
  }

  size_t width = size.width();
  size_t height = size.height();

  if (texture->width != 0 && texture->height != 0) {
    width = texture->width;
    height = texture->height;
  }

  VkFormat vk_format = static_cast<VkFormat>(texture->format);
  bool is_yuv = IsYuvFormat(vk_format);

  // Set fAlloc.fMemory from texture->image_memory. Without this, Skia's
  // GrVkImage has a null memory handle, which can cause issues during
  // texture creation and lifecycle management.
  GrVkImageInfo image_info = {
      .fImage = reinterpret_cast<VkImage>(texture->image),
      .fImageTiling = VK_IMAGE_TILING_OPTIMAL,
      // The embedder has already transitioned the image to
      // SHADER_READ_ONLY_OPTIMAL.  Reporting UNDEFINED here would cause Skia
      // to issue a spurious UNDEFINED -> SHADER_READ_ONLY_OPTIMAL barrier that
      // discards the image contents.
      .fImageLayout = is_yuv ? VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
                             : VK_IMAGE_LAYOUT_UNDEFINED,
      .fFormat = vk_format,
      .fImageUsageFlags = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
                          VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
                          VK_IMAGE_USAGE_TRANSFER_DST_BIT |
                          VK_IMAGE_USAGE_SAMPLED_BIT,
      .fSampleCount = 1,
      .fLevelCount = 1,
  };

  // For multi-planar YUV formats, populate the YCbCr conversion info so that
  // Skia knows how to convert YUV to RGB when sampling the image.
  if (is_yuv) {
    image_info.fYcbcrConversionInfo = skgpu::VulkanYcbcrConversionInfo(
        vk_format, VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709,
        VK_SAMPLER_YCBCR_RANGE_ITU_FULL, VK_CHROMA_LOCATION_COSITED_EVEN,
        VK_CHROMA_LOCATION_COSITED_EVEN, VK_FILTER_LINEAR, VK_FALSE,
        {VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY,
         VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY},
        VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT |
            VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT |
            VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT |
            VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT |
            VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT |
            VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT);
  }

  auto gr_backend_texture =
      GrBackendTextures::MakeVk(width, height, image_info);
  SkImages::TextureReleaseProc release_proc = texture->destruction_callback;
  auto image =
      SkImages::BorrowTextureFrom(context,                   // context
                                  gr_backend_texture,        // texture handle
                                  kTopLeft_GrSurfaceOrigin,  // origin
                                  kRGB_888x_SkColorType,     // color type
                                  kPremul_SkAlphaType,       // alpha type
                                  nullptr,                   // colorspace
                                  release_proc,       // texture release proc
                                  texture->user_data  // texture release context
      );

  if (!image) {
    // In case Skia rejects the image, call the release proc so that
    // embedders can perform collection of intermediates.
    if (release_proc) {
      release_proc(texture->user_data);
    }
    return nullptr;
  }

  return DlImageSkia::Make(std::move(image));
}

sk_sp<DlImage> EmbedderExternalTextureVulkan::ResolveTextureImpeller(
    int64_t texture_id,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  std::unique_ptr<FlutterVulkanTexture> texture_desc =
      external_texture_callback_(texture_id, size.width(), size.height());
  if (!texture_desc) {
    return nullptr;
  }

  auto& impeller_context =
      impeller::ContextVK::Cast(*aiks_context->GetContext());

  auto texture_source = std::make_shared<EmbedderExternalTextureSourceVulkan>(
      aiks_context->GetContext(), texture_desc.get());

  auto texture = std::make_shared<impeller::TextureVK>(
      aiks_context->GetContext(), texture_source);
  // Transition the layout to shader read.
  {
    auto buffer = impeller_context.CreateCommandBuffer();
    impeller::CommandBufferVK& buffer_vk =
        impeller::CommandBufferVK::Cast(*buffer);

    impeller::BarrierVK barrier;
    barrier.cmd_buffer = buffer_vk.GetCommandBuffer();
    barrier.src_access = impeller::vk::AccessFlagBits::eColorAttachmentWrite |
                         impeller::vk::AccessFlagBits::eTransferWrite;
    barrier.src_stage =
        impeller::vk::PipelineStageFlagBits::eColorAttachmentOutput |
        impeller::vk::PipelineStageFlagBits::eTransfer;
    barrier.dst_access = impeller::vk::AccessFlagBits::eShaderRead;
    barrier.dst_stage = impeller::vk::PipelineStageFlagBits::eFragmentShader;

    barrier.new_layout = impeller::vk::ImageLayout::eShaderReadOnlyOptimal;

    if (!texture_source->SetLayout(barrier).ok()) {
      return nullptr;
    }
    if (!impeller_context.GetCommandQueue()->Submit({buffer}).ok()) {
      return nullptr;
    }
  }
  impeller_context.DisposeThreadLocalCachedResources();
  return impeller::DlImageImpeller::Make(texture);
}

EmbedderExternalTextureVulkan::~EmbedderExternalTextureVulkan() = default;

// |flutter::Texture|
void EmbedderExternalTextureVulkan::OnGrContextCreated() {}

// |flutter::Texture|
void EmbedderExternalTextureVulkan::OnGrContextDestroyed() {}

// |flutter::Texture|
void EmbedderExternalTextureVulkan::MarkNewFrameAvailable() {
  last_image_ = nullptr;
}

// |flutter::Texture|
void EmbedderExternalTextureVulkan::OnTextureUnregistered() {}

}  // namespace flutter
