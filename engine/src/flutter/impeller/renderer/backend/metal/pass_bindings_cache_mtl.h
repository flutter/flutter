// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_PASS_BINDINGS_CACHE_MTL_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_PASS_BINDINGS_CACHE_MTL_H_

#include <Metal/Metal.h>

#include <array>
#include <optional>
#include <vector>

#include "impeller/core/formats.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

//-----------------------------------------------------------------------------
/// @brief      Ensures that bindings on the pass are not redundantly set or
///             updated. Avoids making the driver do additional checks and makes
///             the frame insights during profiling and instrumentation not
///             complain about the same.
///
///             There should be no change to rendering if this caching was
///             absent.
///
struct PassBindingsCacheMTL {
  explicit PassBindingsCacheMTL() {}

  ~PassBindingsCacheMTL() = default;

  PassBindingsCacheMTL(const PassBindingsCacheMTL&) = delete;

  PassBindingsCacheMTL(PassBindingsCacheMTL&&) = delete;

  /// @brief Set the command encoder for this pass bindings cache.
  ///
  /// The encoder must be set before any state adjusting commands can be called.
  void SetEncoder(id<MTLRenderCommandEncoder> encoder);

  /// @brief Set the render pipeline state for the current encoder.
  ///
  /// If this matches the previous render pipeline state, no update
  /// is performed.
  ///
  /// @returns true if the pipeline state changed.
  bool SetRenderPipelineState(id<MTLRenderPipelineState> pipeline);

  /// @brief Set the depth and stencil state for the current encoder.
  ///
  /// If this matches the previous depth and stencil state, no update
  /// is performed.
  void SetDepthStencilState(id<MTLDepthStencilState> depth_stencil);

  /// @brief Set the buffer for the given shader stage, binding, and offset.
  ///
  /// If the buffer is already bound, only the offset is updated.
  bool SetBuffer(ShaderStage stage,
                 uint64_t index,
                 uint64_t offset,
                 id<MTLBuffer> buffer);

  /// @brief Set the texture for the given stage and binding.
  ///
  /// If the same texture is already bound at the index for this stage, no
  /// state updates are performed.
  bool SetTexture(ShaderStage stage, uint64_t index, id<MTLTexture> texture);

  /// @brief Set the sampler for the given stage and binding.
  ///
  /// If the same sampler is already bound at the index for this stage, no
  /// state updates are performed.
  bool SetSampler(ShaderStage stage,
                  uint64_t index,
                  id<MTLSamplerState> sampler);

  /// @brief Set the viewport if the value is different from the current encoder
  ///        state
  void SetViewport(const Viewport& viewport);

  /// @brief Set the encoder scissor rect if the value is different from the
  ///        current encoder state.
  void SetScissor(const IRect32& scissor);

  /// @brief Set the encoder's stencil reference if the value is different from
  ///        the current encoder state.
  void SetStencilRef(uint32_t stencil_ref);

  /// @brief Set the encoder front-facing winding if it differs from the
  ///        current encoder state.
  void SetWindingOrder(WindingOrder winding);

  /// @brief Set the encoder cull mode if it differs from the current encoder
  ///        state.
  void SetCullMode(CullMode cull_mode);

  /// @brief Set the encoder triangle fill mode if it differs from the current
  ///        encoder state.
  void SetPolygonMode(PolygonMode polygon_mode);

 private:
  struct BufferOffsetPair {
    id<MTLBuffer> buffer = nullptr;
    size_t offset = 0u;
  };

  // Shader argument table binding indices are small, dense integers, so
  // per-stage vectors indexed by the binding index avoid the allocation and
  // lookup costs of a node-based map on the per-command hot path.
  static constexpr size_t kShaderStageCount = 4u;
  static_assert(kShaderStageCount ==
                static_cast<size_t>(ShaderStage::kCompute) + 1u);
  static constexpr uint64_t kMaxBindingIndex = 512u;

  using BufferBindings =
      std::array<std::vector<BufferOffsetPair>, kShaderStageCount>;
  using TextureBindings =
      std::array<std::vector<id<MTLTexture>>, kShaderStageCount>;
  using SamplerBindings =
      std::array<std::vector<id<MTLSamplerState>>, kShaderStageCount>;

  static bool IsCacheableStage(ShaderStage stage) {
    return stage == ShaderStage::kVertex || stage == ShaderStage::kFragment;
  }

  id<MTLRenderCommandEncoder> encoder_;
  id<MTLRenderPipelineState> pipeline_ = nullptr;
  id<MTLDepthStencilState> depth_stencil_ = nullptr;
  BufferBindings buffers_;
  TextureBindings textures_;
  SamplerBindings samplers_;
  std::optional<Viewport> viewport_;
  std::optional<IRect32> scissor_;
  std::optional<uint32_t> stencil_ref_;
  std::optional<WindingOrder> winding_;
  std::optional<CullMode> cull_mode_;
  std::optional<PolygonMode> polygon_mode_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_PASS_BINDINGS_CACHE_MTL_H_
