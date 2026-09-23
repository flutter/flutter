// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_vulkan.h"

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/embedder_struct_macros.h"
#if IMPELLER_SUPPORTS_RENDERING
#include "flutter/impeller/display_list/dl_image_impeller.h"      // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/texture_vk.h"  // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/yuv_conversion_library_vk.h"  // nogncheck
#include "impeller/core/texture_descriptor.h"    // nogncheck
#include "impeller/display_list/aiks_context.h"  // nogncheck
#include "impeller/renderer/context.h"           // nogncheck
#endif                                           // IMPELLER_SUPPORTS_RENDERING
#include "include/core/SkCanvas.h"
#include "include/core/SkPaint.h"
#include "third_party/skia/include/core/SkAlphaType.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkImageGanesh.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkTypes.h"

namespace flutter {

namespace {
/// Returns true if the given VkFormat is a multi-planar YUV format that
/// requires a sampler YCbCr conversion.
bool IsYuvFormat(VkFormat format) {
  switch (format) {
    // 8-bit multi-planar formats.
    case VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM:
    case VK_FORMAT_G8_B8R8_2PLANE_420_UNORM:
    case VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM:
    case VK_FORMAT_G8_B8R8_2PLANE_422_UNORM:
    case VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM:
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
    case VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM:
    case VK_FORMAT_G16_B16R16_2PLANE_420_UNORM:
    case VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM:
    case VK_FORMAT_G16_B16R16_2PLANE_422_UNORM:
    case VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM:
    case VK_FORMAT_G16_B16R16_2PLANE_444_UNORM:
      return true;
    default:
      return false;
  }
}

SkColorType ToSkColorType(VkFormat format) {
  switch (format) {
    case VK_FORMAT_R8G8B8A8_UNORM:
      return kRGBA_8888_SkColorType;
    case VK_FORMAT_R8G8B8A8_SRGB:
      return kSRGBA_8888_SkColorType;
    case VK_FORMAT_B8G8R8A8_UNORM:
      return kBGRA_8888_SkColorType;
    case VK_FORMAT_R16G16B16A16_SFLOAT:
      return kRGBA_F16_SkColorType;
    case VK_FORMAT_R32G32B32A32_SFLOAT:
      return kRGBA_F32_SkColorType;
    case VK_FORMAT_R8_UNORM:
      return kR8_unorm_SkColorType;
    case VK_FORMAT_R8G8_UNORM:
      return kR8G8_unorm_SkColorType;
    default:
      return kUnknown_SkColorType;
  }
}

#if IMPELLER_SUPPORTS_RENDERING
impeller::PixelFormat ToPixelFormat(uint32_t vk_format) {
  switch (vk_format) {
    case VK_FORMAT_R8G8B8A8_UNORM:
      return impeller::PixelFormat::kR8G8B8A8UNormInt;
    case VK_FORMAT_R8G8B8A8_SRGB:
      return impeller::PixelFormat::kR8G8B8A8UNormIntSRGB;
    case VK_FORMAT_B8G8R8A8_UNORM:
      return impeller::PixelFormat::kB8G8R8A8UNormInt;
    case VK_FORMAT_B8G8R8A8_SRGB:
      return impeller::PixelFormat::kB8G8R8A8UNormIntSRGB;
    case VK_FORMAT_R32G32B32A32_SFLOAT:
      return impeller::PixelFormat::kR32G32B32A32Float;
    case VK_FORMAT_R16G16B16A16_SFLOAT:
      return impeller::PixelFormat::kR16G16B16A16Float;
    case VK_FORMAT_S8_UINT:
      return impeller::PixelFormat::kS8UInt;
    case VK_FORMAT_D24_UNORM_S8_UINT:
      return impeller::PixelFormat::kD24UnormS8Uint;
    case VK_FORMAT_D32_SFLOAT_S8_UINT:
      return impeller::PixelFormat::kD32FloatS8UInt;
    case VK_FORMAT_R8_UNORM:
      return impeller::PixelFormat::kR8UNormInt;
    case VK_FORMAT_R8G8_UNORM:
      return impeller::PixelFormat::kR8G8UNormInt;
    default:
      return impeller::PixelFormat::kUnknown;
  }
}
#endif  // IMPELLER_SUPPORTS_RENDERING
}  // namespace

// --- EmbedderExternalTextureSourceVulkan ---
#if IMPELLER_SUPPORTS_RENDERING

EmbedderExternalTextureSourceVulkan::EmbedderExternalTextureSourceVulkan(
    const std::shared_ptr<impeller::Context>& p_context,
    FlutterVulkanExternalTexture* embedder_desc)
    : TextureSourceVK(ToTextureDescriptor(embedder_desc)),
      destruction_callback_(
          SAFE_ACCESS(embedder_desc, destruction_callback, nullptr)),
      user_data_(SAFE_ACCESS(embedder_desc, user_data, nullptr)) {
  const impeller::ContextVK& context = impeller::ContextVK::Cast(*p_context);
  const impeller::vk::Device& device = context.GetDevice();
  texture_image_ = impeller::vk::Image(
      reinterpret_cast<VkImage>(SAFE_ACCESS(embedder_desc, image, 0)));

  needs_yuv_conversion_ = IsYuvFormat(
      static_cast<VkFormat>(SAFE_ACCESS(embedder_desc, format, 0u)));
  std::shared_ptr<impeller::YUVConversionVK> yuv_conversion;
  if (needs_yuv_conversion_) {
    yuv_conversion = CreateYUVConversion(context, embedder_desc);
    if (!yuv_conversion || !yuv_conversion->IsValid()) {
      VALIDATION_LOG << "Failed to create yuv conversion";
      return;
    }
  }

  // Create image view for the newly created image.
  if (!CreateTextureImageView(device, embedder_desc, yuv_conversion)) {
    VALIDATION_LOG << "Failed to create texture image view";
    return;
  }

  yuv_conversion_ = std::move(yuv_conversion);
  is_valid_ = true;
}

EmbedderExternalTextureSourceVulkan::~EmbedderExternalTextureSourceVulkan() {
  texture_image_view_.reset();
  if (destruction_callback_) {
    destruction_callback_(user_data_);
  }
}

impeller::TextureDescriptor
EmbedderExternalTextureSourceVulkan::ToTextureDescriptor(
    FlutterVulkanExternalTexture* embedder_desc) {
  const impeller::ISize size = impeller::ISize{
      static_cast<int64_t>(SAFE_ACCESS(embedder_desc, width, 0)),
      static_cast<int64_t>(SAFE_ACCESS(embedder_desc, height, 0))};
  impeller::TextureDescriptor desc;
  desc.storage_mode = impeller::StorageMode::kDevicePrivate;
  desc.format = ToPixelFormat(SAFE_ACCESS(embedder_desc, format, 0u));
  desc.size = size;
  desc.type = impeller::TextureType::kTexture2D;
  desc.sample_count = impeller::SampleCount::kCount1;
  desc.compression_type = impeller::CompressionType::kLossless;
  desc.mip_count = 1u;
  desc.usage = impeller::TextureUsage::kShaderRead;
  return desc;
}

std::shared_ptr<impeller::YUVConversionVK>
EmbedderExternalTextureSourceVulkan::CreateYUVConversion(
    const impeller::ContextVK& context,
    FlutterVulkanExternalTexture* embedder_desc) {
  impeller::YUVConversionDescriptorVK conversion_chain;
  impeller::vk::SamplerYcbcrConversionCreateInfo& conversion_info =
      conversion_chain.get();

  const impeller::vk::Format vk_format =
      static_cast<impeller::vk::Format>(SAFE_ACCESS(embedder_desc, format, 0u));
  conversion_info.format = vk_format;
  conversion_info.ycbcrModel =
      impeller::vk::SamplerYcbcrModelConversion::eYcbcr709;
  conversion_info.ycbcrRange = impeller::vk::SamplerYcbcrRange::eItuFull;
  conversion_info.components = {impeller::vk::ComponentSwizzle::eIdentity,
                                impeller::vk::ComponentSwizzle::eIdentity,
                                impeller::vk::ComponentSwizzle::eIdentity,
                                impeller::vk::ComponentSwizzle::eIdentity};
  conversion_info.xChromaOffset = impeller::vk::ChromaLocation::eCositedEven;
  conversion_info.yChromaOffset = impeller::vk::ChromaLocation::eCositedEven;

  impeller::vk::FormatProperties format_props;
  context.GetPhysicalDevice().getFormatProperties(vk_format, &format_props);

  const bool supports_linear_filtering =
      !!(format_props.optimalTilingFeatures &
         impeller::vk::FormatFeatureFlagBits::
             eSampledImageYcbcrConversionLinearFilter) &&
      !!(format_props.optimalTilingFeatures &
         impeller::vk::FormatFeatureFlagBits::eSampledImageFilterLinear);

  conversion_info.chromaFilter = supports_linear_filtering
                                     ? impeller::vk::Filter::eLinear
                                     : impeller::vk::Filter::eNearest;
  conversion_info.forceExplicitReconstruction = false;
  return context.GetYUVConversionLibrary()->GetConversion(conversion_chain);
}

bool EmbedderExternalTextureSourceVulkan::CreateTextureImageView(
    const impeller::vk::Device& device,
    FlutterVulkanExternalTexture* embedder_desc,
    const std::shared_ptr<impeller::YUVConversionVK>& yuv_conversion_wrapper) {
  impeller::vk::StructureChain<impeller::vk::ImageViewCreateInfo,
                               impeller::vk::SamplerYcbcrConversionInfo>
      view_chain;
  impeller::vk::ImageViewCreateInfo& view_info = view_chain.get();
  view_info.image = texture_image_;
  view_info.viewType = impeller::vk::ImageViewType::e2D;
  view_info.format =
      static_cast<impeller::vk::Format>(SAFE_ACCESS(embedder_desc, format, 0u));
  view_info.subresourceRange.aspectMask =
      impeller::vk::ImageAspectFlagBits::eColor;
  view_info.subresourceRange.baseMipLevel = 0u;
  view_info.subresourceRange.baseArrayLayer = 0u;
  view_info.subresourceRange.levelCount = 1;
  view_info.subresourceRange.layerCount = 1;

  if (yuv_conversion_wrapper) {
    view_chain.get<impeller::vk::SamplerYcbcrConversionInfo>().conversion =
        yuv_conversion_wrapper->GetConversion();
  } else {
    view_chain.unlink<impeller::vk::SamplerYcbcrConversionInfo>();
  }
  impeller::vk::ResultValue<impeller::vk::UniqueImageView> image_view =
      device.createImageViewUnique(view_info);
  if (image_view.result != impeller::vk::Result::eSuccess) {
    return false;
  }
  texture_image_view_ = std::move(image_view.value);
  return true;
}

bool EmbedderExternalTextureSourceVulkan::IsValid() const {
  return is_valid_;
}

// |TextureSourceVK|
impeller::vk::Image EmbedderExternalTextureSourceVulkan::GetImage() const {
  return texture_image_;
}

// |TextureSourceVK|
impeller::vk::ImageView EmbedderExternalTextureSourceVulkan::GetImageView()
    const {
  return texture_image_view_.get();
}

// |TextureSourceVK|
impeller::vk::ImageView
EmbedderExternalTextureSourceVulkan::GetRenderTargetView(
    uint32_t mip_level,
    uint32_t array_layer) const {
  return texture_image_view_.get();
}

// |TextureSourceVK|
bool EmbedderExternalTextureSourceVulkan::IsSwapchainImage() const {
  return is_swapchain_image_;
}

// |TextureSourceVK|
std::shared_ptr<impeller::YUVConversionVK>
EmbedderExternalTextureSourceVulkan::GetYUVConversion() const {
  return needs_yuv_conversion_ ? yuv_conversion_ : nullptr;
}
#endif  // IMPELLER_SUPPORTS_RENDERING

// --- EmbedderExternalTextureVulkan ---

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
  if (last_image_ == nullptr && !freeze) {
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
#if IMPELLER_SUPPORTS_RENDERING
  if (!!aiks_context) {
    return ResolveTextureImpeller(texture_id, aiks_context, size);
  }
#endif  // IMPELLER_SUPPORTS_RENDERING
  if (!!context) {
    return ResolveTextureSkia(texture_id, context, size);
  }
  return nullptr;
}

sk_sp<DlImage> EmbedderExternalTextureVulkan::ResolveTextureSkia(
    int64_t texture_id,
    GrDirectContext* context,
    const SkISize& size) {
  if (!context) {
    return nullptr;
  }
  context->flushAndSubmit();
  context->resetContext(kAll_GrBackendState);
  std::unique_ptr<FlutterVulkanExternalTexture> texture_desc =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture_desc) {
    return nullptr;
  }

