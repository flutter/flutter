// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_

#include <memory>

#include "flutter/fml/task_runner.h"
#include "impeller/base/comparable.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "third_party/abseil-cpp/absl/container/linked_hash_map.h"
#include "third_party/abseil-cpp/absl/status/status.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A task queue designed for managing compilation of pipeline state
///             objects for OpenGL ES backend.
///
///             Jobs are performed in two steps, `Start` and `Finish`, so that
///             several jobs can be compiling at once. Up to
///             `max_active_jobs` jobs are started, in insertion order, before
///             the oldest started job is finished.
///
///             At most one task is outstanding on the worker task runner at a
///             time, and each task performs a single step before scheduling
///             the next one. This prevents pipeline compilation from
///             monopolizing the worker (IO) task runner, letting other tasks
///             interleave between steps.
///
class PipelineCompileQueueGLES final
    : public std::enable_shared_from_this<PipelineCompileQueueGLES> {
 public:
  //----------------------------------------------------------------------------
  /// @brief      A compile job, performed in two steps that are always run in
  ///             order on the same thread.
  ///
  class CompileJob {
   public:
    virtual ~CompileJob() = default;

    //--------------------------------------------------------------------------
    /// @brief      Starts the job.
    ///
    /// @return     An error if the job failed, in which case `Finish` is not
    ///             called.
    ///
    virtual absl::Status Start() = 0;

    //--------------------------------------------------------------------------
    /// @brief      Finishes the job. Only called if `Start` succeeded.
    ///
    virtual absl::Status Finish() = 0;
  };

  /// The default maximum number of jobs that are started but not yet finished.
  static constexpr size_t kDefaultMaxActiveJobs = 4;

  static std::shared_ptr<PipelineCompileQueueGLES> Create(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner,
      size_t max_active_jobs = kDefaultMaxActiveJobs);

  ~PipelineCompileQueueGLES();

  PipelineCompileQueueGLES(const PipelineCompileQueueGLES&) = delete;

  PipelineCompileQueueGLES& operator=(const PipelineCompileQueueGLES&) = delete;

  //----------------------------------------------------------------------------
  /// @brief      Post a compile job for the specified descriptor.
  ///
  /// @param[in]  desc  The description
  /// @param[in]  job   The job
  ///
  /// @return     If the job was successfully posted to the worker task runner.
  ///
  bool PostJobForDescriptor(const PipelineDescriptor& desc,
                            std::unique_ptr<CompileJob> job);

  //----------------------------------------------------------------------------
  /// @brief      Ensures the job for the descriptor is done before returning.
  ///             If the job has not been started, it is started and finished
  ///             on the calling thread. If it has been started, the worker is
  ///             told to finish it next and the calling thread waits for that.
  ///             Must not be called on the worker task runner.
  ///
  /// @param[in]  desc  The description
  ///
  void PerformJobEagerly(const PipelineDescriptor& desc);

 private:
  /// A job that has been started on the worker but not yet finished.
  struct ActiveJob {
    std::unique_ptr<CompileJob> job;
    /// Whether a thread is waiting in `PerformJobEagerly` for the job to be
    /// finished.
    bool awaited = false;
  };

  using InactiveJobMap =
      absl::linked_hash_map<PipelineDescriptor,
                            std::unique_ptr<CompileJob>,
                            ComparableHash<PipelineDescriptor>,
                            ComparableEqual<PipelineDescriptor>>;
  using ActiveJobMap =
      absl::linked_hash_map<PipelineDescriptor,
                            ActiveJob,
                            ComparableHash<PipelineDescriptor>,
                            ComparableEqual<PipelineDescriptor>>;

  PipelineCompileQueueGLES(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner,
      size_t max_active_jobs);

  /// Posts a task to the worker that calls `Run`.
  void ScheduleRun();

  /// Performs a single step on the worker. In order of preference: finishes an
  /// active job that a thread is waiting on, starts the oldest inactive job if
  /// there is room for another active job, or finishes the oldest active job.
  /// Schedules itself again until there is no work left.
  void Run();

  /// Returns the oldest active job that a thread is waiting on, or the end of
  /// `active_jobs_` if there is none.
  ActiveJobMap::iterator FindAwaitedActiveJob() IPLR_REQUIRES(mutex_);

  /// Moves the oldest inactive job to the active jobs and returns it.
  ActiveJobMap::iterator ActivateOldestInactiveJob() IPLR_REQUIRES(mutex_);

  /// Starts the active job. Removes it if it fails to start.
  void StartActiveJob(ActiveJobMap::iterator active_job);

  /// Finishes and removes the active job.
  void FinishActiveJob(ActiveJobMap::iterator active_job);

  /// Removes the active job and wakes any threads waiting on it.
  void RemoveActiveJob(ActiveJobMap::iterator active_job);

  /// Starts and finishes the job back to back on the calling thread.
  static void PerformJobImmediately(CompileJob& job);

  std::shared_ptr<fml::BasicTaskRunner> worker_task_runner_;
  const size_t max_active_jobs_;
  Mutex mutex_;
  ConditionVariable active_job_removed_;
  /// Jobs that have not been started, oldest first.
  InactiveJobMap inactive_jobs_ IPLR_GUARDED_BY(mutex_);
  /// Jobs that have been started on the worker but not yet finished, oldest
  /// first. Only `Run`, on the worker, adds or removes entries.
  ActiveJobMap active_jobs_ IPLR_GUARDED_BY(mutex_);
  bool is_processing_ IPLR_GUARDED_BY(mutex_) = false;
  size_t priorities_elevated_ IPLR_GUARDED_BY(mutex_) = 0;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
