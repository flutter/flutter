// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/lib/bounds_checker.h"

#include "mojo/public/cpp/bindings/lib/bindings_serialization.h"
#include "mojo/public/cpp/environment/logging.h"
#include "mojo/public/cpp/system/handle.h"

namespace mojo {
namespace internal {

BoundsChecker::BoundsChecker(const void* data,
                             uint32_t data_num_bytes,
                             size_t num_handles)
    : data_begin_(reinterpret_cast<uintptr_t>(data)),
      data_end_(data_begin_ + data_num_bytes),
      handle_begin_(0),
      handle_end_(static_cast<uint32_t>(num_handles)) {
  if (data_end_ < data_begin_) {
    // The calculation of |data_end_| overflowed.
    // It shouldn't happen but if it does, set the range to empty so
    // IsValidRange() and ClaimMemory() always fail.
    MOJO_DCHECK(false) << "Not reached";
    data_end_ = data_begin_;
  }
  if (handle_end_ < num_handles) {
    // Assigning |num_handles| to |handle_end_| overflowed.
    // It shouldn't happen but if it does, set the handle index range to empty.
    MOJO_DCHECK(false) << "Not reached";
    handle_end_ = 0;
  }
}

BoundsChecker::~BoundsChecker() {
}

bool BoundsChecker::ClaimMemory(const void* position, uint32_t num_bytes) {
  uintptr_t begin = reinterpret_cast<uintptr_t>(position);
  uintptr_t end = begin + num_bytes;

  if (!InternalIsValidRange(begin, end))
    return false;

  data_begin_ = end;
  return true;
}

bool BoundsChecker::ClaimHandle(const Handle& encoded_handle) {
  uint32_t index = encoded_handle.value();
  if (index == kEncodedInvalidHandleValue)
    return true;

  if (index < handle_begin_ || index >= handle_end_)
    return false;

  // |index| + 1 shouldn't overflow, because |index| is not the max value of
  // uint32_t (it is less than |handle_end_|).
  handle_begin_ = index + 1;
  return true;
}

bool BoundsChecker::IsValidRange(const void* position,
                                 uint32_t num_bytes) const {
  uintptr_t begin = reinterpret_cast<uintptr_t>(position);
  uintptr_t end = begin + num_bytes;

  return InternalIsValidRange(begin, end);
}

bool BoundsChecker::InternalIsValidRange(uintptr_t begin, uintptr_t end) const {
  return end > begin && begin >= data_begin_ && end <= data_end_;
}

}  // namespace internal
}  // namespace mojo
