// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_

#include <atomic>

#include "flutter/fml/closure.h"
#include "flutter/fml/task_runner.h"
#include "impeller/renderer/pipeline_compile_queue.h"

namespace impeller {

class PipelineCompileQueueGLES : public PipelineCompileQueue {
 public:
  static std::shared_ptr<PipelineCompileQueueGLES> Create(
      fml::RefPtr<fml::TaskRunner> worker_task_runner);

  explicit PipelineCompileQueueGLES(
      fml::RefPtr<fml::TaskRunner> worker_task_runner);

  ~PipelineCompileQueueGLES() override;

  PipelineCompileQueueGLES(const PipelineCompileQueueGLES&) = delete;

  PipelineCompileQueueGLES& operator=(const PipelineCompileQueueGLES&) = delete;

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
                            const fml::closure& job) override;

  //----------------------------------------------------------------------------
  /// @brief      Post a job to the worker task runner.
  ///
  /// @param[in]  job   The job
  ///
  void PostJob(const fml::closure& job) override;

  void ProcessJobsSequentially();

 private:
  fml::RefPtr<fml::TaskRunner> worker_task_runner_;
  std::atomic<bool> is_processing_{false};
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
