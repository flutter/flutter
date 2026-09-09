// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_

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
class PipelineCompileQueueGLES : public PipelineCompileQueue {
 public:
  static std::shared_ptr<PipelineCompileQueueGLES> Create(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  ~PipelineCompileQueueGLES() override;

  PipelineCompileQueueGLES(const PipelineCompileQueueGLES&) = delete;

  PipelineCompileQueueGLES& operator=(const PipelineCompileQueueGLES&) = delete;

  void PostJob(const fml::closure& job) override;

  void OnJobAdded() override;

 private:
  explicit PipelineCompileQueueGLES(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);
  void DrainPendingJobs();

  std::shared_ptr<fml::BasicTaskRunner> worker_task_runner_;
  Mutex processing_mutex_;
  bool is_processing_ IPLR_GUARDED_BY(processing_mutex_) = false;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
