// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/id_manager.h"
#include "base/logging.h"

namespace gpu {
namespace gles2 {

IdManager::IdManager() {}

IdManager::~IdManager() {}

bool IdManager::AddMapping(GLuint client_id, GLuint service_id) {
  std::pair<MapType::iterator, bool> result = id_map_.insert(
      std::make_pair(client_id, service_id));
  return result.second;
}

bool IdManager::RemoveMapping(GLuint client_id, GLuint service_id) {
  MapType::iterator iter = id_map_.find(client_id);
  if (iter != id_map_.end() && iter->second == service_id) {
    id_map_.erase(iter);
    return true;
  }
  return false;
}

bool IdManager::GetServiceId(GLuint client_id, GLuint* service_id) {
  DCHECK(service_id);
  MapType::iterator iter = id_map_.find(client_id);
  if (iter != id_map_.end()) {
    *service_id = iter->second;
    return true;
  }
  return false;
}

bool IdManager::GetClientId(GLuint service_id, GLuint* client_id) {
  DCHECK(client_id);
  MapType::iterator end(id_map_.end());
  for (MapType::iterator iter(id_map_.begin());
       iter != end;
       ++iter) {
    if (iter->second == service_id) {
      *client_id = iter->first;
      return true;
    }
  }
  return false;
}

}  // namespace gles2
}  // namespace gpu


