// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/surface_producer_vk.h"

#include <array>

#include "fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/surface_vk.h"

namespace impeller {

std::unique_ptr<SurfaceProducerVK> SurfaceProducerVK::Create(
    std::weak_ptr<Context> context,
    const SurfaceProducerCreateInfoVK& create_info) {
  auto surface_producer =
      std::make_unique<SurfaceProducerVK>(context, create_info);
  if (!surface_producer->SetupSyncObjects()) {
    FML_LOG(ERROR) << "Failed to setup sync objects.";
    return nullptr;
  }

  return surface_producer;
}

SurfaceProducerVK::SurfaceProducerVK(
    std::weak_ptr<Context> context,
    const SurfaceProducerCreateInfoVK& create_info)
    : context_(context), create_info_(create_info) {}

SurfaceProducerVK::~SurfaceProducerVK() = default;

std::unique_ptr<Surface> SurfaceProducerVK::AcquireSurface() {
  auto fence_wait_res = create_info_.device.waitForFences({*in_flight_fence_},
                                                          VK_TRUE, UINT64_MAX);
  if (fence_wait_res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to wait for fence: "
                   << vk::to_string(fence_wait_res);
    return nullptr;
  }

  auto fence_reset_res = create_info_.device.resetFences({*in_flight_fence_});
  if (fence_reset_res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to reset fence: "
                   << vk::to_string(fence_reset_res);
    return nullptr;
  }

  uint32_t image_index;
  auto acuire_image_res = create_info_.device.acquireNextImageKHR(
      create_info_.swapchain->GetSwapchain(), UINT64_MAX,
      *image_available_semaphore_, {}, &image_index);

  if (acuire_image_res != vk::Result::eSuccess &&
      acuire_image_res != vk::Result::eSuboptimalKHR) {
    VALIDATION_LOG << "Failed to acquire next image: "
                   << vk::to_string(acuire_image_res);
    return nullptr;
  }

  if (acuire_image_res == vk::Result::eSuboptimalKHR) {
    VALIDATION_LOG << "Suboptimal image acquired.";
  }

  SurfaceVK::SwapCallback swap_callback = [this, image_index]() {
    return Present(image_index);
  };

  if (auto context = context_.lock()) {
    ContextVK* context_vk = reinterpret_cast<ContextVK*>(context.get());
    return SurfaceVK::WrapSwapchainImage(
        create_info_.swapchain->GetSwapchainImage(image_index), context_vk,
        std::move(swap_callback));
  } else {
    return nullptr;
  }
}

bool SurfaceProducerVK::SetupSyncObjects() {
  vk::SemaphoreCreateInfo semaphore_create_info;

  {
    auto image_avail_res =
        create_info_.device.createSemaphoreUnique(semaphore_create_info);
    if (image_avail_res.result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Failed to create image available semaphore: "
                     << vk::to_string(image_avail_res.result);
      return false;
    }
    image_available_semaphore_ = std::move(image_avail_res.value);
  }

  {
    auto render_finished_res =
        create_info_.device.createSemaphoreUnique(semaphore_create_info);
    if (render_finished_res.result != vk::Result::eSuccess) {
      FML_LOG(ERROR) << "Failed to create render finished semaphore: "
                     << vk::to_string(render_finished_res.result);
      return false;
    }
    render_finished_semaphore_ = std::move(render_finished_res.value);
  }

  vk::FenceCreateInfo fence_create_info;
  fence_create_info.flags = vk::FenceCreateFlagBits::eSignaled;
  {
    auto fence_res = create_info_.device.createFenceUnique(fence_create_info);
    if (fence_res.result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Failed to create fence: "
                     << vk::to_string(fence_res.result);
      return false;
    }
    in_flight_fence_ = std::move(fence_res.value);
  }

  return true;
}

bool SurfaceProducerVK::Submit(vk::CommandBuffer buffer) {
  vk::SubmitInfo submit_info;
  std::array<vk::PipelineStageFlags, 1> wait_stages = {
      vk::PipelineStageFlagBits::eColorAttachmentOutput};
  submit_info.setWaitDstStageMask(wait_stages);

  std::array<vk::Semaphore, 1> wait_semaphores = {*image_available_semaphore_};
  submit_info.setWaitSemaphores(wait_semaphores);

  std::array<vk::Semaphore, 1> signal_semaphores = {
      *render_finished_semaphore_};
  submit_info.setSignalSemaphores(signal_semaphores);

  std::array<vk::CommandBuffer, 1> command_buffers = {buffer};
  submit_info.setCommandBuffers(command_buffers);

  auto graphics_submit_res =
      create_info_.graphics_queue.submit({submit_info}, *in_flight_fence_);
  if (graphics_submit_res != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "Failed to submit graphics queue: "
                   << vk::to_string(graphics_submit_res);
    return false;
  }

  return true;
}

bool SurfaceProducerVK::Present(uint32_t image_index) {
  vk::PresentInfoKHR present_info;

  std::array<vk::Semaphore, 1> signal_semaphores = {
      *render_finished_semaphore_};
  present_info.setWaitSemaphores(signal_semaphores);

  std::array<vk::SwapchainKHR, 1> swapchains = {
      create_info_.swapchain->GetSwapchain()};
  present_info.setSwapchains(swapchains);

  std::array<uint32_t, 1> image_indices = {image_index};
  present_info.setImageIndices(image_indices);

  auto present_res = create_info_.present_queue.presentKHR(present_info);
  if (present_res != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "Failed to present: " << vk::to_string(present_res);
    return false;
  }

  return true;
}

}  // namespace impeller
