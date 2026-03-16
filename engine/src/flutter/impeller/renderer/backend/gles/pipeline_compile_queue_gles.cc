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
    : PipelineCompileQueue(),
      worker_task_runner_(std::move(worker_task_runner)) {}

PipelineCompileQueueGLES::~PipelineCompileQueueGLES() {}

void PipelineCompileQueueGLES::PostJob(const fml::closure& job) {
  if (!job) {
    return;
  }

  worker_task_runner_->PostTask(job);
}

}  // namespace impeller
