// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_RECORDING_H_
#define FLUTTER_LIB_GPU_RECORDING_H_

#include <cstddef>
#include <cstdint>
#include <memory>
#include <type_traits>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/lib/gpu/binding_set.h"
#include "flutter/lib/gpu/compute_pipeline.h"
#include "flutter/lib/gpu/render_pipeline.h"
#include "flutter/lib/gpu/shader.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/core/shader_types.h"
#include "impeller/core/texture.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/render_target.h"

namespace flutter {
namespace gpu {

/// The ops a recording holds, each with a struct below.
enum class RecordedOp : uint8_t {
  kSetPipelineState,
  kBindUniform,
  kBindTexture,
  kBindSet,
  kClearBindings,
  kBindVertexBuffer,
  kBindIndexBuffer,
  kSetStencilReference,
  kSetScissor,
  kSetViewport,
  kDraw,
  kSetComputePipeline,
  kBindComputeBuffer,
  kBindComputeTexture,
  kDispatch,
  kCopyBufferToTexture,
  kCopyTextureToBuffer,
  kCopyTextureToTexture,
};

/// The start of every op. Ops are plain data and are never destroyed, so
/// resetting a recording costs nothing per op. The objects they point at are
/// kept alive by the recording that holds them.
struct OpHeader {
  RecordedOp op;
  uint16_t size;
};

template <RecordedOp kOp>
struct Op : OpHeader {
  static constexpr RecordedOp kKind = kOp;
};

// Ops are written in place by `OpStream::Append`, never constructed.
// NOLINTBEGIN(cppcoreguidelines-pro-type-member-init)

struct SetPipelineStateOp : Op<RecordedOp::kSetPipelineState> {
  const RenderPipeline::Core* core;
  /// The draw state, without shaders or a vertex layout.
  const impeller::PipelineDescriptor* descriptor;
};

struct BindUniformOp : Op<RecordedOp::kBindUniform> {
  impeller::ShaderStage stage;
  const Shader::UniformBinding* binding;
  const impeller::DeviceBuffer* buffer;
  uint32_t offset;
  uint32_t length;
};

struct BindTextureOp : Op<RecordedOp::kBindTexture> {
  impeller::ShaderStage stage;
  const Shader::TextureBinding* binding;
  const impeller::Texture* texture;
  /// A `SamplerDescriptor::ToKey` key.
  uint64_t sampler_key;
};

struct BindSetOp : Op<RecordedOp::kBindSet> {
  uint32_t slot;
  /// Null empties the slot.
  const BindingSet::Contents* contents;
};

struct ClearBindingsOp : Op<RecordedOp::kClearBindings> {};

struct BindVertexBufferOp : Op<RecordedOp::kBindVertexBuffer> {
  uint32_t slot;
  const impeller::DeviceBuffer* buffer;
  uint32_t offset;
  uint32_t length;
};

struct BindIndexBufferOp : Op<RecordedOp::kBindIndexBuffer> {
  impeller::IndexType type;
  const impeller::DeviceBuffer* buffer;
  uint32_t offset;
  uint32_t length;
};

struct SetStencilReferenceOp : Op<RecordedOp::kSetStencilReference> {
  uint32_t reference;
};

struct SetScissorOp : Op<RecordedOp::kSetScissor> {
  impeller::IRect32 scissor;
};

struct SetViewportOp : Op<RecordedOp::kSetViewport> {
  impeller::Rect rect;
  float z_near;
  float z_far;
};

struct DrawOp : Op<RecordedOp::kDraw> {
  bool indexed;
  uint32_t element_count;
  uint32_t instance_count;
};

struct SetComputePipelineOp : Op<RecordedOp::kSetComputePipeline> {
  BackendComputePipeline* pipeline;
};

struct BindComputeBufferOp : Op<RecordedOp::kBindComputeBuffer> {
  impeller::DescriptorType type;
  const impeller::ShaderUniformSlot* slot;
  const impeller::ShaderMetadata* metadata;
  const impeller::DeviceBuffer* buffer;
  uint64_t offset;
  uint64_t length;
};

struct BindComputeTextureOp : Op<RecordedOp::kBindComputeTexture> {
  const impeller::SampledImageSlot* slot;
  const impeller::ShaderMetadata* metadata;
  const impeller::Texture* texture;
  uint64_t sampler_key;
};

struct DispatchOp : Op<RecordedOp::kDispatch> {
  uint32_t workgroup_count[3];
};

struct CopyBufferToTextureOp : Op<RecordedOp::kCopyBufferToTexture> {
  uint32_t mip_level;
  const impeller::DeviceBuffer* source;
  impeller::Texture* destination;
  uint64_t source_offset;
  uint64_t source_length;
  impeller::IRect destination_region;
  uint32_t slice;
};

struct CopyTextureToBufferOp : Op<RecordedOp::kCopyTextureToBuffer> {
  impeller::Texture* source;
  impeller::DeviceBuffer* destination;
  impeller::IRect source_region;
  uint64_t destination_offset;
};

struct CopyTextureToTextureOp : Op<RecordedOp::kCopyTextureToTexture> {
  impeller::Texture* source;
  impeller::Texture* destination;
  impeller::IRect source_region;
  impeller::IPoint destination_origin;
};

// NOLINTEND(cppcoreguidelines-pro-type-member-init)

/// A block of recorded ops. Chunks are fixed size so that a stream grows
/// without moving what it already holds.
// NOLINTNEXTLINE(cppcoreguidelines-pro-type-member-init)
struct RecordingChunk {
  static constexpr size_t kSize = 64 * 1024;

