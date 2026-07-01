// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"

namespace impeller {

std::shared_ptr<PipelineCompileQueueGLES> PipelineCompileQueueGLES::Create(
    fml::RefPtr<fml::TaskRunner> worker_task_runner) {
  if (!worker_task_runner) {
    return nullptr;
  }
  return std::shared_ptr<PipelineCompileQueueGLES>(
      new PipelineCompileQueueGLES(std::move(worker_task_runner)));
}

PipelineCompileQueueGLES::PipelineCompileQueueGLES(
    fml::RefPtr<fml::TaskRunner> worker_task_runner)
    : worker_task_runner_(std::move(worker_task_runner)) {}

PipelineCompileQueueGLES::~PipelineCompileQueueGLES() = default;

void PipelineCompileQueueGLES::OnJobAdded() {
  // To prevent potential deadlocks and reduce lock contention, avoid calling
  // external or virtual methods (such as DrainPendingJobs, which posts tasks
  // to the task runner) while holding a mutex. Instead, minimize the scope of
  // the lock by using a local boolean flag to trigger the draining process
  // outside the lock block.
  bool should_drain = false;
  {
    Lock lock(processing_mutex_);
    if (!is_processing_) {
      is_processing_ = true;
      should_drain = true;
    }
  }
  if (should_drain) {
    DrainPendingJobs();
  }
}

void PipelineCompileQueueGLES::PostJob(const fml::closure& job) {
  if (!job) {
    return;
  }

  worker_task_runner_->PostTask(job);
}

void PipelineCompileQueueGLES::DrainPendingJobs() {
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
      queue->DrainPendingJobs();
    }
  });
}

}  // namespace impeller
