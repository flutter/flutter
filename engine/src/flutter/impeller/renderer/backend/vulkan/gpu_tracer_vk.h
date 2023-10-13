// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "impeller/renderer/backend/vulkan/context_vk.h"

namespace impeller {

/// @brief A class that uses timestamp queries to record the approximate GPU
/// execution time.
class GPUTracerVK {
 public:
  explicit GPUTracerVK(const std::weak_ptr<ContextVK>& context);

  ~GPUTracerVK() = default;

  /// @brief Record the approximate start time of the GPU workload for the
  ///        current frame.
  void RecordStartFrameTime();

  /// @brief Record the approximate end time of the GPU workload for the current
  ///        frame.
  void RecordEndFrameTime();

 private:
  void ResetQueryPool(size_t pool);

  const std::weak_ptr<ContextVK> context_;
  vk::UniqueQueryPool query_pool_ = {};

  size_t current_index_ = 0u;
  // The number of nanoseconds for each timestamp unit.
  float timestamp_period_ = 1;
  bool started_frame_ = false;
  bool valid_ = false;
};

}  // namespace impeller
