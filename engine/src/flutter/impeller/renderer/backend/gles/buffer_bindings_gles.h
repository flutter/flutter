// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <unordered_map>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/backend/gles/gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/command.h"

namespace impeller {

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

  bool BindVertexAttributes(const ProcTableGLES& gl,
                            size_t vertex_offset) const;

  bool BindUniformData(const ProcTableGLES& gl,
                       Allocator& transients_allocator,
                       const Bindings& vertex_bindings,
                       const Bindings& fragment_bindings);

  bool UnbindVertexAttributes(const ProcTableGLES& gl) const;

 private:
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
  };
  std::vector<VertexAttribPointer> vertex_attrib_arrays_;

  std::unordered_map<std::string, GLint> uniform_locations_;

  using BindingMap = std::unordered_map<std::string, std::vector<GLint>>;
  BindingMap binding_map_ = {};

  const std::vector<GLint>& ComputeUniformLocations(
      const ShaderMetadata* metadata);

  GLint ComputeTextureLocation(const ShaderMetadata* metadata);

  bool BindUniformBuffer(const ProcTableGLES& gl,
                         Allocator& transients_allocator,
                         const BufferResource& buffer);

  std::optional<size_t> BindTextures(const ProcTableGLES& gl,
                                     const Bindings& bindings,
                                     ShaderStage stage,
                                     size_t unit_start_index = 0);

  BufferBindingsGLES(const BufferBindingsGLES&) = delete;

  BufferBindingsGLES& operator=(const BufferBindingsGLES&) = delete;
};

}  // namespace impeller
