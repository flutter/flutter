// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/profiler/scoped_tracker.h"

#include "base/bind.h"

namespace tracked_objects {

namespace {

ScopedProfile::Mode g_scoped_profile_mode = ScopedProfile::DISABLED;

}  // namespace

// static
void ScopedTracker::Enable() {
  g_scoped_profile_mode = ScopedProfile::ENABLED;
}

ScopedTracker::ScopedTracker(const Location& location)
    : scoped_profile_(location, g_scoped_profile_mode) {
}

}  // namespace tracked_objects
