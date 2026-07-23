// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fml/status.h"

#include <chrono>

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

// Logs per-heap memory usage and budgets after a failed queue submission.
// VK_EXT_memory_budget data is far more useful than the static heap sizes,
// but the extension is not tracked by the context; detect whether the driver
// filled the chained struct by checking every heap's budget. A driver that
// populated the struct reports a non-zero budget for at least one heap,
// whereas an ignored pNext struct stays zero-initialized.
static void LogHeapBudgetsAtOOM(const ContextVK& context,
                                size_t failed_buffer_count) {
  vk::PhysicalDeviceMemoryProperties2 mem_props2;
  vk::PhysicalDeviceMemoryBudgetPropertiesEXT budget_props;
  mem_props2.pNext = &budget_props;

  // getMemoryProperties2 is core Vulkan 1.1 and always available.
  context.GetPhysicalDevice().getMemoryProperties2(&mem_props2);

  const auto& heaps = mem_props2.memoryProperties.memoryHeaps;
  const uint32_t heap_count = mem_props2.memoryProperties.memoryHeapCount;

  bool has_budget = false;
  for (uint32_t i = 0; i < heap_count; i++) {
    has_budget = has_budget || budget_props.heapBudget[i] != 0;
  }

  VALIDATION_LOG << "=== Vulkan memory snapshot at OOM ===";
  for (uint32_t i = 0; i < heap_count; i++) {
    bool is_device_local = static_cast<bool>(
        heaps[i].flags & vk::MemoryHeapFlagBits::eDeviceLocal);
    if (has_budget) {
      VALIDATION_LOG << "  heap[" << i << "] "
                     << (is_device_local ? "DEVICE_LOCAL" : "host      ")
                     << "  used="
                     << (budget_props.heapUsage[i] >> kBytesToMBShift) << "MB"
                     << "  budget="
                     << (budget_props.heapBudget[i] >> kBytesToMBShift) << "MB"
                     << "  total=" << (heaps[i].size >> kBytesToMBShift) << "MB"
                     << (budget_props.heapUsage[i] > budget_props.heapBudget[i]
                             ? "  <<< OVER BUDGET"
                             : "");
    } else {
      VALIDATION_LOG << "  heap[" << i << "] "
                     << (is_device_local ? "DEVICE_LOCAL" : "host      ")
                     << "  total=" << (heaps[i].size >> kBytesToMBShift) << "MB"
                     << "  (VK_EXT_memory_budget not available)";
    }
  }
  VALIDATION_LOG << "  submit_count=" << failed_buffer_count
                 << " cmd buffers in failed submission";
  VALIDATION_LOG << "=====================================";
}

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

  auto context = context_.lock();
  if (!context) {
    VALIDATION_LOG << "Device lost.";
    return fml::Status(fml::StatusCode::kCancelled, "Device lost.");
  }
  if (context->IsDeviceLost()) {
    return fml::Status(fml::StatusCode::kCancelled, "Device lost.");
  }

  // Throttle: wait until there is capacity for a new in-flight submission.
  // This creates backpressure to prevent host memory exhaustion when the GPU
  // cannot keep up with the rate of submission. The 5-second timeout is
  // generous: even a heavily loaded GPU should complete a frame submission
  // well within this window. On timeout, the submission is cancelled to
  // enforce the limit strictly.
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

  // Release the in-flight slot on any error path below. On success, the slot
  // is instead released by the fence completion callback.
  fml::ScopedCleanupClosure release_slot([state = in_flight_state_]() {
    {
      std::lock_guard<std::mutex> lock(state->mutex);
      --state->count;
    }
    state->cv.notify_one();
  });

  auto [fence_result, fence] = context->GetDevice().createFenceUnique({});
  if (fence_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create fence: " << vk::to_string(fence_result);
    return fml::Status(fml::StatusCode::kCancelled, "Failed to create fence.");
  }

  // Shared between the submit callback (failure path) and the fence
  // completion callback (success path). Exactly one of the two consumes it.
  auto shared_tracked_objects =
      std::make_shared<std::vector<std::shared_ptr<TrackedObjectsVK>>>(
          std::move(tracked_objects));

  // This will be called immediately by FenceWaiterVK::AddFence.
  auto submit_callback = [&context, &vk_buffers,
                          &shared_tracked_objects](vk::Fence submit_fence) {
    vk::SubmitInfo submit_info;
    submit_info.setCommandBuffers(vk_buffers);
    auto status =
        context->GetGraphicsQueue()->Submit(submit_info, submit_fence);
    if (status != vk::Result::eSuccess) {
      VALIDATION_LOG << "Failed to submit queue: " << vk::to_string(status)
                     << " (" << vk_buffers.size() << " cmd buffer(s))";
      // Some drivers non-conformantly invalidate VkCommandPool and
      // VkCommandBuffer handles during a vkQueueSubmit that fails with an
      // out-of-memory error (observed on AMD). Abandon those handles (and
      // associated descriptor pools) without calling any Vulkan API so that
      // RAII destructors do not call vkFreeCommandBuffers /
      // vkDestroyCommandPool / vkDestroyDescriptorPool on already-invalid
      // objects.
      for (auto& tracked : *shared_tracked_objects) {
        if (tracked) {
          tracked->AbandonForDriverCrash();
        }
      }
      // Mark device lost BEFORE any further Vulkan calls so that racing
      // threads (swapchain acquire, other submissions) short-circuit
      // immediately. Do NOT call vkDeviceWaitIdle: the driver's internal
      // allocator may be corrupted after the failed submission, and any
      // further Vulkan call can access-fault inside the ICD.
      context->MarkDeviceLost();
      LogHeapBudgetsAtOOM(*context, vk_buffers.size());
      return fml::Status(fml::StatusCode::kCancelled,
                         "Failed to submit queue.");
    }
    return fml::Status();
  };

  std::shared_ptr<GpuSubmissionTracker> tracker =
      context->GetMutableSubmissionTracker();
  uint64_t submission_id = tracker->RecordSubmission();

  // This will be called later when the command completes.
  auto in_flight_state = in_flight_state_;
  auto fence_complete_callback = [in_flight_state, completion_callback, tracker,
                                  submission_id,
                                  shared_tracked_objects]() mutable {
    // Free GPU resources first to reclaim memory before releasing the
    // submission slot, so the next waiter has memory available.
    shared_tracked_objects->clear();
    tracker->RecordCompletion(submission_id);
    {
      std::lock_guard<std::mutex> lock(in_flight_state->mutex);
      --in_flight_state->count;
    }
    in_flight_state->cv.notify_one();
    if (completion_callback) {
      completion_callback(CommandBuffer::Status::kCompleted);
    }
  };

  // Submit will proceed, call callback with true when it is done and do not
  // call when `reset` is collected.
  auto fence_status = context->GetFenceWaiter()->AddFence(
      std::move(fence), submit_callback, std::move(fence_complete_callback));
  if (!fence_status.ok()) {
    tracker->RecordCompletion(submission_id);
    return fence_status;
  }
  release_slot.Release();
  reset.Release();
  return fml::Status();
}

}  // namespace impeller
