// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FML_SHELL_COMMON_TASK_RUNNER_MERGER_H_
#define FML_SHELL_COMMON_TASK_RUNNER_MERGER_H_

#include <condition_variable>
#include <mutex>

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
  //
  // If the task queues are the same, we consider them statically merged.
  // When task queues are statically merged this method becomes no-op.
  void MergeWithLease(size_t lease_term);

  // Un-merges the threads now, and resets the lease term to 0.
  //
  // Must be executed on the raster task runner.
  //
  // If the task queues are the same, we consider them statically merged.
  // When task queues are statically merged, we never unmerge them and
  // this method becomes no-op.
  void UnMergeNow();

  // If the task queues are the same, we consider them statically merged.
  // When task queues are statically merged this method becomes no-op.
  void ExtendLeaseTo(size_t lease_term);

  // Returns |RasterThreadStatus::kUnmergedNow| if this call resulted in
  // splitting the raster and platform threads. Reduces the lease term by 1.
  //
  // If the task queues are the same, we consider them statically merged.
  // When task queues are statically merged this method becomes no-op.
  RasterThreadStatus DecrementLease();

  bool IsMerged();

  // Waits until the threads are merged.
  //
  // Must run on the platform task runner.
  void WaitUntilMerged();

  RasterThreadMerger(fml::TaskQueueId platform_queue_id,
                     fml::TaskQueueId gpu_queue_id);

  // Returns true if the current thread owns rasterizing.
  // When the threads are merged, platform thread owns rasterizing.
  // When un-merged, raster thread owns rasterizing.
  bool IsOnRasterizingThread() const;

  // Returns true if the current thread is the platform thread.
  bool IsOnPlatformThread() const;

  // Enables the thread merger.
  void Enable();

  // Disables the thread merger. Once disabled, any call to
  // |MergeWithLease| or |UnMergeNow| results in a noop.
  void Disable();

  // Whether the thread merger is enabled. By default, the thread merger is
  // enabled. If false, calls to |MergeWithLease| or |UnMergeNow| results in a
  // noop.
  bool IsEnabled();

  // Registers a callback that can be used to clean up global state right after
  // the thread configuration has changed.
  //
  // For example, it can be used to clear the GL context so it can be used in
  // the next task from a different thread.
  void SetMergeUnmergeCallback(const fml::closure& callback);

 private:
  static const int kLeaseNotSet;
  fml::TaskQueueId platform_queue_id_;
  fml::TaskQueueId gpu_queue_id_;
  fml::RefPtr<fml::MessageLoopTaskQueues> task_queues_;
  std::atomic_int lease_term_;
  std::condition_variable merged_condition_;
  std::mutex lease_term_mutex_;
  fml::closure merge_unmerge_callback_;
  bool enabled_;

  bool IsMergedUnSafe() const;

  bool IsEnabledUnSafe() const;

  // The platform_queue_id and gpu_queue_id are exactly the same.
  // We consider the threads are always merged and cannot be unmerged.
  bool TaskQueuesAreSame() const;

  FML_FRIEND_REF_COUNTED_THREAD_SAFE(RasterThreadMerger);
  FML_FRIEND_MAKE_REF_COUNTED(RasterThreadMerger);
  FML_DISALLOW_COPY_AND_ASSIGN(RasterThreadMerger);
};

}  // namespace fml

#endif  // FML_SHELL_COMMON_TASK_RUNNER_MERGER_H_
