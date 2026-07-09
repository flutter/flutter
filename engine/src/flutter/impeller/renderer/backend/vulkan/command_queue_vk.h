// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_COMMAND_QUEUE_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_COMMAND_QUEUE_VK_H_

#include <condition_variable>
#include <memory>
#include <mutex>

#include "impeller/renderer/command_queue.h"

namespace impeller {

class ContextVK;

class CommandQueueVK : public CommandQueue {
 public:
  /// Maximum number of command buffer submissions that can be simultaneously
  /// in-flight. When this limit is reached, Submit() will synchronously wait
  /// for an older submission to complete before proceeding. This provides
  /// backpressure to prevent host memory exhaustion under heavy GPU load.
  ///
  /// This is intentionally one greater than kMaxFramesInFlight (2) so that
  /// the submission queue does not bottleneck the frame pipeline - the
  /// rasterizer can always submit without waiting unless the GPU has fallen
  /// three submissions behind.
  static constexpr uint32_t kMaxInFlightSubmissions = 3u;

  explicit CommandQueueVK(const std::weak_ptr<ContextVK>& context);

  ~CommandQueueVK() override;

  fml::Status Submit(const std::vector<std::shared_ptr<CommandBuffer>>& buffers,
                     const CompletionCallback& completion_callback = {},
                     bool block_on_schedule = false) override;

 private:
  /// Shared state for tracking in-flight submissions. Uses a shared_ptr so
  /// that fence completion callbacks (which run on the FenceWaiterVK thread)
  /// can safely decrement the counter even if CommandQueueVK has been
  /// destroyed.
  struct InFlightState {
    std::mutex mutex;
    std::condition_variable cv;
    uint32_t count = 0;
  };

  std::weak_ptr<ContextVK> context_;
  std::shared_ptr<InFlightState> in_flight_state_;

  CommandQueueVK(const CommandQueueVK&) = delete;

  CommandQueueVK& operator=(const CommandQueueVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_COMMAND_QUEUE_VK_H_
