// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/*
 * Copyright (C) 2011 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#include <stdint.h>

#include <iostream>
#include <limits>

#include "mojo/public/cpp/environment/logging.h"
#include "mojo/services/media/common/cpp/linear_transform.h"

namespace mojo {
namespace media {

template<class T>
static inline constexpr T ABS(T x) {
  return (x < 0) ? -x : x;
}

namespace internal {

template <class T>
void Reduce(T* numerator, T* denominator) {
  MOJO_DCHECK(numerator && denominator);
  if (!numerator || !denominator) { return; }

  T a, b;
  a = *numerator;
  b = *denominator;

  if (a == 0) {
    *denominator = 1;
    return;
  }

  // This implements Euclid's method to find GCD.
  if (a < b) {
    T tmp = a;
    a = b;
    b = tmp;
  }

  while (1) {
    // a is now the greater of the two.
    const T remainder = a % b;
    if (remainder == 0) {
      *numerator /= b;
      *denominator /= b;
      return;
    }
    // by swapping remainder and b, we are guaranteeing that a is
    // still the greater of the two upon entrance to the loop.
    a = b;
    b = remainder;
  }
}

template void Reduce<uint64_t>(uint64_t* numerator, uint64_t* denominator);
template void Reduce<uint32_t>(uint32_t* numerator, uint32_t* denominator);

}  // namespace internal


// Compute A + B and store in out.  Return false if the sum would have either
// over or underflowed, and true otherwise.
static inline bool sum_check_ovfl(int64_t a, int64_t b, int64_t* out) {
  // Compute result = a + b, then check for under/overflow.
  //
  // We know that if both a and b have the same sign bit, and the result has a
  // different sign bit, then we have under/overflow.  An easy way to compute
  // this is
  //
  // (A_signbit XNOR B_signbit) & (B_signbit XOR result_signbit)
  //
  // which is equivalent to
  //
  // (A_signbit XOR B_signbit XOR 1) & (A_signbit XOR result_signbit)
  *out = a + b;

  if ((a ^ b ^ std::numeric_limits<int64_t>::min()) &
      (a ^ *out) & std::numeric_limits<int64_t>::min())
    return false;

  return true;
}

// Static math methods involving linear transformations
static bool scale_u64_to_u64(
    uint64_t value,
    uint32_t numerator,
    uint32_t denominator,
    uint64_t* out,
    bool round_up_not_down) {
  uint64_t tmp1, tmp2;
  uint32_t r;

  MOJO_DCHECK(out);
  MOJO_DCHECK(denominator);

  // Let U32(X) denote a uint32_t containing the upper 32 bits of a 64 bit
  // integer X.
  // Let L32(X) denote a uint32_t containing the lower 32 bits of a 64 bit
  // integer X.
  // Let X[A, B] with A <= B denote bits A through B of the integer X.
  // Let (A | B) denote the concatenation of two 32 bit ints, A and B.
  // IOW X = (A | B) => U32(X) == A && L32(X) == B
  //
  // compute M = value * numerator (a 96 bit int)
  // ---------------------------------
  // tmp2 = U32(value) * numerator (a 64 bit int)
  // tmp1 = L32(value) * numerator (a 64 bit int)
  // which means
  // M = value * numerator = (tmp2 << 32) + tmp1
  tmp2 = (value >> 32) * numerator;
  tmp1 = (value & std::numeric_limits<uint32_t>::max()) * numerator;

  // compute M[32, 95]
  // tmp2 = tmp2 + U32(tmp1)
  //      = (U32(value) * numerator) + U32(L32(value) * numerator)
  //      = M[32, 95]
  tmp2 += tmp1 >> 32;

  // if M[64, 95] >= denominator, then M/denominator has bits > 63 set and we
  // have an overflow.
  if ((tmp2 >> 32) >= denominator) {
    *out = std::numeric_limits<uint64_t>::max();
    return false;
  }

  // Divide.  Going in we know
  // tmp2 = M[32, 95]
  // U32(tmp2) < denominator
  r = tmp2 % denominator;
  tmp2 /= denominator;

  // At this point
  // tmp1      = L32(value) * numerator
  // tmp2      = M[32, 95] / denominator
  //           = (M / denominator)[32, 95]
  // r         = M[32, 95] % denominator
  // U32(tmp2) = 0
  //
  // compute tmp1 = (r | M[0, 31])
  tmp1 = (tmp1 & std::numeric_limits<uint32_t>::max()) | ((uint64_t)r << 32);

  // Divide again.  Keep the remainder around in order to round properly.
  r = tmp1 % denominator;
  tmp1 /= denominator;

  // At this point
  // tmp2      = (M / denominator)[32, 95]
  // tmp1      = (M / denominator)[ 0, 31]
  // r         =  M % denominator
  // U32(tmp1) = 0
  // U32(tmp2) = 0

  // Pack the result and deal with the round-up case (As well as the
  // remote possibility of over overflow in such a case).
  *out = (tmp2 << 32) | tmp1;
  if (r && round_up_not_down) {
    ++(*out);
    if (!(*out)) {
      *out = std::numeric_limits<uint64_t>::max();
      return false;
    }
  }

  return true;
}

static bool linear_transform_s64_to_s64(
    int64_t  val,
    int64_t  basis1,
    uint32_t numerator,
    uint32_t denominator,
    bool     invert_frac,
    int64_t  basis2,
    int64_t* out) {
  uint64_t scaled;
  uint64_t abs_val;
  bool is_neg;

  if (!out) {
    return false;
  }

  // Compute abs(val - basis_64). Keep track of whether or not this delta
  // will be negative after the scale operation.
  if (val < basis1) {
    is_neg = true;
    abs_val = basis1 - val;
  } else {
    is_neg = false;
    abs_val = val - basis1;
  }

  if (!scale_u64_to_u64(abs_val,
        invert_frac ? denominator : numerator,
        invert_frac ? numerator : denominator,
        &scaled,
        is_neg)) {
    return false;  // overflow/underflow
  }

  // if scaled is >= 0x8000<etc>, then we are going to overflow or
  // underflow unless ABS(basis2) is large enough to pull us back into the
  // non-overflow/underflow region.
  if (scaled & std::numeric_limits<int64_t>::min()) {
    if (is_neg && (basis2 < 0)) {
      return false;  // certain underflow
    }

    if (!is_neg && (basis2 >= 0)) {
      return false;  // certain overflow
    }

    if (ABS(basis2) <= static_cast<int64_t>(
          scaled & std::numeric_limits<int64_t>::max())) {
      return false;  // not enough
    }

    // Looks like we are OK
    *out = (is_neg ? (-scaled) : scaled) + basis2;
  } else {
    // Scaled fits within signed bounds, so we just need reapply the sign bit to
    // scaled, compute the sum, and check for over/underflow.

    if (is_neg)
      scaled = -scaled;

    if (!sum_check_ovfl(scaled, basis2, out))
      return false;
  }

  return true;
}

bool LinearTransform::DoForwardTransform(int64_t a_in, int64_t* b_out) const {
  if (0 == scale.denominator)
    return false;

  return linear_transform_s64_to_s64(a_in,
      a_zero,
      scale.numerator,
      scale.denominator,
      false,
      b_zero,
      b_out);
}

bool LinearTransform::DoReverseTransform(int64_t b_in, int64_t* a_out) const {
  if (0 == scale.numerator)
    return false;

  return linear_transform_s64_to_s64(b_in,
      b_zero,
      scale.numerator,
      scale.denominator,
      true,
      a_zero,
      a_out);
}

void LinearTransform::Ratio::Reduce(
    uint32_t* numerator, uint32_t* denominator) {
  MOJO_DCHECK(numerator && denominator);
  if (!numerator || !denominator) { return; }

  if (*denominator) {
    internal::Reduce(reinterpret_cast<uint32_t*>(numerator), denominator);
  } else {
    *numerator = *numerator ? 1 : 0;
  }
}

bool LinearTransform::Ratio::Compose(const Ratio& a,
                                     const Ratio& b,
                                     Ratio* out) {
  MOJO_DCHECK(out);
  if (!out) { return false; }

  uint64_t numerator   = static_cast<uint64_t>(a.numerator) * b.numerator;
  uint64_t denominator = static_cast<uint64_t>(a.denominator) * b.denominator;

  if (!numerator || !denominator) {
    out->numerator = numerator ? 1 : 0;
    out->denominator = denominator ? 1 : 0;
    return true;
  }

  internal::Reduce(reinterpret_cast<uint64_t*>(&numerator), &denominator);

  unsigned int leading_zeros = __builtin_clzl((numerator << 1) | denominator);
  bool lossy = leading_zeros < 32;
  if (lossy) {
    unsigned int shift = 32 - leading_zeros;
    numerator   >>= shift;
    denominator >>= shift;
  }

  out->numerator = static_cast<uint32_t>(numerator);
  out->denominator = static_cast<uint32_t>(denominator);
  return !lossy;
}

std::ostream& operator<<(std::ostream& os,
                         const LinearTransform::Ratio& r) {
  os << r.numerator << "/" << r.denominator;
  return os;
}

std::ostream& operator<<(std::ostream& os,
                         const LinearTransform& lt) {
  os << "["  << lt.a_zero
     << " (" << lt.scale
     << ") " << lt.b_zero
     << "]";
  return os;
}

}  // namespace media
}  // namespace mojo
