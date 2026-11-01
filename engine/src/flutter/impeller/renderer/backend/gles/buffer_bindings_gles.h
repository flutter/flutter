// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_BUFFER_BINDINGS_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_BUFFER_BINDINGS_GLES_H_

#include <array>
#include <cstdint>
#include <optional>
#include <vector>

#include "impeller/core/shader_types.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/gles.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/backend/gles/sampler_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"
#include "impeller/renderer/command.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_map.h"

namespace impeller {

namespace testing {
FML_TEST_CLASS(BufferBindingsGLESTest, BindUniformData);
FML_TEST_CLASS(BufferBindingsGLESTest, BindArrayData);
FML_TEST_CLASS(BufferBindingsGLESTest, BindUniformDataVerticesAndMatrices);
FML_TEST_CLASS(BufferBindingsGLESTest, BindUniformFailsWithoutFloatType);
FML_TEST_CLASS(BufferBindingsGLESTest,
               BindsTexturesAcrossThePerStageUnitBoundary);
FML_TEST_CLASS(BufferBindingsGLESTest, RejectsTexturesBeyondThePerStageLimit);
FML_TEST_CLASS(BufferBindingsGLESTest, RejectsTexturesBeyondTheCombinedLimit);
FML_TEST_CLASS(BufferBindingsGLESTest,
               SkipsRedundantSamplerConfigurationOnSameTexture);
FML_TEST_CLASS(BufferBindingsGLESTest,
               DeduplicatesActiveTextureBindTextureAndSamplerUniform);
}  // namespace testing

//------------------------------------------------------------------------------
/// @brief      Caches the sampler configuration state applied to GL texture
///             objects during a render pass.
///
class SamplerStateCache {
 public:
  SamplerStateCache() = default;

  ~SamplerStateCache() = default;

  bool IsTextureConfigured(const SamplerGLES& sampler,
                           const TextureGLES& texture) const;

  bool ConfigureBoundTexture(const SamplerGLES& sampler,
                             const TextureGLES& texture,
                             const ProcTableGLES& gl);

 private:
  absl::flat_hash_map<HandleGLES, uint64_t, HandleGLES::Hash, HandleGLES::Equal>
      configured_samplers_;

  SamplerStateCache(const SamplerStateCache&) = delete;

  SamplerStateCache& operator=(const SamplerStateCache&) = delete;
};

//------------------------------------------------------------------------------
/// @brief      Caches OpenGL ES vertex attribute array, buffer binding, and
///             texture unit state across draw commands within a render pass.
///
class VertexAttribStateCache {
 public:
  static constexpr size_t kMaxVertexAttribs = 16;
  static constexpr size_t kMaxTextureUnits = 32;

  VertexAttribStateCache() = default;

  ~VertexAttribStateCache() = default;

  void BeginDrawVertexAttributes() { current_draw_attribs_mask_ = 0; }

  void MarkAttributeUsed(GLuint index) {
    if (index < kMaxVertexAttribs) {
      current_draw_attribs_mask_ |= (1u << index);
    }
  }

  bool BindVertexAttribute(const ProcTableGLES& gl,
                           GLuint index,
                           GLint size,
                           GLenum type,
                           GLenum normalized,
                           GLsizei stride,
                           size_t attribute_offset,
                           GLuint divisor);

  void DisableUnusedAttribsBeforeDraw(const ProcTableGLES& gl);

  void ResetAtPassEnd(const ProcTableGLES& gl);

  [[nodiscard]] bool BindArrayBuffer(const DeviceBufferGLES& buffer);

  [[nodiscard]] bool BindElementArrayBuffer(const DeviceBufferGLES& buffer);

  [[nodiscard]] bool BindAndConfigureTexture(const ProcTableGLES& gl,
                                             size_t unit_index,
                                             GLenum target_unit,
                                             const TextureGLES& texture,
                                             const SamplerGLES& sampler,
                                             SamplerStateCache* sampler_cache);

  void BindSamplerUniform(const ProcTableGLES& gl,
                          GLuint program_handle,
                          GLint location,
                          size_t unit_index);

  // For testing.
  void SetBoundArrayBufferForTest(GLuint vbo) { bound_array_buffer_ = vbo; }

 private:
  struct AttribSlotState {
    GLuint vbo = 0;
    GLint size = 0;
    GLenum type = 0;
    GLboolean normalized = GL_FALSE;
    GLsizei stride = 0;
    uintptr_t offset = 0;
    GLuint divisor = 0;
    bool valid = false;
  };

  GLuint bound_array_buffer_ = 0;
  GLuint bound_element_array_buffer_ = 0;
  uint32_t enabled_attribs_mask_ = 0;
  uint32_t current_draw_attribs_mask_ = 0;
  uint32_t non_zero_divisor_mask_ = 0;
  std::array<AttribSlotState, kMaxVertexAttribs> slots_ = {};
  GLenum active_texture_unit_ = 0;
  std::array<std::optional<GLuint>, kMaxTextureUnits> bound_textures_ = {};
  absl::flat_hash_map<uint64_t, GLint> configured_sampler_uniforms_ = {};

  VertexAttribStateCache(const VertexAttribStateCache&) = delete;

  VertexAttribStateCache& operator=(const VertexAttribStateCache&) = delete;
};

//------------------------------------------------------------------------------
/// @brief      Sets up stage bindings for single draw call in the OpenGLES
///             backend.
///
class BufferBindingsGLES {
 public:
  BufferBindingsGLES();

