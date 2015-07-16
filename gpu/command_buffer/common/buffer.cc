// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/common/buffer.h"

#include "base/logging.h"

#include "base/numerics/safe_math.h"

namespace gpu {
SharedMemoryBufferBacking::SharedMemoryBufferBacking(
    scoped_ptr<base::SharedMemory> shared_memory,
    size_t size)
    : shared_memory_(shared_memory.Pass()), size_(size) {}

SharedMemoryBufferBacking::~SharedMemoryBufferBacking() {}

void* SharedMemoryBufferBacking::GetMemory() const {
  return shared_memory_->memory();
}

size_t SharedMemoryBufferBacking::GetSize() const { return size_; }

Buffer::Buffer(scoped_ptr<BufferBacking> backing)
    : backing_(backing.Pass()),
      memory_(backing_->GetMemory()),
      size_(backing_->GetSize()) {
  DCHECK(memory_) << "The memory must be mapped to create a Buffer";
}

Buffer::~Buffer() {}

void* Buffer::GetDataAddress(uint32 data_offset, uint32 data_size) const {
  base::CheckedNumeric<uint32> end = data_offset;
  end += data_size;
  if (!end.IsValid() || end.ValueOrDie() > static_cast<uint32>(size_))
    return NULL;
  return static_cast<uint8*>(memory_) + data_offset;
}

} // namespace gpu
