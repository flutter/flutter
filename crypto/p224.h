// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_P224_H_
#define CRYPTO_P224_H_

#include <string>

#include "base/basictypes.h"
#include "base/strings/string_piece.h"
#include "crypto/crypto_export.h"

namespace crypto {

// P224 implements an elliptic curve group, commonly known as P224 and defined
// in FIPS 186-3, section D.2.2.
namespace p224 {

// An element of the field (ℤ/pℤ) is represented with 8, 28-bit limbs in
// little endian order.
typedef uint32 FieldElement[8];

struct CRYPTO_EXPORT Point {
  // SetFromString the value of the point from the 56 byte, external
  // representation. The external point representation is an (x, y) pair of a
  // point on the curve. Each field element is represented as a big-endian
  // number < p.
  bool SetFromString(const base::StringPiece& in);

  // ToString returns an external representation of the Point.
  std::string ToString() const;

  // An Point is represented in Jacobian form (x/z², y/z³).
  FieldElement x, y, z;
};

// kScalarBytes is the number of bytes needed to represent an element of the
// P224 field.
static const size_t kScalarBytes = 28;

// ScalarMult computes *out = in*scalar where scalar is a 28-byte, big-endian
// number.
void CRYPTO_EXPORT ScalarMult(const Point& in, const uint8* scalar, Point* out);

// ScalarBaseMult computes *out = g*scalar where g is the base point of the
// curve and scalar is a 28-byte, big-endian number.
void CRYPTO_EXPORT ScalarBaseMult(const uint8* scalar, Point* out);

// Add computes *out = a+b.
void CRYPTO_EXPORT Add(const Point& a, const Point& b, Point* out);

// Negate calculates out = -a;
void CRYPTO_EXPORT Negate(const Point& a, Point* out);

}  // namespace p224

}  // namespace crypto

#endif  // CRYPTO_P224_H_
