// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SCHEDULER_TIME_INTERVAL_H_
#define SKY_SCHEDULER_TIME_INTERVAL_H_

#include "base/time/time.h"

namespace sky {

struct TimeInterval {
  TimeInterval() {}
  TimeInterval(base::TimeTicks base, base::TimeDelta duration)
      : base(base), duration(duration) {}

  base::TimeTicks NextAfter(base::TimeTicks when);

  base::TimeTicks base;
  base::TimeDelta duration;
};
}

#endif  // SKY_SCHEDULER_TIME_INTERVAL_H_
