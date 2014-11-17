// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/scheduler/time_interval.h"

#include <cstdlib>

namespace sky {

base::TimeTicks TimeInterval::NextAfter(base::TimeTicks when) {
  int64 offset = std::abs((when - base).ToInternalValue());
  base::TimeDelta excess =
      base::TimeDelta::FromInternalValue(offset % duration.ToInternalValue());
  return when + duration - excess;
}
}