  ~BufferBindingsGLES();

  bool RegisterVertexStageInput(
      const ProcTableGLES& gl,
      const std::vector<ShaderStageIOSlot>& inputs,
      const std::vector<ShaderStageBufferLayout>& layouts);

  bool ReadUniformsBindings(const ProcTableGLES& gl, GLuint program);

  /// Bind the vertex attributes for buffer slot [binding].
  ///
  /// [instance] re-points instance-rate attributes at the given instance,
  /// used to emulate an instanced draw on drivers without hardware
  /// instancing support. It is 0 for a non-instanced or hardware-instanced
  /// draw.
  bool BindVertexAttributes(const ProcTableGLES& gl,
                            size_t binding,
                            size_t vertex_offset,
                            size_t instance = 0,
                            VertexAttribStateCache* attrib_cache = nullptr);

  bool BindUniformData(const ProcTableGLES& gl,
                       const std::vector<TextureAndSampler>& bound_textures,
                       const std::vector<BufferResource>& bound_buffers,
                       Range texture_range,
                       Range buffer_range,
                       SamplerStateCache* sampler_cache = nullptr,
                       VertexAttribStateCache* attrib_cache = nullptr);

  bool UnbindVertexAttributes(const ProcTableGLES& gl);

 private:
  FML_FRIEND_TEST(testing::BufferBindingsGLESTest, BindUniformData);
  FML_FRIEND_TEST(testing::BufferBindingsGLESTest, BindArrayData);
  FML_FRIEND_TEST(testing::BufferBindingsGLESTest,
                  BindUniformDataVerticesAndMatrices);
  FML_FRIEND_TEST(testing::BufferBindingsGLESTest,
                  BindUniformFailsWithoutFloatType);
  FML_FRIEND_TEST(testing::BufferBindingsGLESTest,
                  BindsTexturesAcrossThePerStageUnitBoundary);
  FML_FRIEND_TEST(testing::BufferBindingsGLESTest,
                  RejectsTexturesBeyondThePerStageLimit);
  FML_FRIEND_TEST(testing::BufferBindingsGLESTest,
                  RejectsTexturesBeyondTheCombinedLimit);
  FML_FRIEND_TEST(testing::BufferBindingsGLESTest,
                  SkipsRedundantSamplerConfigurationOnSameTexture);
  FML_FRIEND_TEST(testing::BufferBindingsGLESTest,
                  DeduplicatesActiveTextureBindTextureAndSamplerUniform);
  //----------------------------------------------------------------------------
  /// @brief      The arguments to glVertexAttribPointer.
  ///
  struct VertexAttribPointer {
    GLuint index = 0u;
    GLint size = 4;
    GLenum type = GL_FLOAT;
    GLenum normalized = GL_FALSE;
    GLsizei stride = 0u;
    GLsizei offset = 0u;
    // glVertexAttribDivisor value: 0 advances per vertex, 1 per instance.
    GLuint vertex_attrib_divisor = 0u;
  };
  std::vector<std::vector<VertexAttribPointer>> vertex_attrib_arrays_;

  absl::flat_hash_map<std::string, GLint> uniform_locations_;
  struct UBOInfo {
    GLint block_index = 0;
    GLuint binding_point = 0;
    GLint data_size = 0;
  };
  absl::flat_hash_map<std::string, UBOInfo> ubo_locations_;

  using BindingMap = absl::flat_hash_map<std::string, std::vector<GLint>>;
  BindingMap binding_map_ = {};
  GLuint vertex_array_object_ = 0;
  GLuint program_handle_ = GL_NONE;
  bool use_ubo_ = false;

  const std::vector<GLint>& ComputeUniformLocations(
      const ShaderMetadata* metadata);

  bool ReadUniformsBindingsV2(const ProcTableGLES& gl, GLuint program);

  bool ReadUniformsBindingsV3(const ProcTableGLES& gl, GLuint program);

  GLint ComputeTextureLocation(const ShaderMetadata* metadata);

  bool BindUniformBuffer(const ProcTableGLES& gl, const BufferResource& buffer);

  bool BindUniformBufferV2(const ProcTableGLES& gl,
                           const BufferView& buffer,
                           const ShaderMetadata* metadata,
                           const DeviceBufferGLES& device_buffer_gles);

  bool BindUniformBufferV3(const ProcTableGLES& gl,
                           const BufferView& buffer,
                           const ShaderMetadata* metadata,
                           const DeviceBufferGLES& device_buffer_gles);

  std::optional<size_t> BindTextures(
      const ProcTableGLES& gl,
      const std::vector<TextureAndSampler>& bound_textures,
      Range texture_range,
      ShaderStage stage,
      size_t unit_start_index = 0,
      SamplerStateCache* sampler_cache = nullptr,
      VertexAttribStateCache* attrib_cache = nullptr);

  BufferBindingsGLES(const BufferBindingsGLES&) = delete;

  BufferBindingsGLES& operator=(const BufferBindingsGLES&) = delete;

  // For testing.
  void SetUniformBindings(
      absl::flat_hash_map<std::string, GLint> uniform_locations) {
    uniform_locations_ = std::move(uniform_locations);
  }
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_BUFFER_BINDINGS_GLES_H_
