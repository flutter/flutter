// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/swapchain/ahb/ahb_swapchain_impl_vk.h"

#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/barrier_vk.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain/ahb/ahb_formats.h"
#include "impeller/renderer/backend/vulkan/swapchain/surface_vk.h"
#include "impeller/toolkit/android/surface_transaction.h"

namespace impeller {

//------------------------------------------------------------------------------
/// The maximum number of presents pending in the compositor after which the
/// acquire calls will block.
///
static constexpr const size_t kMaxPendingPresents = 2u;

static TextureDescriptor ToSwapchainTextureDescriptor(
    const android::HardwareBufferDescriptor& ahb_desc) {
  TextureDescriptor desc;
  desc.storage_mode = StorageMode::kDevicePrivate;
  desc.type = TextureType::kTexture2D;
  desc.format = ToPixelFormat(ahb_desc.format);
  desc.size = ahb_desc.size;
  desc.mip_count = 1u;
  desc.usage = TextureUsage::kRenderTarget;
  desc.sample_count = SampleCount::kCount1;
  desc.compression_type = CompressionType::kLossless;
  return desc;
}

std::shared_ptr<AHBSwapchainImplVK> AHBSwapchainImplVK::Create(
    const std::weak_ptr<Context>& context,
    std::weak_ptr<android::SurfaceControl> surface_control,
    const ISize& size,
    bool enable_msaa) {
  auto impl = std::shared_ptr<AHBSwapchainImplVK>(new AHBSwapchainImplVK(
      context, std::move(surface_control), size, enable_msaa));
  return impl->IsValid() ? impl : nullptr;
}

AHBSwapchainImplVK::AHBSwapchainImplVK(
    const std::weak_ptr<Context>& context,
    std::weak_ptr<android::SurfaceControl> surface_control,
    const ISize& size,
    bool enable_msaa)
    : surface_control_(std::move(surface_control)),
      pending_presents_(std::make_shared<fml::Semaphore>(kMaxPendingPresents)) {
  desc_ = android::HardwareBufferDescriptor::MakeForSwapchainImage(size);
  pool_ = std::make_shared<AHBTexturePoolVK>(context, desc_);
  if (!pool_->IsValid()) {
    return;
  }
  transients_ = std::make_shared<SwapchainTransientsVK>(
      context, ToSwapchainTextureDescriptor(desc_), enable_msaa);
  is_valid_ = true;
}

AHBSwapchainImplVK::~AHBSwapchainImplVK() = default;

const ISize& AHBSwapchainImplVK::GetSize() const {
  return desc_.size;
}

bool AHBSwapchainImplVK::IsValid() const {
  return is_valid_;
}

const android::HardwareBufferDescriptor& AHBSwapchainImplVK::GetDescriptor()
    const {
  return desc_;
}

std::unique_ptr<Surface> AHBSwapchainImplVK::AcquireNextDrawable() {
  {
    TRACE_EVENT0("impeller", "CompositorPendingWait");
    if (!pending_presents_->Wait()) {
      return nullptr;
    }
  }

  AutoSemaSignaler auto_sema_signaler =
      std::make_shared<fml::ScopedCleanupClosure>(
          [sema = pending_presents_]() { sema->Signal(); });

  if (!is_valid_) {
    return nullptr;
  }

  auto texture = pool_->Pop();

  if (!texture) {
    VALIDATION_LOG << "Could not create AHB texture source.";
    return nullptr;
  }

  auto surface = SurfaceVK::WrapSwapchainImage(
      transients_, texture,
      [signaler = auto_sema_signaler, weak = weak_from_this(), texture]() {
        auto thiz = weak.lock();
        if (!thiz) {
          VALIDATION_LOG << "Swapchain died before image could be presented.";
          return false;
        }
        return thiz->Present(signaler, texture);
      });

  if (!surface) {
    return nullptr;
  }

  return surface;
}

bool AHBSwapchainImplVK::Present(
    const AutoSemaSignaler& signaler,
    const std::shared_ptr<AHBTextureSourceVK>& texture) {
  auto control = surface_control_.lock();
  if (!control || !control->IsValid()) {
    VALIDATION_LOG << "Surface control died before swapchain image could be "
                      "presented.";
    return false;
  }

  if (!texture) {
    return false;
  }

  auto fence = SubmitCompletionSignal(texture);

  if (!fence) {
    VALIDATION_LOG << "Could not submit completion signal.";
    return false;
  }

  android::SurfaceTransaction transaction;
  if (!transaction.SetContents(control.get(),               //
                               texture->GetBackingStore(),  //
                               fence->CreateFD()            //
                               )) {
    VALIDATION_LOG << "Could not set swapchain image contents on the surface "
                      "control.";
    return false;
  }
  return transaction.Apply([signaler, texture, weak = weak_from_this()]() {
    auto thiz = weak.lock();
    if (!thiz) {
      return;
    }
    thiz->OnTextureSetOnSurfaceControl(signaler, texture);
  });
}

std::shared_ptr<ExternalFenceVK> AHBSwapchainImplVK::SubmitCompletionSignal(
    const std::shared_ptr<AHBTextureSourceVK>& texture) const {
  auto context = transients_->GetContext().lock();
  if (!context) {
    return nullptr;
  }
  auto fence = std::make_shared<ExternalFenceVK>(context);
  if (!fence || !fence->IsValid()) {
    return nullptr;
  }

  auto command_buffer = context->CreateCommandBuffer();
  if (!command_buffer) {
    return nullptr;
  }
  command_buffer->SetLabel("AHBPresentCommandBuffer");
  const auto& encoder = CommandBufferVK::Cast(*command_buffer).GetEncoder();

  const auto command_encoder_vk = encoder->GetCommandBuffer();

  BarrierVK barrier;
  barrier.cmd_buffer = command_encoder_vk;
  barrier.new_layout = vk::ImageLayout::eGeneral;
  barrier.src_stage = vk::PipelineStageFlagBits::eColorAttachmentOutput;
  barrier.src_access = vk::AccessFlagBits::eColorAttachmentWrite;
  barrier.dst_stage = vk::PipelineStageFlagBits::eBottomOfPipe;
  barrier.dst_access = {};

  if (!texture->SetLayout(barrier).ok()) {
    return nullptr;
  }

  encoder->Track(fence->GetSharedHandle());

  if (!encoder->EndCommandBuffer()) {
    return nullptr;
  }

  vk::SubmitInfo submit_info;
  submit_info.setCommandBuffers(command_encoder_vk);

  auto result = ContextVK::Cast(*context).GetGraphicsQueue()->Submit(
      submit_info, fence->GetHandle());
  if (result != vk::Result::eSuccess) {
    return nullptr;
  }
  return fence;
}

void AHBSwapchainImplVK::OnTextureSetOnSurfaceControl(
    const AutoSemaSignaler& signaler,
    std::shared_ptr<AHBTextureSourceVK> texture) {
  signaler->Reset();
  // The transaction completion indicates that the surface control now
  // references the hardware buffer. We can recycle the previous set buffer
  // safely.
  Lock lock(currently_displayed_texture_mutex_);
  auto old_texture = currently_displayed_texture_;
  currently_displayed_texture_ = std::move(texture);
  pool_->Push(std::move(old_texture));
}

}  // namespace impeller
