// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_RATIONAL_H_
#define FLUTTER_IMPELLER_GEOMETRY_RATIONAL_H_

#include <cstdint>
#include "impeller/geometry/scalar.h"

namespace impeller {

class Rational {
 public:
  constexpr explicit Rational(int32_t num) : num_(num), den_(1) {}

  constexpr Rational(int32_t num, uint32_t den) : num_(num), den_(den) {}

  int32_t GetNumerator() const { return num_; }

  uint32_t GetDenominator() const { return den_; }

  bool operator==(const Rational& that) const;

  bool operator<(const Rational& that) const;

  uint64_t GetHash() const;

  explicit operator Scalar() const { return static_cast<float>(num_) / den_; }

  Rational Invert() const;

 private:
  int32_t num_;
  uint32_t den_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_GEOMETRY_RATIONAL_H_
