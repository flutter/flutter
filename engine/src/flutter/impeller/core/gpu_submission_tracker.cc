// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/gpu_submission_tracker.h"

#include <algorithm>

namespace impeller {

uint64_t GpuSubmissionTracker::RecordSubmission() {
  Lock lock(mutex_);
  uint64_t id = ++last_id_;
  pending_.push_back(id);
  return id;
}

void GpuSubmissionTracker::RecordCompletion(uint64_t id) {
  Lock lock(mutex_);
  auto it = std::lower_bound(pending_.begin(), pending_.end(), id);
  if (it != pending_.end() && *it == id) {
    pending_.erase(it);
  }
}

uint64_t GpuSubmissionTracker::CompletedThrough() const {
  Lock lock(mutex_);
  if (pending_.empty()) {
    return last_id_;
  }
  return pending_.front() - 1;
}

uint64_t GpuSubmissionTracker::LatestSubmission() const {
  Lock lock(mutex_);
  return last_id_;
}

}  // namespace impeller
