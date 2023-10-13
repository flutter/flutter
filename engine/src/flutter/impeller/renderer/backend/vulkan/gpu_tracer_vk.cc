// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/gpu_tracer_vk.h"

#include <utility>
#include "fml/trace_event.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/command_buffer.h"

namespace impeller {

static constexpr uint32_t kPoolSize = 128u;

GPUTracerVK::GPUTracerVK(const std::weak_ptr<ContextVK>& context)
    : context_(context) {
  auto strong_context = context_.lock();
  if (!strong_context) {
    return;
  }
  timestamp_period_ = strong_context->GetPhysicalDevice()
                          .getProperties()
                          .limits.timestampPeriod;
  if (timestamp_period_ <= 0) {
    // The device does not support timestamp queries.
    return;
  }
  vk::QueryPoolCreateInfo info;
  info.queryCount = kPoolSize;
  info.queryType = vk::QueryType::eTimestamp;

  auto [status, pool] = strong_context->GetDevice().createQueryPoolUnique(info);
  if (status != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create query pool.";
    return;
  }
  query_pool_ = std::move(pool);
  // Disable tracing in release mode.
#ifdef IMPELLER_DEBUG
  valid_ = true;
#endif
}

void GPUTracerVK::RecordStartFrameTime() {
  if (!valid_) {
    return;
  }
  auto strong_context = context_.lock();
  if (!strong_context) {
    return;
  }
  auto buffer = strong_context->CreateCommandBuffer();
  auto vk_trace_cmd_buffer =
      CommandBufferVK::Cast(*buffer).GetEncoder()->GetCommandBuffer();
  // The two commands below are executed in order, such that writeTimeStamp is
  // guaranteed to occur after resetQueryPool has finished. The validation
  // layer seem particularly strict, and efforts to reset the entire pool
  // were met with validation errors (though seemingly correct measurements).
  // To work around this, the tracer only resets the query that will be
  // used next.
  vk_trace_cmd_buffer.resetQueryPool(query_pool_.get(), current_index_, 1);
  vk_trace_cmd_buffer.writeTimestamp(vk::PipelineStageFlagBits::eBottomOfPipe,
                                     query_pool_.get(), current_index_);

  if (!buffer->SubmitCommands()) {
    VALIDATION_LOG << "GPUTracerVK: Failed to record start time.";
  }

  // The logic in RecordEndFrameTime requires us to have recorded a pair of
  // tracing events. If this method failed for any reason we need to be sure we
  // don't attempt to record and read back a second value, or we will get values
  // that span multiple frames.
  started_frame_ = true;
}

void GPUTracerVK::RecordEndFrameTime() {
  if (!valid_ || !started_frame_) {
    return;
  }
  auto strong_context = context_.lock();
  if (!strong_context) {
    return;
  }

  started_frame_ = false;
  auto last_query = current_index_;
  current_index_ += 1;

  auto buffer = strong_context->CreateCommandBuffer();
  auto vk_trace_cmd_buffer =
      CommandBufferVK::Cast(*buffer).GetEncoder()->GetCommandBuffer();
  vk_trace_cmd_buffer.resetQueryPool(query_pool_.get(), current_index_, 1);
  vk_trace_cmd_buffer.writeTimestamp(vk::PipelineStageFlagBits::eBottomOfPipe,
                                     query_pool_.get(), current_index_);

  // On completion of the second time stamp recording, we read back this value
  // and the previous value. The difference is approximately the frame time.
  const auto device_holder = strong_context->GetDeviceHolder();
  if (!buffer->SubmitCommands([&, last_query,
                               device_holder](CommandBuffer::Status status) {
        auto strong_context = context_.lock();
        if (!strong_context) {
          return;
        }
        uint64_t bits[2] = {0, 0};
        auto result = device_holder->GetDevice().getQueryPoolResults(
            query_pool_.get(), last_query, 2, sizeof(bits), &bits,
            sizeof(int64_t), vk::QueryResultFlagBits::e64);

        if (result == vk::Result::eSuccess) {
          // This value should probably be available in some form besides a
          // timeline event but that is a job for a future Jonah.
          auto gpu_ms = (((bits[1] - bits[0]) * timestamp_period_) / 1000000);
          FML_TRACE_COUNTER(
              "flutter", "GPUTracer",
              reinterpret_cast<int64_t>(this),  // Trace Counter ID
              "FrameTimeMS", gpu_ms);
        }
      })) {
    if (!buffer->SubmitCommands()) {
      VALIDATION_LOG << "GPUTracerVK failed to record frame end time.";
    }
  }

  if (current_index_ == kPoolSize - 1) {
    current_index_ = 0u;
  }
}

}  // namespace impeller
