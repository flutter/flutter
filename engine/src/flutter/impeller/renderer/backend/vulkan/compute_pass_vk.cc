// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/compute_pass_vk.h"

#include "flutter/fml/trace_event.h"
#include "impeller/renderer/backend/vulkan/binding_helpers_vk.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/compute_pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

ComputePassVK::ComputePassVK(std::weak_ptr<const Context> context,
                             std::weak_ptr<CommandBufferVK> command_buffer)
    : ComputePass(std::move(context)),
      command_buffer_(std::move(command_buffer)) {
  is_valid_ = true;
}

ComputePassVK::~ComputePassVK() = default;

bool ComputePassVK::IsValid() const {
  return is_valid_;
}

void ComputePassVK::OnSetLabel(const std::string& label) {
  if (label.empty()) {
    return;
  }
  label_ = label;
}

static bool UpdateBindingLayouts(const Bindings& bindings,
                                 const vk::CommandBuffer& buffer) {
  BarrierVK barrier;
  barrier.cmd_buffer = buffer;
  barrier.src_access = vk::AccessFlagBits::eTransferWrite;
  barrier.src_stage = vk::PipelineStageFlagBits::eTransfer;
  barrier.dst_access = vk::AccessFlagBits::eShaderRead;
  barrier.dst_stage = vk::PipelineStageFlagBits::eComputeShader;

  barrier.new_layout = vk::ImageLayout::eShaderReadOnlyOptimal;

  for (const auto& [_, data] : bindings.sampled_images) {
    if (!TextureVK::Cast(*data.texture.resource).SetLayout(barrier)) {
      return false;
    }
  }
  return true;
}

static bool UpdateBindingLayouts(const ComputeCommand& command,
                                 const vk::CommandBuffer& buffer) {
  return UpdateBindingLayouts(command.bindings, buffer);
}

static bool UpdateBindingLayouts(const std::vector<ComputeCommand>& commands,
                                 const vk::CommandBuffer& buffer) {
  for (const auto& command : commands) {
    if (!UpdateBindingLayouts(command, buffer)) {
      return false;
    }
  }
  return true;
}

bool ComputePassVK::OnEncodeCommands(const Context& context,
                                     const ISize& grid_size,
                                     const ISize& thread_group_size) const {
  TRACE_EVENT0("impeller", "ComputePassVK::EncodeCommands");
  if (!IsValid()) {
    return false;
  }

  FML_DCHECK(!grid_size.IsEmpty() && !thread_group_size.IsEmpty());

  const auto& vk_context = ContextVK::Cast(context);
  auto command_buffer = command_buffer_.lock();
  if (!command_buffer) {
    VALIDATION_LOG << "Command buffer died before commands could be encoded.";
    return false;
  }
  auto encoder = command_buffer->GetEncoder();
  if (!encoder) {
    return false;
  }

  fml::ScopedCleanupClosure pop_marker(
      [&encoder]() { encoder->PopDebugGroup(); });
  if (!label_.empty()) {
    encoder->PushDebugGroup(label_.c_str());
  } else {
    pop_marker.Release();
  }
  auto cmd_buffer = encoder->GetCommandBuffer();

  if (!UpdateBindingLayouts(commands_, cmd_buffer)) {
    VALIDATION_LOG << "Could not update binding layouts for compute pass.";
    return false;
  }
  auto desc_sets_result =
      AllocateAndBindDescriptorSets(vk_context, encoder, commands_);
  if (!desc_sets_result.ok()) {
    return false;
  }
  auto desc_sets = desc_sets_result.value();

  TRACE_EVENT0("impeller", "EncodeComputePassCommands");
  size_t desc_index = 0;
  for (const auto& command : commands_) {
    const auto& pipeline_vk = ComputePipelineVK::Cast(*command.pipeline);

    cmd_buffer.bindPipeline(vk::PipelineBindPoint::eCompute,
                            pipeline_vk.GetPipeline());
    cmd_buffer.bindDescriptorSets(
        vk::PipelineBindPoint::eCompute,             // bind point
        pipeline_vk.GetPipelineLayout(),             // layout
        0,                                           // first set
        {vk::DescriptorSet{desc_sets[desc_index]}},  // sets
        nullptr                                      // offsets
    );

    // TOOD(dnfield): This should be moved to caps. But for now keeping this
    // in parallel with Metal.
    auto device_properties = vk_context.GetPhysicalDevice().getProperties();

    auto max_wg_size = device_properties.limits.maxComputeWorkGroupSize;

    int64_t width = grid_size.width;
    int64_t height = grid_size.height;

    // Special case for linear processing.
    if (height == 1) {
      int64_t minimum = 1;
      int64_t threadGroups = std::max(
          static_cast<int64_t>(std::ceil(width * 1.0 / max_wg_size[0] * 1.0)),
          minimum);
      cmd_buffer.dispatch(threadGroups, 1, 1);
    } else {
      while (width > max_wg_size[0]) {
        width = std::max(static_cast<int64_t>(1), width / 2);
      }
      while (height > max_wg_size[1]) {
        height = std::max(static_cast<int64_t>(1), height / 2);
      }
      cmd_buffer.dispatch(width, height, 1);
    }
    desc_index += 1;
  }

  return true;
}

}  // namespace impeller
