// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/rational.h"

#include <cmath>
#include <cstdlib>
#include <numeric>

namespace impeller {
namespace {
uint32_t AbsToUnsigned(int32_t x) {
  return static_cast<uint32_t>(std::abs(x));
}
}  // namespace

bool Rational::operator==(const Rational& that) const {
  if (den_ == that.den_) {
    return num_ == that.num_;
  } else if ((num_ >= 0) != (that.num_ >= 0)) {
    return false;
  } else {
    return AbsToUnsigned(num_) * that.den_ == AbsToUnsigned(that.num_) * den_;
  }
}

bool Rational::operator!=(const Rational& that) const {
  return !(*this == that);
}

bool Rational::operator<(const Rational& that) const {
  if (den_ == that.den_) {
    return num_ < that.num_;
  } else if ((num_ >= 0) != (that.num_ >= 0)) {
    return num_ < that.num_;
  } else {
    return AbsToUnsigned(num_) * that.den_ < AbsToUnsigned(that.num_) * den_;
  }
}

uint64_t Rational::GetHash() const {
  if (num_ == 0) {
    return 0;
  }
  uint64_t gcd = std::gcd(num_, den_);
  return ((num_ / gcd) << 32) | (den_ / gcd);
}

Rational Rational::Invert() const {
  if (num_ >= 0) {
    return Rational(den_, num_);
  } else {
    return Rational(-1 * static_cast<int32_t>(den_), std::abs(num_));
  }
}

}  // namespace impeller
