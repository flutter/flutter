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

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_LINEAR_TRANSFORM_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_LINEAR_TRANSFORM_H_

#include <stdint.h>

#include <iosfwd>

namespace mojo {
namespace media {

// LinearTransform defines a structure which hold the definition of a
// transformation from single dimensional coordinate system A into coordinate
// system B (and back again).  Values in A and in B are 64 bit, the linear
// scale factor is expressed as a rational number using two 32 bit values.
//
// Specifically, let
// f(a) = b
// F(b) = f^-1(b) = a
// then
//
// f(a) = (((a - a_zero) * scale.numerator) / scale.denominator) + b_zero;
//
// and
//
// F(b) = (((b - b_zero) * scale.denominator) / scale.numerator) + a_zero;
//
struct LinearTransform {
  struct Ratio {
    Ratio() { }
    Ratio(uint32_t _numerator, uint32_t _denominator)
      : numerator(_numerator),
        denominator(_denominator) {
        Reduce();
      }

    // Helper which will reduce the fraction numerator/denominator using
    // Euclid's method.
    static void Reduce(uint32_t* numerator, uint32_t* denominator);

    // Reduce the internal scaling rational.
    void Reduce() { Reduce(&numerator, &denominator); }

    // Compute a * b, reduce and store in out.
    //
    // Returns true if the composition was computed and stored with no loss of
    // precision.  Returns false if the reduced form of the composition could
    // not be stored as a 32 bit ratio and had to be shifted in order to be
    // stored.
    static bool Compose(const Ratio& a, const Ratio& b, Ratio* out);

    uint32_t numerator = 1;
    uint32_t denominator = 1;
  };

  LinearTransform() { }

  LinearTransform(uint32_t numerator, uint32_t denominator)
    : scale(numerator, denominator) {}

  explicit LinearTransform(const Ratio& s) : scale(s) {}

  LinearTransform(int64_t az,
                  uint32_t numerator,
                  uint32_t denominator,
                  int64_t bz)
    : scale(numerator, denominator),
      a_zero(az),
      b_zero(bz) {}

  LinearTransform(int64_t az, const Ratio& s, int64_t bz)
    : scale(s),
      a_zero(az),
      b_zero(bz) {}

  // Transform from A->B
  // Returns true on success, or false in the case of a singularity or an
  // overflow.
  bool DoForwardTransform(int64_t a_in, int64_t* b_out) const;

  // Transform from B->A
  // Returns true on success, or false in the case of a singularity or an
  // overflow.
  bool DoReverseTransform(int64_t b_in, int64_t* a_out) const;

  Ratio   scale;
  int64_t a_zero = 0;
  int64_t b_zero = 0;
};

std::ostream& operator<<(std::ostream& os,
                         const LinearTransform::Ratio& r);
std::ostream& operator<<(std::ostream& os,
                         const LinearTransform& lt);

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_LINEAR_TRANSFORM_H_
