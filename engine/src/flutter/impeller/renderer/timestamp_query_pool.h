// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_TIMESTAMP_QUERY_POOL_H_
#define FLUTTER_IMPELLER_RENDERER_TIMESTAMP_QUERY_POOL_H_

#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <vector>

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      The timestamps read back from a `TimestampQueryPool`.
///
struct TimestampQueryResults {
  /// Nanosecond timestamps indexed by query slot. An empty entry means the
  /// slot was never written, or the GPU discarded its result.
  ///
  /// These are points on the GPU's own timeline, not durations. Subtracting
  /// one from another is only meaningful when the GPU is known to have
  /// executed the writes in the recorded order.
  std::vector<std::optional<uint64_t>> timestamps;

  /// Whether the GPU reported that its timer was interrupted while these
  /// timestamps were recorded. Every timestamp in the set is unusable when
  /// this is true.
  bool disjoint = false;
};

//------------------------------------------------------------------------------
/// @brief      A fixed set of slots that passes write GPU timestamps into.
///
///             Pools are created from a `Context` and attached to a pass with
///             `TimestampWrites`. Results are only readable once the GPU has
///             retired every command buffer that recorded writes into the
///             pool.
///
class TimestampQueryPool {
 public:
  virtual ~TimestampQueryPool();

  /// The number of slots in this pool.
  size_t GetQueryCount() const;

  //----------------------------------------------------------------------------
  /// @brief      Read back every slot in the pool.
  ///
  ///             Call this only after the GPU has retired the command buffers
  ///             that recorded into the pool. Reading early leaves the
  ///             not-yet-written slots empty instead of stalling.
  ///
  virtual TimestampQueryResults Resolve() const = 0;

 protected:
  explicit TimestampQueryPool(size_t query_count);

  const size_t query_count_;

 private:
  TimestampQueryPool(const TimestampQueryPool&) = delete;

  TimestampQueryPool& operator=(const TimestampQueryPool&) = delete;
};

//------------------------------------------------------------------------------
/// @brief      The timestamps a pass writes at its own execution boundaries.
///
///             Writes are declared when the pass is created rather than
///             recorded as free floating commands, because backends can only
///             sample counters at stage boundaries.
///
struct TimestampWrites {
  /// The pool the timestamps are written into. It must stay alive until the
  /// GPU has retired the command buffer the pass was recorded into.
  std::shared_ptr<TimestampQueryPool> pool;

  /// The slot written when the GPU begins executing the pass.
  std::optional<size_t> beginning_of_pass_write_index;

  /// The slot written when the GPU finishes executing the pass.
  std::optional<size_t> end_of_pass_write_index;

  /// Whether a pool is present and every requested slot is in range.
  bool IsValid() const;

  /// Whether anything at all would be recorded.
  bool HasWrites() const;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_TIMESTAMP_QUERY_POOL_H_
