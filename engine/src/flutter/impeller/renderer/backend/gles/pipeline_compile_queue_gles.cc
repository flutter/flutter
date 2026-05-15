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

PipelineCompileQueueGLES::~PipelineCompileQueueGLES() {}

bool PipelineCompileQueueGLES::PostJobForDescriptor(
    const PipelineDescriptor& desc,
    const fml::closure& job) {
  if (!job) {
    return false;
  }

  if (!AddJob(desc, job)) {
    // This bit is being extremely conservative. If insertion did not take
    // place, someone gave the compile queue a job for the same description.
    // This is highly unusual but technically not impossible. Just run the job
    // eagerly.
    FML_LOG(ERROR) << "Got multiple compile jobs for the same descriptor. "
                      "Running eagerly.";
    PostJob(job);
    return true;
  }

  bool expected = false;
  if (is_processing_.compare_exchange_strong(expected, true)) {
    ProcessJobsSequentially();
  }
  return true;
}

void PipelineCompileQueueGLES::PostJob(const fml::closure& job) {
  if (!job) {
    return;
  }

  worker_task_runner_->PostTask(job);
}

void PipelineCompileQueueGLES::ProcessJobsSequentially() {
  PostJob([weak_queue = weak_from_this()]() {
    if (auto queue = std::static_pointer_cast<PipelineCompileQueueGLES>(
            weak_queue.lock())) {
      queue->DoOneJob();
      if (!queue->HasPendingJobs()) {
        queue->is_processing_ = false;
        return;
      }
      queue->ProcessJobsSequentially();
    }
  });
}

}  // namespace impeller
