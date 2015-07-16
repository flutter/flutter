// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A class to Manage a growing transfer buffer.

#include "gpu/command_buffer/client/transfer_buffer.h"

#include "base/bits.h"
#include "base/logging.h"
#include "base/trace_event/trace_event.h"
#include "gpu/command_buffer/client/cmd_buffer_helper.h"

namespace gpu {

TransferBuffer::TransferBuffer(
    CommandBufferHelper* helper)
    : helper_(helper),
      result_size_(0),
      default_buffer_size_(0),
      min_buffer_size_(0),
      max_buffer_size_(0),
      alignment_(0),
      size_to_flush_(0),
      bytes_since_last_flush_(0),
      buffer_id_(-1),
      result_buffer_(NULL),
      result_shm_offset_(0),
      usable_(true) {
}

TransferBuffer::~TransferBuffer() {
  Free();
}

bool TransferBuffer::Initialize(
    unsigned int default_buffer_size,
    unsigned int result_size,
    unsigned int min_buffer_size,
    unsigned int max_buffer_size,
    unsigned int alignment,
    unsigned int size_to_flush) {
  result_size_ = result_size;
  default_buffer_size_ = default_buffer_size;
  min_buffer_size_ = min_buffer_size;
  max_buffer_size_ = max_buffer_size;
  alignment_ = alignment;
  size_to_flush_ = size_to_flush;
  ReallocateRingBuffer(default_buffer_size_ - result_size);
  return HaveBuffer();
}

void TransferBuffer::Free() {
  if (HaveBuffer()) {
    TRACE_EVENT0("gpu", "TransferBuffer::Free");
    helper_->Finish();
    helper_->command_buffer()->DestroyTransferBuffer(buffer_id_);
    buffer_id_ = -1;
    buffer_ = NULL;
    result_buffer_ = NULL;
    result_shm_offset_ = 0;
    ring_buffer_.reset();
    bytes_since_last_flush_ = 0;
  }
}

bool TransferBuffer::HaveBuffer() const {
  DCHECK(buffer_id_ == -1 || buffer_.get());
  return buffer_id_ != -1;
}

RingBuffer::Offset TransferBuffer::GetOffset(void* pointer) const {
  return ring_buffer_->GetOffset(pointer);
}

void TransferBuffer::FreePendingToken(void* p, unsigned int token) {
  ring_buffer_->FreePendingToken(p, token);
  if (bytes_since_last_flush_ >= size_to_flush_ && size_to_flush_ > 0) {
    helper_->Flush();
    bytes_since_last_flush_ = 0;
  }
}

void TransferBuffer::AllocateRingBuffer(unsigned int size) {
  for (;size >= min_buffer_size_; size /= 2) {
    int32 id = -1;
    scoped_refptr<gpu::Buffer> buffer =
        helper_->command_buffer()->CreateTransferBuffer(size, &id);
    if (id != -1) {
      DCHECK(buffer.get());
      buffer_ = buffer;
      ring_buffer_.reset(new RingBuffer(
          alignment_,
          result_size_,
          buffer_->size() - result_size_,
          helper_,
          static_cast<char*>(buffer_->memory()) + result_size_));
      buffer_id_ = id;
      result_buffer_ = buffer_->memory();
      result_shm_offset_ = 0;
      return;
    }
    // we failed so don't try larger than this.
    max_buffer_size_ = size / 2;
  }
  usable_ = false;
}

static unsigned int ComputePOTSize(unsigned int dimension) {
  return (dimension == 0) ? 0 : 1 << base::bits::Log2Ceiling(dimension);
}

void TransferBuffer::ReallocateRingBuffer(unsigned int size) {
  // What size buffer would we ask for if we needed a new one?
  unsigned int needed_buffer_size = ComputePOTSize(size + result_size_);
  needed_buffer_size = std::max(needed_buffer_size, min_buffer_size_);
  needed_buffer_size = std::max(needed_buffer_size, default_buffer_size_);
  needed_buffer_size = std::min(needed_buffer_size, max_buffer_size_);

  if (usable_ && (!HaveBuffer() || needed_buffer_size > buffer_->size())) {
    if (HaveBuffer()) {
      Free();
    }
    AllocateRingBuffer(needed_buffer_size);
  }
}

void* TransferBuffer::AllocUpTo(
    unsigned int size, unsigned int* size_allocated) {
  DCHECK(size_allocated);

  ReallocateRingBuffer(size);

  if (!HaveBuffer()) {
    return NULL;
  }

  unsigned int max_size = ring_buffer_->GetLargestFreeOrPendingSize();
  *size_allocated = std::min(max_size, size);
  bytes_since_last_flush_ += *size_allocated;
  return ring_buffer_->Alloc(*size_allocated);
}

void* TransferBuffer::Alloc(unsigned int size) {
  ReallocateRingBuffer(size);

  if (!HaveBuffer()) {
    return NULL;
  }

  unsigned int max_size = ring_buffer_->GetLargestFreeOrPendingSize();
  if (size > max_size) {
    return NULL;
  }

  bytes_since_last_flush_ += size;
  return ring_buffer_->Alloc(size);
}

void* TransferBuffer::GetResultBuffer() {
  ReallocateRingBuffer(result_size_);
  return result_buffer_;
}

int TransferBuffer::GetResultOffset() {
  ReallocateRingBuffer(result_size_);
  return result_shm_offset_;
}

int TransferBuffer::GetShmId() {
  ReallocateRingBuffer(result_size_);
  return buffer_id_;
}

unsigned int TransferBuffer::GetCurrentMaxAllocationWithoutRealloc() const {
  return HaveBuffer() ? ring_buffer_->GetLargestFreeOrPendingSize() : 0;
}

unsigned int TransferBuffer::GetMaxAllocation() const {
  return HaveBuffer() ? max_buffer_size_ - result_size_ : 0;
}

void ScopedTransferBufferPtr::Release() {
  if (buffer_) {
    transfer_buffer_->FreePendingToken(buffer_, helper_->InsertToken());
    buffer_ = NULL;
    size_ = 0;
  }
}

void ScopedTransferBufferPtr::Reset(unsigned int new_size) {
  Release();
  // NOTE: we allocate buffers of size 0 so that HaveBuffer will be true, so
  // that address will return a pointer just like malloc, and so that GetShmId
  // will be valid. That has the side effect that we'll insert a token on free.
  // We could add code skip the token for a zero size buffer but it doesn't seem
  // worth the complication.
  buffer_ = transfer_buffer_->AllocUpTo(new_size, &size_);
}

}  // namespace gpu
