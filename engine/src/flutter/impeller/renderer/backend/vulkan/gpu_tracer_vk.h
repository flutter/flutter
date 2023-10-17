// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <thread>

#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/device_holder.h"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

/// @brief A class that uses timestamp queries to record the approximate GPU
/// execution time.
class GPUTracerVK {
 public:
  explicit GPUTracerVK(const std::shared_ptr<DeviceHolder>& device_holder);

  ~GPUTracerVK() = default;

  /// @brief Record a timestamp query into the provided cmd buffer to record
  ///        start time.
  void RecordCmdBufferStart(const vk::CommandBuffer& buffer);

  /// @brief Record a timestamp query into the provided cmd buffer to record end
  ///        time.
  ///
  ///        Returns the index that should be passed to [OnFenceComplete].
  std::optional<size_t> RecordCmdBufferEnd(const vk::CommandBuffer& buffer);

  /// @brief Signal that the cmd buffer is completed.
  ///
  ///        If [frame_index] is std::nullopt, this frame recording is ignored.
  void OnFenceComplete(std::optional<size_t> frame_index, bool success);

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
  const std::shared_ptr<DeviceHolder> device_holder_;

  struct GPUTraceState {
    size_t current_index = 0;
    size_t pending_buffers = 0;
    // If a cmd buffer submission fails for any reason, this field is used
    // to indicate that the query pool results may be incomplete and this
    // frame should be discarded.
    bool contains_failure = false;
    vk::UniqueQueryPool query_pool;
  };

  mutable Mutex trace_state_mutex_;
  GPUTraceState trace_states_[16] IPLR_GUARDED_BY(trace_state_mutex_);
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

}  // namespace impeller