  RecordingChunk* next = nullptr;
  size_t used = 0;
  alignas(alignof(std::max_align_t)) uint8_t data[kSize - 2 * sizeof(void*)];
};

/// An append-only sequence of ops.
class OpStream {
 public:
  OpStream() = default;

  ~OpStream();

  /// Appends an op, and returns it for the caller to fill in.
  template <typename T>
  T* Append() {
    static_assert(std::is_trivially_destructible_v<T>);
    static_assert(alignof(T) <= kAlignment);
    constexpr size_t aligned_size =
        (sizeof(T) + kAlignment - 1) & ~(kAlignment - 1);
    if (aligned_size > static_cast<size_t>(limit_ - cursor_)) [[unlikely]] {
      AddChunk();
    }
    auto* op = reinterpret_cast<T*>(cursor_);
    cursor_ += aligned_size;
    op->op = T::kKind;
    op->size = static_cast<uint16_t>(aligned_size);
    return op;
  }

  /// Calls [visitor] with the header of every op, in order. Nothing may be
  /// appended while this runs.
  template <typename Visitor>
  void ForEach(Visitor&& visitor) const {
    for (RecordingChunk* chunk = head_; chunk; chunk = chunk->next) {
      const uint8_t* cursor = chunk->data;
      const uint8_t* end = chunk == tail_ ? cursor_ : chunk->data + chunk->used;
      while (cursor < end) {
        const auto* header = reinterpret_cast<const OpHeader*>(cursor);
        visitor(*header);
        cursor += header->size;
      }
    }
  }

  /// Drops every op and frees the chunks.
  void Reset();

 private:
  static constexpr size_t kAlignment = 8;

  void AddChunk();

  RecordingChunk* head_ = nullptr;
  RecordingChunk* tail_ = nullptr;
  uint8_t* cursor_ = nullptr;
  uint8_t* limit_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(OpStream);
};

/// What one pass recorded, for a replay thread to encode. Holds no Dart
/// wrappables, so it can be released on any thread.
class PassRecording {
 public:
  enum class Kind : uint8_t {
    kRender,
    kCompute,
    kBlit,
  };

  using Ptr = std::unique_ptr<PassRecording>;

  explicit PassRecording(Kind kind) : kind_(kind) {}

  /// Keeps [object] alive until this recording is dropped.
  void Retain(std::shared_ptr<const void> object) {
    retained_.emplace_back(std::move(object));
  }

  Kind GetKind() const { return kind_; }

  /// Set once, when a render pass begins.
  impeller::RenderTarget render_target;

  OpStream ops;

 private:
  const Kind kind_;
  std::vector<std::shared_ptr<const void>> retained_;

  FML_DISALLOW_COPY_AND_ASSIGN(PassRecording);
};

}  // namespace gpu
}  // namespace flutter

#endif  // FLUTTER_LIB_GPU_RECORDING_H_
