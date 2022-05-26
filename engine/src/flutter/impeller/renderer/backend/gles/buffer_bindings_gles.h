// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/gles/gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/vertex_descriptor.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Sets up stage bindings for single draw call in the OpenGLES
///             backend.
///
class BufferBindingsGLES {
 public:
  BufferBindingsGLES();

  ~BufferBindingsGLES();

  bool RegisterVertexStageInput(const ProcTableGLES& gl,
                                const std::vector<ShaderStageIOSlot>& inputs);

  bool ReadUniformsBindings(const ProcTableGLES& gl, GLuint program);

  bool BindVertexAttributes(const ProcTableGLES& gl,
                            size_t vertex_offset) const;

  bool BindUniformData(const ProcTableGLES& gl,
                       Allocator& transients_allocator,
                       const Bindings& vertex_bindings,
                       const Bindings& fragment_bindings) const;

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
  std::map<std::string, GLint> uniform_locations_;

  bool BindUniformBuffer(const ProcTableGLES& gl,
                         Allocator& transients_allocator,
                         const BufferResource& buffer) const;

  bool BindTextures(const ProcTableGLES& gl,
                    const Bindings& bindings,
                    ShaderStage stage) const;

  FML_DISALLOW_COPY_AND_ASSIGN(BufferBindingsGLES);
};

}  // namespace impeller
