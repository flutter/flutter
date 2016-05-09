// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_TIMELINE_RATE_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_TIMELINE_RATE_H_

#include <stdint.h>

#include <limits>

#include "mojo/public/cpp/environment/logging.h"

namespace mojo {
namespace media {

// TODO(dalesat): Consider always allowing inexact results.

// Expresses the relative rate of a timeline as the ratio between two uint32_t
// values subject_delta / reference_delta. "subject" refers to the timeline
// whose rate is being represented, and "reference" refers to the timeline
// relative to which the rate is expressed.
class TimelineRate {
 public:
  // Used to indicate overflow of scaling operations.
  static constexpr int64_t kOverflow = std::numeric_limits<int64_t>::max();

  // Reduces the ratio of *subject_delta and *reference_delta.
  static void Reduce(uint32_t* subject_delta, uint32_t* reference_delta);

  // Produces the product of the rates. If exact is true, DCHECKs on loss of
  // precision.
  static void Product(uint32_t a_subject_delta,
                      uint32_t a_reference_delta,
                      uint32_t b_subject_delta,
                      uint32_t b_reference_delta,
                      uint32_t* product_subject_delta,
                      uint32_t* product_reference_delta,
                      bool exact = true);

  // Produces the product of the rates and the int64_t as an int64_t. Returns
  // kOverflow on overflow.
  static int64_t Scale(int64_t value,
                       uint32_t subject_delta,
                       uint32_t reference_delta);

  // Returns the product of the rates. If exact is true, DCHECKs on loss of
  // precision.
  static TimelineRate Product(const TimelineRate& a,
                              const TimelineRate& b,
                              bool exact = true) {
    uint32_t result_subject_delta;
    uint32_t result_reference_delta;
    Product(a.subject_delta(), a.reference_delta(), b.subject_delta(),
            b.reference_delta(), &result_subject_delta, &result_reference_delta,
            exact);
    return TimelineRate(result_subject_delta, result_reference_delta);
  }

  TimelineRate() : subject_delta_(0), reference_delta_(1) {}

  explicit TimelineRate(uint32_t subject_delta)
      : subject_delta_(subject_delta), reference_delta_(1) {}

  TimelineRate(uint32_t subject_delta, uint32_t reference_delta)
      : subject_delta_(subject_delta), reference_delta_(reference_delta) {
    MOJO_DCHECK(reference_delta != 0);
    Reduce(&subject_delta_, &reference_delta_);
  }

  // Returns the inverse of the rate. DCHECKs if the subject_delta of this
  // rate is zero.
  TimelineRate Inverse() const {
    MOJO_DCHECK(subject_delta_ != 0);
    return TimelineRate(reference_delta_, subject_delta_);
  }

  // Scales the value by this rate. Returns kOverflow on overflow.
  int64_t Scale(int64_t value) const {
    return Scale(value, subject_delta_, reference_delta_);
  }

  uint32_t subject_delta() const { return subject_delta_; }
  uint32_t reference_delta() const { return reference_delta_; }

 private:
  uint32_t subject_delta_;
  uint32_t reference_delta_;
};

// Tests two rates for equality.
inline bool operator==(const TimelineRate& a, const TimelineRate& b) {
  return a.subject_delta() == b.subject_delta() &&
         a.reference_delta() == b.reference_delta();
}

// Tests two rates for inequality.
inline bool operator!=(const TimelineRate& a, const TimelineRate& b) {
  return !(a == b);
}

// Returns the product of the two rates. DCHECKs on loss of precision.
inline TimelineRate operator*(const TimelineRate& a, const TimelineRate& b) {
  return TimelineRate::Product(a, b);
}

// Returns the product of the rate and the int64_t. Returns kOverflow on
// overflow.
inline int64_t operator*(const TimelineRate& a, int64_t b) {
  return a.Scale(b);
}

// Returns the product of the rate and the int64_t. Returns kOverflow on
// overflow.
inline int64_t operator*(int64_t a, const TimelineRate& b) {
  return b.Scale(a);
}

// Returns the the int64_t divided by the rate. Returns kOverflow on
// overflow.
inline int64_t operator/(int64_t a, const TimelineRate& b) {
  return b.Inverse().Scale(a);
}

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_TIMELINE_RATE_H_
