// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the definition of the RingBuffer class.

#ifndef GPU_COMMAND_BUFFER_CLIENT_RING_BUFFER_H_
#define GPU_COMMAND_BUFFER_CLIENT_RING_BUFFER_H_

#include <deque>

#include "base/logging.h"
#include "base/macros.h"
#include "gpu/gpu_export.h"

namespace gpu {
class CommandBufferHelper;

// RingBuffer manages a piece of memory as a ring buffer. Memory is allocated
// with Alloc and then a is freed pending a token with FreePendingToken.  Old
// allocations must not be kept past new allocations.
class GPU_EXPORT RingBuffer {
 public:
  typedef unsigned int Offset;

  // Creates a RingBuffer.
  // Parameters:
  //   alignment: Alignment for allocations.
  //   base_offset: The offset of the start of the buffer.
  //   size: The size of the buffer in bytes.
  //   helper: A CommandBufferHelper for dealing with tokens.
  //   base: The physical address that corresponds to base_offset.
  RingBuffer(unsigned int alignment, Offset base_offset,
             unsigned int size, CommandBufferHelper* helper, void* base);

  ~RingBuffer();

  // Allocates a block of memory. If the buffer is out of directly available
  // memory, this function may wait until memory that was freed "pending a
  // token" can be re-used.
  //
  // Parameters:
  //   size: the size of the memory block to allocate.
  //
  // Returns:
  //   the pointer to the allocated memory block.
  void* Alloc(unsigned int size);

  // Frees a block of memory, pending the passage of a token. That memory won't
  // be re-allocated until the token has passed through the command stream.
  //
  // Parameters:
  //   pointer: the pointer to the memory block to free.
  //   token: the token value to wait for before re-using the memory.
  void FreePendingToken(void* pointer, unsigned int token);

  // Gets the size of the largest free block that is available without waiting.
  unsigned int GetLargestFreeSizeNoWaiting();

  // Gets the size of the largest free block that can be allocated if the
  // caller can wait. Allocating a block of this size will succeed, but may
  // block.
  unsigned int GetLargestFreeOrPendingSize() {
    return size_;
  }

  // Gets a pointer to a memory block given the base memory and the offset.
  void* GetPointer(RingBuffer::Offset offset) const {
    return static_cast<int8*>(base_) + offset;
  }

  // Gets the offset to a memory block given the base memory and the address.
  RingBuffer::Offset GetOffset(void* pointer) const {
    return static_cast<int8*>(pointer) - static_cast<int8*>(base_);
  }

  // Rounds the given size to the alignment in use.
  unsigned int RoundToAlignment(unsigned int size) {
    return (size + alignment_ - 1) & ~(alignment_ - 1);
  }


 private:
  enum State {
    IN_USE,
    PADDING,
    FREE_PENDING_TOKEN
  };
  // Book-keeping sturcture that describes a block of memory.
  struct Block {
    Block(Offset _offset, unsigned int _size, State _state)
        : offset(_offset),
          size(_size),
          token(0),
          state(_state) {
    }
    Offset offset;
    unsigned int size;
    unsigned int token;  // token to wait for.
    State state;
  };

  typedef std::deque<Block> Container;
  typedef unsigned int BlockIndex;

  void FreeOldestBlock();

  CommandBufferHelper* helper_;

  // Used blocks are added to the end, blocks are freed from the beginning.
  Container blocks_;

  // The base offset of the ring buffer.
  Offset base_offset_;

  // The size of the ring buffer.
  Offset size_;

  // Offset of first free byte.
  Offset free_offset_;

  // Offset of first used byte.
  // Range between in_use_mark and free_mark is in use.
  Offset in_use_offset_;

  // Alignment for allocations.
  unsigned int alignment_;

  // The physical address that corresponds to base_offset.
  void* base_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(RingBuffer);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_RING_BUFFER_H_