  FlutterVulkanExternalTexture* desc = texture_desc.get();
  size_t width = size.width();
  size_t height = size.height();

  if (SAFE_ACCESS(desc, width, 0) != 0 && SAFE_ACCESS(desc, height, 0) != 0) {
    width = SAFE_ACCESS(desc, width, 0);
    height = SAFE_ACCESS(desc, height, 0);
  }

  VkFormat vk_format = static_cast<VkFormat>(SAFE_ACCESS(desc, format, 0u));
  bool is_yuv = IsYuvFormat(vk_format);

  GrVkImageInfo image_info = {
      .fImage = reinterpret_cast<VkImage>(SAFE_ACCESS(desc, image, 0)),
      .fImageTiling = VK_IMAGE_TILING_OPTIMAL,
      .fImageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
      .fFormat = vk_format,
      .fImageUsageFlags = VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
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

  // YUV formats (e.g. NV12) only register kRGB_888x in Skia's GrVkCaps,
  // so we must use kRGB_888x for YUV. For non-YUV formats, map the VkFormat
  // to the corresponding SkColorType to handle BGRA and other formats
  // correctly.
  SkColorType color_type =
      is_yuv ? kRGB_888x_SkColorType : ToSkColorType(vk_format);

  GrBackendTexture gr_backend_texture =
      GrBackendTextures::MakeVk(width, height, image_info);
  SkImages::TextureReleaseProc release_proc =
      SAFE_ACCESS(desc, destruction_callback, nullptr);
  sk_sp<SkImage> image = SkImages::BorrowTextureFrom(
      context,                   // context
      gr_backend_texture,        // texture handle
      kTopLeft_GrSurfaceOrigin,  // origin
      color_type,                // color type
      kPremul_SkAlphaType,       // alpha type
      nullptr,                   // colorspace
      release_proc,              // texture release proc
      SAFE_ACCESS(desc, user_data,
                  nullptr)  // texture release context
  );

  if (!image) {
    // In case Skia rejects the image, call the release proc so that
    // embedders can perform collection of intermediates.
    if (release_proc) {
      release_proc(SAFE_ACCESS(desc, user_data, nullptr));
    }
    return nullptr;
  }

  return DlImageSkia::Make(std::move(image));
}

#if IMPELLER_SUPPORTS_RENDERING
sk_sp<DlImage> EmbedderExternalTextureVulkan::ResolveTextureImpeller(
    int64_t texture_id,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  std::unique_ptr<FlutterVulkanExternalTexture> texture_desc =
      external_texture_callback_(texture_id, size.width(), size.height());
  if (!texture_desc) {
    return nullptr;
  }

  FlutterVulkanExternalTexture* desc = texture_desc.get();
  if (SAFE_ACCESS(desc, width, 0) == 0 || SAFE_ACCESS(desc, height, 0) == 0) {
    if (STRUCT_HAS_MEMBER(desc, width)) {
      desc->width = size.width();
    }
    if (STRUCT_HAS_MEMBER(desc, height)) {
      desc->height = size.height();
    }
  }

  std::shared_ptr<EmbedderExternalTextureSourceVulkan> texture_source =
      std::make_shared<EmbedderExternalTextureSourceVulkan>(
          aiks_context->GetContext(), texture_desc.get());

  if (!texture_source->IsValid()) {
    return nullptr;
  }

  std::shared_ptr<impeller::TextureVK> texture =
      std::make_shared<impeller::TextureVK>(aiks_context->GetContext(),
                                            texture_source);

  return impeller::DlImageImpeller::Make(texture);
}
#endif  // IMPELLER_SUPPORTS_RENDERING

EmbedderExternalTextureVulkan::~EmbedderExternalTextureVulkan() = default;

// |flutter::Texture|
void EmbedderExternalTextureVulkan::OnGrContextCreated() {}

// |flutter::Texture|
void EmbedderExternalTextureVulkan::OnGrContextDestroyed() {
  last_image_ = nullptr;
}

// |flutter::Texture|
void EmbedderExternalTextureVulkan::MarkNewFrameAvailable() {
  last_image_ = nullptr;
}

// |flutter::Texture|
void EmbedderExternalTextureVulkan::OnTextureUnregistered() {}

}  // namespace flutter
