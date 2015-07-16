// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/mapped_memory.h"

#include <algorithm>
#include <functional>

#include "base/logging.h"
#include "base/trace_event/trace_event.h"
#include "gpu/command_buffer/client/cmd_buffer_helper.h"

namespace gpu {

MemoryChunk::MemoryChunk(int32 shm_id,
                         scoped_refptr<gpu::Buffer> shm,
                         CommandBufferHelper* helper,
                         const base::Closure& poll_callback)
    : shm_id_(shm_id),
      shm_(shm),
      allocator_(shm->size(), helper, poll_callback, shm->memory()) {}

MemoryChunk::~MemoryChunk() {}

MappedMemoryManager::MappedMemoryManager(CommandBufferHelper* helper,
                                         const base::Closure& poll_callback,
                                         size_t unused_memory_reclaim_limit)
    : chunk_size_multiple_(FencedAllocator::kAllocAlignment),
      helper_(helper),
      poll_callback_(poll_callback),
      allocated_memory_(0),
      max_free_bytes_(unused_memory_reclaim_limit) {
}

MappedMemoryManager::~MappedMemoryManager() {
  CommandBuffer* cmd_buf = helper_->command_buffer();
  for (MemoryChunkVector::iterator iter = chunks_.begin();
       iter != chunks_.end(); ++iter) {
    MemoryChunk* chunk = *iter;
    cmd_buf->DestroyTransferBuffer(chunk->shm_id());
  }
}

void* MappedMemoryManager::Alloc(
    unsigned int size, int32* shm_id, unsigned int* shm_offset) {
  DCHECK(shm_id);
  DCHECK(shm_offset);
  if (size <= allocated_memory_) {
    size_t total_bytes_in_use = 0;
    // See if any of the chunks can satisfy this request.
    for (size_t ii = 0; ii < chunks_.size(); ++ii) {
      MemoryChunk* chunk = chunks_[ii];
      chunk->FreeUnused();
      total_bytes_in_use += chunk->bytes_in_use();
      if (chunk->GetLargestFreeSizeWithoutWaiting() >= size) {
        void* mem = chunk->Alloc(size);
        DCHECK(mem);
        *shm_id = chunk->shm_id();
        *shm_offset = chunk->GetOffset(mem);
        return mem;
      }
    }

    // If there is a memory limit being enforced and total free
    // memory (allocated_memory_ - total_bytes_in_use) is larger than
    // the limit try waiting.
    if (max_free_bytes_ != kNoLimit &&
        (allocated_memory_ - total_bytes_in_use) >= max_free_bytes_) {
      TRACE_EVENT0("gpu", "MappedMemoryManager::Alloc::wait");
      for (size_t ii = 0; ii < chunks_.size(); ++ii) {
        MemoryChunk* chunk = chunks_[ii];
        if (chunk->GetLargestFreeSizeWithWaiting() >= size) {
          void* mem = chunk->Alloc(size);
          DCHECK(mem);
          *shm_id = chunk->shm_id();
          *shm_offset = chunk->GetOffset(mem);
          return mem;
        }
      }
    }
  }

  // Make a new chunk to satisfy the request.
  CommandBuffer* cmd_buf = helper_->command_buffer();
  unsigned int chunk_size =
      ((size + chunk_size_multiple_ - 1) / chunk_size_multiple_) *
      chunk_size_multiple_;
  int32 id = -1;
  scoped_refptr<gpu::Buffer> shm =
      cmd_buf->CreateTransferBuffer(chunk_size, &id);
  if (id  < 0)
    return NULL;
  DCHECK(shm.get());
  MemoryChunk* mc = new MemoryChunk(id, shm, helper_, poll_callback_);
  allocated_memory_ += mc->GetSize();
  chunks_.push_back(mc);
  void* mem = mc->Alloc(size);
  DCHECK(mem);
  *shm_id = mc->shm_id();
  *shm_offset = mc->GetOffset(mem);
  return mem;
}

void MappedMemoryManager::Free(void* pointer) {
  for (size_t ii = 0; ii < chunks_.size(); ++ii) {
    MemoryChunk* chunk = chunks_[ii];
    if (chunk->IsInChunk(pointer)) {
      chunk->Free(pointer);
      return;
    }
  }
  NOTREACHED();
}

void MappedMemoryManager::FreePendingToken(void* pointer, int32 token) {
  for (size_t ii = 0; ii < chunks_.size(); ++ii) {
    MemoryChunk* chunk = chunks_[ii];
    if (chunk->IsInChunk(pointer)) {
      chunk->FreePendingToken(pointer, token);
      return;
    }
  }
  NOTREACHED();
}

void MappedMemoryManager::FreeUnused() {
  CommandBuffer* cmd_buf = helper_->command_buffer();
  MemoryChunkVector::iterator iter = chunks_.begin();
  while (iter != chunks_.end()) {
    MemoryChunk* chunk = *iter;
    chunk->FreeUnused();
    if (!chunk->InUse()) {
      cmd_buf->DestroyTransferBuffer(chunk->shm_id());
      allocated_memory_ -= chunk->GetSize();
      iter = chunks_.erase(iter);
    } else {
      ++iter;
    }
  }
}

}  // namespace gpu
