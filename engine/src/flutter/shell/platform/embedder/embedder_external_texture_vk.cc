// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_vk.h"

#include <utility>

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

#if defined(IMPELLER_SUPPORTS_RENDERING)
#include "flutter/impeller/core/texture_descriptor.h"         // nogncheck
#include "flutter/impeller/display_list/aiks_context.h"       // nogncheck
#include "flutter/impeller/display_list/dl_image_impeller.h"  // nogncheck
#include "flutter/impeller/geometry/size.h"                   // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/command_buffer_vk.h"  // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"  // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/formats_vk.h"  // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/texture_source_vk.h"  // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/texture_vk.h"  // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/vk.h"          // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/yuv_conversion_library_vk.h"  // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/yuv_conversion_vk.h"  // nogncheck
#endif  // defined(IMPELLER_SUPPORTS_RENDERING)

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
#include "third_party/skia/include/gpu/vk/VulkanTypes.h"

namespace flutter {

#if defined(IMPELLER_SUPPORTS_RENDERING)
namespace {

class WrappedExternalTextureSourceVK final : public impeller::TextureSourceVK {
 public:
  WrappedExternalTextureSourceVK(
      impeller::TextureDescriptor desc,
      impeller::vk::Image image,
      impeller::vk::UniqueImageView image_view,
      std::shared_ptr<impeller::YUVConversionVK> yuv_conversion,
      VoidCallback destruction_callback,
      void* user_data)
      : TextureSourceVK(desc),
        image_(image),
        image_view_(std::move(image_view)),
        yuv_conversion_(std::move(yuv_conversion)),
        destruction_callback_(destruction_callback),
        user_data_(user_data) {}

  ~WrappedExternalTextureSourceVK() override {
    if (destruction_callback_) {
      TRACE_EVENT0("flutter", "VulkanExternalTextureDestructionCallback");
      destruction_callback_(user_data_);
    }
  }

  impeller::vk::Image GetImage() const override { return image_; }

  impeller::vk::ImageView GetImageView() const override {
    return image_view_.get();
  }

  impeller::vk::ImageView GetRenderTargetView(
      uint32_t mip_level,
      uint32_t array_layer) const override {
    return image_view_.get();
  }

  std::shared_ptr<impeller::YUVConversionVK> GetYUVConversion() const override {
    return yuv_conversion_;
  }

  bool IsSwapchainImage() const override { return false; }

 private:
  impeller::vk::Image image_;
  impeller::vk::UniqueImageView image_view_;
  std::shared_ptr<impeller::YUVConversionVK> yuv_conversion_;
  VoidCallback destruction_callback_;
  void* user_data_;
};

}  // namespace
#endif  // defined(IMPELLER_SUPPORTS_RENDERING)

EmbedderExternalTextureVK::EmbedderExternalTextureVK(
    int64_t texture_identifier,
    const ExternalTextureCallback& callback)
    : Texture(texture_identifier), external_texture_callback_(callback) {
  FML_DCHECK(external_texture_callback_);
}

EmbedderExternalTextureVK::~EmbedderExternalTextureVK() = default;

void EmbedderExternalTextureVK::Paint(PaintContext& context,
                                      const DlRect& bounds,
                                      bool freeze,
                                      const DlImageSampling sampling) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureVK::Paint");
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

sk_sp<DlImage> EmbedderExternalTextureVK::ResolveTexture(
    int64_t texture_id,
    GrDirectContext* context,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureVK::ResolveTexture");
  if (aiks_context) {
    return ResolveTextureImpeller(texture_id, aiks_context, size);
  } else if (context) {
    return ResolveTextureSkia(texture_id, context, size);
  }
  return nullptr;
}

sk_sp<DlImage> EmbedderExternalTextureVK::ResolveTextureSkia(
    int64_t texture_id,
    GrDirectContext* context,
    const SkISize& size) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureVK::ResolveTextureSkia");
  if (!context) {
    return nullptr;
  }
  context->flushAndSubmit();
  context->resetContext(kAll_GrBackendState);

