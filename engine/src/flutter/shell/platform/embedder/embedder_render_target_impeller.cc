// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_render_target_impeller.h"

#include "flutter/fml/logging.h"
#include "flutter/impeller/renderer/render_target.h"

#ifdef SHELL_ENABLE_VULKAN
#include "flutter/impeller/display_list/aiks_context.h"           // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"  // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/formats_vk.h"  // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/texture_vk.h"  // nogncheck
#include "flutter/impeller/renderer/backend/vulkan/texture_wrapper_vk.h"  // nogncheck
#include "flutter/impeller/renderer/context.h"  // nogncheck
#endif                                          // SHELL_ENABLE_VULKAN

namespace flutter {

EmbedderRenderTargetImpeller::EmbedderRenderTargetImpeller(
    FlutterBackingStore backing_store,
    std::shared_ptr<impeller::AiksContext> aiks_context,
    std::unique_ptr<impeller::RenderTarget> impeller_target,
    fml::closure on_release,
    fml::closure framebuffer_destruction_callback,
    MakeOrClearCurrentCallback on_make_current,
    MakeOrClearCurrentCallback on_clear_current)
    : EmbedderRenderTarget(backing_store, std::move(on_release)),
      aiks_context_(std::move(aiks_context)),
      impeller_target_(std::move(impeller_target)),
      framebuffer_destruction_callback_(
          std::move(framebuffer_destruction_callback)),
      on_make_current_(std::move(on_make_current)),
      on_clear_current_(std::move(on_clear_current)) {
  FML_DCHECK(aiks_context_);
  FML_DCHECK(impeller_target_);
}

#ifdef SHELL_ENABLE_VULKAN
std::unique_ptr<EmbedderRenderTarget> EmbedderRenderTargetImpeller::MakeVulkan(
    FlutterBackingStore backing_store,
    fml::closure on_release,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    const FlutterBackingStoreConfig& config,
    const FlutterVulkanBackingStore* vulkan) {
  if (!aiks_context) {
    FML_LOG(ERROR) << "Impeller context is null.";
    return nullptr;
  }
  if (!vulkan || !vulkan->image) {
    FML_LOG(ERROR) << "Invalid Vulkan backing store.";
    return nullptr;
  }

  fml::ScopedCleanupClosure destruction_callback(
      [callback = vulkan->destruction_callback,
       user_data = vulkan->user_data]() {
        if (callback) {
          callback(user_data);
        }
      });

  const auto size = impeller::ISize(config.size.width, config.size.height);

  std::optional<impeller::PixelFormat> format =
      impeller::VkFormatToImpellerFormat(
          static_cast<impeller::vk::Format>(vulkan->image->format));
  if (!format.has_value()) {
    FML_LOG(ERROR) << "Unsupported Vulkan backing store pixel format: "
                   << vulkan->image->format;
    return nullptr;
  }

  // Embedder-supplied Vulkan backing store images are single-level 2D render
  // targets without mipmaps.
  constexpr size_t kSingleMipLevel = 1;

  impeller::TextureDescriptor texture_desc;
  texture_desc.storage_mode = impeller::StorageMode::kDevicePrivate;
  texture_desc.type = impeller::TextureType::kTexture2D;
  texture_desc.format = *format;
  texture_desc.size = size;
  texture_desc.mip_count = kSingleMipLevel;
  texture_desc.usage = impeller::TextureUsage::kRenderTarget;
  texture_desc.sample_count = impeller::SampleCount::kCount1;

  auto wrapped_source = impeller::WrapTextureSourceVK(
      aiks_context->GetContext(),                                           //
      texture_desc,                                                         //
      impeller::vk::Image(reinterpret_cast<VkImage>(vulkan->image->image))  //
  );
  if (!wrapped_source) {
    FML_LOG(ERROR) << "Could not wrap embedder supplied Vulkan render image.";
    return nullptr;
  }

  auto wrapped_color = std::make_shared<impeller::TextureVK>(
      aiks_context->GetContext(), std::move(wrapped_source));

  impeller::RenderTargetAllocator allocator(
      aiks_context->GetContext()->GetResourceAllocator());
  impeller::RenderTarget impeller_target;
  if (aiks_context->GetContext()->GetCapabilities()->SupportsOffscreenMSAA()) {
    impeller_target = allocator.CreateOffscreenMSAA(
        *aiks_context->GetContext(),                                //
        size,                                                       //
        /*mip_count=*/kSingleMipLevel,                              //
        "Offscreen Layer",                                          //
        impeller::RenderTarget::kDefaultColorAttachmentConfigMSAA,  //
        impeller::RenderTarget::kDefaultStencilAttachmentConfig,    //
        /*existing_color_msaa_texture=*/nullptr,                    //
        /*existing_color_resolve_texture=*/wrapped_color,           //
        /*existing_depth_stencil_texture=*/nullptr,                 //
        /*target_pixel_format=*/*format                             //
    );
  }
  if (!impeller_target.IsValid()) {
    impeller_target = allocator.CreateOffscreen(
        *aiks_context->GetContext(),                              //
        size,                                                     //
        /*mip_count=*/kSingleMipLevel,                            //
        "EmbedderVulkan",                                         //
        impeller::RenderTarget::kDefaultColorAttachmentConfig,    //
        impeller::RenderTarget::kDefaultStencilAttachmentConfig,  //
        /*existing_color_texture=*/wrapped_color,                 //
        /*existing_depth_stencil_texture=*/nullptr,               //
        /*target_pixel_format=*/*format                           //
    );
  }

  return std::make_unique<EmbedderRenderTargetImpeller>(
      backing_store, aiks_context,
      std::make_unique<impeller::RenderTarget>(std::move(impeller_target)),
      std::move(on_release), destruction_callback.Release());
}
#endif  // SHELL_ENABLE_VULKAN

EmbedderRenderTargetImpeller::~EmbedderRenderTargetImpeller() {
  impeller_target_.reset();
  if (framebuffer_destruction_callback_) {
    framebuffer_destruction_callback_();
  }
}

sk_sp<SkSurface> EmbedderRenderTargetImpeller::GetSkiaSurface() const {
  return nullptr;
}

impeller::RenderTarget* EmbedderRenderTargetImpeller::GetImpellerRenderTarget()
    const {
  return impeller_target_.get();
}

std::shared_ptr<impeller::AiksContext>
EmbedderRenderTargetImpeller::GetAiksContext() const {
  return aiks_context_;
}

DlISize EmbedderRenderTargetImpeller::GetRenderTargetSize() const {
  auto size = impeller_target_->GetRenderTargetSize();
  return DlISize(size);
}

EmbedderRenderTarget::SetCurrentResult
EmbedderRenderTargetImpeller::MaybeMakeCurrent() const {
  if (on_make_current_ != nullptr) {
    return on_make_current_();
  }
  return {true, false};
}

EmbedderRenderTarget::SetCurrentResult
EmbedderRenderTargetImpeller::MaybeClearCurrent() const {
  if (on_clear_current_ != nullptr) {
    return on_clear_current_();
  }
  return {true, false};
}

}  // namespace flutter
