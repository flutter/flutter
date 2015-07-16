// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_BOUNDS_CHECKER_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_BOUNDS_CHECKER_H_

#include <stdint.h>

#include "mojo/public/cpp/system/macros.h"

namespace mojo {

class Handle;

namespace internal {

// BoundsChecker is used to validate object sizes, pointers and handle indices
// for payload of incoming messages.
class BoundsChecker {
 public:
  // [data, data + data_num_bytes) specifies the initial valid memory range.
  // [0, num_handles) specifies the initial valid range of handle indices.
  BoundsChecker(const void* data, uint32_t data_num_bytes, size_t num_handles);

  ~BoundsChecker();

  // Claims the specified memory range.
  // The method succeeds if the range is valid to claim. (Please see
  // the comments for IsValidRange().)
  // On success, the valid memory range is shrinked to begin right after the end
  // of the claimed range.
  bool ClaimMemory(const void* position, uint32_t num_bytes);

  // Claims the specified encoded handle (which is basically a handle index).
  // The method succeeds if:
  // - |encoded_handle|'s value is |kEncodedInvalidHandleValue|.
  // - the handle is contained inside the valid range of handle indices. In this
  // case, the valid range is shinked to begin right after the claimed handle.
  bool ClaimHandle(const Handle& encoded_handle);

  // Returns true if the specified range is not empty, and the range is
  // contained inside the valid memory range.
  bool IsValidRange(const void* position, uint32_t num_bytes) const;

 private:
  bool InternalIsValidRange(uintptr_t begin, uintptr_t end) const;

  // [data_begin_, data_end_) is the valid memory range.
  uintptr_t data_begin_;
  uintptr_t data_end_;

  // [handle_begin_, handle_end_) is the valid handle index range.
  uint32_t handle_begin_;
  uint32_t handle_end_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(BoundsChecker);
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_BOUNDS_CHECKER_H_
