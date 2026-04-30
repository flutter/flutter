// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>

#include "flutter/fml/safe_math.h"
#include "third_party/abseil-cpp/absl/numeric/int128.h"

namespace fml {

size_t SafeMath::mul(size_t x, size_t y) {
  return sizeof(size_t) == sizeof(uint64_t) ? mul64(x, y) : mul32(x, y);
}

uint32_t SafeMath::mul32(uint32_t x, uint32_t y) {
  uint64_t big_x = x;
  uint64_t big_y = y;
  uint64_t result = big_x * big_y;
  if (result >> 32) {
    overflow_detected_ = true;
  }
  return static_cast<uint32_t>(result);
}

uint64_t SafeMath::mul64(uint64_t x, uint64_t y) {
  if (x <= std::numeric_limits<uint32_t>::max() &&
      y <= std::numeric_limits<uint32_t>::max()) {
    return x * y;
  }

  absl::uint128 big_x = x;
  absl::uint128 big_y = y;
  absl::uint128 result = big_x * big_y;
  if (absl::Uint128High64(result)) {
    overflow_detected_ = true;
  }
  return absl::Uint128Low64(result);
}

}  // namespace fml
