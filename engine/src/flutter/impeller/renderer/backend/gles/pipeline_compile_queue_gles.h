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

class PipelineCompileQueueGLES : public PipelineCompileQueue {
 public:
  static std::shared_ptr<PipelineCompileQueueGLES> Create(
      fml::RefPtr<fml::TaskRunner> worker_task_runner);

  explicit PipelineCompileQueueGLES(
      fml::RefPtr<fml::TaskRunner> worker_task_runner);

  ~PipelineCompileQueueGLES() override;

  PipelineCompileQueueGLES(const PipelineCompileQueueGLES&) = delete;

  PipelineCompileQueueGLES& operator=(const PipelineCompileQueueGLES&) = delete;

  void PostJob(const fml::closure& job) override;

  void OnJobAdded() override;

 private:
  void DrainPendingJobs();

  fml::RefPtr<fml::TaskRunner> worker_task_runner_;
  Mutex processing_mutex_;
  bool is_processing_ IPLR_GUARDED_BY(processing_mutex_) = false;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
