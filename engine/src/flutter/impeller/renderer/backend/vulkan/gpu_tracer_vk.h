// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <thread>

#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/device_holder.h"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

class GPUProbe;

/// @brief A class that uses timestamp queries to record the approximate GPU
/// execution time.
class GPUTracerVK : public std::enable_shared_from_this<GPUTracerVK> {
 public:
  explicit GPUTracerVK(const std::shared_ptr<DeviceHolder>& device_holder);

  ~GPUTracerVK() = default;

  /// @brief Create a GPUProbe to trace the execution of a command buffer on the
  ///        GPU.
  std::unique_ptr<GPUProbe> CreateGPUProbe();

  /// @brief Signal the start of a frame workload.
  ///
  ///        Any cmd buffers that are created after this call and before
  ///        [MarkFrameEnd] will be attributed to the current frame.
  void MarkFrameStart();

  /// @brief Signal the end of a frame workload.
  void MarkFrameEnd();

  // visible for testing.
  bool IsEnabled() const;

 private:
  friend class GPUProbe;

  static const constexpr size_t kTraceStatesSize = 32u;

  /// @brief Signal that the cmd buffer is completed.
  ///
  ///        If [frame_index] is std::nullopt, this frame recording is ignored.
  void OnFenceComplete(size_t frame);

  /// @brief Record a timestamp query into the provided cmd buffer to record
  ///        start time.
  void RecordCmdBufferStart(const vk::CommandBuffer& buffer, GPUProbe& probe);

  /// @brief Record a timestamp query into the provided cmd buffer to record end
  ///        time.
  void RecordCmdBufferEnd(const vk::CommandBuffer& buffer, GPUProbe& probe);

  const std::shared_ptr<DeviceHolder> device_holder_;

  struct GPUTraceState {
    size_t current_index = 0;
    size_t pending_buffers = 0;
    vk::UniqueQueryPool query_pool;
  };

  mutable Mutex trace_state_mutex_;
  GPUTraceState trace_states_[kTraceStatesSize] IPLR_GUARDED_BY(
      trace_state_mutex_);
  size_t current_state_ IPLR_GUARDED_BY(trace_state_mutex_) = 0u;

  // The number of nanoseconds for each timestamp unit.
  float timestamp_period_ = 1;

  // If in_frame_ is not true, then this cmd buffer was started as a part of
  // some non-frame workload like image decoding. We should not record this as
  // part of the frame workload, as the gap between this non-frame and a
  // frameworkload may be substantial. For example, support the engine creates a
  // cmd buffer to perform an image upload at timestamp 0 and then 30 ms later
  // actually renders a frame. Without the in_frame_ guard, the GPU frame time
  // would include this 30ms gap during which the engine was idle.
  bool in_frame_ = false;

  // Track the raster thread id to avoid recording mipmap/image cmd buffers
  // that are not guaranteed to start/end according to frame boundaries.
  std::thread::id raster_thread_id_;
  bool enabled_ = false;
};

class GPUProbe {
 public:
  explicit GPUProbe(const std::weak_ptr<GPUTracerVK>& tracer);

  GPUProbe(GPUProbe&&) = delete;
  GPUProbe& operator=(GPUProbe&&) = delete;

  ~GPUProbe();

  /// @brief Record a timestamp query into the provided cmd buffer to record
  ///        start time.
  void RecordCmdBufferStart(const vk::CommandBuffer& buffer);

  /// @brief Record a timestamp query into the provided cmd buffer to record end
  ///        time.
  void RecordCmdBufferEnd(const vk::CommandBuffer& buffer);

 private:
  friend class GPUTracerVK;

  std::weak_ptr<GPUTracerVK> tracer_;
  std::optional<size_t> index_ = std::nullopt;
};

}  // namespace impeller
