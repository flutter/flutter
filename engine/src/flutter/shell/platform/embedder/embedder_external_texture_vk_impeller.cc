// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The Impeller backed implementation of EmbedderExternalTextureVK. This
// translation unit is only built when `impeller_supports_rendering` is true.
// Platforms that build the Vulkan embedder against Skia/Ganesh only (for
// example Fuchsia) never compile or link this file, which keeps the Impeller
// dependency out of their dependency graph entirely.

#include "flutter/shell/platform/embedder/embedder_external_texture_vk.h"

#include <functional>
#include <memory>
#include <utility>

#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/backend/vulkan/texture_wrapper_vk.h"

#if defined(FML_OS_ANDROID)
#include "impeller/renderer/backend/vulkan/android/ahb_texture_source_vk.h"
#include "impeller/toolkit/android/hardware_buffer.h"
#endif  // defined(FML_OS_ANDROID)

namespace flutter {

#if defined(FML_OS_ANDROID)
namespace {
class WrappedAHBTextureSourceVK final : public impeller::TextureSourceVK {
 public:
  WrappedAHBTextureSourceVK(
      std::shared_ptr<impeller::AHBTextureSourceVK> source,
      std::function<void()> deletion_proc)
      : TextureSourceVK(source->GetTextureDescriptor()),
        source_(std::move(source)),
        deletion_proc_(std::move(deletion_proc)) {}

  ~WrappedAHBTextureSourceVK() override {
    if (deletion_proc_) {
      deletion_proc_();
    }
  }

  impeller::vk::Image GetImage() const override { return source_->GetImage(); }

  impeller::vk::ImageView GetImageView() const override {
    return source_->GetImageView();
  }

  impeller::vk::ImageView GetRenderTargetView(
      uint32_t mip_level,
      uint32_t array_layer) const override {
    return source_->GetRenderTargetView(mip_level, array_layer);
  }

  bool IsSwapchainImage() const override { return source_->IsSwapchainImage(); }

  std::shared_ptr<impeller::YUVConversionVK> GetYUVConversion() const override {
    return source_->GetYUVConversion();
  }

 private:
  std::shared_ptr<impeller::AHBTextureSourceVK> source_;
  std::function<void()> deletion_proc_;
};
}  // namespace
#endif  // defined(FML_OS_ANDROID)

sk_sp<DlImage> EmbedderExternalTextureVK::ResolveTextureImpeller(
    int64_t texture_id,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  if (!aiks_context || !aiks_context->GetContext()) {
    return nullptr;
  }
  std::unique_ptr<FlutterVulkanExternalTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture) {
    return nullptr;
  }

  fml::ScopedCleanupClosure scoped_cleanup([&texture]() {
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
  });

  size_t width = size.width();
  size_t height = size.height();
  if (texture->width != 0 && texture->height != 0) {
    width = texture->width;
    height = texture->height;
  }

  if (width == 0 || height == 0) {
    FML_LOG(ERROR) << "Invalid external texture dimensions: " << width << "x"
                   << height;
    return nullptr;
  }

  if (texture->type == kFlutterVulkanExternalTextureTypeVkImage) {
    if (!texture->vk_image) {
      FML_LOG(ERROR) << "Embedder supplied null VkImage handle.";
      return nullptr;
    }

    auto vk_format = static_cast<impeller::vk::Format>(texture->format);
    auto format = impeller::VkFormatToImpellerFormat(vk_format);
    if (!format.has_value()) {
      FML_LOG(ERROR) << "Unsupported pixel format for Vulkan external texture: "
                     << impeller::vk::to_string(vk_format);
      return nullptr;
    }

    impeller::TextureDescriptor desc;
    desc.format = format.value();
    desc.size = impeller::ISize(width, height);
    desc.storage_mode = impeller::StorageMode::kDevicePrivate;
    desc.mip_count = 1;
    desc.usage = impeller::TextureUsage::kShaderRead;

    auto wrapped_texture = impeller::WrapTextureVK(
        aiks_context->GetContext(), desc,
        impeller::vk::Image(reinterpret_cast<VkImage>(texture->vk_image)),
        [callback = texture->destruction_callback,
         user_data = texture->user_data]() {
          if (callback) {
            callback(user_data);
          }
        });

    if (!wrapped_texture) {
      FML_LOG(ERROR)
          << "Could not wrap embedder supplied Vulkan external texture.";
      return nullptr;
    }

    scoped_cleanup.Release();
    return impeller::DlImageImpeller::Make(wrapped_texture);
  } else if (texture->type ==
             kFlutterVulkanExternalTextureTypeAHardwareBuffer) {
#if defined(FML_OS_ANDROID)
    if (!texture->hardware_buffer) {
      FML_LOG(ERROR) << "Embedder supplied null AHardwareBuffer handle.";
      return nullptr;
    }
    AHardwareBuffer* ahb =
        reinterpret_cast<AHardwareBuffer*>(texture->hardware_buffer);
    auto hb_desc = impeller::android::HardwareBuffer::Describe(ahb);
    if (!hb_desc.has_value()) {
      FML_LOG(ERROR) << "Could not describe AHardwareBuffer.";
      return nullptr;
    }

    auto raw_source = std::make_shared<impeller::AHBTextureSourceVK>(
        aiks_context->GetContext(), ahb, hb_desc.value());
    if (!raw_source->IsValid()) {
      FML_LOG(ERROR) << "Could not create AHBTextureSourceVK.";
      return nullptr;
    }

    std::shared_ptr<impeller::TextureSourceVK> wrapped_source =
        std::make_shared<WrappedAHBTextureSourceVK>(
            raw_source, [callback = texture->destruction_callback,
                         user_data = texture->user_data]() {
              if (callback) {
                callback(user_data);
              }
            });

    auto impeller_texture = std::make_shared<impeller::TextureVK>(
        aiks_context->GetContext(), wrapped_source);

    // Transition layout to shader read optimal.
    auto context_vk = std::static_pointer_cast<impeller::ContextVK>(
        aiks_context->GetContext());
    auto buffer = context_vk->CreateCommandBuffer();
    if (!buffer) {
      FML_LOG(ERROR) << "Could not create command buffer for AHB transition.";
      return nullptr;
    }
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

    if (!impeller_texture->SetLayout(barrier) ||
        !context_vk->GetCommandQueue()->Submit({buffer}).ok()) {
      FML_LOG(ERROR) << "Failed to transition AHardwareBuffer layout to "
                        "shader read optimal.";
      return nullptr;
    }

    scoped_cleanup.Release();
    return impeller::DlImageImpeller::Make(impeller_texture);
#else
    FML_LOG(ERROR)
        << "AHardwareBuffer external textures are only supported on Android.";
    return nullptr;
#endif  // defined(FML_OS_ANDROID)
  }

  return nullptr;
}

}  // namespace flutter
