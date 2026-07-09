// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_GPU_SUBMISSION_TRACKER_H_
#define FLUTTER_IMPELLER_CORE_GPU_SUBMISSION_TRACKER_H_

#include <cstdint>
#include <mutex>
#include <vector>

#include "impeller/base/thread_safety.h"

namespace impeller {

/// @brief Tracks GPU completion of submitted command buffers as a monotonic
///        watermark.
///
/// Backends record an id for each submitted command buffer and mark it from
/// the command buffer's completion callback. Consumers compare ids against
/// [CompletedThrough] to find out whether the GPU is done with all work
/// submitted up to a point in time, regardless of the order in which
/// individual command buffers complete.
///
/// All methods are thread safe.
class GpuSubmissionTracker {
 public:
  /// Records a command buffer submission and returns its id.
  uint64_t RecordSubmission();

  /// Marks a previously recorded submission as completed by the GPU.
  void RecordCompletion(uint64_t id);

  /// Returns the highest id such that all submissions with ids up to and
  /// including it have completed.
  uint64_t CompletedThrough() const;

  /// Returns the id of the most recent submission.
  uint64_t LatestSubmission() const;

 private:
  mutable std::mutex mutex_;
  uint64_t last_id_ IPLR_GUARDED_BY(mutex_) = 0;
  // Sorted, since ids are recorded in increasing order. The pending count
  // tracks GPU queue depth and stays small, so erasure is cheap and steady
  // state performs no heap allocation.
  std::vector<uint64_t> pending_ IPLR_GUARDED_BY(mutex_);
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_CORE_GPU_SUBMISSION_TRACKER_H_