  std::unique_ptr<FlutterVulkanExternalTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture) {
    return nullptr;
  }

  size_t width = texture->width != 0 ? texture->width : size.width();
  size_t height = texture->height != 0 ? texture->height : size.height();

  GrVkImageInfo image_info = {
      .fImage = reinterpret_cast<VkImage>(texture->image),
      .fImageTiling = VK_IMAGE_TILING_OPTIMAL,
      .fImageLayout = static_cast<VkImageLayout>(texture->image_layout),
      .fFormat = static_cast<VkFormat>(texture->format),
      .fImageUsageFlags = VK_IMAGE_USAGE_SAMPLED_BIT,
      .fSampleCount = 1,
      .fLevelCount = 1,
  };

  if (texture->ycbcr_conversion_info != nullptr) {
    const auto* ycbcr = texture->ycbcr_conversion_info;
    VkComponentMapping components = {
        .r = static_cast<VkComponentSwizzle>(ycbcr->components.r),
        .g = static_cast<VkComponentSwizzle>(ycbcr->components.g),
        .b = static_cast<VkComponentSwizzle>(ycbcr->components.b),
        .a = static_cast<VkComponentSwizzle>(ycbcr->components.a),
    };
    if (ycbcr->external_format != 0) {
      image_info.fYcbcrConversionInfo = skgpu::VulkanYcbcrConversionInfo(
          ycbcr->external_format,
          static_cast<VkSamplerYcbcrModelConversion>(ycbcr->ycbcr_model),
          static_cast<VkSamplerYcbcrRange>(ycbcr->ycbcr_range),
          static_cast<VkChromaLocation>(ycbcr->x_chroma_offset),
          static_cast<VkChromaLocation>(ycbcr->y_chroma_offset),
          static_cast<VkFilter>(ycbcr->chroma_filter),
          static_cast<VkBool32>(ycbcr->force_explicit_reconstruction),
          components, static_cast<VkFormatFeatureFlags>(0));
    } else {
      image_info.fYcbcrConversionInfo = skgpu::VulkanYcbcrConversionInfo(
          static_cast<VkFormat>(ycbcr->format),
          static_cast<VkSamplerYcbcrModelConversion>(ycbcr->ycbcr_model),
          static_cast<VkSamplerYcbcrRange>(ycbcr->ycbcr_range),
          static_cast<VkChromaLocation>(ycbcr->x_chroma_offset),
          static_cast<VkChromaLocation>(ycbcr->y_chroma_offset),
          static_cast<VkFilter>(ycbcr->chroma_filter),
          static_cast<VkBool32>(ycbcr->force_explicit_reconstruction),
          components, static_cast<VkFormatFeatureFlags>(0));
    }
  }

  auto gr_backend_texture =
      GrBackendTextures::MakeVk(width, height, image_info);

  struct ReleaseContext {
    VoidCallback callback;
    void* user_data;
  };

  SkImages::TextureReleaseProc release_proc = nullptr;
  ReleaseContext* release_context = nullptr;
  if (texture->destruction_callback) {
    release_context =
        new ReleaseContext{texture->destruction_callback, texture->user_data};
    release_proc = [](void* context) {
      TRACE_EVENT0("flutter", "VulkanExternalTextureDestructionCallback");
      auto* rc = static_cast<ReleaseContext*>(context);
      if (rc) {
        if (rc->callback) {
          rc->callback(rc->user_data);
        }
        delete rc;
      }
    };
  }

  auto image = SkImages::BorrowTextureFrom(
      context, gr_backend_texture, kTopLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, kPremul_SkAlphaType, nullptr, release_proc,
      release_context);

  if (!image) {
    if (release_proc && release_context) {
      release_proc(release_context);
    }
    FML_LOG(ERROR) << "Could not create external texture: " << texture_id;
    return nullptr;
  }

  return DlImageSkia::Make(std::move(image));
}

