// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/surface_producer_vk.h"

#include <array>

#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/surface_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

std::unique_ptr<SurfaceProducerVK> SurfaceProducerVK::Create(
    std::weak_ptr<Context> context,
    const SurfaceProducerCreateInfoVK& create_info) {
  auto surface_producer =
      std::make_unique<SurfaceProducerVK>(context, create_info);
  if (!surface_producer->SetupSyncObjects()) {
    VALIDATION_LOG << "Failed to setup sync objects.";
    return nullptr;
  }

  return surface_producer;
}

SurfaceProducerVK::SurfaceProducerVK(
    std::weak_ptr<Context> context,
    const SurfaceProducerCreateInfoVK& create_info)
    : context_(context), create_info_(create_info) {}

SurfaceProducerVK::~SurfaceProducerVK() = default;

std::unique_ptr<Surface> SurfaceProducerVK::AcquireSurface(
    size_t current_frame) {
  current_frame = current_frame % kMaxFramesInFlight;
  const auto& sync_objects = sync_objects_[current_frame];

  auto fence_wait_res = create_info_.device.waitForFences(
      {*sync_objects->in_flight_fence}, VK_TRUE, UINT64_MAX);
  if (fence_wait_res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to wait for fence: "
                   << vk::to_string(fence_wait_res);
    return nullptr;
  }

  auto fence_reset_res =
      create_info_.device.resetFences({*sync_objects->in_flight_fence});
  if (fence_reset_res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to reset fence: "
                   << vk::to_string(fence_reset_res);
    return nullptr;
  }

  uint32_t image_index;
  auto acuire_image_res = create_info_.device.acquireNextImageKHR(
      create_info_.swapchain->GetSwapchain(), UINT64_MAX,
      *sync_objects->image_available_semaphore, {}, &image_index);

  if (acuire_image_res != vk::Result::eSuccess &&
      acuire_image_res != vk::Result::eSuboptimalKHR) {
    VALIDATION_LOG << "Failed to acquire next image: "
                   << vk::to_string(acuire_image_res);
    return nullptr;
  }

  if (acuire_image_res == vk::Result::eSuboptimalKHR) {
    VALIDATION_LOG << "Suboptimal image acquired.";
  }

  SurfaceVK::SwapCallback swap_callback = [this, current_frame, image_index]() {
    return Present(current_frame, image_index);
  };

  if (auto context = context_.lock()) {
    ContextVK* context_vk = reinterpret_cast<ContextVK*>(context.get());
    return SurfaceVK::WrapSwapchainImage(
        current_frame, create_info_.swapchain->GetSwapchainImage(image_index),
        context_vk, std::move(swap_callback));
  } else {
    return nullptr;
  }
}

std::unique_ptr<SurfaceSyncObjectsVK> SurfaceSyncObjectsVK::Create(
    vk::Device device) {
  auto sync_objects = std::make_unique<SurfaceSyncObjectsVK>();
  vk::SemaphoreCreateInfo semaphore_create_info;

  {
    auto image_avail_res = device.createSemaphoreUnique(semaphore_create_info);
    if (image_avail_res.result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Failed to create image available semaphore: "
                     << vk::to_string(image_avail_res.result);
      return nullptr;
    }
    sync_objects->image_available_semaphore = std::move(image_avail_res.value);
  }

  {
    auto render_finished_res =
        device.createSemaphoreUnique(semaphore_create_info);
    if (render_finished_res.result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Failed to create render finished semaphore: "
                     << vk::to_string(render_finished_res.result);
      return nullptr;
    }
    sync_objects->render_finished_semaphore =
        std::move(render_finished_res.value);
  }

  vk::FenceCreateInfo fence_create_info;
  fence_create_info.flags = vk::FenceCreateFlagBits::eSignaled;
  {
    auto fence_res = device.createFenceUnique(fence_create_info);
    if (fence_res.result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Failed to create fence: "
                     << vk::to_string(fence_res.result);
      return nullptr;
    }
    sync_objects->in_flight_fence = std::move(fence_res.value);
  }

  return sync_objects;
}

bool SurfaceProducerVK::SetupSyncObjects() {
  for (size_t i = 0; i < kMaxFramesInFlight; i++) {
    auto sync_objects = SurfaceSyncObjectsVK::Create(create_info_.device);
    if (!sync_objects) {
      return false;
    }
    sync_objects_[i] = std::move(sync_objects);
  }
  return true;
}

bool SurfaceProducerVK::QueueCommandBuffer(uint32_t frame_num,
                                           vk::UniqueCommandBuffer buffer) {
  command_buffers_[frame_num].push_back(std::move(buffer));
  return true;
}

bool SurfaceProducerVK::Submit(uint32_t frame_num) {
  auto& sync_objects = sync_objects_[frame_num];
  vk::SubmitInfo submit_info;
  std::array<vk::PipelineStageFlags, 1> wait_stages = {
      vk::PipelineStageFlagBits::eColorAttachmentOutput};
  submit_info.setWaitDstStageMask(wait_stages);

  std::array<vk::Semaphore, 1> wait_semaphores = {
      *sync_objects->image_available_semaphore};
  submit_info.setWaitSemaphores(wait_semaphores);

  std::array<vk::Semaphore, 1> signal_semaphores = {
      *sync_objects->render_finished_semaphore};
  submit_info.setSignalSemaphores(signal_semaphores);

  std::vector<vk::CommandBuffer> command_buffers = {};
  for (auto& buf : command_buffers_[frame_num]) {
    command_buffers.push_back(*buf);
  }
  submit_info.setCommandBuffers(command_buffers);

  auto graphics_submit_res = create_info_.graphics_queue.submit(
      {submit_info}, *sync_objects->in_flight_fence);
  if (graphics_submit_res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to submit graphics queue: "
                   << vk::to_string(graphics_submit_res);
    return false;
  }

  auto idle_wait_res = create_info_.graphics_queue.waitIdle();
  if (idle_wait_res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to wait for graphics queue idle: "
                   << vk::to_string(idle_wait_res);
    return false;
  }

  return true;
}

bool SurfaceProducerVK::Present(size_t frame_num, uint32_t image_index) {
  Submit(frame_num);

  auto& sync_objects = sync_objects_[frame_num];

  vk::PresentInfoKHR present_info;

  std::array<vk::Semaphore, 1> signal_semaphores = {
      *sync_objects->render_finished_semaphore};
  present_info.setWaitSemaphores(signal_semaphores);

  std::array<vk::SwapchainKHR, 1> swapchains = {
      create_info_.swapchain->GetSwapchain()};
  present_info.setSwapchains(swapchains);

  std::array<uint32_t, 1> image_indices = {image_index};
  present_info.setImageIndices(image_indices);

  auto present_res = create_info_.present_queue.presentKHR(present_info);
  if ((present_res != vk::Result::eSuccess) &&
      (present_res != vk::Result::eSuboptimalKHR)) {
    command_buffers_[frame_num].clear();
    stash_rp_[frame_num].clear();
    return false;
  }

  command_buffers_[frame_num].clear();
  stash_rp_[frame_num].clear();
  return true;
}

}  // namespace impeller
