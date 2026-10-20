// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_RECORDING_H_
#define FLUTTER_LIB_GPU_RECORDING_H_

#include <cstdint>
#include <memory>
#include <utility>
#include <vector>

#include "flutter/lib/gpu/binding_set.h"
#include "flutter/lib/gpu/render_pipeline.h"
#include "flutter/lib/gpu/shader.h"
#include "fml/task_runner.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/core/texture.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/render_target.h"

namespace flutter {
namespace gpu {

/// The ops a `RenderPassRecording` replays, in recorded order. An op's
/// payload, if it has one, is at the op's index in the matching array.
enum class RecordedOp : uint8_t {
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
};

/// What a render pass records on the UI thread for the raster thread to
/// replay into an `impeller::RenderPass`. Holds no Dart wrappables, so it can
/// be released on any thread.
struct RenderPassRecording {
  struct PipelineState {
    std::shared_ptr<const RenderPipeline::Core> pipeline;
    /// Built from the pass state. Stage entrypoints and the vertex
    /// descriptor are bound at replay.
    impeller::PipelineDescriptor descriptor;
    /// The descriptor's hash, which keys known build failures.
    size_t key = 0;
  };

  struct UniformBind {
    const Shader::UniformBinding* binding = nullptr;
    impeller::ShaderStage stage = impeller::ShaderStage::kUnknown;
    impeller::BufferView view;
  };

  struct TextureBind {
    const Shader::TextureBinding* binding = nullptr;
    impeller::ShaderStage stage = impeller::ShaderStage::kUnknown;
    std::shared_ptr<const impeller::Texture> texture;
    impeller::SamplerDescriptor sampler;
  };

  struct SetBind {
    uint32_t slot = 0;
    std::shared_ptr<const BindingSet::Contents> contents;
  };

  struct VertexBufferBind {
    uint32_t slot = 0;
    impeller::BufferView view;
  };

  struct IndexBufferBind {
    impeller::BufferView view;
    impeller::IndexType type = impeller::IndexType::kNone;
  };

  struct Draw {
    uint32_t pipeline_state = 0;
    uint32_t element_count = 0;
    uint32_t instance_count = 0;
    bool indexed = false;
  };

  impeller::RenderTarget render_target;
  /// Set on the recording thread when the command buffer is submitted.
  /// Nothing is recorded after that, so the replay thread can read the
  /// recording without synchronization.
  bool sealed = false;
  std::vector<std::pair<RecordedOp, uint32_t>> ops;
  std::vector<PipelineState> pipeline_states;
  std::vector<UniformBind> uniforms;
  std::vector<TextureBind> textures;
  std::vector<SetBind> sets;
  std::vector<VertexBufferBind> vertex_buffers;
  std::vector<IndexBufferBind> index_buffers;
  std::vector<uint32_t> stencil_references;
  std::vector<impeller::IRect32> scissors;
  std::vector<impeller::Viewport> viewports;
  std::vector<Draw> draws;
  /// Keep the binding pointers above valid until replay is done.
  std::vector<std::shared_ptr<const Shader::Reflection>> reflections;

  template <typename T>
  void Push(RecordedOp op, std::vector<T>& payloads, T&& payload) {
    ops.emplace_back(op, static_cast<uint32_t>(payloads.size()));
    payloads.push_back(std::forward<T>(payload));
  }

  void Push(RecordedOp op) { ops.emplace_back(op, 0u); }

  void RetainReflection(const std::shared_ptr<const Shader::Reflection>& r);
};

/// A blit copy recorded by a command buffer.
struct RecordedBlit {
  enum class Kind : uint8_t {
    kBufferToTexture,
    kTextureToBuffer,
    kTextureToTexture,
  };

  Kind kind = Kind::kBufferToTexture;
  impeller::BufferView source_buffer;
  std::shared_ptr<impeller::Texture> source_texture;
  std::shared_ptr<impeller::DeviceBuffer> destination_buffer;
  std::shared_ptr<impeller::Texture> destination_texture;
  impeller::IRect region{};
  impeller::IPoint destination_origin{};
  size_t destination_offset = 0;
  uint32_t mip_level = 0;
  uint32_t slice = 0;
};

/// A command buffer's passes, in the order they were begun.
struct CommandBufferRecording {
  struct Encodable {
    std::shared_ptr<RenderPassRecording> render_pass;
    std::vector<RecordedBlit> blits;
  };

  std::vector<Encodable> encodables;
};

/// The task runner Flutter GPU work is encoded and submitted on: the raster
/// task runner of the current UI isolate, or null when there is none (unit
/// tests), in which case callers do the work inline.
fml::RefPtr<fml::TaskRunner> GetReplayTaskRunner();

/// Creates a command buffer from [context], replays [recording] into it, and
/// submits it, all on the calling thread. [completion] runs when the work
/// finishes, or with `kError` when encoding or submission fails. The
/// recording is kept alive until then. Returns whether the work was
/// submitted.
bool ReplayAndSubmit(const std::shared_ptr<impeller::Context>& context,
                     std::shared_ptr<const CommandBufferRecording> recording,
                     impeller::CommandBuffer::CompletionCallback completion);

}  // namespace gpu
}  // namespace flutter

#endif  // FLUTTER_LIB_GPU_RECORDING_H_
