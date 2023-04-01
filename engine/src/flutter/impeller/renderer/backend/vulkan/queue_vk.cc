// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/queue_vk.h"

#include "impeller/renderer/backend/vulkan/context_vk.h"

namespace impeller {

QueueVK::QueueVK(QueueIndexVK index, vk::Queue queue)
    : index_(index), queue_(queue) {}

QueueVK::~QueueVK() = default;

const QueueIndexVK& QueueVK::GetIndex() const {
  return index_;
}

vk::Result QueueVK::Submit(const vk::SubmitInfo& submit_info,
                           const vk::Fence& fence) const {
  Lock lock(queue_mutex_);
  return queue_.submit(submit_info, fence);
}

void QueueVK::InsertDebugMarker(const char* label) const {
  if (!HasValidationLayers()) {
    return;
  }
  vk::DebugUtilsLabelEXT label_info;
  label_info.pLabelName = label;
  Lock lock(queue_mutex_);
  queue_.insertDebugUtilsLabelEXT(label_info);
}

QueuesVK::QueuesVK() = default;

QueuesVK::QueuesVK(const vk::Device& device,
                   QueueIndexVK graphics,
                   QueueIndexVK compute,
                   QueueIndexVK transfer) {
  auto vk_graphics = device.getQueue(graphics.family, graphics.index);
  auto vk_compute = device.getQueue(compute.family, compute.index);
  auto vk_transfer = device.getQueue(transfer.family, transfer.index);

  // Always setup the graphics queue.
  graphics_queue = std::make_shared<QueueVK>(graphics, vk_graphics);
  ContextVK::SetDebugName(device, vk_graphics, "ImpellerGraphicsQ");

  // Setup the compute queue if its different from the graphics queue.
  if (compute == graphics) {
    compute_queue = graphics_queue;
  } else {
    compute_queue = std::make_shared<QueueVK>(compute, vk_compute);
    ContextVK::SetDebugName(device, vk_compute, "ImpellerComputeQ");
  }

  // Setup the transfer queue if its different from the graphics or compute
  // queues.
  if (transfer == graphics) {
    transfer_queue = graphics_queue;
  } else if (transfer == compute) {
    transfer_queue = compute_queue;
  } else {
    transfer_queue = std::make_shared<QueueVK>(transfer, vk_transfer);
    ContextVK::SetDebugName(device, vk_transfer, "ImpellerTransferQ");
  }
}

bool QueuesVK::IsValid() const {
  return graphics_queue && compute_queue && transfer_queue;
}

}  // namespace impeller
