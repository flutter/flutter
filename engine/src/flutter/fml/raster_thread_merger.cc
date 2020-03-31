// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/raster_thread_merger.h"
#include "flutter/fml/message_loop_impl.h"

namespace fml {

const int RasterThreadMerger::kLeaseNotSet = -1;

RasterThreadMerger::RasterThreadMerger(fml::TaskQueueId platform_queue_id,
                                       fml::TaskQueueId gpu_queue_id)
    : platform_queue_id_(platform_queue_id),
      gpu_queue_id_(gpu_queue_id),
      task_queues_(fml::MessageLoopTaskQueues::GetInstance()),
      lease_term_(kLeaseNotSet) {
  is_merged_ = task_queues_->Owns(platform_queue_id_, gpu_queue_id_);
}

void RasterThreadMerger::MergeWithLease(size_t lease_term) {
  FML_DCHECK(lease_term > 0) << "lease_term should be positive.";
  if (!is_merged_) {
    is_merged_ = task_queues_->Merge(platform_queue_id_, gpu_queue_id_);
    lease_term_ = lease_term;
  }
}

bool RasterThreadMerger::IsOnRasterizingThread() {
  const auto current_queue_id = MessageLoop::GetCurrentTaskQueueId();
  if (is_merged_) {
    return current_queue_id == platform_queue_id_;
  } else {
    return current_queue_id == gpu_queue_id_;
  }
}

void RasterThreadMerger::ExtendLeaseTo(size_t lease_term) {
  FML_DCHECK(lease_term > 0) << "lease_term should be positive.";
  if (lease_term_ != kLeaseNotSet && (int)lease_term > lease_term_) {
    lease_term_ = lease_term;
  }
}

bool RasterThreadMerger::IsMerged() const {
  return is_merged_;
}

RasterThreadStatus RasterThreadMerger::DecrementLease() {
  if (!is_merged_) {
    return RasterThreadStatus::kRemainsUnmerged;
  }

  // we haven't been set to merge.
  if (lease_term_ == kLeaseNotSet) {
    return RasterThreadStatus::kRemainsUnmerged;
  }

  FML_DCHECK(lease_term_ > 0)
      << "lease_term should always be positive when merged.";
  lease_term_--;
  if (lease_term_ == 0) {
    bool success = task_queues_->Unmerge(platform_queue_id_);
    FML_CHECK(success) << "Unable to un-merge the raster and platform threads.";
    is_merged_ = false;
    return RasterThreadStatus::kUnmergedNow;
  }

  return RasterThreadStatus::kRemainsMerged;
}

}  // namespace fml
