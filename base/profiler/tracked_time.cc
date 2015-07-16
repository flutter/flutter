// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/profiler/tracked_time.h"

#include "build/build_config.h"

#if defined(OS_WIN)
#include <mmsystem.h>  // Declare timeGetTime()... after including build_config.
#endif

namespace tracked_objects {

Duration::Duration() : ms_(0) {}
Duration::Duration(int32 duration) : ms_(duration) {}

Duration& Duration::operator+=(const Duration& other) {
  ms_ += other.ms_;
  return *this;
}

Duration Duration::operator+(const Duration& other) const {
  return Duration(ms_ + other.ms_);
}

bool Duration::operator==(const Duration& other) const {
  return ms_ == other.ms_;
}

bool Duration::operator!=(const Duration& other) const {
  return ms_ != other.ms_;
}

bool Duration::operator>(const Duration& other) const {
  return ms_ > other.ms_;
}

// static
Duration Duration::FromMilliseconds(int ms) { return Duration(ms); }

int32 Duration::InMilliseconds() const { return ms_; }

//------------------------------------------------------------------------------

TrackedTime::TrackedTime() : ms_(0) {}
TrackedTime::TrackedTime(int32 ms) : ms_(ms) {}
TrackedTime::TrackedTime(const base::TimeTicks& time)
    : ms_(static_cast<int32>((time - base::TimeTicks()).InMilliseconds())) {
}

// static
TrackedTime TrackedTime::Now() {
  return TrackedTime(base::TimeTicks::Now());
}

Duration TrackedTime::operator-(const TrackedTime& other) const {
  return Duration(ms_ - other.ms_);
}

TrackedTime TrackedTime::operator+(const Duration& other) const {
  return TrackedTime(ms_ + other.ms_);
}

bool TrackedTime::is_null() const { return ms_ == 0; }

}  // namespace tracked_objects
