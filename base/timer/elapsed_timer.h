// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TIMER_ELAPSED_TIMER_H_
#define BASE_TIMER_ELAPSED_TIMER_H_

#include "base/base_export.h"
#include "base/macros.h"
#include "base/time/time.h"

namespace base {

// A simple wrapper around TimeTicks::Now().
class BASE_EXPORT ElapsedTimer {
 public:
  ElapsedTimer();

  // Returns the time elapsed since object construction.
  TimeDelta Elapsed() const;

 private:
  TimeTicks begin_;

  DISALLOW_COPY_AND_ASSIGN(ElapsedTimer);
};

}  // namespace base

#endif  // BASE_TIMER_ELAPSED_TIMER_H_
