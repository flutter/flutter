// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/rand_util.h"

#include <math.h>
#include <stdint.h>

#include <algorithm>
#include <limits>

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/strings/string_util.h"

namespace base {

int RandInt(int min, int max) {
  DCHECK_LE(min, max);

  uint64 range = static_cast<uint64>(max) - min + 1;
  int result = min + static_cast<int>(base::RandGenerator(range));
  DCHECK_GE(result, min);
  DCHECK_LE(result, max);
  return result;
}

double RandDouble() {
  return BitsToOpenEndedUnitInterval(base::RandUint64());
}

double BitsToOpenEndedUnitInterval(uint64 bits) {
  // We try to get maximum precision by masking out as many bits as will fit
  // in the target type's mantissa, and raising it to an appropriate power to
  // produce output in the range [0, 1).  For IEEE 754 doubles, the mantissa
  // is expected to accommodate 53 bits.

  COMPILE_ASSERT(std::numeric_limits<double>::radix == 2, otherwise_use_scalbn);
  static const int kBits = std::numeric_limits<double>::digits;
  uint64 random_bits = bits & ((UINT64_C(1) << kBits) - 1);
  double result = ldexp(static_cast<double>(random_bits), -1 * kBits);
  DCHECK_GE(result, 0.0);
  DCHECK_LT(result, 1.0);
  return result;
}

uint64 RandGenerator(uint64 range) {
  DCHECK_GT(range, 0u);
  // We must discard random results above this number, as they would
  // make the random generator non-uniform (consider e.g. if
  // MAX_UINT64 was 7 and |range| was 5, then a result of 1 would be twice
  // as likely as a result of 3 or 4).
  uint64 max_acceptable_value =
      (std::numeric_limits<uint64>::max() / range) * range - 1;

  uint64 value;
  do {
    value = base::RandUint64();
  } while (value > max_acceptable_value);

  return value % range;
}

std::string RandBytesAsString(size_t length) {
  DCHECK_GT(length, 0u);
  std::string result;
  RandBytes(WriteInto(&result, length + 1), length);
  return result;
}

}  // namespace base
