// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/command_buffer_gles.h"

#include <memory>
#include <utility>

#include "impeller/base/config.h"
#include "impeller/renderer/backend/gles/blit_pass_gles.h"
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
  if (reactor_->CanReactOnCurrentThread()) {
    const auto result = reactor_->React();
    if (callback) {
      callback(result ? CommandBuffer::Status::kCompleted
                      : CommandBuffer::Status::kError);
    }
    return result;
  }

  // Submission is accepted even when no GL context is current yet. The
  // reactor keeps previously encoded operations queued on this thread.
  if (!callback) {
    return true;
  }

  auto deferred_callback =
      std::make_shared<DeferredCompletionCallback>(std::move(callback));
  if (!reactor_->AddOperation(
          [deferred_callback](const ReactorGLES& reactor) {
            deferred_callback->Complete();
          },
          /*defer=*/true)) {
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
