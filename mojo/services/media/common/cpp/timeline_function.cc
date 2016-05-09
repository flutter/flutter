// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>
#include <utility>

#include "mojo/public/cpp/environment/logging.h"
#include "mojo/services/media/common/cpp/timeline_function.h"

namespace mojo {
namespace media {

// static
int64_t TimelineFunction::Apply(
    int64_t reference_time,
    int64_t subject_time,
    const TimelineRate& rate,  // subject_delta / reference_delta
    int64_t reference_input) {
  return rate.Scale(reference_input - reference_time) + subject_time;
}

// static
TimelineFunction TimelineFunction::Compose(const TimelineFunction& bc,
                                           const TimelineFunction& ab,
                                           bool exact) {
  return TimelineFunction(ab.reference_time(), bc.Apply(ab.subject_time()),
                          TimelineRate::Product(ab.rate(), bc.rate(), exact));
}

}  // namespace media
}  // namespace mojo
