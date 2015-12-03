// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_ALIGNED_ALLOC_H_
#define MOJO_EDK_PLATFORM_ALIGNED_ALLOC_H_

#include <assert.h>
#include <stdint.h>
#include <stdlib.h>

#include <memory>

namespace mojo {
namespace platform {

// "Raw" (C-style) aligned allocation/free -------------------------------------

// Allocates a buffer of a alignment |alignment| (which must be a power of 2 and
// a multiple of |sizeof(void*)|) and size |size| (which must be nonzero).
inline void* RawAlignedAlloc(size_t alignment, size_t size) {
  assert((alignment & (alignment - 1)) == 0u);  // Power-of-2 check.
  assert(alignment % sizeof(void*) == 0u);
  assert(size > 0u);
  void* rv = nullptr;
  if (posix_memalign(&rv, alignment, size) != 0) {
    abort();
    return nullptr;
  }
  assert(rv);
  assert(reinterpret_cast<uintptr_t>(rv) % alignment == 0u);
  return rv;
}

// Frees a buffer that was allocated with |RawAlignedAlloc()|.
inline void RawAlignedFree(void* ptr) {
  free(ptr);
}

// Deleter for buffers allocated using |RawAlignedAlloc()|, for use with
// |std::unique_ptr| (etc.). Use like:
//   std::unique_ptr<char, mojo::platform::RawAlignedFreeDeleter> buffer;
// (or use the |AlignedUniquePtr| type alias below).
struct RawAlignedFreeDeleter {
  void operator()(void* ptr) const { RawAlignedFree(ptr); }
};

// C++ aligned allocation/free wrappers ----------------------------------------

template <typename T>
using AlignedUniquePtr = std::unique_ptr<T, RawAlignedFreeDeleter>;

// Allocates a buffer of nominal type |T|, alignment |alignment| (which must be
// a power of 2, a multiple of |sizeof(void*)| and a nonzero multiple of
// |alignof(T)|), and size |size| (which must be a multiple of |sizeof(T)|).
template <typename T>
inline AlignedUniquePtr<T> AlignedAlloc(size_t alignment, size_t size) {
  assert(size % sizeof(T) == 0u);
  assert(alignment % alignof(T) == 0u);
  return AlignedUniquePtr<T>(static_cast<T*>(RawAlignedAlloc(alignment, size)));
}

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_ALIGNED_ALLOC_H_
