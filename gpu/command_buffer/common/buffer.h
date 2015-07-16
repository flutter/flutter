// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_COMMON_BUFFER_H_
#define GPU_COMMAND_BUFFER_COMMON_BUFFER_H_

#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/shared_memory.h"
#include "gpu/gpu_export.h"

namespace base {
  class SharedMemory;
}

namespace gpu {

class GPU_EXPORT BufferBacking {
 public:
  virtual ~BufferBacking() {}
  virtual void* GetMemory() const = 0;
  virtual size_t GetSize() const = 0;
};

class GPU_EXPORT SharedMemoryBufferBacking : public BufferBacking {
 public:
  SharedMemoryBufferBacking(scoped_ptr<base::SharedMemory> shared_memory,
                            size_t size);
  ~SharedMemoryBufferBacking() override;
  void* GetMemory() const override;
  size_t GetSize() const override;
  base::SharedMemory* shared_memory() { return shared_memory_.get(); }

 private:
  scoped_ptr<base::SharedMemory> shared_memory_;
  size_t size_;
  DISALLOW_COPY_AND_ASSIGN(SharedMemoryBufferBacking);
};

// Buffer owns a piece of shared-memory of a certain size.
class GPU_EXPORT Buffer : public base::RefCountedThreadSafe<Buffer> {
 public:
  explicit Buffer(scoped_ptr<BufferBacking> backing);

  BufferBacking* backing() const { return backing_.get(); }
  void* memory() const { return memory_; }
  size_t size() const { return size_; }

  // Returns NULL if the address overflows the memory.
  void* GetDataAddress(uint32 data_offset, uint32 data_size) const;

 private:
  friend class base::RefCountedThreadSafe<Buffer>;
  ~Buffer();

  scoped_ptr<BufferBacking> backing_;
  void* memory_;
  size_t size_;

  DISALLOW_COPY_AND_ASSIGN(Buffer);
};

static inline scoped_ptr<BufferBacking> MakeBackingFromSharedMemory(
    scoped_ptr<base::SharedMemory> shared_memory,
    size_t size) {
  return scoped_ptr<BufferBacking>(
      new SharedMemoryBufferBacking(shared_memory.Pass(), size));
}

static inline scoped_refptr<Buffer> MakeBufferFromSharedMemory(
    scoped_ptr<base::SharedMemory> shared_memory,
    size_t size) {
  return new Buffer(MakeBackingFromSharedMemory(shared_memory.Pass(), size));
}

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_BUFFER_H_
