// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_BUILD_TIME_H_
#define BASE_BUILD_TIME_H_

#include "base/base_export.h"
#include "base/time/time.h"

namespace base {

// GetBuildTime returns the time at which the current binary was built.
//
// This uses the __DATE__ and __TIME__ macros, which don't trigger a rebuild
// when they change. However, official builds will always be rebuilt from
// scratch.
//
// Also, since __TIME__ doesn't include a timezone, this value should only be
// considered accurate to a day.
//
// NOTE: This function is disabled except for the official builds, by default
// the date returned is "Sep 02 2008 08:00:00 PST".
Time BASE_EXPORT GetBuildTime();

}  // namespace base

#endif  // BASE_BUILD_TIME_H_
