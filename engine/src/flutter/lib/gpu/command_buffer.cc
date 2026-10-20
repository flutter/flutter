// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/command_buffer.h"

#include "dart_api.h"
#include "fml/make_copyable.h"
#include "impeller/core/buffer_view.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"
#include "lib/ui/ui_dart_state.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, CommandBuffer);

CommandBuffer::CommandBuffer(std::shared_ptr<impeller::Context> context)
    : context_(std::move(context)),
      recording_(std::make_shared<CommandBufferRecording>()) {}

CommandBuffer::~CommandBuffer() = default;

bool CommandBuffer::AddRenderPass(
    std::shared_ptr<RenderPassRecording> render_pass) {
  if (submitted_) {
    return false;
  }
  CommandBufferRecording::Encodable encodable;
  encodable.render_pass = std::move(render_pass);
  recording_->encodables.push_back(std::move(encodable));
  return true;
}

std::vector<RecordedBlit>* CommandBuffer::OpenBlits() {
  if (submitted_) {
    return nullptr;
  }
  auto& encodables = recording_->encodables;
  if (encodables.empty() || encodables.back().render_pass) {
    encodables.emplace_back();
  }
  return &encodables.back().blits;
}

bool CommandBuffer::CopyBufferToTexture(DeviceBuffer& source,
                                        size_t source_offset,
                                        size_t source_length,
                                        Texture& destination,
                                        impeller::IRect destination_region,
                                        uint32_t mip_level,
                                        uint32_t slice) {
  auto* blits = OpenBlits();
  if (!blits) {
    return false;
  }
  blits->push_back(RecordedBlit{
      .kind = RecordedBlit::Kind::kBufferToTexture,
      .source_buffer = impeller::BufferView(
          source.GetBuffer(), impeller::Range(source_offset, source_length)),
      .destination_texture = destination.GetTexture(),
      .region = destination_region,
      .mip_level = mip_level,
      .slice = slice,
  });
  return true;
}

bool CommandBuffer::CopyTextureToBuffer(Texture& source,
                                        impeller::IRect source_region,
                                        DeviceBuffer& destination,
                                        size_t destination_offset) {
  auto* blits = OpenBlits();
  if (!blits) {
    return false;
  }
  blits->push_back(RecordedBlit{
      .kind = RecordedBlit::Kind::kTextureToBuffer,
      .source_texture = source.GetTexture(),
      .destination_buffer = destination.GetBuffer(),
      .region = source_region,
      .destination_offset = destination_offset,
  });
  return true;
}

bool CommandBuffer::CopyTextureToTexture(Texture& source,
                                         Texture& destination,
                                         impeller::IRect source_region,
                                         impeller::IPoint destination_origin) {
  auto* blits = OpenBlits();
  if (!blits) {
    return false;
  }
  blits->push_back(RecordedBlit{
      .kind = RecordedBlit::Kind::kTextureToTexture,
      .source_texture = source.GetTexture(),
      .destination_texture = destination.GetTexture(),
      .region = source_region,
      .destination_origin = destination_origin,
  });
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

  // Passes recorded into this command buffer are done once it is submitted.
  for (auto& encodable : recording_->encodables) {
    if (encodable.render_pass) {
      encodable.render_pass->sealed = true;
    }
  }
  std::shared_ptr<const CommandBufferRecording> recording =
      std::move(recording_);

  fml::RefPtr<fml::TaskRunner> raster_task_runner = GetReplayTaskRunner();
  if (!raster_task_runner) {
    return ReplayAndSubmit(context_, std::move(recording),
                           std::move(combined_completion_callback));
  }
  raster_task_runner->PostTask(fml::MakeCopyable(
      [context = context_, recording = std::move(recording),
       completion = std::move(combined_completion_callback)]() mutable {
        ReplayAndSubmit(context, std::move(recording), std::move(completion));
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
      contextWrapper->GetContextShared());
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
