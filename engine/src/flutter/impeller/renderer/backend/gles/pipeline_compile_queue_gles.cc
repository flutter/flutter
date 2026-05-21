// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

std::shared_ptr<PipelineCompileQueueGLES> PipelineCompileQueueGLES::Create(
    fml::RefPtr<fml::TaskRunner> worker_task_runner) {
  return std::shared_ptr<PipelineCompileQueueGLES>(
      new PipelineCompileQueueGLES(std::move(worker_task_runner)));
}

PipelineCompileQueueGLES::PipelineCompileQueueGLES(
    fml::RefPtr<fml::TaskRunner> worker_task_runner)
    : worker_task_runner_(std::move(worker_task_runner)) {}

// The base class destructor calls FinishAllJobs() which drains any remaining
// pending jobs on the current thread. If a ProcessJobsSequentially task is
// still in flight on the IO thread, the weak_from_this() capture in the
// posted lambda will safely return nullptr and the task will be a no-op.
// Any jobs already taken from the queue by the IO thread will still execute,
// but this is safe because they capture weak references to the pipeline
// library (not to this compile queue).
PipelineCompileQueueGLES::~PipelineCompileQueueGLES() = default;

void PipelineCompileQueueGLES::OnJobAdded() {
  Lock lock(processing_mutex_);
  if (!is_processing_) {
    is_processing_ = true;
    ProcessJobsSequentially();
  }
}

void PipelineCompileQueueGLES::PostJob(const fml::closure& job) {
  if (!job) {
    return;
  }
  if (worker_task_runner_) {
    worker_task_runner_->PostTask(job);
  } else {
    // No task runner available, execute synchronously on the current thread.
    // This is safe in Playground/test environments where the current thread
    // is the GL thread.
    job();
  }
}

void PipelineCompileQueueGLES::ProcessJobsSequentially() {
  PostJob([weak_queue = weak_from_this()]() {
    if (auto queue = std::static_pointer_cast<PipelineCompileQueueGLES>(
            weak_queue.lock())) {
      queue->DoOneJob();
      {
        Lock lock(queue->processing_mutex_);
        if (!queue->HasPendingJobs()) {
          queue->is_processing_ = false;
          return;
        }
      }
      queue->ProcessJobsSequentially();
    }
  });
}

}  // namespace impeller
