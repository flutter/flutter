// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

std::shared_ptr<PipelineCompileQueueGLES> PipelineCompileQueueGLES::Create(
    fml::RefPtr<fml::TaskRunner> task_runner) {
  return std::shared_ptr<PipelineCompileQueueGLES>(
      new PipelineCompileQueueGLES(std::move(task_runner)));
}

PipelineCompileQueueGLES::PipelineCompileQueueGLES(
    fml::RefPtr<fml::TaskRunner> task_runner)
    : PipelineCompileQueue(nullptr), task_runner_(std::move(task_runner)) {}

PipelineCompileQueueGLES::~PipelineCompileQueueGLES() {
  FinishAllJobs();
}

bool PipelineCompileQueueGLES::PostJobForDescriptor(
    const PipelineDescriptor& desc,
    const fml::closure& job) {
  if (!job) {
    return false;
  }

  {
    Lock lock(pending_jobs_mutex_);
    auto insertion_result = pending_jobs_.insert(std::make_pair(desc, job));
    if (!insertion_result.second) {
      // This bit is being extremely conservative. If insertion did not take
      // place, someone gave the compile queue a job for the same description.
      // This is highly unusual but technically not impossible. Just run the job
      // eagerly.
      FML_LOG(ERROR) << "Got multiple compile jobs for the same descriptor. "
                        "Running eagerly.";
      // Don't invoke the job here has there are we have currently acquired a
      // mutex.
      task_runner_->PostTask(job);
      return true;
    }
  }

  task_runner_->PostTask([weak_queue = weak_from_this()]() {
    if (auto queue = std::static_pointer_cast<PipelineCompileQueueGLES>(
            weak_queue.lock())) {
      queue->DoOneJob();
    }
  });
  return true;
}

}  // namespace impeller
