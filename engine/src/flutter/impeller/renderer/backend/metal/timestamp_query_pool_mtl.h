// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_TIMESTAMP_QUERY_POOL_MTL_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_TIMESTAMP_QUERY_POOL_MTL_H_

#include <Metal/Metal.h>

#include <cstdint>
#include <memory>

#include "impeller/base/backend_cast.h"
#include "impeller/renderer/timestamp_query_pool.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      An `MTLCounterSampleBuffer` of timestamp counters.
///
///             Metal only samples counters at stage, draw, blit, and dispatch
///             boundaries, so slots are attached to a pass descriptor rather
///             than written by a free floating command.
///
///             Sampled values are GPU ticks, whose relationship to nanoseconds
///             is not fixed. `sampleTimestamps:gpuTimestamp:` is read once at
///             construction and again on resolve to derive the conversion.
///
class TimestampQueryPoolMTL final
    : public TimestampQueryPool,
      public BackendCast<TimestampQueryPoolMTL, TimestampQueryPool> {
 public:
  /// Whether [device] can sample timestamp counters at stage boundaries.
  static bool IsSupported(id<MTLDevice> device);

  static std::shared_ptr<TimestampQueryPoolMTL> Create(id<MTLDevice> device,
                                                       size_t query_count);

  // |TimestampQueryPool|
  ~TimestampQueryPoolMTL() override;

  // |TimestampQueryPool|
  TimestampQueryResults Resolve() const override;

  //----------------------------------------------------------------------------
  /// @brief      Attach this pool's sample buffer to [descriptor] so the GPU
  ///             samples it at the pass's stage boundaries.
  ///
  void AttachTo(MTLRenderPassDescriptor* descriptor,
                std::optional<size_t> beginning_of_pass_write_index,
                std::optional<size_t> end_of_pass_write_index) const;

 private:
  // Held as an untyped `id` (an `id<MTLCounterSampleBuffer>`) because that
  // protocol is newer than the minimum deployment target.
  TimestampQueryPoolMTL(id<MTLDevice> device, id buffer, size_t query_count);

  id<MTLDevice> device_ = nil;
  id buffer_ = nil;
  uint64_t base_cpu_timestamp_ = 0;
  uint64_t base_gpu_timestamp_ = 0;

  TimestampQueryPoolMTL(const TimestampQueryPoolMTL&) = delete;

  TimestampQueryPoolMTL& operator=(const TimestampQueryPoolMTL&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_TIMESTAMP_QUERY_POOL_MTL_H_
