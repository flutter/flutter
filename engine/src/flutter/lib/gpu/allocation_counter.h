// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_ALLOCATION_COUNTER_H_
#define FLUTTER_LIB_GPU_ALLOCATION_COUNTER_H_

#include <cstddef>

namespace flutter::gpu {

/// Counts this thread's heap allocations from construction until `Stop`. This
/// is what lets tests hold a path to zero, rather than trusting a reading of
/// the code. Linking it replaces the global `operator new` for the whole
/// binary.
class AllocationCounter {
 public:
  AllocationCounter();

  ~AllocationCounter();

  size_t Stop();
};

}  // namespace flutter::gpu

#endif  // FLUTTER_LIB_GPU_ALLOCATION_COUNTER_H_
