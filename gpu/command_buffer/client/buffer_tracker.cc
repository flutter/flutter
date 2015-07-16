// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/buffer_tracker.h"

#include "gpu/command_buffer/client/cmd_buffer_helper.h"
#include "gpu/command_buffer/client/mapped_memory.h"

namespace gpu {
namespace gles2 {

BufferTracker::BufferTracker(MappedMemoryManager* manager)
    : mapped_memory_(manager) {
}

BufferTracker::~BufferTracker() {
  while (!buffers_.empty()) {
    RemoveBuffer(buffers_.begin()->first);
  }
}

BufferTracker::Buffer* BufferTracker::CreateBuffer(
    GLuint id, GLsizeiptr size) {
  DCHECK_NE(0u, id);
  DCHECK_LE(0, size);
  int32 shm_id = -1;
  uint32 shm_offset = 0;
  void* address = NULL;
  if (size)
    address = mapped_memory_->Alloc(size, &shm_id, &shm_offset);

  Buffer* buffer = new Buffer(id, size, shm_id, shm_offset, address);
  std::pair<BufferMap::iterator, bool> result =
      buffers_.insert(std::make_pair(id, buffer));
  DCHECK(result.second);
  return buffer;
}

BufferTracker::Buffer* BufferTracker::GetBuffer(GLuint client_id) {
  BufferMap::iterator it = buffers_.find(client_id);
  return it != buffers_.end() ? it->second : NULL;
}

void BufferTracker::RemoveBuffer(GLuint client_id) {
  BufferMap::iterator it = buffers_.find(client_id);
  if (it != buffers_.end()) {
    Buffer* buffer = it->second;
    buffers_.erase(it);
    if (buffer->address_)
      mapped_memory_->Free(buffer->address_);
    delete buffer;
  }
}

void BufferTracker::FreePendingToken(Buffer* buffer, int32 token) {
  if (buffer->address_)
    mapped_memory_->FreePendingToken(buffer->address_, token);
  buffer->size_ = 0;
  buffer->shm_id_ = 0;
  buffer->shm_offset_ = 0;
  buffer->address_ = NULL;
  buffer->last_usage_token_ = 0;
  buffer->last_async_upload_token_ = 0;
}

void BufferTracker::Unmanage(Buffer* buffer) {
  buffer->size_ = 0;
  buffer->shm_id_ = 0;
  buffer->shm_offset_ = 0;
  buffer->address_ = NULL;
  buffer->last_usage_token_ = 0;
  buffer->last_async_upload_token_ = 0;
}

void BufferTracker::Free(Buffer* buffer) {
  if (buffer->address_)
    mapped_memory_->Free(buffer->address_);

  buffer->size_ = 0;
  buffer->shm_id_ = 0;
  buffer->shm_offset_ = 0;
  buffer->address_ = NULL;
  buffer->last_usage_token_ = 0;
  buffer->last_async_upload_token_ = 0;
}

}  // namespace gles2
}  // namespace gpu
