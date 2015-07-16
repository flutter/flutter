// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/timer/elapsed_timer.h"

namespace base {

ElapsedTimer::ElapsedTimer() {
  begin_ = TimeTicks::Now();
}

TimeDelta ElapsedTimer::Elapsed() const {
  return TimeTicks::Now() - begin_;
}

}  // namespace base
