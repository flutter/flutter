// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_vk.h"

#include <utility>

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"

#include "third_party/skia/include/core/SkAlphaType.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkImageGanesh.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkTypes.h"
#if defined(FML_OS_ANDROID) && defined(SK_BUILD_FOR_ANDROID) && \
    __ANDROID_API__ >= 26
#include "third_party/skia/include/android/GrAHardwareBufferUtils.h"
#include "third_party/skia/include/android/SkImageAndroid.h"
#endif

namespace flutter {

EmbedderExternalTextureVK::EmbedderExternalTextureVK(
    int64_t texture_identifier,
    ExternalTextureCallback callback)
    : Texture(texture_identifier),
      external_texture_callback_(std::move(callback)) {
  FML_DCHECK(external_texture_callback_);
}

EmbedderExternalTextureVK::~EmbedderExternalTextureVK() = default;

// |flutter::Texture|
void EmbedderExternalTextureVK::Paint(PaintContext& context,
                                      const DlRect& bounds,
                                      bool freeze,
                                      const DlImageSampling sampling) {
  if (last_image_ == nullptr) {
    last_image_ =
        ResolveTexture(Id(),                                                 //
                       context.gr_context,                                   //
                       context.aiks_context,                                 //
                       SkISize::Make(bounds.GetWidth(), bounds.GetHeight())  //
        );
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
#if IMPELLER_SUPPORTS_RENDERING
  if (aiks_context) {
    return ResolveTextureImpeller(texture_id, aiks_context, size);
  }
#endif  // IMPELLER_SUPPORTS_RENDERING
  if (context) {
    return ResolveTextureSkia(texture_id, context, size);
  }
  return nullptr;
}

sk_sp<DlImage> EmbedderExternalTextureVK::ResolveTextureSkia(
    int64_t texture_id,
    GrDirectContext* context,
    const SkISize& size) {
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

  size_t width = size.width();
  size_t height = size.height();
  if (texture->width != 0 && texture->height != 0) {
    width = texture->width;
    height = texture->height;
  }

  if (width == 0 || height == 0) {
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    FML_LOG(ERROR) << "Invalid external texture dimensions: " << width << "x"
                   << height;
    return nullptr;
  }

  SkColorType color_type = kRGBA_8888_SkColorType;
  if (static_cast<VkFormat>(texture->format) == VK_FORMAT_B8G8R8A8_UNORM) {
    color_type = kBGRA_8888_SkColorType;
  }

  if (texture->type == kFlutterVulkanExternalTextureTypeVkImage) {
    GrVkImageInfo gr_image_info = {};
    gr_image_info.fImage = reinterpret_cast<VkImage>(texture->vk_image);
    gr_image_info.fImageTiling = VK_IMAGE_TILING_OPTIMAL;
    gr_image_info.fImageLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    gr_image_info.fFormat = static_cast<VkFormat>(texture->format);
    gr_image_info.fImageUsageFlags =
        VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
        VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT;
    gr_image_info.fSampleCount = 1;
    gr_image_info.fLevelCount = 1;

    auto gr_backend_texture =
        GrBackendTextures::MakeVk(width, height, gr_image_info);
    SkImages::TextureReleaseProc release_proc = texture->destruction_callback;
    auto image = SkImages::BorrowTextureFrom(
        context, gr_backend_texture, kTopLeft_GrSurfaceOrigin, color_type,
        kPremul_SkAlphaType, nullptr, release_proc, texture->user_data);

    if (!image) {
      if (release_proc) {
        release_proc(texture->user_data);
      }
      FML_LOG(ERROR) << "Could not create Skia Vulkan external texture.";
      return nullptr;
    }

    return DlImageSkia::Make(std::move(image));
  } else if (texture->type ==
             kFlutterVulkanExternalTextureTypeAHardwareBuffer) {
#if defined(FML_OS_ANDROID) && defined(SK_BUILD_FOR_ANDROID) && \
    __ANDROID_API__ >= 26
    AHardwareBuffer* ahb =
        reinterpret_cast<AHardwareBuffer*>(texture->hardware_buffer);
    if (!ahb) {
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      FML_LOG(ERROR) << "Embedder supplied null AHardwareBuffer.";
      return nullptr;
    }

    GrAHardwareBufferUtils::DeleteImageProc delete_proc = nullptr;
    GrAHardwareBufferUtils::UpdateImageProc update_proc = nullptr;
    GrAHardwareBufferUtils::TexImageCtx image_ctx = nullptr;
    auto backend_format = GrAHardwareBufferUtils::GetVulkanBackendFormat(
        context, ahb, texture->format, false);
    auto backend_texture = GrAHardwareBufferUtils::MakeVulkanBackendTexture(
        context, ahb, width, height, &delete_proc, &update_proc, &image_ctx,
        false, backend_format, false);
    if (!backend_texture.isValid()) {
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      FML_LOG(ERROR)
          << "Could not make Vulkan backend texture from AHardwareBuffer.";
      return nullptr;
    }

    struct ReleaseContext {
      GrAHardwareBufferUtils::DeleteImageProc delete_proc;
      GrAHardwareBufferUtils::TexImageCtx image_ctx;
      VoidCallback destruction_callback;
      void* user_data;
    };
    auto* release_ctx = new ReleaseContext{
        .delete_proc = delete_proc,
        .image_ctx = image_ctx,
        .destruction_callback = texture->destruction_callback,
        .user_data = texture->user_data,
    };

    auto image = SkImages::BorrowTextureFrom(
        context, backend_texture, kTopLeft_GrSurfaceOrigin, color_type,
        kPremul_SkAlphaType, nullptr,
        [](void* ctx) {
          auto* rc = static_cast<ReleaseContext*>(ctx);
          if (rc->delete_proc && rc->image_ctx) {
            rc->delete_proc(rc->image_ctx);
          }
          if (rc->destruction_callback) {
            rc->destruction_callback(rc->user_data);
          }
          delete rc;
        },
        release_ctx);

    if (!image) {
      if (delete_proc && image_ctx) {
        delete_proc(image_ctx);
      }
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      delete release_ctx;
      FML_LOG(ERROR)
          << "Could not create Skia AHardwareBuffer external texture.";
      return nullptr;
    }
    return DlImageSkia::Make(std::move(image));
#else
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    FML_LOG(ERROR) << "AHardwareBuffer external textures are only supported on "
                      "Android API 26+.";
    return nullptr;
#endif
  }

  if (texture->destruction_callback) {
    texture->destruction_callback(texture->user_data);
  }
  return nullptr;
}

// |flutter::Texture|
void EmbedderExternalTextureVK::OnGrContextCreated() {}

// |flutter::Texture|
void EmbedderExternalTextureVK::OnGrContextDestroyed() {}

// |flutter::Texture|
void EmbedderExternalTextureVK::MarkNewFrameAvailable() {
  last_image_ = nullptr;
}

// |flutter::Texture|
void EmbedderExternalTextureVK::OnTextureUnregistered() {}

}  // namespace flutter
