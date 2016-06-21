// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_TIMELINE_FUNCTION_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_TIMELINE_FUNCTION_H_

#include "mojo/public/cpp/bindings/type_converter.h"
#include "mojo/public/cpp/environment/logging.h"
#include "mojo/services/media/common/cpp/timeline_rate.h"
#include "mojo/services/media/common/interfaces/timelines.mojom.h"

namespace mojo {
namespace media {

// TODO(dalesat): Consider always allowing inexact results.

// A linear function from int64_t to int64_t with non-negative slope that
// translates reference timeline values into subject timeline values (the
// 'subject' being the timeline that's represented by the function). The
// representation is in point-slope form. The point is represented as two
// int64_t time values (reference_time, subject_time), and the slope (rate) is
// represented as a TimelineRate, the ratio of two uint32_t values
// (subject_delta / reference_delta).
class TimelineFunction {
 public:
  // Applies a timeline function.
  static int64_t Apply(
      int64_t reference_time,
      int64_t subject_time,
      const TimelineRate& rate,  // subject_delta / reference_delta
      int64_t reference_input);

  // Applies the inverse of a timeline function.
  static int64_t ApplyInverse(
      int64_t reference_time,
      int64_t subject_time,
      const TimelineRate& rate,  // subject_delta / reference_delta
      int64_t subject_input) {
    MOJO_DCHECK(rate.reference_delta() != 0u);
    return Apply(subject_time, reference_time, rate.Inverse(), subject_input);
  }

  // Composes two timeline functions B->C and A->B producing A->C. If exact is
  // true, DCHECKs on loss of precision.
  static TimelineFunction Compose(const TimelineFunction& bc,
                                  const TimelineFunction& ab,
                                  bool exact = true);

  TimelineFunction() : reference_time_(0), subject_time_(0) {}

  TimelineFunction(int64_t reference_time,
                   int64_t subject_time,
                   uint32_t reference_delta,
                   uint32_t subject_delta)
      : reference_time_(reference_time),
        subject_time_(subject_time),
        rate_(subject_delta, reference_delta) {}

  TimelineFunction(int64_t reference_time,
                   int64_t subject_time,
                   const TimelineRate& rate)  // subject_delta / reference_delta
      : reference_time_(reference_time),
        subject_time_(subject_time),
        rate_(rate) {}

  explicit TimelineFunction(
      const TimelineRate& rate)  // subject_delta / reference_delta
      : reference_time_(0),
        subject_time_(0),
        rate_(rate) {}

  // Applies the function. Returns TimelineRate::kOverflow on overflow.
  int64_t Apply(int64_t reference_input) const {
    return Apply(reference_time_, subject_time_, rate_, reference_input);
  }

  // Applies the inverse of the function. Returns TimelineRate::kOverflow on
  // overflow.
  int64_t ApplyInverse(int64_t subject_input) const {
    MOJO_DCHECK(rate_.reference_delta() != 0u);
    return ApplyInverse(reference_time_, subject_time_, rate_, subject_input);
  }

  // Applies the function.  Returns TimelineRate::kOverflow on overflow.
  int64_t operator()(int64_t reference_input) const {
    return Apply(reference_input);
  }

  // Returns a timeline function that is the inverse if this timeline function.
  TimelineFunction Inverse() const {
    MOJO_DCHECK(rate_.reference_delta() != 0u);
    return TimelineFunction(subject_time_, reference_time_, rate_.Inverse());
  }

  int64_t reference_time() const { return reference_time_; }

  int64_t subject_time() const { return subject_time_; }

  const TimelineRate& rate() const { return rate_; }

  uint32_t reference_delta() const { return rate_.reference_delta(); }

  uint32_t subject_delta() const { return rate_.subject_delta(); }

 private:
  int64_t reference_time_;
  int64_t subject_time_;
  TimelineRate rate_;  // subject_delta / reference_delta
};

// Tests two timeline functions for equality. Equality requires equal basis
// values.
inline bool operator==(const TimelineFunction& a, const TimelineFunction& b) {
  return a.reference_time() == b.reference_time() &&
         a.subject_time() == b.subject_time() && a.rate() == b.rate();
}

// Tests two timeline functions for inequality. Equality requires equal basis
// values.
inline bool operator!=(const TimelineFunction& a, const TimelineFunction& b) {
  return !(a == b);
}

// Composes two timeline functions B->C and A->B producing A->C. DCHECKs on
// loss of precision.
inline TimelineFunction operator*(const TimelineFunction& bc,
                                  const TimelineFunction& ab) {
  return TimelineFunction::Compose(bc, ab);
}

}  // namespace media

template <>
struct TypeConverter<TimelineTransformPtr, media::TimelineFunction> {
  static TimelineTransformPtr Convert(
      const media::TimelineFunction& input);
};

template <>
struct TypeConverter<media::TimelineFunction, TimelineTransformPtr> {
  static media::TimelineFunction Convert(
      const TimelineTransformPtr& input);
};

}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_TIMELINE_FUNCTION_H_
