// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/command_buffer.h"

#include "dart_api.h"
#include "fml/make_copyable.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"
#include "lib/ui/ui_dart_state.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, CommandBuffer);

CommandBuffer::CommandBuffer(
    std::shared_ptr<impeller::Context> context,
    std::shared_ptr<impeller::CommandBuffer> command_buffer)
    : context_(std::move(context)),
      command_buffer_(std::move(command_buffer)) {}

CommandBuffer::~CommandBuffer() = default;

std::shared_ptr<impeller::CommandBuffer> CommandBuffer::GetCommandBuffer() {
  return command_buffer_;
}

void CommandBuffer::AddRenderPass(
    std::shared_ptr<impeller::RenderPass> render_pass) {
  encodables_.push_back(std::move(render_pass));
}

bool CommandBuffer::AddCompletionCallback(
    impeller::CommandBuffer::CompletionCallback completion_callback) {
  if (submitted_) {
    return false;
  }
  if (completion_callback) {
    completion_callbacks_.push_back(std::move(completion_callback));
  }
  return true;
}

bool CommandBuffer::Submit() {
  return CommandBuffer::Submit({});
}

bool CommandBuffer::Submit(
    const impeller::CommandBuffer::CompletionCallback& completion_callback) {
  if (submitted_) {
    return false;
  }
  submitted_ = true;

  std::vector<impeller::CommandBuffer::CompletionCallback> callbacks =
      std::move(completion_callbacks_);
  if (completion_callback) {
    callbacks.push_back(completion_callback);
  }
  impeller::CommandBuffer::CompletionCallback combined_completion_callback;
  if (!callbacks.empty()) {
    combined_completion_callback =
        [callbacks = std::move(callbacks)](
            impeller::CommandBuffer::Status status) mutable {
          for (auto& callback : callbacks) {
            callback(status);
          }
        };
  }

  // For the GLES backend, command queue submission just flushes the reactor,
  // which needs to happen on the raster thread.
  if (context_->GetBackendType() == impeller::Context::BackendType::kOpenGLES) {
    auto dart_state = flutter::UIDartState::Current();
    auto& task_runners = dart_state->GetTaskRunners();

    task_runners.GetRasterTaskRunner()->PostTask(
        fml::MakeCopyable([context = context_, command_buffer = command_buffer_,
                           completion_callback = combined_completion_callback,
                           encodables = encodables_]() mutable {
          for (auto& encodable : encodables) {
            encodable->EncodeCommands();
          }

          auto status = context->GetCommandQueue()->Submit({command_buffer},
                                                           completion_callback);
          if (!status.ok() && completion_callback) {
            completion_callback(impeller::CommandBuffer::Status::kError);
          }
          context->DisposeThreadLocalCachedResources();
        }));
    return true;
  }

  for (auto& encodable : encodables_) {
    encodable->EncodeCommands();
  }

  auto status = context_->GetCommandQueue()->Submit(
      {command_buffer_}, combined_completion_callback);
  context_->DisposeThreadLocalCachedResources();
  if (!status.ok() && combined_completion_callback) {
    combined_completion_callback(impeller::CommandBuffer::Status::kError);
  }
  return status.ok();
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

bool InternalFlutterGpu_CommandBuffer_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* contextWrapper) {
  auto res = fml::MakeRefCounted<flutter::gpu::CommandBuffer>(
      contextWrapper->GetContextShared(),
      contextWrapper->GetContext().CreateCommandBuffer());
  res->AssociateWithDartWrapper(wrapper);

  return true;
}

Dart_Handle InternalFlutterGpu_CommandBuffer_Submit(
    flutter::gpu::CommandBuffer* wrapper,
    Dart_Handle completion_callback) {
  if (Dart_IsNull(completion_callback)) {
    bool success = wrapper->Submit();
    if (!success) {
      return tonic::ToDart("Failed to submit CommandBuffer");
    }
    return Dart_Null();
  }

  if (!Dart_IsClosure(completion_callback)) {
    return tonic::ToDart("Completion callback must be a function");
  }

  auto dart_state = flutter::UIDartState::Current();
  auto& task_runners = dart_state->GetTaskRunners();

  auto persistent_completion_callback =
      std::make_unique<tonic::DartPersistentValue>(dart_state,
                                                   completion_callback);

  auto ui_task_completion_callback = fml::MakeCopyable(
      [callback = std::move(persistent_completion_callback),
       task_runners](impeller::CommandBuffer::Status status) mutable {
        bool success = status != impeller::CommandBuffer::Status::kError;

        auto ui_completion_task = fml::MakeCopyable(
            [callback = std::move(callback), success]() mutable {
              auto dart_state = callback->dart_state().lock();
              if (!dart_state) {
                // The root isolate could have died in the meantime.
                return;
              }
              tonic::DartState::Scope scope(dart_state);

              tonic::DartInvoke(callback->Get(), {tonic::ToDart(success)});

              // callback is associated with the Dart isolate and must be
              // deleted on the UI thread.
              callback.reset();
            });
        task_runners.GetUITaskRunner()->PostTask(ui_completion_task);
      });
  bool success = wrapper->Submit(ui_task_completion_callback);
  if (!success) {
    return tonic::ToDart("Failed to submit CommandBuffer");
  }
  return Dart_Null();
}
