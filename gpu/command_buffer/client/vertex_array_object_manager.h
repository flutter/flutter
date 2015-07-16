// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_VERTEX_ARRAY_OBJECT_MANAGER_H_
#define GPU_COMMAND_BUFFER_CLIENT_VERTEX_ARRAY_OBJECT_MANAGER_H_

#include <GLES2/gl2.h>

#include "base/containers/hash_tables.h"
#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "gles2_impl_export.h"

namespace gpu {
namespace gles2 {

class GLES2Implementation;
class GLES2CmdHelper;
class VertexArrayObject;

// VertexArrayObjectManager manages vertex array objects on the client side
// of the command buffer.
class GLES2_IMPL_EXPORT VertexArrayObjectManager {
 public:
  VertexArrayObjectManager(
      GLuint max_vertex_attribs,
      GLuint array_buffer_id,
      GLuint element_array_buffer_id,
      bool support_client_side_arrays);
  ~VertexArrayObjectManager();

  bool IsReservedId(GLuint id) const;

  // Binds an element array.
  // Returns true if service should be called.
  bool BindElementArray(GLuint id);

  // Unbind buffer.
  void UnbindBuffer(GLuint id);

  // Geneates array objects for the given ids.
  void GenVertexArrays(GLsizei n, const GLuint* arrays);

  // Deletes array objects for the given ids.
  void DeleteVertexArrays(GLsizei n, const GLuint* arrays);

  // Binds a vertex array.
  // changed will be set to true if the service should be called.
  // Returns false if array is an unknown id.
  bool BindVertexArray(GLuint array, bool* changed);

  // simulated will be set to true if buffers were simulated.
  // Returns true service should be called.
  bool SetupSimulatedClientSideBuffers(
      const char* function_name,
      GLES2Implementation* gl,
      GLES2CmdHelper* gl_helper,
      GLsizei num_elements,
      GLsizei primcount,
      bool* simulated);

  // Returns true if buffers were setup.
  bool SetupSimulatedIndexAndClientSideBuffers(
      const char* function_name,
      GLES2Implementation* gl,
      GLES2CmdHelper* gl_helper,
      GLsizei count,
      GLenum type,
      GLsizei primcount,
      const void* indices,
      GLuint* offset,
      bool* simulated);

  bool HaveEnabledClientSideBuffers() const;

  void SetAttribEnable(GLuint index, bool enabled);

  bool GetVertexAttrib(GLuint index, GLenum pname, uint32* param);

  bool GetAttribPointer(GLuint index, GLenum pname, void** ptr) const;

  // Returns false if error.
  bool SetAttribPointer(
      GLuint buffer_id,
      GLuint index,
      GLint size,
      GLenum type,
      GLboolean normalized,
      GLsizei stride,
      const void* ptr);

  void SetAttribDivisor(GLuint index, GLuint divisor);

  GLuint bound_element_array_buffer() const;

 private:
  typedef base::hash_map<GLuint, VertexArrayObject*> VertexArrayObjectMap;

  bool IsDefaultVAOBound() const;

  GLsizei CollectData(const void* data,
                      GLsizei bytes_per_element,
                      GLsizei real_stride,
                      GLsizei num_elements);

  GLuint max_vertex_attribs_;
  GLuint array_buffer_id_;
  GLsizei array_buffer_size_;
  GLsizei array_buffer_offset_;
  GLuint element_array_buffer_id_;
  GLsizei element_array_buffer_size_;
  GLsizei collection_buffer_size_;
  scoped_ptr<int8[]> collection_buffer_;

  VertexArrayObject* default_vertex_array_object_;
  VertexArrayObject* bound_vertex_array_object_;
  VertexArrayObjectMap vertex_array_objects_;

  const bool support_client_side_arrays_;

  DISALLOW_COPY_AND_ASSIGN(VertexArrayObjectManager);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_VERTEX_ARRAY_OBJECT_MANAGER_H_

