// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_

#include <atomic>

#include "flutter/fml/closure.h"
#include "flutter/fml/task_runner.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/pipeline_compile_queue.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A task queue designed for managing compilation of pipeline state
///             objects for OpenGL ES backend.
///
///             This subclass uses a fml::TaskRunner as the worker task runner
///             and implements a sequential job processing mechanism to prevent
///             blocking the IO task runner.
///
///             Key characteristics:
///             - Uses fml::RefPtr<fml::TaskRunner> for worker_task_runner_
///             - Processes jobs sequentially: loads one job at a time before
///               proceeding to the next, preventing IO task runner blocking
///             - Uses DrainPendingJobs() to recursively process jobs one by one
///             - Employs is_processing_ flag and processing_mutex_ to control
///               sequential processing
///
///             The sequential processing ensures that pipeline compilation jobs
///             do not overwhelm the task runner, which is particularly
///             important for GLES backend where resource loading patterns
///             differ from Vulkan.
///
///             The job counters and the drain report belong to the queue and
///             not to the task runner, because the runner runs any task the
///             engine posts and has no notion of a job. PipelineLibraryGLES
///             starts links in these jobs and has to know when they are the
///             only work left, which is what the drain report says.
///
class PipelineCompileQueueGLES : public PipelineCompileQueue {
 public:
  static std::shared_ptr<PipelineCompileQueueGLES> Create(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  ~PipelineCompileQueueGLES() override;

  PipelineCompileQueueGLES(const PipelineCompileQueueGLES&) = delete;

  PipelineCompileQueueGLES& operator=(const PipelineCompileQueueGLES&) = delete;

  void PostJob(const fml::closure& job) override;

  void OnJobAdded() override;

  //----------------------------------------------------------------------------
  /// @brief      Returns true if the current thread is running a job of this
  ///             queue.
  ///
  ///             PipelineLibraryGLES starts a link in one job and checks it in
  ///             a later job on the same task runner, so it defers a link only
  ///             when this returns true.
  ///
  bool IsRunningJobOnCurrentThread() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns how many jobs of this queue run right now.
  ///
  ///             The GL context belongs to one thread at a time, so
  ///             PipelineLibraryGLES checks in debug builds that its work
  ///             never runs next to another job of the same queue.
  ///
  int RunningJobCount() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns true while the queue works through its jobs.
  ///
  bool IsProcessingJobs() const;

  //----------------------------------------------------------------------------
  /// @brief      Sets the callback that runs on the worker task runner once
  ///             the queue has no jobs left. Passing nullptr clears it.
  ///
  ///             PipelineLibraryGLES checks the links it started from this
  ///             callback, so the driver gets the programs still queued before
  ///             the first status query waits for one. The library also checks
  ///             them earlier when its limit of pending links is reached.
  ///
  void SetOnDrained(fml::closure on_drained);

 private:
  explicit PipelineCompileQueueGLES(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);
  void DrainPendingJobs();

  void NotifyDrained();

  std::shared_ptr<fml::BasicTaskRunner> worker_task_runner_;
  std::atomic<int> running_jobs_ = 0;
  mutable Mutex processing_mutex_;
  bool is_processing_ IPLR_GUARDED_BY(processing_mutex_) = false;
  Mutex on_drained_mutex_;
  fml::closure on_drained_ IPLR_GUARDED_BY(on_drained_mutex_);
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
