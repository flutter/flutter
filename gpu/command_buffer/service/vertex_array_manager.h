// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_VERTEX_ARRAY_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_VERTEX_ARRAY_MANAGER_H_

#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

class VertexAttribManager;

// This class keeps track of the vertex arrays and their sizes so we can do
// bounds checking.
class GPU_EXPORT VertexArrayManager {
 public:
  VertexArrayManager();
  ~VertexArrayManager();

  // Must call before destruction.
  void Destroy(bool have_context);

  // Creates a VertexAttribManager and if client_visible,
  // maps it to the client_id.
  scoped_refptr<VertexAttribManager> CreateVertexAttribManager(
      GLuint client_id,
      GLuint service_id,
      uint32 num_vertex_attribs,
      bool client_visible);

  // Gets the vertex attrib manager for the given vertex array.
  VertexAttribManager* GetVertexAttribManager(GLuint client_id);

  // Removes the vertex attrib manager for the given vertex array.
  void RemoveVertexAttribManager(GLuint client_id);

  // Gets a client id for a given service id.
  bool GetClientId(GLuint service_id, GLuint* client_id) const;

 private:
  friend class VertexAttribManager;

  void StartTracking(VertexAttribManager* vertex_attrib_manager);
  void StopTracking(VertexAttribManager* vertex_attrib_manager);

  // Info for each vertex array in the system.
  typedef base::hash_map<GLuint, scoped_refptr<VertexAttribManager> >
      VertexAttribManagerMap;
  VertexAttribManagerMap vertex_attrib_managers_;

  // Counts the number of VertexArrayInfo allocated with 'this' as its manager.
  // Allows to check no VertexArrayInfo will outlive this.
  unsigned int vertex_attrib_manager_count_;

  bool have_context_;

  DISALLOW_COPY_AND_ASSIGN(VertexArrayManager);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_VERTEX_ARRAY_MANAGER_H_
