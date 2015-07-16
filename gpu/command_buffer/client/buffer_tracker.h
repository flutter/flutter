// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_BUFFER_TRACKER_H_
#define GPU_COMMAND_BUFFER_CLIENT_BUFFER_TRACKER_H_

#include <GLES2/gl2.h>

#include <queue>
#include "base/containers/hash_tables.h"
#include "gles2_impl_export.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"

namespace gpu {

class CommandBufferHelper;
class MappedMemoryManager;

namespace gles2 {

// Tracks buffer objects for client side of command buffer.
class GLES2_IMPL_EXPORT BufferTracker {
 public:
  class GLES2_IMPL_EXPORT Buffer {
   public:
    Buffer(GLuint id,
           unsigned int size,
           int32 shm_id,
           uint32 shm_offset,
           void* address)
        : id_(id),
          size_(size),
          shm_id_(shm_id),
          shm_offset_(shm_offset),
          address_(address),
          mapped_(false),
          last_usage_token_(0),
          last_async_upload_token_(0) {
    }

    GLenum id() const {
      return id_;
    }

    unsigned int size() const {
      return size_;
    }

    int32 shm_id() const {
      return shm_id_;
    }

    uint32 shm_offset() const {
      return shm_offset_;
    }

    void* address() const {
      return address_;
    }

    void set_mapped(bool mapped) {
      mapped_ = mapped;
    }

    bool mapped() const {
      return mapped_;
    }

    void set_last_usage_token(int token) {
      last_usage_token_ = token;
    }

    int last_usage_token() const {
      return last_usage_token_;
    }

    void set_last_async_upload_token(uint32 async_token) {
      last_async_upload_token_ = async_token;
    }

    GLuint last_async_upload_token() const {
      return last_async_upload_token_;
    }

   private:
    friend class BufferTracker;
    friend class BufferTrackerTest;

    GLuint id_;
    unsigned int size_;
    int32 shm_id_;
    uint32 shm_offset_;
    void* address_;
    bool mapped_;
    int32 last_usage_token_;
    GLuint last_async_upload_token_;
  };

  BufferTracker(MappedMemoryManager* manager);
  ~BufferTracker();

  Buffer* CreateBuffer(GLuint id, GLsizeiptr size);
  Buffer* GetBuffer(GLuint id);
  void RemoveBuffer(GLuint id);

  // Frees the block of memory associated with buffer, pending the passage
  // of a token.
  void FreePendingToken(Buffer* buffer, int32 token);
  void Unmanage(Buffer* buffer);
  void Free(Buffer* buffer);

 private:
  typedef base::hash_map<GLuint, Buffer*> BufferMap;

  MappedMemoryManager* mapped_memory_;
  BufferMap buffers_;

  DISALLOW_COPY_AND_ASSIGN(BufferTracker);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_BUFFER_TRACKER_H_
