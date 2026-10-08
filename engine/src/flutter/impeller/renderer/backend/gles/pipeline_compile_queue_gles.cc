// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"

#include <algorithm>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

std::shared_ptr<PipelineCompileQueueGLES> PipelineCompileQueueGLES::Create(
    std::shared_ptr<fml::BasicTaskRunner> worker_task_runner,
    size_t max_active_jobs) {
  if (!worker_task_runner || max_active_jobs == 0) {
    return nullptr;
  }
  return std::shared_ptr<PipelineCompileQueueGLES>(new PipelineCompileQueueGLES(
      std::move(worker_task_runner), max_active_jobs));
}

PipelineCompileQueueGLES::PipelineCompileQueueGLES(
    std::shared_ptr<fml::BasicTaskRunner> worker_task_runner,
    size_t max_active_jobs)
    : worker_task_runner_(std::move(worker_task_runner)),
      max_active_jobs_(max_active_jobs) {}

PipelineCompileQueueGLES::~PipelineCompileQueueGLES() {
  // Tasks already posted to the worker only hold a weak reference to the queue
  // and become no-ops.
  InactiveJobMap inactive_jobs;
  ActiveJobMap active_jobs;
  {
    Lock lock(mutex_);
    inactive_jobs.swap(inactive_jobs_);
    active_jobs.swap(active_jobs_);
  }
  // Flush any jobs that haven't been started.
  for (auto& [desc, job] : inactive_jobs) {
    PerformJobImmediately(*job);
  }
  // Jobs that have been started must be finished on the worker, the thread
  // that started them.
  for (auto& [desc, active_job] : active_jobs) {
    worker_task_runner_->PostTask(
        [job = std::shared_ptr<CompileJob>(std::move(active_job.job))]() {
          // Jobs report their own errors.
          job->Finish().IgnoreError();
        });
  }
}

bool PipelineCompileQueueGLES::PostJobForDescriptor(
    const PipelineDescriptor& desc,
    std::unique_ptr<CompileJob> job) {
  if (!job) {
    return false;
  }

  bool is_duplicate = false;
  bool should_schedule = false;
  {
    Lock lock(mutex_);
    is_duplicate = inactive_jobs_.contains(desc) || active_jobs_.contains(desc);
    if (!is_duplicate) {
      inactive_jobs_.try_emplace(desc, std::move(job));
      should_schedule = !is_processing_;
      is_processing_ = true;
    }
  }

  if (is_duplicate) {
    // This bit is being extremely conservative. If insertion did not take
    // place, someone gave the compile queue a job for the same descritor. This
    // is highly unusual but technically not impossible. Just run the job
    // eagerly.
    FML_LOG(WARNING) << "Got multiple compile jobs for the same descriptor. "
                        "Running eagerly.";
    worker_task_runner_->PostTask(
        [job = std::shared_ptr<CompileJob>(std::move(job))]() {
          PerformJobImmediately(*job);
        });
  } else if (should_schedule) {
    ScheduleRun();
  }
  return true;
}

void PipelineCompileQueueGLES::PerformJobEagerly(
    const PipelineDescriptor& desc) {
  std::unique_ptr<CompileJob> job;
  {
    Lock lock(mutex_);
    InactiveJobMap::iterator found = inactive_jobs_.find(desc);
    if (found == inactive_jobs_.end()) {
      ActiveJobMap::iterator active_job = active_jobs_.find(desc);
      if (active_job == active_jobs_.end()) {
        return;
      }
      // A job that has been started must be finished by the worker, the
      // thread that started it. Have the worker finish it next and wait for
      // that.
      active_job->second.awaited = true;
      active_job_removed_.Wait(mutex_, [&]() IPLR_REQUIRES(mutex_) {
        return !active_jobs_.contains(desc);
      });
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
    inactive_jobs_.erase(found);
  }
  PerformJobImmediately(*job);
}

void PipelineCompileQueueGLES::ScheduleRun() {
  worker_task_runner_->PostTask([weak_queue = weak_from_this()]() {
    if (std::shared_ptr<PipelineCompileQueueGLES> queue = weak_queue.lock()) {
      queue->Run();
    }
  });
}

void PipelineCompileQueueGLES::Run() {
  ActiveJobMap::iterator active_job;
  bool should_start = false;
  {
    Lock lock(mutex_);
    if (ActiveJobMap::iterator awaited_job = FindAwaitedActiveJob();
        awaited_job != active_jobs_.end()) {
      active_job = awaited_job;
    } else if (active_jobs_.size() < max_active_jobs_ &&
               !inactive_jobs_.empty()) {
      active_job = ActivateOldestInactiveJob();
      should_start = true;
    } else if (!active_jobs_.empty()) {
      active_job = active_jobs_.begin();
    } else {
      is_processing_ = false;
      return;
    }
  }
  // Only this method adds or removes active jobs, so the iterator remains
  // valid while the job is started or finished outside of the lock.
  if (should_start) {
    StartActiveJob(active_job);
  } else {
    FinishActiveJob(active_job);
  }
  ScheduleRun();
}

PipelineCompileQueueGLES::ActiveJobMap::iterator
PipelineCompileQueueGLES::FindAwaitedActiveJob() {
  return std::find_if(active_jobs_.begin(), active_jobs_.end(),
                      [](const ActiveJobMap::value_type& entry) {
                        return entry.second.awaited;
                      });
}

PipelineCompileQueueGLES::ActiveJobMap::iterator
PipelineCompileQueueGLES::ActivateOldestInactiveJob() {
  InactiveJobMap::iterator inactive_job = inactive_jobs_.begin();
  ActiveJobMap::iterator active_job =
      active_jobs_
          .try_emplace(inactive_job->first,
                       ActiveJob{.job = std::move(inactive_job->second)})
          .first;
  inactive_jobs_.erase(inactive_job);
  return active_job;
}

void PipelineCompileQueueGLES::StartActiveJob(
    ActiveJobMap::iterator active_job) {
  if (!active_job->second.job->Start().ok()) {
    RemoveActiveJob(active_job);
  }
}

void PipelineCompileQueueGLES::FinishActiveJob(
    ActiveJobMap::iterator active_job) {
  // Jobs report their own errors.
  active_job->second.job->Finish().IgnoreError();
  RemoveActiveJob(active_job);
}

void PipelineCompileQueueGLES::RemoveActiveJob(
    ActiveJobMap::iterator active_job) {
  std::unique_ptr<CompileJob> job;
  {
    Lock lock(mutex_);
    job = std::move(active_job->second.job);
    active_jobs_.erase(active_job);
  }
  active_job_removed_.NotifyAll();
}

void PipelineCompileQueueGLES::PerformJobImmediately(CompileJob& job) {
  if (!job.Start().ok()) {
    return;
  }
  // Jobs report their own errors.
  job.Finish().IgnoreError();
}

}  // namespace impeller
