// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"

#include "flutter/fml/closure.h"
#include "fml/status.h"
#include "fml/status_or.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"
#include "impeller/renderer/backend/vulkan/gpu_tracer_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

class TrackedObjectsVK {
 public:
  explicit TrackedObjectsVK(
      const std::weak_ptr<const DeviceHolder>& device_holder,
      const std::shared_ptr<CommandPoolVK>& pool,
      std::unique_ptr<GPUProbe> probe)
      : desc_pool_(device_holder), probe_(std::move(probe)) {
    if (!pool) {
      return;
    }
    auto buffer = pool->CreateCommandBuffer();
    if (!buffer) {
      return;
    }
    pool_ = pool;
    buffer_ = std::move(buffer);
    is_valid_ = true;
  }

  ~TrackedObjectsVK() {
    if (!buffer_) {
      return;
    }
    pool_->CollectCommandBuffer(std::move(buffer_));
  }

  bool IsValid() const { return is_valid_; }

  void Track(std::shared_ptr<SharedObjectVK> object) {
    if (!object) {
      return;
    }
    tracked_objects_.insert(std::move(object));
  }

  void Track(std::shared_ptr<const Buffer> buffer) {
    if (!buffer) {
      return;
    }
    tracked_buffers_.insert(std::move(buffer));
  }

  bool IsTracking(const std::shared_ptr<const Buffer>& buffer) const {
    if (!buffer) {
      return false;
    }
    return tracked_buffers_.find(buffer) != tracked_buffers_.end();
  }

  void Track(std::shared_ptr<const TextureSourceVK> texture) {
    if (!texture) {
      return;
    }
    tracked_textures_.insert(std::move(texture));
  }

  bool IsTracking(const std::shared_ptr<const TextureSourceVK>& texture) const {
    if (!texture) {
      return false;
    }
    return tracked_textures_.find(texture) != tracked_textures_.end();
  }

  vk::CommandBuffer GetCommandBuffer() const { return *buffer_; }

  DescriptorPoolVK& GetDescriptorPool() { return desc_pool_; }

  GPUProbe& GetGPUProbe() const { return *probe_.get(); }

 private:
  DescriptorPoolVK desc_pool_;
  // `shared_ptr` since command buffers have a link to the command pool.
  std::shared_ptr<CommandPoolVK> pool_;
  vk::UniqueCommandBuffer buffer_;
  std::set<std::shared_ptr<SharedObjectVK>> tracked_objects_;
  std::set<std::shared_ptr<const Buffer>> tracked_buffers_;
  std::set<std::shared_ptr<const TextureSourceVK>> tracked_textures_;
  std::unique_ptr<GPUProbe> probe_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(TrackedObjectsVK);
};

CommandEncoderFactoryVK::CommandEncoderFactoryVK(
    const std::weak_ptr<const ContextVK>& context)
    : context_(context) {}

void CommandEncoderFactoryVK::SetLabel(const std::string& label) {
  label_ = label;
}

std::shared_ptr<CommandEncoderVK> CommandEncoderFactoryVK::Create() {
  auto context = context_.lock();
  if (!context) {
    return nullptr;
  }
  auto& context_vk = ContextVK::Cast(*context);
  auto recycler = context_vk.GetCommandPoolRecycler();
  if (!recycler) {
    return nullptr;
  }
  auto tls_pool = recycler->Get();
  if (!tls_pool) {
    return nullptr;
  }

  auto tracked_objects = std::make_shared<TrackedObjectsVK>(
      context_vk.GetDeviceHolder(), tls_pool,
      context->GetGPUTracer()->CreateGPUProbe());
  auto queue = context_vk.GetGraphicsQueue();

  if (!tracked_objects || !tracked_objects->IsValid() || !queue) {
    return nullptr;
  }

  vk::CommandBufferBeginInfo begin_info;
  begin_info.flags = vk::CommandBufferUsageFlagBits::eOneTimeSubmit;
  if (tracked_objects->GetCommandBuffer().begin(begin_info) !=
      vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not begin command buffer.";
    return nullptr;
  }

  if (label_.has_value()) {
    context_vk.SetDebugName(tracked_objects->GetCommandBuffer(),
                            label_.value());
  }
  tracked_objects->GetGPUProbe().RecordCmdBufferStart(
      tracked_objects->GetCommandBuffer());

  return std::make_shared<CommandEncoderVK>(context_vk.GetDeviceHolder(),
                                            tracked_objects, queue,
                                            context_vk.GetFenceWaiter());
}

CommandEncoderVK::CommandEncoderVK(
    std::weak_ptr<const DeviceHolder> device_holder,
    std::shared_ptr<TrackedObjectsVK> tracked_objects,
    const std::shared_ptr<QueueVK>& queue,
    std::shared_ptr<FenceWaiterVK> fence_waiter)
    : device_holder_(std::move(device_holder)),
      tracked_objects_(std::move(tracked_objects)),
      queue_(queue),
      fence_waiter_(std::move(fence_waiter)) {}

CommandEncoderVK::~CommandEncoderVK() = default;

bool CommandEncoderVK::IsValid() const {
  return is_valid_;
}

