// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_FIXED_BUFFER_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_FIXED_BUFFER_H_

#include "mojo/public/cpp/bindings/lib/buffer.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace internal {

// FixedBuffer provides a simple way to allocate objects within a fixed chunk
// of memory. Objects are allocated by calling the |Allocate| method, which
// extends the buffer accordingly. Objects allocated in this way are not freed
// explicitly. Instead, they remain valid so long as the FixedBuffer remains
// valid.  The Leak method may be used to steal the underlying memory from the
// FixedBuffer.
//
// Typical usage:
//
//   {
//     FixedBuffer buf(8 + 8);
//
//     int* a = static_cast<int*>(buf->Allocate(sizeof(int)));
//     *a = 2;
//
//     double* b = static_cast<double*>(buf->Allocate(sizeof(double)));
//     *b = 3.14f;
//
//     void* data = buf.Leak();
//     Process(data);
//
//     free(data);
//   }
//
class FixedBuffer : public Buffer {
 public:
  explicit FixedBuffer(size_t size);
  ~FixedBuffer() override;

  // Grows the buffer by |num_bytes| and returns a pointer to the start of the
  // addition. The resulting address is 8-byte aligned, and the content of the
  // memory is zero-filled.
  void* Allocate(size_t num_bytes) override;

  size_t size() const { return size_; }

  // Returns the internal memory owned by the Buffer to the caller. The Buffer
  // relinquishes its pointer, effectively resetting the state of the Buffer
  // and leaving the caller responsible for freeing the returned memory address
  // when no longer needed.
  void* Leak();

 private:
  char* ptr_;
  size_t cursor_;
  size_t size_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(FixedBuffer);
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_FIXED_BUFFER_H_
