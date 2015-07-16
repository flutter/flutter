// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_ID_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_ID_MANAGER_H_

#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

// This class maps one set of ids to another.
//
// NOTE: To support shared resources an instance of this class will
// need to be shared by multiple GLES2Decoders.
class GPU_EXPORT IdManager {
 public:
  IdManager();
  ~IdManager();

  // Maps a client_id to a service_id. Return false if the client_id or
  // service_id are already mapped to something else.
  bool AddMapping(GLuint client_id, GLuint service_id);

  // Unmaps a pair of ids. Returns false if the pair were not previously mapped.
  bool RemoveMapping(GLuint client_id, GLuint service_id);

  // Gets the corresponding service_id for the given client_id.
  // Returns false if there is no corresponding service_id.
  bool GetServiceId(GLuint client_id, GLuint* service_id);

  // Gets the corresponding client_id for the given service_id.
  // Returns false if there is no corresponding client_id.
  bool GetClientId(GLuint service_id, GLuint* client_id);

 private:
  typedef base::hash_map<GLuint, GLuint> MapType;
  MapType id_map_;

  DISALLOW_COPY_AND_ASSIGN(IdManager);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_ID_MANAGER_H_

