// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/command_buffer.h"

#include "dart_api.h"
#include "flutter/lib/gpu/replay.h"
#include "fml/make_copyable.h"
#include "impeller/renderer/command_buffer.h"
#include "lib/ui/ui_dart_state.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, CommandBuffer);

CommandBuffer::CommandBuffer(std::shared_ptr<impeller::Context> context,
                             std::shared_ptr<ReplayQueue> replay_queue)
    : context_(std::move(context)),
      replay_queue_(replay_queue
                        ? std::move(replay_queue)
                        : std::make_shared<ReplayQueue>(context_, nullptr)),
      encoder_(std::make_shared<CommandBufferEncoder>(replay_queue_)) {}

CommandBuffer::~CommandBuffer() {
  // Never submitted. The Impeller command buffer belongs to the replay thread.
  if (encoder_) {
    replay_queue_->Post(
        [encoder = std::move(encoder_)]() mutable { encoder.reset(); });
  }
}

PassRecording* CommandBuffer::BeginPass(PassRecording::Kind kind,
                                        const void* owner) {
  if (submitted_) {
    return nullptr;
  }
  EndOpenPass();
  open_pass_ = PassRecording::Acquire(kind);
  open_pass_owner_ = owner;
  return open_pass_.get();
}

void CommandBuffer::EndPass(const void* owner) {
  if (open_pass_ && open_pass_owner_ == owner) {
    EndOpenPass();
  }
}

void CommandBuffer::EndOpenPass() {
  if (!open_pass_) {
    return;
  }
  open_pass_owner_ = nullptr;
  recorded_bytes_ += open_pass_->ops.GetAllocatedSize();
  replay_queue_->Post(fml::MakeCopyable(
      [encoder = encoder_, recording = std::move(open_pass_)]() mutable {
        encoder->Encode(std::move(recording));
      }));
}

const std::shared_ptr<impeller::Context>& CommandBuffer::GetContext() const {
  return context_;
}

PassRecording* CommandBuffer::OpenBlitPass() {
  if (open_pass_ && open_pass_->GetKind() == PassRecording::Kind::kBlit) {
    return open_pass_.get();
  }
  return BeginPass(PassRecording::Kind::kBlit, nullptr);
}

bool CommandBuffer::CopyBufferToTexture(DeviceBuffer& source,
                                        size_t source_offset,
                                        size_t source_length,
                                        Texture& destination,
                                        impeller::IRect destination_region,
                                        uint32_t mip_level,
                                        uint32_t slice) {
  const size_t source_size =
      source.GetBuffer()->GetDeviceBufferDescriptor().size;
  if (source_offset > source_size ||
      source_length > source_size - source_offset) {
    return false;
  }
  PassRecording* blits = OpenBlitPass();
  if (!blits) {
    return false;
  }
  blits->Retain(source.GetRetainStamp(), source.GetBuffer());
  blits->Retain(destination.GetRetainStamp(), destination.GetTexture());
  auto* op = blits->ops.Append<CopyBufferToTextureOp>();
  op->source = source.GetBuffer().get();
  op->source_offset = source_offset;
  op->source_length = source_length;
  op->destination = destination.GetTexture().get();
  op->destination_region = destination_region;
  op->mip_level = mip_level;
  op->slice = slice;
  return true;
}

bool CommandBuffer::CopyTextureToBuffer(Texture& source,
                                        impeller::IRect source_region,
                                        DeviceBuffer& destination,
                                        size_t destination_offset) {
  PassRecording* blits = OpenBlitPass();
  if (!blits) {
    return false;
  }
  blits->Retain(source.GetRetainStamp(), source.GetTexture());
  blits->Retain(destination.GetRetainStamp(), destination.GetBuffer());
  auto* op = blits->ops.Append<CopyTextureToBufferOp>();
  op->source = source.GetTexture().get();
  op->destination = destination.GetBuffer().get();
  op->source_region = source_region;
  op->destination_offset = destination_offset;
  return true;
}

bool CommandBuffer::CopyTextureToTexture(Texture& source,
                                         Texture& destination,
                                         impeller::IRect source_region,
                                         impeller::IPoint destination_origin) {
  PassRecording* blits = OpenBlitPass();
  if (!blits) {
    return false;
  }
  blits->Retain(source.GetRetainStamp(), source.GetTexture());
  blits->Retain(destination.GetRetainStamp(), destination.GetTexture());
  auto* op = blits->ops.Append<CopyTextureToTextureOp>();
  op->source = source.GetTexture().get();
  op->destination = destination.GetTexture().get();
  op->source_region = source_region;
  op->destination_origin = destination_origin;
  return true;
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
  EndOpenPass();
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

  replay_queue_->AddInFlightBytes(recorded_bytes_);
  if (replay_queue_->RunsOnCallingThread()) {
    return CommandBufferEncoder::Submit(std::move(encoder_),
                                        std::move(combined_completion_callback),
                                        recorded_bytes_);
  }
  replay_queue_->Post(
      fml::MakeCopyable([encoder = std::move(encoder_),
                         completion = std::move(combined_completion_callback),
                         bytes = recorded_bytes_]() mutable {
        CommandBufferEncoder::Submit(std::move(encoder), std::move(completion),
                                     bytes);
      }));
  return true;
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
      contextWrapper->GetContextShared(), contextWrapper->GetReplayQueue());
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

Dart_Handle InternalFlutterGpu_CommandBuffer_CopyBufferToTexture(
    flutter::gpu::CommandBuffer* command_buffer,
    flutter::gpu::DeviceBuffer* source,
    int source_offset_in_bytes,
    int source_length_in_bytes,
    flutter::gpu::Texture* destination,
    int destination_x,
    int destination_y,
    int destination_width,
    int destination_height,
    int mip_level,
    int slice) {
  if (!command_buffer->CopyBufferToTexture(
          *source, static_cast<size_t>(source_offset_in_bytes),
          static_cast<size_t>(source_length_in_bytes), *destination,
          impeller::IRect::MakeXYWH(destination_x, destination_y,
                                    destination_width, destination_height),
          static_cast<uint32_t>(mip_level), static_cast<uint32_t>(slice))) {
    return tonic::ToDart("Failed to append copyBufferToTexture");
  }
  return Dart_Null();
}

Dart_Handle InternalFlutterGpu_CommandBuffer_CopyTextureToBuffer(
    flutter::gpu::CommandBuffer* command_buffer,
    flutter::gpu::Texture* source,
    int source_x,
    int source_y,
    int source_width,
    int source_height,
    flutter::gpu::DeviceBuffer* destination,
    int destination_offset_in_bytes) {
  if (!command_buffer->CopyTextureToBuffer(
          *source,
          impeller::IRect::MakeXYWH(source_x, source_y, source_width,
                                    source_height),
          *destination, static_cast<size_t>(destination_offset_in_bytes))) {
    return tonic::ToDart("Failed to append copyTextureToBuffer");
  }
  return Dart_Null();
}

Dart_Handle InternalFlutterGpu_CommandBuffer_CopyTextureToTexture(
    flutter::gpu::CommandBuffer* command_buffer,
    flutter::gpu::Texture* source,
    flutter::gpu::Texture* destination,
    int source_x,
    int source_y,
    int source_width,
    int source_height,
    int destination_x,
    int destination_y) {
  if (!command_buffer->CopyTextureToTexture(
          *source, *destination,
          impeller::IRect::MakeXYWH(source_x, source_y, source_width,
                                    source_height),
          impeller::IPoint(destination_x, destination_y))) {
    return tonic::ToDart("Failed to append copyTextureToTexture");
  }
  return Dart_Null();
}
