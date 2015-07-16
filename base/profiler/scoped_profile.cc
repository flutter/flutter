// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/profiler/scoped_profile.h"

#include "base/location.h"
#include "base/tracked_objects.h"


namespace tracked_objects {


ScopedProfile::ScopedProfile(const Location& location, Mode mode)
    : birth_(NULL) {
  if (mode == DISABLED)
    return;

  birth_ = ThreadData::TallyABirthIfActive(location);
  if (!birth_)
    return;

  stopwatch_.Start();
}

ScopedProfile::~ScopedProfile() {
  if (!birth_)
    return;

  stopwatch_.Stop();
  ThreadData::TallyRunInAScopedRegionIfTracking(birth_, stopwatch_);
}

}  // namespace tracked_objects
