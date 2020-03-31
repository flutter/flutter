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

enum class RasterThreadStatus {
  kRemainsMerged,
  kRemainsUnmerged,
  kUnmergedNow
};

class RasterThreadMerger
    : public fml::RefCountedThreadSafe<RasterThreadMerger> {
 public:
  // Merges the raster thread into platform thread for the duration of
  // the lease term. Lease is managed by the caller by either calling
  // |ExtendLeaseTo| or |DecrementLease|.
  // When the caller merges with a lease term of say 2. The threads
  // are going to remain merged until 2 invocations of |DecreaseLease|,
  // unless an |ExtendLeaseTo| gets called.
  void MergeWithLease(size_t lease_term);

  void ExtendLeaseTo(size_t lease_term);

  // Returns |RasterThreadStatus::kUnmergedNow| if this call resulted in
  // splitting the raster and platform threads. Reduces the lease term by 1.
  RasterThreadStatus DecrementLease();

  bool IsMerged() const;

  RasterThreadMerger(fml::TaskQueueId platform_queue_id,
                     fml::TaskQueueId gpu_queue_id);

  // Returns true if the current thread owns rasterizing.
  // When the threads are merged, platform thread owns rasterizing.
  // When un-merged, raster thread owns rasterizing.
  bool IsOnRasterizingThread();

 private:
  static const int kLeaseNotSet;
  fml::TaskQueueId platform_queue_id_;
  fml::TaskQueueId gpu_queue_id_;
  fml::RefPtr<fml::MessageLoopTaskQueues> task_queues_;
  std::atomic_int lease_term_;
  bool is_merged_;

  FML_FRIEND_REF_COUNTED_THREAD_SAFE(RasterThreadMerger);
  FML_FRIEND_MAKE_REF_COUNTED(RasterThreadMerger);
  FML_DISALLOW_COPY_AND_ASSIGN(RasterThreadMerger);
};

}  // namespace fml

#endif  // FML_SHELL_COMMON_TASK_RUNNER_MERGER_H_
