// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/tracking_info.h"

#include <stddef.h>
#include "base/tracked_objects.h"

namespace base {

TrackingInfo::TrackingInfo()
    : birth_tally(NULL) {
}

TrackingInfo::TrackingInfo(
    const tracked_objects::Location& posted_from,
    base::TimeTicks delayed_run_time)
    : birth_tally(
          tracked_objects::ThreadData::TallyABirthIfActive(posted_from)),
      time_posted(tracked_objects::ThreadData::Now()),
      delayed_run_time(delayed_run_time) {
}

TrackingInfo::~TrackingInfo() {}

}  // namespace base

