// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"

#include <atomic>

#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"

namespace impeller {

namespace {
// The queue whose job this thread runs right now. Two engines in one process
// have a queue each, so the queue is part of the answer.
thread_local const PipelineCompileQueueGLES* tls_running_queue = nullptr;
}  // namespace

int PipelineCompileQueueGLES::RunningJobCount() const {
  return running_jobs_.load();
}

bool PipelineCompileQueueGLES::IsRunningJobOnCurrentThread() const {
  return tls_running_queue == this;
}

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

  worker_task_runner_->PostTask([job, weak_queue = weak_from_this()]() {
    auto queue =
        std::static_pointer_cast<PipelineCompileQueueGLES>(weak_queue.lock());
    if (!queue) {
      // The queue is gone, so there is nothing to account the job to, and the
      // job still runs as it did before.
      job();
      return;
    }
    const PipelineCompileQueueGLES* previous = tls_running_queue;
    tls_running_queue = queue.get();
    queue->running_jobs_.fetch_add(1);
    fml::ScopedCleanupClosure restore([&queue, previous]() {
      queue->running_jobs_.fetch_sub(1);
      tls_running_queue = previous;
    });
    job();
  });
}

bool PipelineCompileQueueGLES::IsProcessingJobs() const {
  Lock lock(processing_mutex_);
  return is_processing_;
}

void PipelineCompileQueueGLES::SetOnDrained(fml::closure on_drained) {
  Lock lock(on_drained_mutex_);
  on_drained_ = std::move(on_drained);
}

void PipelineCompileQueueGLES::NotifyDrained() {
  fml::closure on_drained;
  {
    Lock lock(on_drained_mutex_);
    on_drained = on_drained_;
  }
  if (on_drained) {
    on_drained();
  }
}

void PipelineCompileQueueGLES::DrainPendingJobs() {
  PostJob([weak_queue = weak_from_this()]() {
    if (auto queue = std::static_pointer_cast<PipelineCompileQueueGLES>(
            weak_queue.lock())) {
      queue->DoOneJob();
      bool drained = false;
      {
        Lock lock(queue->processing_mutex_);
        if (!queue->HasPendingJobs()) {
          queue->is_processing_ = false;
          drained = true;
        }
      }
      if (drained) {
        queue->NotifyDrained();
        return;
      }
      queue->DrainPendingJobs();
    }
  });
}

}  // namespace impeller
