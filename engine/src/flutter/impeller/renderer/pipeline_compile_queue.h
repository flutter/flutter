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
class PipelineCompileQueue
    : public std::enable_shared_from_this<PipelineCompileQueue> {
 public:
  PipelineCompileQueue() = default;

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

 protected:
  //----------------------------------------------------------------------------
  /// @brief      Post a compilation job to the worker task runner.
  ///
  ///             This is a pure virtual function that must be implemented by
  ///             subclasses. It is responsible for actually dispatching the
  ///             job closure to the appropriate task runner for execution.
  ///
  /// @param[in]  job  The compilation job closure to post
  ///
  virtual void PostJob(const fml::closure& job) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Called by PostJobForDescriptor after a job has been
  ///             successfully added to the queue. Subclasses must implement
  ///             this to define their scheduling strategy.
  ///
  ///             The default implementation for duplicate descriptors is to
  ///             run the job eagerly. Subclasses can override this behavior
  ///             by checking for duplicates before calling the base class.
  ///
  virtual void OnJobAdded() = 0;

  //----------------------------------------------------------------------------
  /// @brief      Execute one pending compilation job from the queue.
  ///
  ///             This method retrieves and executes a single job from the
  ///             pending jobs queue. It is typically called by subclasses
  ///             when they are ready to process the next job in the queue.
  ///
  void DoOneJob();

  //----------------------------------------------------------------------------
  /// @brief      Add a compilation job to the pending queue for the specified
  ///             descriptor.
  ///
  /// @param[in]  desc  The pipeline descriptor that identifies the job
  /// @param[in]  job   The compilation job closure to add
  ///
  /// @return     True if the job was successfully added to the queue, false
  ///             if a job for this descriptor already exists.
  ///
  bool AddJob(const PipelineDescriptor& desc, const fml::closure& job);

  //----------------------------------------------------------------------------
  /// @brief      Check if there are any pending compilation jobs in the queue.
  ///
  /// @return     True if there are pending jobs waiting to be processed,
  ///             false otherwise.
  ///
  bool HasPendingJobs();

 private:
  Mutex pending_jobs_mutex_;
  std::unordered_map<PipelineDescriptor,
                     fml::closure,
                     ComparableHash<PipelineDescriptor>,
                     ComparableEqual<PipelineDescriptor>>
      pending_jobs_ IPLR_GUARDED_BY(pending_jobs_mutex_);
  size_t priorities_elevated_ = {};
  fml::closure TakeJob(const PipelineDescriptor& desc);
  fml::closure TakeNextJob();
  void FinishAllJobs();
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_PIPELINE_COMPILE_QUEUE_H_
