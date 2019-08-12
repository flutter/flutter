// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/gpu_thread_merger.h"
#include "flutter/fml/message_loop_impl.h"

namespace fml {

const int GpuThreadMerger::kLeaseNotSet = -1;

GpuThreadMerger::GpuThreadMerger(fml::TaskQueueId platform_queue_id,
                                 fml::TaskQueueId gpu_queue_id)
    : platform_queue_id_(platform_queue_id),
      gpu_queue_id_(gpu_queue_id),
      task_queues_(fml::MessageLoopTaskQueues::GetInstance()),
      lease_term_(kLeaseNotSet) {
  is_merged_ = task_queues_->Owns(platform_queue_id_, gpu_queue_id_);
}

void GpuThreadMerger::MergeWithLease(size_t lease_term) {
  FML_DCHECK(lease_term > 0) << "lease_term should be positive.";
  if (!is_merged_) {
    is_merged_ = task_queues_->Merge(platform_queue_id_, gpu_queue_id_);
    lease_term_ = lease_term;
  }
}

bool GpuThreadMerger::IsOnRasterizingThread() {
  const auto current_queue_id = MessageLoop::GetCurrentTaskQueueId();
  if (is_merged_) {
    return current_queue_id == platform_queue_id_;
  } else {
    return current_queue_id == gpu_queue_id_;
  }
}

void GpuThreadMerger::ExtendLeaseTo(size_t lease_term) {
  FML_DCHECK(lease_term > 0) << "lease_term should be positive.";
  if (lease_term_ != kLeaseNotSet && (int)lease_term > lease_term_) {
    lease_term_ = lease_term;
  }
}

bool GpuThreadMerger::IsMerged() const {
  return is_merged_;
}

GpuThreadStatus GpuThreadMerger::DecrementLease() {
  if (!is_merged_) {
    return GpuThreadStatus::kRemainsUnmerged;
  }

  // we haven't been set to merge.
  if (lease_term_ == kLeaseNotSet) {
    return GpuThreadStatus::kRemainsUnmerged;
  }

  FML_DCHECK(lease_term_ > 0)
      << "lease_term should always be positive when merged.";
  lease_term_--;
  if (lease_term_ == 0) {
    bool success = task_queues_->Unmerge(platform_queue_id_);
    FML_CHECK(success) << "Unable to un-merge the GPU and platform threads.";
    is_merged_ = false;
    return GpuThreadStatus::kUnmergedNow;
  }

  return GpuThreadStatus::kRemainsMerged;
}

}  // namespace fml
