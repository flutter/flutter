// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/command_buffer.h"

#include <string>

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

CommandBuffer::CommandBuffer(
    std::shared_ptr<impeller::Context> context,
    std::shared_ptr<impeller::CommandBuffer> command_buffer)
    : context_(std::move(context)),
      command_buffer_(std::move(command_buffer)) {}

CommandBuffer::~CommandBuffer() = default;

bool CommandBuffer::Encodable::EncodeCommands() const {
  if (render_pass) {
    return render_pass->EncodeCommands();
  }
  if (blit_pass) {
    return blit_pass->EncodeCommands();
  }
  return false;
}

std::shared_ptr<impeller::CommandBuffer> CommandBuffer::GetCommandBuffer() {
  return command_buffer_;
}

void CommandBuffer::AddRenderPass(
    std::shared_ptr<impeller::RenderPass> render_pass) {
  Encodable encodable;
  encodable.render_pass = std::move(render_pass);
  encodables_.push_back(std::move(encodable));
}

std::shared_ptr<impeller::BlitPass> CommandBuffer::GetOrCreateBlitPass() {
  if (!encodables_.empty() && encodables_.back().blit_pass) {
    return encodables_.back().blit_pass;
  }
  auto blit_pass = command_buffer_->CreateBlitPass();
  if (!blit_pass) {
    return nullptr;
  }
  Encodable encodable;
  encodable.blit_pass = blit_pass;
  encodables_.push_back(std::move(encodable));
  return blit_pass;
}

bool CommandBuffer::CopyBufferToTexture(DeviceBuffer& source,
                                        size_t source_offset,
                                        size_t source_length,
                                        Texture& destination,
                                        impeller::IRect destination_region,
                                        uint32_t mip_level,
                                        uint32_t slice) {
  auto blit_pass = GetOrCreateBlitPass();
  if (!blit_pass) {
    return false;
  }
  impeller::BufferView source_view(
      source.GetBuffer(), impeller::Range(source_offset, source_length));
  return blit_pass->AddCopy(
      std::move(source_view), destination.GetTexture(), destination_region,
      /*label=*/"CommandBuffer.copyBufferToTexture", mip_level, slice);
}

bool CommandBuffer::CopyTextureToBuffer(Texture& source,
                                        impeller::IRect source_region,
                                        DeviceBuffer& destination,
                                        size_t destination_offset) {
  auto blit_pass = GetOrCreateBlitPass();
  if (!blit_pass) {
    return false;
  }
  return blit_pass->AddCopy(source.GetTexture(), destination.GetBuffer(),
                            source_region, destination_offset,
                            "CommandBuffer.copyTextureToBuffer");
}

bool CommandBuffer::CopyTextureToTexture(Texture& source,
                                         Texture& destination,
                                         impeller::IRect source_region,
                                         impeller::IPoint destination_origin) {
  auto blit_pass = GetOrCreateBlitPass();
  if (!blit_pass) {
    return false;
  }
  return blit_pass->AddCopy(source.GetTexture(), destination.GetTexture(),
                            source_region, destination_origin,
                            "CommandBuffer.copyTextureToTexture");
}

bool CommandBuffer::Submit() {
  return CommandBuffer::Submit({});
}

bool CommandBuffer::Submit(
    const impeller::CommandBuffer::CompletionCallback& completion_callback) {
  // For the GLES backend, command queue submission just flushes the reactor,
  // which needs to happen on the raster thread.
  if (context_->GetBackendType() == impeller::Context::BackendType::kOpenGLES) {
    auto dart_state = flutter::UIDartState::Current();
    auto& task_runners = dart_state->GetTaskRunners();

    task_runners.GetRasterTaskRunner()->PostTask(
        fml::MakeCopyable([context = context_, command_buffer = command_buffer_,
                           completion_callback = completion_callback,
                           encodables = encodables_]() mutable {
          for (auto& encodable : encodables) {
            if (!encodable.EncodeCommands()) {
              if (completion_callback) {
                completion_callback(impeller::CommandBuffer::Status::kError);
              }
              context->DisposeThreadLocalCachedResources();
              return;
            }
          }

          context->GetCommandQueue()->Submit({command_buffer},
                                             completion_callback);
          context->DisposeThreadLocalCachedResources();
        }));
    return true;
  }

  for (auto& encodable : encodables_) {
    if (!encodable.EncodeCommands()) {
      return false;
    }
  }

  auto status = context_->GetCommandQueue()->Submit({command_buffer_},
                                                    completion_callback);
  context_->DisposeThreadLocalCachedResources();
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

static Dart_Handle ValidateNonNegative(std::string_view name, int value) {
  if (value < 0) {
    return tonic::ToDart(std::string(name) + " must be non-negative");
  }
  return Dart_Null();
}

static Dart_Handle ValidateNativeObject(std::string_view name,
                                        const void* object) {
  if (object == nullptr) {
    return tonic::ToDart(std::string(name) + " must not be null");
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
  Dart_Handle error = ValidateNativeObject("commandBuffer", command_buffer);
  if (!Dart_IsNull(error)) {
    return error;
  }
  error = ValidateNativeObject("source", source);
  if (!Dart_IsNull(error)) {
    return error;
  }
  error = ValidateNativeObject("destination", destination);
  if (!Dart_IsNull(error)) {
    return error;
  }
  error = ValidateNonNegative("sourceOffsetInBytes", source_offset_in_bytes);
  if (!Dart_IsNull(error)) {
    return error;
  }
  error = ValidateNonNegative("sourceLengthInBytes", source_length_in_bytes);
  if (!Dart_IsNull(error)) {
    return error;
  }
  error = ValidateNonNegative("mipLevel", mip_level);
  if (!Dart_IsNull(error)) {
    return error;
  }
  error = ValidateNonNegative("slice", slice);
  if (!Dart_IsNull(error)) {
    return error;
  }
  if (destination_width <= 0 || destination_height <= 0) {
    return tonic::ToDart(
        "destinationWidth and destinationHeight must be positive");
  }
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
  Dart_Handle error = ValidateNativeObject("commandBuffer", command_buffer);
  if (!Dart_IsNull(error)) {
    return error;
  }
  error = ValidateNativeObject("source", source);
  if (!Dart_IsNull(error)) {
    return error;
  }
  error = ValidateNativeObject("destination", destination);
  if (!Dart_IsNull(error)) {
    return error;
  }
  if (source_width <= 0 || source_height <= 0) {
    return tonic::ToDart("sourceWidth and sourceHeight must be positive");
  }
  error = ValidateNonNegative("destinationOffsetInBytes",
                              destination_offset_in_bytes);
  if (!Dart_IsNull(error)) {
    return error;
  }
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
  Dart_Handle error = ValidateNativeObject("commandBuffer", command_buffer);
  if (!Dart_IsNull(error)) {
    return error;
  }
  error = ValidateNativeObject("source", source);
  if (!Dart_IsNull(error)) {
    return error;
  }
  error = ValidateNativeObject("destination", destination);
  if (!Dart_IsNull(error)) {
    return error;
  }
  if (source_width <= 0 || source_height <= 0) {
    return tonic::ToDart("sourceWidth and sourceHeight must be positive");
  }
  if (!command_buffer->CopyTextureToTexture(
          *source, *destination,
          impeller::IRect::MakeXYWH(source_x, source_y, source_width,
                                    source_height),
          impeller::IPoint(destination_x, destination_y))) {
    return tonic::ToDart("Failed to append copyTextureToTexture");
  }
  return Dart_Null();
}
