// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/command_buffer_gles.h"

#include <atomic>
#include <memory>
#include <utility>

#include "impeller/base/config.h"
#include "impeller/renderer/backend/gles/blit_pass_gles.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/render_pass_gles.h"

namespace impeller {
namespace {

/// Invokes a deferred command buffer completion callback exactly once.
///
/// The callback is completed with `kCompleted` when the deferred reactor
/// operation runs. If the operation is discarded before it runs, such as during
/// reactor teardown, the callback is completed with `kError`.
class DeferredCompletionCallback {
 public:
  explicit DeferredCompletionCallback(
      CommandBuffer::CompletionCallback callback)
      : callback_(std::move(callback)) {}

  /// Completes with `kError` unless the callback was already invoked.
  ~DeferredCompletionCallback() { Invoke(CommandBuffer::Status::kError); }

  DeferredCompletionCallback(const DeferredCompletionCallback&) = delete;
  DeferredCompletionCallback& operator=(const DeferredCompletionCallback&) =
      delete;
  DeferredCompletionCallback(DeferredCompletionCallback&&) = delete;
  DeferredCompletionCallback& operator=(DeferredCompletionCallback&&) = delete;

  /// Completes with `kCompleted` when the deferred reactor operation runs.
  void Complete() { Invoke(CommandBuffer::Status::kCompleted); }

 private:
  void Invoke(CommandBuffer::Status status) {
    if (!callback_) {
      return;
    }
    auto callback = std::exchange(callback_, nullptr);
    callback(status);
  }

  CommandBuffer::CompletionCallback callback_;
};

}  // namespace

CommandBufferGLES::CommandBufferGLES(std::weak_ptr<const Context> context,
                                     std::shared_ptr<ReactorGLES> reactor)
    : CommandBuffer(std::move(context)),
      reactor_(std::move(reactor)),
      is_valid_(reactor_ && reactor_->IsValid()) {}

CommandBufferGLES::~CommandBufferGLES() = default;

// |CommandBuffer|
void CommandBufferGLES::SetLabel(std::string_view label) const {
  // Cannot support.
}

// |CommandBuffer|
bool CommandBufferGLES::IsValid() const {
  return is_valid_;
}

// |CommandBuffer|
bool CommandBufferGLES::OnSubmitCommands(bool block_on_schedule,
                                         CompletionCallback callback) {
  // The reactor consumes commands on the GL thread and GL synchronizes
  // buffer reuse implicitly, so submissions are tracked at reactor
  // consumption granularity rather than GPU completion.
  std::shared_ptr<GpuSubmissionTracker> tracker;
  uint64_t submission_id = 0;
  if (auto context = context_.lock()) {
    tracker = ContextGLES::Cast(*context).GetMutableSubmissionTracker();
    submission_id = tracker->RecordSubmission();
  }

  if (reactor_->CanReactOnCurrentThread()) {
    const auto result = reactor_->React();
    if (ContextGLES::IsJobPoolConstrainedDriver()) {
      // Drivers prone to internal job-pool exhaustion crash once too many
      // submitted jobs are awaiting retirement; this accumulates during long
      // low-load sessions (small frames and uploads outpace the driver's
      // retirement cadence). Periodically finish the queue so the pool stays
      // shallow. See https://github.com/flutter/flutter/issues/189190.
      constexpr uint64_t kJobPoolDrainInterval = 64;
      static std::atomic<uint64_t> submission_count = 0;
      if (submission_count.fetch_add(1, std::memory_order_relaxed) %
              kJobPoolDrainInterval ==
          kJobPoolDrainInterval - 1) {
        reactor_->GetProcTable().Finish();
      }
    }
    if (tracker) {
      tracker->RecordCompletion(submission_id);
    }
    if (callback) {
      callback(result ? CommandBuffer::Status::kCompleted
                      : CommandBuffer::Status::kError);
    }
    return result;
  }

  // Submission is accepted even when no GL context is current yet. The
  // reactor keeps previously encoded operations queued on this thread.
  std::shared_ptr<DeferredCompletionCallback> deferred_callback;
  if (callback) {
    deferred_callback =
        std::make_shared<DeferredCompletionCallback>(std::move(callback));
  }
  if (!reactor_->AddOperation(
          [deferred_callback, tracker,
           submission_id](const ReactorGLES& reactor) {
            if (tracker) {
              tracker->RecordCompletion(submission_id);
            }
            if (deferred_callback) {
              deferred_callback->Complete();
            }
          },
          /*defer=*/true)) {
    if (tracker) {
      tracker->RecordCompletion(submission_id);
    }
    return false;
  }
  return true;
}

// |CommandBuffer|
void CommandBufferGLES::OnWaitUntilCompleted() {
  reactor_->GetProcTable().Finish();
}

// |CommandBuffer|
void CommandBufferGLES::OnWaitUntilScheduled() {
  reactor_->GetProcTable().Flush();
}

// |CommandBuffer|
std::shared_ptr<RenderPass> CommandBufferGLES::OnCreateRenderPass(
    RenderTarget target) {
  if (!IsValid()) {
    return nullptr;
  }
  auto context = context_.lock();
  if (!context) {
    return nullptr;
  }
  auto pass = std::shared_ptr<RenderPassGLES>(
      new RenderPassGLES(context, target, reactor_));
  if (!pass->IsValid()) {
    return nullptr;
  }
  return pass;
}

// |CommandBuffer|
std::shared_ptr<BlitPass> CommandBufferGLES::OnCreateBlitPass() {
  if (!IsValid()) {
    return nullptr;
  }
  auto pass = std::shared_ptr<BlitPassGLES>(new BlitPassGLES(reactor_));
  if (!pass->IsValid()) {
    return nullptr;
  }
  return pass;
}

// |CommandBuffer|
std::shared_ptr<ComputePass> CommandBufferGLES::OnCreateComputePass() {
  // Compute passes aren't supported until GLES 3.2, at which point Vulkan is
  // available anyway.
  return nullptr;
}

}  // namespace impeller
