// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_GPU_SUBMISSION_TRACKER_H_
#define FLUTTER_IMPELLER_CORE_GPU_SUBMISSION_TRACKER_H_

#include <cstdint>
#include <memory>
#include <utility>
#include <vector>

#include "impeller/base/thread.h"

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
  mutable Mutex mutex_;
  uint64_t last_id_ IPLR_GUARDED_BY(mutex_) = 0;
  // Sorted, since ids are recorded in increasing order. The pending count
  // tracks GPU queue depth and stays small, so erasure is cheap and steady
  // state performs no heap allocation.
  std::vector<uint64_t> pending_ IPLR_GUARDED_BY(mutex_);
};

/// @brief RAII handle for a queued or in-flight GPU submission recorded in a
///        [GpuSubmissionTracker].
///
/// Calling [Complete] or destroying a live handle calls
/// [GpuSubmissionTracker::RecordCompletion] for the recorded id if it has not
/// already been completed.
class PendingGpuSubmission {
 public:
  PendingGpuSubmission() = default;

  explicit PendingGpuSubmission(std::shared_ptr<GpuSubmissionTracker> tracker)
      : tracker_(std::move(tracker)),
        id_(tracker_ ? tracker_->RecordSubmission() : 0) {}

  ~PendingGpuSubmission() { Complete(); }

  PendingGpuSubmission(const PendingGpuSubmission&) = delete;
  PendingGpuSubmission& operator=(const PendingGpuSubmission&) = delete;

  PendingGpuSubmission(PendingGpuSubmission&& other) noexcept
      : tracker_(std::move(other.tracker_)), id_(std::exchange(other.id_, 0)) {}

  PendingGpuSubmission& operator=(PendingGpuSubmission&& other) noexcept {
    if (this != &other) {
      Complete();
      tracker_ = std::move(other.tracker_);
      id_ = std::exchange(other.id_, 0);
    }
    return *this;
  }

  bool IsPending() const { return tracker_ != nullptr; }

  uint64_t GetId() const { return id_; }

  const std::shared_ptr<GpuSubmissionTracker>& GetTracker() const {
    return tracker_;
  }

  /// Marks the recorded submission as completed if it is still pending.
  void Complete() {
    if (tracker_) {
      tracker_->RecordCompletion(id_);
      tracker_.reset();
      id_ = 0;
    }
  }

 private:
  std::shared_ptr<GpuSubmissionTracker> tracker_;
  uint64_t id_ = 0;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_CORE_GPU_SUBMISSION_TRACKER_H_
