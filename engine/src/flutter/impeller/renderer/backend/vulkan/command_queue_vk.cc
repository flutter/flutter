// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fml/status.h"

#include "impeller/renderer/backend/vulkan/command_queue_vk.h"

#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"
#include "impeller/renderer/backend/vulkan/tracked_objects_vk.h"
#include "impeller/renderer/command_buffer.h"

namespace impeller {

// Timeout waiting for an in-flight submission slot. Generous enough that no
// legitimate GPU workload should hit it.
static constexpr std::chrono::seconds kSubmitSlotTimeout{5};

// Right-shift to convert bytes to megabytes for diagnostic logging.
static constexpr uint32_t kBytesToMBShift = 20;

CommandQueueVK::CommandQueueVK(const std::weak_ptr<ContextVK>& context)
    : context_(context), in_flight_state_(std::make_shared<InFlightState>()) {}

CommandQueueVK::~CommandQueueVK() = default;

fml::Status CommandQueueVK::Submit(
    const std::vector<std::shared_ptr<CommandBuffer>>& buffers,
    const CompletionCallback& completion_callback,
    bool block_on_schedule) {
  if (buffers.empty()) {
    return fml::Status(fml::StatusCode::kInvalidArgument,
                       "No command buffers provided.");
  }
  // Success or failure, you only get to submit once.
  fml::ScopedCleanupClosure reset([&]() {
    if (completion_callback) {
      completion_callback(CommandBuffer::Status::kError);
    }
  });

  std::vector<vk::CommandBuffer> vk_buffers;
  std::vector<std::shared_ptr<TrackedObjectsVK>> tracked_objects;
  vk_buffers.reserve(buffers.size());
  tracked_objects.reserve(buffers.size());
  for (const std::shared_ptr<CommandBuffer>& buffer : buffers) {
    CommandBufferVK& command_buffer = CommandBufferVK::Cast(*buffer);
    if (!command_buffer.EndCommandBuffer()) {
      return fml::Status(fml::StatusCode::kCancelled,
                         "Failed to end command buffer.");
    }
    vk_buffers.push_back(command_buffer.GetCommandBuffer());
    tracked_objects.push_back(std::move(command_buffer.tracked_objects_));
  }

  // Throttle: wait until we have capacity for a new in-flight submission.
  // This creates backpressure to prevent host memory exhaustion when the GPU
  // cannot keep up with the rate of submission. The 5-second timeout is
  // generous - even a heavily loaded discrete GPU should complete a frame
  // submission well within this window. On timeout, the submission is
  // cancelled to enforce the limit strictly.
  {
    std::unique_lock<std::mutex> lock(in_flight_state_->mutex);
    if (!in_flight_state_->cv.wait_for(lock, kSubmitSlotTimeout, [this]() {
          return in_flight_state_->count < kMaxInFlightSubmissions;
        })) {
      VALIDATION_LOG << "Timed out waiting for in-flight submission slot. "
                     << "In-flight: " << in_flight_state_->count
                     << ". Cancelling submission to prevent resource "
                     << "exhaustion.";
      return fml::Status(fml::StatusCode::kCancelled,
                         "Timed out waiting for in-flight submission slot.");
    }
    ++in_flight_state_->count;
  }

  // Release the in-flight slot on any error path below.
  auto release_slot = fml::ScopedCleanupClosure([state = in_flight_state_]() {
    {
      std::lock_guard<std::mutex> lock(state->mutex);
      --state->count;
    }
    state->cv.notify_one();
  });

  auto context = context_.lock();
  if (!context) {
    VALIDATION_LOG << "Device lost.";
    return fml::Status(fml::StatusCode::kCancelled, "Device lost.");
  }
  if (context->IsDeviceLost()) {
    return fml::Status(fml::StatusCode::kCancelled, "Device lost.");
  }
  auto [fence_result, fence] = context->GetDevice().createFenceUnique({});
  if (fence_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create fence: " << vk::to_string(fence_result);
    return fml::Status(fml::StatusCode::kCancelled, "Failed to create fence.");
  }

  vk::SubmitInfo submit_info;
  submit_info.setCommandBuffers(vk_buffers);
  auto status = context->GetGraphicsQueue()->Submit(submit_info, *fence);
  if (status != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to submit queue: " << vk::to_string(status)
                   << " (" << vk_buffers.size() << " cmd buffer(s))";
    // The AMD driver non-conformantly frees VkCommandPool and VkCommandBuffer
    // handles during a vkQueueSubmit that fails with OOM. Abandon those
    // handles (and associated descriptor pools) without calling any Vulkan API,
    // so that RAII destructors do not call vkFreeCommandBuffers /
    // vkDestroyCommandPool / vkDestroyDescriptorPool on
    // already-invalid objects.
    for (auto& tracked : tracked_objects) {
      if (tracked) {
        tracked->AbandonForDriverCrash();
      }
    }
    // Mark device lost BEFORE any further Vulkan calls so that racing threads
    // (swapchain acquire, other submissions) short-circuit immediately.
    context->MarkDeviceLost();
    // Log memory heap budgets. On AMD RDNA (and most desktop Vulkan 1.1+
    // drivers) VK_EXT_memory_budget is available and provides actual heap
    // usage vs budget - far more useful than just the static heap sizes.
    // Fall back to static properties when the extension is absent.
    {
      vk::PhysicalDeviceMemoryProperties2 mem_props2;
      vk::PhysicalDeviceMemoryBudgetPropertiesEXT budget_props;
      mem_props2.pNext = &budget_props;

      // getMemoryProperties2 is core Vulkan 1.1 - always available.
      context->GetPhysicalDevice().getMemoryProperties2(&mem_props2);

      const auto& heaps = mem_props2.memoryProperties.memoryHeaps;
      const uint32_t heap_count = mem_props2.memoryProperties.memoryHeapCount;

      // budget_props.heapBudget[i] == 0 means the extension data wasn't
      // filled (driver too old or extension not exposed). In that case we
      // fall back to just logging the static heap size.
      bool has_budget = budget_props.heapBudget[0] != 0;

      VALIDATION_LOG << "=== Vulkan memory snapshot at OOM ===";
      for (uint32_t i = 0; i < heap_count; i++) {
        bool is_device_local = static_cast<bool>(
            heaps[i].flags & vk::MemoryHeapFlagBits::eDeviceLocal);
        if (has_budget) {
          VALIDATION_LOG
              << "  heap[" << i << "] "
              << (is_device_local ? "DEVICE_LOCAL" : "host      ")
              << "  used=" << (budget_props.heapUsage[i] >> kBytesToMBShift)
              << "MB"
              << "  budget=" << (budget_props.heapBudget[i] >> kBytesToMBShift)
              << "MB"
              << "  total=" << (heaps[i].size >> kBytesToMBShift) << "MB"
              << (budget_props.heapUsage[i] > budget_props.heapBudget[i]
                      ? "  <<< OVER BUDGET"
                      : "");
        } else {
          VALIDATION_LOG << "  heap[" << i << "] "
                         << (is_device_local ? "DEVICE_LOCAL" : "host      ")
                         << "  total=" << (heaps[i].size >> kBytesToMBShift)
                         << "MB"
                         << "  (VK_EXT_memory_budget not available)";
        }
      }
      VALIDATION_LOG << "  submit_count=" << vk_buffers.size()
                     << " cmd buffers in failed submission";
      VALIDATION_LOG << "=====================================";
    }
    // Do NOT call vkDeviceWaitIdle - AMD's internal CPU allocator is corrupted
    // after OOM from vkQueueSubmit; any further Vulkan call (including
    // vkDeviceWaitIdle) access-faults inside the ICD.
    // Release the fence handle without calling vkDestroyFence - AMD may have
    // partially tracked the fence internally even though the submit failed,
    // so calling vkDestroyFence would trigger VUID-vkDestroyFence-fence-01120.
    fence.release();
    return fml::Status(fml::StatusCode::kCancelled, "Failed to submit queue.");
  }

  // Submit succeeded. The fence callback will release the in-flight slot
  // when the GPU work completes. Capture a copy of in_flight_state_ so the
  // callback is safe even if CommandQueueVK is destroyed first.
  auto in_flight_state = in_flight_state_;
  auto added_fence = context->GetFenceWaiter()->AddFence(
      std::move(fence),
      [in_flight_state, completion_callback,
       tracked_objects = std::move(tracked_objects)]() mutable {
        // Free GPU resources first to reclaim memory before releasing the
        // submission slot. This ensures the next waiter has memory available.
        tracked_objects.clear();
        {
          std::lock_guard<std::mutex> lock(in_flight_state->mutex);
          --in_flight_state->count;
        }
        in_flight_state->cv.notify_one();
        if (completion_callback) {
          completion_callback(CommandBuffer::Status::kCompleted);
        }
      });
  if (!added_fence) {
    return fml::Status(fml::StatusCode::kCancelled, "Failed to add fence.");
  }

  // Submission is fully in-flight. Prevent the error-path cleanup closures
  // from firing - the fence callback handles everything.
  release_slot.Release();
  reset.Release();
  return fml::Status();
}

}  // namespace impeller
