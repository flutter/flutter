// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <memory>
#include <string>

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "impeller/renderer/buffer_view.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/sampler.h"
#include "impeller/renderer/shader_types.h"
#include "impeller/renderer/texture.h"
#include "impeller/renderer/vertex_buffer.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

struct Bindings {
  std::map<size_t, BufferView> buffers;
  std::map<size_t, std::shared_ptr<const Texture>> textures;
  std::map<size_t, std::shared_ptr<const Sampler>> samplers;
};

//------------------------------------------------------------------------------
/// @brief      An object used to specify work to the GPU along with references
///             to resources the GPU will used when doing said work.
///
///             To construct a valid command, follow these steps:
///             * Specify a valid pipeline.
///             * Specify vertex information via a call `BindVertices`
///             * Specify any stage bindings.
///             * (Optional) Specify a debug label.
///
///             Command are very lightweight objects and can be created
///             frequently and on demand. The resources referenced in commands
///             views into buffers managed by other allocators and resource
///             managers.
///
struct Command {
  //----------------------------------------------------------------------------
  /// The pipeline to use for this command.
  ///
  std::shared_ptr<Pipeline> pipeline;
  //----------------------------------------------------------------------------
  /// The buffer, texture, and sampler bindings used by the vertex pipeline
  /// stage.
  ///
  Bindings vertex_bindings;
  //----------------------------------------------------------------------------
  /// The buffer, texture, and sampler bindings used by the fragment pipeline
  /// stage.
  ///
  Bindings fragment_bindings;
  //----------------------------------------------------------------------------
  /// The index buffer binding used by the vertex shader stage. Instead of
  /// setting this directly, it usually easier to specify the vertex and index
  /// buffer bindings directly via a single call to `BindVertices`.
  ///
  BufferView index_buffer;
  size_t index_count = 0u;
  std::string label;
  PrimitiveType primitive_type = PrimitiveType::kTriangle;
  WindingOrder winding = WindingOrder::kClockwise;

  bool BindVertices(const VertexBuffer& buffer);

  template <class T>
  bool BindResource(ShaderStage stage,
                    const ShaderUniformSlot<T> slot,
                    BufferView view) {
    return BindResource(stage, slot.binding, std::move(view));
  }

  bool BindResource(ShaderStage stage, size_t binding, BufferView view);

  bool BindResource(ShaderStage stage,
                    const SampledImageSlot& slot,
                    std::shared_ptr<const Texture> texture);

  bool BindResource(ShaderStage stage,
                    const SampledImageSlot& slot,
                    std::shared_ptr<const Sampler> sampler);

  bool BindResource(ShaderStage stage,
                    const SampledImageSlot& slot,
                    std::shared_ptr<const Texture> texture,
                    std::shared_ptr<const Sampler> sampler);

  constexpr operator bool() const { return pipeline && pipeline->IsValid(); }
};

template <class VertexShader_, class FragmentShader_>
struct CommandT {
  using VertexShader = VertexShader_;
  using FragmentShader = FragmentShader_;
  using VertexBufferBuilder =
      VertexBufferBuilder<typename VertexShader_::PerVertexData>;
  using Pipeline = PipelineT<VertexShader_, FragmentShader_>;

  CommandT(PipelineT<VertexShader, FragmentShader>& pipeline) {
    command_.label = VertexShader::kLabel;

    // This could be moved to the accessor to delay the wait.
    command_.pipeline = pipeline.WaitAndGet();
  }

  static VertexBufferBuilder CreateVertexBuilder() {
    VertexBufferBuilder builder;
    builder.SetLabel(std::string{VertexShader::kLabel});
    return builder;
  }

  Command& Get() { return command_; }

  operator Command&() { return Get(); }

  bool BindVertices(VertexBufferBuilder builder, HostBuffer& buffer) {
    return command_.BindVertices(builder.CreateVertexBuffer(buffer));
  }

  bool BindVerticesDynamic(const VertexBuffer& buffer) {
    return command_.BindVertices(buffer);
  }

 private:
  Command command_;
};

}  // namespace impeller
