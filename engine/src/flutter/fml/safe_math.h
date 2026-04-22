// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_SAFE_MATH_H_
#define FLUTTER_FML_SAFE_MATH_H_

#include <cstddef>
#include <cstdint>

namespace fml {

// Math operations that check for overflow.
// Based on Skia's SkSafeMath.
class SafeMath {
 public:
  bool overflow_detected() const { return overflow_detected_; }

  size_t mul(size_t x, size_t y);

 private:
  uint32_t mul32(uint32_t x, uint32_t y);
  uint64_t mul64(uint64_t x, uint64_t y);

  bool overflow_detected_ = false;
};

}  // namespace fml

#endif  // FLUTTER_FML_SAFE_MATH_H_
