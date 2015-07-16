// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_TRANSFER_BUFFER_H_
#define GPU_COMMAND_BUFFER_CLIENT_TRANSFER_BUFFER_H_

#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/client/ring_buffer.h"
#include "gpu/command_buffer/common/buffer.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/gpu_export.h"

namespace gpu {

class CommandBufferHelper;

// Interface for managing the transfer buffer.
class GPU_EXPORT TransferBufferInterface {
 public:
  TransferBufferInterface() { }
  virtual ~TransferBufferInterface() { }

  virtual bool Initialize(
      unsigned int buffer_size,
      unsigned int result_size,
      unsigned int min_buffer_size,
      unsigned int max_buffer_size,
      unsigned int alignment,
      unsigned int size_to_flush) = 0;

  virtual int GetShmId() = 0;
  virtual void* GetResultBuffer() = 0;
  virtual int GetResultOffset() = 0;

  virtual void Free() = 0;

  virtual bool HaveBuffer() const = 0;

  // Allocates up to size bytes.
  virtual void* AllocUpTo(unsigned int size, unsigned int* size_allocated) = 0;

  // Allocates size bytes.
  // Note: Alloc will fail if it can not return size bytes.
  virtual void* Alloc(unsigned int size) = 0;

  virtual RingBuffer::Offset GetOffset(void* pointer) const = 0;

  virtual void FreePendingToken(void* p, unsigned int token) = 0;
};

// Class that manages the transfer buffer.
class GPU_EXPORT TransferBuffer : public TransferBufferInterface {
 public:
  TransferBuffer(CommandBufferHelper* helper);
  ~TransferBuffer() override;

  // Overridden from TransferBufferInterface.
  bool Initialize(unsigned int default_buffer_size,
                  unsigned int result_size,
                  unsigned int min_buffer_size,
                  unsigned int max_buffer_size,
                  unsigned int alignment,
                  unsigned int size_to_flush) override;
  int GetShmId() override;
  void* GetResultBuffer() override;
  int GetResultOffset() override;
  void Free() override;
  bool HaveBuffer() const override;
  void* AllocUpTo(unsigned int size, unsigned int* size_allocated) override;
  void* Alloc(unsigned int size) override;
  RingBuffer::Offset GetOffset(void* pointer) const override;
  void FreePendingToken(void* p, unsigned int token) override;

  // These are for testing.
  unsigned int GetCurrentMaxAllocationWithoutRealloc() const;
  unsigned int GetMaxAllocation() const;

 private:
  // Tries to reallocate the ring buffer if it's not large enough for size.
  void ReallocateRingBuffer(unsigned int size);

  void AllocateRingBuffer(unsigned int size);

  CommandBufferHelper* helper_;
  scoped_ptr<RingBuffer> ring_buffer_;

  // size reserved for results
  unsigned int result_size_;

  // default size. Size we want when starting or re-allocating
  unsigned int default_buffer_size_;

  // min size we'll consider successful
  unsigned int min_buffer_size_;

  // max size we'll let the buffer grow
  unsigned int max_buffer_size_;

  // alignment for allocations
  unsigned int alignment_;

  // Size at which to do an async flush. 0 = never.
  unsigned int size_to_flush_;

  // Number of bytes since we last flushed.
  unsigned int bytes_since_last_flush_;

  // the current buffer.
  scoped_refptr<gpu::Buffer> buffer_;

  // id of buffer. -1 = no buffer
  int32 buffer_id_;

  // address of result area
  void* result_buffer_;

  // offset to result area
  uint32 result_shm_offset_;

  // false if we failed to allocate min_buffer_size
  bool usable_;
};

// A class that will manage the lifetime of a transferbuffer allocation.
class GPU_EXPORT ScopedTransferBufferPtr {
 public:
  ScopedTransferBufferPtr(
      unsigned int size,
      CommandBufferHelper* helper,
      TransferBufferInterface* transfer_buffer)
      : buffer_(NULL),
        size_(0),
        helper_(helper),
        transfer_buffer_(transfer_buffer) {
    Reset(size);
  }

  ~ScopedTransferBufferPtr() {
    Release();
  }

  bool valid() const {
    return buffer_ != NULL;
  }

  unsigned int size() const {
    return size_;
  }

  int shm_id() const {
    return transfer_buffer_->GetShmId();
  }

  RingBuffer::Offset offset() const {
    return transfer_buffer_->GetOffset(buffer_);
  }

  void* address() const {
    return buffer_;
  }

  void Release();

  void Reset(unsigned int new_size);

 private:
  void* buffer_;
  unsigned int size_;
  CommandBufferHelper* helper_;
  TransferBufferInterface* transfer_buffer_;
  DISALLOW_COPY_AND_ASSIGN(ScopedTransferBufferPtr);
};

template <typename T>
class ScopedTransferBufferArray : public ScopedTransferBufferPtr {
 public:
  ScopedTransferBufferArray(
      unsigned int num_elements,
      CommandBufferHelper* helper, TransferBufferInterface* transfer_buffer)
      : ScopedTransferBufferPtr(
          num_elements * sizeof(T), helper, transfer_buffer) {
  }

  T* elements() {
    return static_cast<T*>(address());
  }

  unsigned int num_elements() const {
    return size() / sizeof(T);
  }
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_TRANSFER_BUFFER_H_
