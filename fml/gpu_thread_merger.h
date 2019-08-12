// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FML_SHELL_COMMON_TASK_RUNNER_MERGER_H_
#define FML_SHELL_COMMON_TASK_RUNNER_MERGER_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/message_loop_task_queues.h"

namespace fml {

class MessageLoopImpl;

enum class GpuThreadStatus { kRemainsMerged, kRemainsUnmerged, kUnmergedNow };

class GpuThreadMerger : public fml::RefCountedThreadSafe<GpuThreadMerger> {
 public:
  // Merges the GPU thread into platform thread for the duration of
  // the lease term. Lease is managed by the caller by either calling
  // |ExtendLeaseTo| or |DecrementLease|.
  // When the caller merges with a lease term of say 2. The threads
  // are going to remain merged until 2 invocations of |DecreaseLease|,
  // unless an |ExtendLeaseTo| gets called.
  void MergeWithLease(size_t lease_term);

  void ExtendLeaseTo(size_t lease_term);

  // Returns |GpuThreadStatus::kUnmergedNow| if this call resulted in splitting
  // the GPU and platform threads. Reduces the lease term by 1.
  GpuThreadStatus DecrementLease();

  bool IsMerged() const;

  GpuThreadMerger(fml::TaskQueueId platform_queue_id,
                  fml::TaskQueueId gpu_queue_id);

  // Returns true if the the current thread owns rasterizing.
  // When the threads are merged, platform thread owns rasterizing.
  // When un-merged, gpu thread owns rasterizing.
  bool IsOnRasterizingThread();

 private:
  static const int kLeaseNotSet;
  fml::TaskQueueId platform_queue_id_;
  fml::TaskQueueId gpu_queue_id_;
  fml::RefPtr<fml::MessageLoopTaskQueues> task_queues_;
  std::atomic_int lease_term_;
  bool is_merged_;

  FML_FRIEND_REF_COUNTED_THREAD_SAFE(GpuThreadMerger);
  FML_FRIEND_MAKE_REF_COUNTED(GpuThreadMerger);
  FML_DISALLOW_COPY_AND_ASSIGN(GpuThreadMerger);
};

}  // namespace fml

#endif  // FML_SHELL_COMMON_TASK_RUNNER_MERGER_H_
