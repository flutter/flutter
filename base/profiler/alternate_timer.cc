// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/profiler/alternate_timer.h"

#include "base/basictypes.h"

namespace {

tracked_objects::NowFunction* g_time_function = NULL;
tracked_objects::TimeSourceType g_time_source_type =
    tracked_objects::TIME_SOURCE_TYPE_WALL_TIME;

}  // anonymous namespace

namespace tracked_objects {

const char kAlternateProfilerTime[] = "CHROME_PROFILER_TIME";

// Set an alternate timer function to replace the OS time function when
// profiling.
void SetAlternateTimeSource(NowFunction* now_function, TimeSourceType type) {
  g_time_function = now_function;
  g_time_source_type = type;
}

NowFunction* GetAlternateTimeSource() {
  return g_time_function;
}

TimeSourceType GetTimeSourceType() {
  return g_time_source_type;
}

}  // namespace tracked_objects
