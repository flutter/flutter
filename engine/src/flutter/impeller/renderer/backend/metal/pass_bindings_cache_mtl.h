// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_PASS_BINDINGS_CACHE_MTL_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_PASS_BINDINGS_CACHE_MTL_H_

#include <Metal/Metal.h>

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
  void SetRenderPipelineState(id<MTLRenderPipelineState> pipeline);

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

 private:
  struct BufferOffsetPair {
    id<MTLBuffer> buffer = nullptr;
    size_t offset = 0u;
  };
  using BufferMap = std::map<uint64_t, BufferOffsetPair>;
  using TextureMap = std::map<uint64_t, id<MTLTexture>>;
  using SamplerMap = std::map<uint64_t, id<MTLSamplerState>>;

  id<MTLRenderCommandEncoder> encoder_;
  id<MTLRenderPipelineState> pipeline_ = nullptr;
  id<MTLDepthStencilState> depth_stencil_ = nullptr;
  std::map<ShaderStage, BufferMap> buffers_;
  std::map<ShaderStage, TextureMap> textures_;
  std::map<ShaderStage, SamplerMap> samplers_;
  std::optional<Viewport> viewport_;
  std::optional<IRect32> scissor_;
  std::optional<uint32_t> stencil_ref_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_PASS_BINDINGS_CACHE_MTL_H_
