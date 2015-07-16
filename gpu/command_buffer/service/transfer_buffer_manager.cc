// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/transfer_buffer_manager.h"

#include <limits>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/process/process_handle.h"
#include "base/trace_event/trace_event.h"
#include "gpu/command_buffer/common/cmd_buffer_common.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"

using ::base::SharedMemory;

namespace gpu {

TransferBufferManagerInterface::~TransferBufferManagerInterface() {
}

TransferBufferManager::TransferBufferManager()
    : shared_memory_bytes_allocated_(0) {
}

TransferBufferManager::~TransferBufferManager() {
  while (!registered_buffers_.empty()) {
    BufferMap::iterator it = registered_buffers_.begin();
    DCHECK(shared_memory_bytes_allocated_ >= it->second->size());
    shared_memory_bytes_allocated_ -= it->second->size();
    registered_buffers_.erase(it);
  }
  DCHECK(!shared_memory_bytes_allocated_);
}

bool TransferBufferManager::Initialize() {
  return true;
}

bool TransferBufferManager::RegisterTransferBuffer(
    int32 id,
    scoped_ptr<BufferBacking> buffer_backing) {
  if (id <= 0) {
    DVLOG(0) << "Cannot register transfer buffer with non-positive ID.";
    return false;
  }

  // Fail if the ID is in use.
  if (registered_buffers_.find(id) != registered_buffers_.end()) {
    DVLOG(0) << "Buffer ID already in use.";
    return false;
  }

  // Register the shared memory with the ID.
  scoped_refptr<Buffer> buffer(new gpu::Buffer(buffer_backing.Pass()));

  // Check buffer alignment is sane.
  DCHECK(!(reinterpret_cast<uintptr_t>(buffer->memory()) &
           (kCommandBufferEntrySize - 1)));

  shared_memory_bytes_allocated_ += buffer->size();
  TRACE_COUNTER_ID1(
      "gpu", "GpuTransferBufferMemory", this, shared_memory_bytes_allocated_);

  registered_buffers_[id] = buffer;

  return true;
}

void TransferBufferManager::DestroyTransferBuffer(int32 id) {
  BufferMap::iterator it = registered_buffers_.find(id);
  if (it == registered_buffers_.end()) {
    DVLOG(0) << "Transfer buffer ID was not registered.";
    return;
  }

  DCHECK(shared_memory_bytes_allocated_ >= it->second->size());
  shared_memory_bytes_allocated_ -= it->second->size();
  TRACE_COUNTER_ID1(
      "gpu", "GpuTransferBufferMemory", this, shared_memory_bytes_allocated_);

  registered_buffers_.erase(it);
}

scoped_refptr<Buffer> TransferBufferManager::GetTransferBuffer(int32 id) {
  if (id == 0)
    return NULL;

  BufferMap::iterator it = registered_buffers_.find(id);
  if (it == registered_buffers_.end())
    return NULL;

  return it->second;
}

}  // namespace gpu

