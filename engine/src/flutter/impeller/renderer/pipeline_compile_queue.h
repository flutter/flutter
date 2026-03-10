// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_PIPELINE_COMPILE_QUEUE_H_
#define FLUTTER_IMPELLER_RENDERER_PIPELINE_COMPILE_QUEUE_H_

#include <unordered_map>

#include "flutter/fml/closure.h"
#include "flutter/fml/concurrent_message_loop.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A task queue designed for managing compilation of pipeline state
///             objects.
///
///             The task queue attempts to perform compile jobs as quickly as
///             possible by dispatching tasks to a concurrent task runner. These
///             tasks are dispatched during renderer creation and usually
///             complete before the first frame is rendered. In this ideal case,
///             this queue is entirely unnecessary and and serves as a thin
///             wrapper around just posting the compile jobs to a concurrent
///             task runner.
///
///             If however, usually on lower end device, the compile jobs cannot
///             be completed before the first frame is rendered, the implicit
///             act of waiting for the compile job to be done can instead be
///             augmented to take the pending job and perform it eagerly on the
///             waiters thread. This effectively turns an idle wait into the job
///             skipping to the front of the line and being done on the callers
///             thread.
///
///             Again, the entire point of this class is the reduce startup
///             times on the lowest end devices. On high end device, a queue is
///             entirely optional. The queue skipping mechanism all assume the
///             optional availability of a compile queue.
///
class PipelineCompileQueue final
    : public std::enable_shared_from_this<PipelineCompileQueue> {
 public:
  static std::shared_ptr<PipelineCompileQueue> Create(
      std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner);

  virtual ~PipelineCompileQueue();

  PipelineCompileQueue(const PipelineCompileQueue&) = delete;

  PipelineCompileQueue& operator=(const PipelineCompileQueue&) = delete;

  //----------------------------------------------------------------------------
  /// @brief      Post a compile job for the specified descriptor.
  ///
  /// @param[in]  desc  The description
  /// @param[in]  job   The job
  ///
  /// @return     If the job was successfully posted to the parallel task
  /// runners.
  ///
  bool PostJobForDescriptor(const PipelineDescriptor& desc,
                            const fml::closure& job);

  //----------------------------------------------------------------------------
  /// @brief      If the task has not yet been done, perform it eagerly on the
  ///             calling thread. This can be used in lieu of an idle wait for
  ///             the task completion on the calling thread.
  ///
  /// @param[in]  desc  The description
  ///
  void PerformJobEagerly(const PipelineDescriptor& desc);

 private:
  std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner_;
  Mutex pending_jobs_mutex_;
  size_t priorities_elevated_ = {};

  std::unordered_map<PipelineDescriptor,
                     fml::closure,
                     ComparableHash<PipelineDescriptor>,
                     ComparableEqual<PipelineDescriptor>>
      pending_jobs_ IPLR_GUARDED_BY(pending_jobs_mutex_);

  explicit PipelineCompileQueue(
      std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner);

  fml::closure TakeJob(const PipelineDescriptor& desc);

  fml::closure TakeNextJob();

  void DoOneJob();

  void FinishAllJobs();
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_PIPELINE_COMPILE_QUEUE_H_
