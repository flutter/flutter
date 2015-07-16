// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/mapping_table.h"

#include "base/logging.h"
#include "mojo/edk/embedder/platform_shared_buffer.h"
#include "mojo/edk/system/configuration.h"

namespace mojo {
namespace system {

MappingTable::MappingTable() {
}

MappingTable::~MappingTable() {
  // This should usually not be reached (the only instance should be owned by
  // the singleton |Core|, which lives forever), except in tests.
}

MojoResult MappingTable::AddMapping(
    scoped_ptr<embedder::PlatformSharedBufferMapping> mapping) {
  DCHECK(mapping);

  if (address_to_mapping_map_.size() >=
      GetConfiguration().max_mapping_table_sze)
    return MOJO_RESULT_RESOURCE_EXHAUSTED;

  uintptr_t address = reinterpret_cast<uintptr_t>(mapping->GetBase());
  DCHECK(address_to_mapping_map_.find(address) ==
         address_to_mapping_map_.end());
  address_to_mapping_map_[address] = mapping.release();
  return MOJO_RESULT_OK;
}

MojoResult MappingTable::RemoveMapping(uintptr_t address) {
  AddressToMappingMap::iterator it = address_to_mapping_map_.find(address);
  if (it == address_to_mapping_map_.end())
    return MOJO_RESULT_INVALID_ARGUMENT;
  embedder::PlatformSharedBufferMapping* mapping_to_delete = it->second;
  address_to_mapping_map_.erase(it);
  delete mapping_to_delete;
  return MOJO_RESULT_OK;
}

}  // namespace system
}  // namespace mojo
