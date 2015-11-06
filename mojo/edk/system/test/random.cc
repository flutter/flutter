// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/random.h"

#include <stdint.h>

#include <limits>

#include "base/logging.h"

namespace mojo {
namespace system {
namespace test {

// TODO(vtl): Replace all of this implementation with suitable use of C++11
// <random> when we can.
int RandomInt(int min, int max) {
  DCHECK_LE(min, max);
  DCHECK_LE(static_cast<int64_t>(max) - min, RAND_MAX);
  DCHECK_LT(static_cast<int64_t>(max) - min, std::numeric_limits<int>::max());

  // This is in-range for an |int| due to the above.
  int range = max - min + 1;
  int max_valid = (RAND_MAX / range) * range - 1;
  int value;
  do {
    value = rand();
  } while (value > max_valid);
  return min + (value % range);
}

}  // namespace test
}  // namespace system
}  // namespace mojo