sk_sp<DlImage> EmbedderExternalTextureVK::ResolveTextureImpeller(
    int64_t texture_id,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
#if defined(IMPELLER_SUPPORTS_RENDERING)
  TRACE_EVENT0("flutter", "EmbedderExternalTextureVK::ResolveTextureImpeller");
  if (!aiks_context) {
    return nullptr;
  }

  std::unique_ptr<FlutterVulkanExternalTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture) {
    return nullptr;
  }

  fml::ScopedCleanupClosure scoped_cleanup([&texture]() {
    if (texture->destruction_callback) {
      TRACE_EVENT0("flutter", "VulkanExternalTextureDestructionCallback");
      texture->destruction_callback(texture->user_data);
    }
  });

  impeller::ContextVK& context_vk =
      impeller::ContextVK::Cast(*aiks_context->GetContext());

  size_t width = texture->width != 0 ? texture->width : size.width();
  size_t height = texture->height != 0 ? texture->height : size.height();

  impeller::vk::Format vk_format =
      static_cast<impeller::vk::Format>(texture->format);
  std::optional<impeller::PixelFormat> pixel_format =
      impeller::VkFormatToImpellerFormat(vk_format);
  impeller::PixelFormat format =
      pixel_format.value_or(impeller::PixelFormat::kR8G8B8A8UNormInt);

  impeller::TextureDescriptor desc;
  desc.format = format;
  desc.size = impeller::ISize(width, height);
  desc.storage_mode = impeller::StorageMode::kDevicePrivate;
  desc.mip_count = 1;
  desc.usage = impeller::TextureUsage::kShaderRead;

  std::shared_ptr<impeller::YUVConversionVK> yuv_conversion = nullptr;
  if (texture->ycbcr_conversion_info != nullptr) {
    const auto* ycbcr = texture->ycbcr_conversion_info;
    impeller::YUVConversionDescriptorVK chain;
    auto& conv_info =
        chain.get<impeller::vk::SamplerYcbcrConversionCreateInfo>();
    conv_info.format = static_cast<impeller::vk::Format>(ycbcr->format);
    conv_info.ycbcrModel =
        static_cast<impeller::vk::SamplerYcbcrModelConversion>(
            ycbcr->ycbcr_model);
    conv_info.ycbcrRange =
        static_cast<impeller::vk::SamplerYcbcrRange>(ycbcr->ycbcr_range);
    conv_info.components.r =
        static_cast<impeller::vk::ComponentSwizzle>(ycbcr->components.r);
    conv_info.components.g =
        static_cast<impeller::vk::ComponentSwizzle>(ycbcr->components.g);
    conv_info.components.b =
        static_cast<impeller::vk::ComponentSwizzle>(ycbcr->components.b);
    conv_info.components.a =
        static_cast<impeller::vk::ComponentSwizzle>(ycbcr->components.a);
    conv_info.xChromaOffset =
        static_cast<impeller::vk::ChromaLocation>(ycbcr->x_chroma_offset);
    conv_info.yChromaOffset =
        static_cast<impeller::vk::ChromaLocation>(ycbcr->y_chroma_offset);
    conv_info.chromaFilter =
        static_cast<impeller::vk::Filter>(ycbcr->chroma_filter);
    conv_info.forceExplicitReconstruction =
        ycbcr->force_explicit_reconstruction;
#if FML_OS_ANDROID
    if (ycbcr->external_format != 0) {
      chain.get<impeller::vk::ExternalFormatANDROID>().externalFormat =
          ycbcr->external_format;
    }
#endif
    yuv_conversion = context_vk.GetYUVConversionLibrary()->GetConversion(chain);
  }

  impeller::vk::Image vk_image(reinterpret_cast<VkImage>(texture->image));

  impeller::vk::StructureChain<impeller::vk::ImageViewCreateInfo,
                               impeller::vk::SamplerYcbcrConversionInfo>
      view_chain;
  auto& view_info = view_chain.get<impeller::vk::ImageViewCreateInfo>();
  view_info.image = vk_image;
  view_info.viewType = impeller::vk::ImageViewType::e2D;
  view_info.format = vk_format;
  view_info.subresourceRange.aspectMask =
      impeller::vk::ImageAspectFlagBits::eColor;
  view_info.subresourceRange.baseMipLevel = 0u;
  view_info.subresourceRange.baseArrayLayer = 0u;
  view_info.subresourceRange.levelCount = 1u;
  view_info.subresourceRange.layerCount = 1u;

  if (yuv_conversion && yuv_conversion->IsValid()) {
    view_chain.get<impeller::vk::SamplerYcbcrConversionInfo>().conversion =
        yuv_conversion->GetConversion();
  } else {
    view_chain.unlink<impeller::vk::SamplerYcbcrConversionInfo>();
  }

  auto [result, image_view] = context_vk.GetDevice().createImageViewUnique(
      view_chain.get<impeller::vk::ImageViewCreateInfo>());
  if (result != impeller::vk::Result::eSuccess) {
    FML_LOG(ERROR)
        << "Failed to create image view for external Vulkan texture: "
        << impeller::vk::to_string(result);
    return nullptr;
  }

  auto source = std::make_shared<WrappedExternalTextureSourceVK>(
      desc, vk_image, std::move(image_view), yuv_conversion,
      texture->destruction_callback, texture->user_data);

  auto texture_vk =
      std::make_shared<impeller::TextureVK>(aiks_context->GetContext(), source);

  impeller::vk::ImageLayout layout =
      static_cast<impeller::vk::ImageLayout>(texture->image_layout);
  if (layout != impeller::vk::ImageLayout::eUndefined) {
    texture_vk->SetLayoutWithoutEncoding(layout);
  } else {
    texture_vk->SetLayoutWithoutEncoding(
        impeller::vk::ImageLayout::eShaderReadOnlyOptimal);
  }

  scoped_cleanup.Release();
  return impeller::DlImageImpeller::Make(texture_vk);
#else
  return nullptr;
#endif
}

void EmbedderExternalTextureVK::OnGrContextCreated() {}

void EmbedderExternalTextureVK::OnGrContextDestroyed() {}

void EmbedderExternalTextureVK::MarkNewFrameAvailable() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureVK::MarkNewFrameAvailable");
  last_image_ = nullptr;
}

void EmbedderExternalTextureVK::OnTextureUnregistered() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureVK::OnTextureUnregistered");
}

}  // namespace flutter
