// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

std::shared_ptr<PipelineCompileQueueGLES> PipelineCompileQueueGLES::Create(
    std::shared_ptr<fml::BasicTaskRunner> worker_task_runner) {
  if (!worker_task_runner) {
    return nullptr;
  }
  return std::shared_ptr<PipelineCompileQueueGLES>(
      new PipelineCompileQueueGLES(std::move(worker_task_runner)));
}

PipelineCompileQueueGLES::PipelineCompileQueueGLES(
    std::shared_ptr<fml::BasicTaskRunner> worker_task_runner)
    : worker_task_runner_(std::move(worker_task_runner)) {}

PipelineCompileQueueGLES::~PipelineCompileQueueGLES() {
  // Flush any jobs still pending. Tasks already posted to the worker only hold
  // a weak reference to the queue and become no-ops.
  while (Job job = TakeNextJob()) {
    job(/*eager=*/true);
  }
}

bool PipelineCompileQueueGLES::PostJobForDescriptor(
    const PipelineDescriptor& desc,
    const Job& job) {
  if (!job) {
    return false;
  }

  bool inserted = false;
  bool should_schedule = false;
  {
    Lock lock(mutex_);
    inserted = pending_jobs_.insert({desc, job}).second;
    should_schedule = inserted && !is_processing_;
    if (should_schedule) {
      is_processing_ = true;
    }
  }

  if (!inserted) {
    // This bit is being extremely conservative. If insertion did not take
    // place, someone gave the compile queue a job for the same descritor. This
    // is highly unusual but technically not impossible. Just run the job
    // eagerly.
    FML_LOG(WARNING) << "Got multiple compile jobs for the same descriptor. "
                        "Running eagerly.";
    worker_task_runner_->PostTask([job]() { job(/*eager=*/false); });
  } else if (should_schedule) {
    ScheduleNextJob();
  }
  return true;
}

void PipelineCompileQueueGLES::PerformJobEagerly(
    const PipelineDescriptor& desc) {
  Job job;
  {
    Lock lock(mutex_);
    auto found = pending_jobs_.find(desc);
    if (found == pending_jobs_.end()) {
      return;
    }
    // The pipeline compile job was somewhere in the task queue. However, a
    // rendering operation needed the job to be done ASAP. Instead of waiting
    // for the pipeline compile queue to eventually get to finishing job, the
    // thread waiting on the job just decided to take the job from the queue and
    // do it itself. If there were jobs ahead of this one, it means that they
    // were mis-prioritized. This counter dumps the number of job
    // re-prioritizations.
    priorities_elevated_++;
    FML_TRACE_COUNTER("impeller", "PipelineCompileQueue",
                      reinterpret_cast<int64_t>(this),  // Trace Counter ID
                      "PrioritiesElevated", priorities_elevated_);
    job = std::move(found->second);
    pending_jobs_.erase(found);
  }
  job(/*eager=*/true);
}

void PipelineCompileQueueGLES::PostTask(const fml::closure& task) {
  worker_task_runner_->PostTask(task);
}

void PipelineCompileQueueGLES::ScheduleNextJob() {
  worker_task_runner_->PostTask([weak_queue = weak_from_this()]() {
    auto queue = weak_queue.lock();
    if (!queue) {
      return;
    }
    if (Job job = queue->TakeNextJob()) {
      job(/*eager=*/false);
      queue->ScheduleNextJob();
    }
  });
}

PipelineCompileQueueGLES::Job PipelineCompileQueueGLES::TakeNextJob() {
  Lock lock(mutex_);
  if (pending_jobs_.empty()) {
    is_processing_ = false;
    return nullptr;
  }
  auto job_iterator = pending_jobs_.begin();
  Job job = std::move(job_iterator->second);
  pending_jobs_.erase(job_iterator);
  return job;
}

}  // namespace impeller
