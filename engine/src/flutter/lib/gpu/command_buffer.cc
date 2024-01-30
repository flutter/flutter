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

bool CommandBuffer::Submit() {
  for (auto& encodable : encodables_) {
    encodable->EncodeCommands();
  }

  return context_->GetCommandQueue()->Submit({command_buffer_}).ok();
}

bool CommandBuffer::Submit(
    const impeller::CommandBuffer::CompletionCallback& completion_callback) {
  for (auto& encodable : encodables_) {
    encodable->EncodeCommands();
  }
  return context_->GetCommandQueue()
      ->Submit({command_buffer_}, completion_callback)
      .ok();
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
      contextWrapper->GetContext(),
      contextWrapper->GetContext()->CreateCommandBuffer());
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

  bool success = wrapper->Submit(fml::MakeCopyable(
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
      }));
  if (!success) {
    return tonic::ToDart("Failed to submit CommandBuffer");
  }
  return Dart_Null();
}