bool CommandEncoderVK::Submit(SubmitCallback callback) {
  // Make sure to call callback with `false` if anything returns early.
  bool fail_callback = !!callback;
  if (!IsValid()) {
    VALIDATION_LOG << "Cannot submit invalid CommandEncoderVK.";
    if (fail_callback) {
      callback(false);
    }
    return false;
  }

  // Success or failure, you only get to submit once.
  fml::ScopedCleanupClosure reset([&]() {
    if (fail_callback) {
      callback(false);
    }
    Reset();
  });

  InsertDebugMarker("QueueSubmit");

  auto command_buffer = GetCommandBuffer();

  tracked_objects_->GetGPUProbe().RecordCmdBufferEnd(command_buffer);

  auto status = command_buffer.end();
  if (status != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to end command buffer: " << vk::to_string(status);
    return false;
  }
  std::shared_ptr<const DeviceHolder> strong_device = device_holder_.lock();
  if (!strong_device) {
    VALIDATION_LOG << "Device lost.";
    return false;
  }
  auto [fence_result, fence] = strong_device->GetDevice().createFenceUnique({});
  if (fence_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create fence: " << vk::to_string(fence_result);
    return false;
  }

  vk::SubmitInfo submit_info;
  std::vector<vk::CommandBuffer> buffers = {command_buffer};
  submit_info.setCommandBuffers(buffers);
  status = queue_->Submit(submit_info, *fence);
  if (status != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to submit queue: " << vk::to_string(status);
    return false;
  }

  // Submit will proceed, call callback with true when it is done and do not
  // call when `reset` is collected.
  fail_callback = false;
  return fence_waiter_->AddFence(
      std::move(fence),
      [callback, tracked_objects = std::move(tracked_objects_)]() mutable {
        // Ensure tracked objects are destructed before calling any final
        // callbacks.
        tracked_objects.reset();
        if (callback) {
          callback(true);
        }
      });
}

vk::CommandBuffer CommandEncoderVK::GetCommandBuffer() const {
  if (tracked_objects_) {
    return tracked_objects_->GetCommandBuffer();
  }
  return {};
}

void CommandEncoderVK::Reset() {
  tracked_objects_.reset();

  queue_ = nullptr;
  is_valid_ = false;
}

bool CommandEncoderVK::Track(std::shared_ptr<SharedObjectVK> object) {
  if (!IsValid()) {
    return false;
  }
  tracked_objects_->Track(std::move(object));
  return true;
}

bool CommandEncoderVK::Track(std::shared_ptr<const Buffer> buffer) {
  if (!IsValid()) {
    return false;
  }
  tracked_objects_->Track(std::move(buffer));
  return true;
}

bool CommandEncoderVK::IsTracking(
    const std::shared_ptr<const Buffer>& buffer) const {
  if (!IsValid()) {
    return false;
  }
  return tracked_objects_->IsTracking(buffer);
}

bool CommandEncoderVK::Track(std::shared_ptr<const TextureSourceVK> texture) {
  if (!IsValid()) {
    return false;
  }
  tracked_objects_->Track(std::move(texture));
  return true;
}

bool CommandEncoderVK::Track(const std::shared_ptr<const Texture>& texture) {
  if (!IsValid()) {
    return false;
  }
  if (!texture) {
    return true;
  }
  return Track(TextureVK::Cast(*texture).GetTextureSource());
}

bool CommandEncoderVK::IsTracking(
    const std::shared_ptr<const Texture>& texture) const {
  if (!IsValid()) {
    return false;
  }
  std::shared_ptr<const TextureSourceVK> source =
      TextureVK::Cast(*texture).GetTextureSource();
  return tracked_objects_->IsTracking(source);
}

fml::StatusOr<std::vector<vk::DescriptorSet>>
CommandEncoderVK::AllocateDescriptorSets(
    uint32_t buffer_count,
    uint32_t sampler_count,
    const std::vector<vk::DescriptorSetLayout>& layouts) {
  if (!IsValid()) {
    return fml::Status(fml::StatusCode::kUnknown, "command encoder invalid");
  }

  return tracked_objects_->GetDescriptorPool().AllocateDescriptorSets(
      buffer_count, sampler_count, layouts);
}

void CommandEncoderVK::PushDebugGroup(const char* label) const {
  if (!HasValidationLayers()) {
    return;
  }
  vk::DebugUtilsLabelEXT label_info;
  label_info.pLabelName = label;
  if (auto command_buffer = GetCommandBuffer()) {
    command_buffer.beginDebugUtilsLabelEXT(label_info);
  }
}

void CommandEncoderVK::PopDebugGroup() const {
  if (!HasValidationLayers()) {
    return;
  }
  if (auto command_buffer = GetCommandBuffer()) {
    command_buffer.endDebugUtilsLabelEXT();
  }
}

void CommandEncoderVK::InsertDebugMarker(const char* label) const {
  if (!HasValidationLayers()) {
    return;
  }
  vk::DebugUtilsLabelEXT label_info;
  label_info.pLabelName = label;
  if (auto command_buffer = GetCommandBuffer()) {
    command_buffer.insertDebugUtilsLabelEXT(label_info);
  }
  if (queue_) {
    queue_->InsertDebugMarker(label);
  }
}

}  // namespace impeller
