// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_BUFFER_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_BUFFER_H_

#include <stddef.h>

namespace mojo {
namespace internal {

// Buffer provides a way to allocate memory. Allocations are 8-byte aligned and
// zero-initialized. Allocations remain valid for the lifetime of the Buffer.
class Buffer {
 public:
  virtual ~Buffer() {}
  virtual void* Allocate(size_t num_bytes) = 0;
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_BUFFER_H_
