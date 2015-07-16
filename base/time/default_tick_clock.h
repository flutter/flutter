// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TIME_DEFAULT_TICK_CLOCK_H_
#define BASE_TIME_DEFAULT_TICK_CLOCK_H_

#include "base/base_export.h"
#include "base/compiler_specific.h"
#include "base/time/tick_clock.h"

namespace base {

// DefaultClock is a Clock implementation that uses TimeTicks::Now().
class BASE_EXPORT DefaultTickClock : public TickClock {
 public:
  ~DefaultTickClock() override;

  // Simply returns TimeTicks::Now().
  TimeTicks NowTicks() override;
};

}  // namespace base

#endif  // BASE_TIME_DEFAULT_TICK_CLOCK_H_
