// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_COMMAND_BUFFER_H_
#define FLUTTER_LIB_GPU_COMMAND_BUFFER_H_

#include <memory>
#include <vector>

#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/device_buffer.h"
#include "flutter/lib/gpu/export.h"
#include "flutter/lib/gpu/recording.h"
#include "flutter/lib/gpu/texture.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/context.h"

namespace flutter {
namespace gpu {

class CommandBufferEncoder;
class ReplayQueue;

/// Records passes on the calling thread, and hands each one to the replay
/// queue when it ends, so that encoding overlaps recording the next pass.
class CommandBuffer : public RefCountedDartWrappable<CommandBuffer> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(CommandBuffer);

 public:
  /// Encodes on [replay_queue], or on the calling thread when it is null.
  explicit CommandBuffer(std::shared_ptr<impeller::Context> context,
                         std::shared_ptr<ReplayQueue> replay_queue = nullptr);

  /// Ends the open pass, then opens a pass of [kind] for [owner]. Returns the
  /// recording, or null if this command buffer was already submitted.
  PassRecording* BeginPass(PassRecording::Kind kind, const void* owner);

  /// Ends the open pass if [owner] began it. Does nothing if it was already
  /// ended by a later command.
  void EndPass(const void* owner);

  /// The recording [owner] began, or null if it has ended.
  PassRecording* GetOpenPass(const void* owner) const {
    return owner == open_pass_owner_ ? open_pass_.get() : nullptr;
  }

  const std::shared_ptr<impeller::Context>& GetContext() const;

  bool AddCompletionCallback(
      impeller::CommandBuffer::CompletionCallback completion_callback);

  bool CopyBufferToTexture(DeviceBuffer& source,
                           size_t source_offset,
                           size_t source_length,
                           Texture& destination,
                           impeller::IRect destination_region,
                           uint32_t mip_level,
                           uint32_t slice);

  bool CopyTextureToBuffer(Texture& source,
                           impeller::IRect source_region,
                           DeviceBuffer& destination,
                           size_t destination_offset);

  bool CopyTextureToTexture(Texture& source,
                            Texture& destination,
                            impeller::IRect source_region,
                            impeller::IPoint destination_origin);

  /// Submits the recorded passes. On the replay queue this returns before they
  /// are encoded, and failures are reported to the completion callbacks.
  bool Submit();
  bool Submit(
      const impeller::CommandBuffer::CompletionCallback& completion_callback);

  ~CommandBuffer() override;

 private:
  void EndOpenPass();

  /// The recording for copies, which share a pass while they are consecutive.
  PassRecording* OpenBlitPass();

  std::shared_ptr<impeller::Context> context_;
  std::shared_ptr<ReplayQueue> replay_queue_;
  std::shared_ptr<CommandBufferEncoder> encoder_;

  PassRecording::Ptr open_pass_;
  const void* open_pass_owner_ = nullptr;
  size_t recorded_bytes_ = 0;
  std::vector<impeller::CommandBuffer::CompletionCallback>
      completion_callbacks_;
  bool submitted_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(CommandBuffer);
};

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_CommandBuffer_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* contextWrapper);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_CommandBuffer_Submit(
    flutter::gpu::CommandBuffer* wrapper,
    Dart_Handle completion_callback);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_CommandBuffer_CopyBufferToTexture(
    flutter::gpu::CommandBuffer* wrapper,
    flutter::gpu::DeviceBuffer* source,
    int source_offset_in_bytes,
    int source_length_in_bytes,
    flutter::gpu::Texture* destination,
    int destination_x,
    int destination_y,
    int destination_width,
    int destination_height,
    int mip_level,
    int slice);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_CommandBuffer_CopyTextureToBuffer(
    flutter::gpu::CommandBuffer* wrapper,
    flutter::gpu::Texture* source,
    int source_x,
    int source_y,
    int source_width,
    int source_height,
    flutter::gpu::DeviceBuffer* destination,
    int destination_offset_in_bytes);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_CommandBuffer_CopyTextureToTexture(
    flutter::gpu::CommandBuffer* wrapper,
    flutter::gpu::Texture* source,
    flutter::gpu::Texture* destination,
    int source_x,
    int source_y,
    int source_width,
    int source_height,
    int destination_x,
    int destination_y);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_COMMAND_BUFFER_H_
