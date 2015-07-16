// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PROFILER_SCOPED_TRACKER_H_
#define BASE_PROFILER_SCOPED_TRACKER_H_

//------------------------------------------------------------------------------
// Utilities for temporarily instrumenting code to dig into issues that were
// found using profiler data.

#include "base/base_export.h"
#include "base/bind.h"
#include "base/callback_forward.h"
#include "base/location.h"
#include "base/profiler/scoped_profile.h"

namespace tracked_objects {

// ScopedTracker instruments a region within the code if the instrumentation is
// enabled. It can be used, for example, to find out if a source of jankiness is
// inside the instrumented code region.
// Details:
// 1. This class creates a task (like ones created by PostTask calls or IPC
// message handlers). This task can be seen in chrome://profiler and is sent as
// a part of profiler data to the UMA server. See profiler_event.proto.
// 2. That task's lifetime is same as the lifetime of the ScopedTracker
// instance.
// 3. The execution time associated with the task is the wallclock time between
// its constructor and destructor, minus wallclock times of directly nested
// tasks.
// 4. Task creation that this class utilizes is highly optimized.
// 5. The class doesn't create a task unless this was enabled for the current
// process. Search for ScopedTracker::Enable for the current list of processes
// and channels where it's activated.
// 6. The class is designed for temporarily instrumenting code to find
// performance problems, after which the instrumentation must be removed.
class BASE_EXPORT ScopedTracker {
 public:
  ScopedTracker(const Location& location);

  // Enables instrumentation for the remainder of the current process' life. If
  // this function is not called, all profiler instrumentations are no-ops.
  static void Enable();

  // Augments a |callback| with provided |location|. This is useful for
  // instrumenting cases when we know that a jank is in a callback and there are
  // many possible callbacks, but they come from a relatively small number of
  // places. We can instrument these few places and at least know which one
  // passes the janky callback.
  template <typename P1>
  static base::Callback<void(P1)> TrackCallback(
      const Location& location,
      const base::Callback<void(P1)>& callback) {
    return base::Bind(&ScopedTracker::ExecuteAndTrackCallback<P1>, location,
                      callback);
  }

 private:
  // Executes |callback|, augmenting it with provided |location|.
  template <typename P1>
  static void ExecuteAndTrackCallback(const Location& location,
                                      const base::Callback<void(P1)>& callback,
                                      P1 p1) {
    ScopedTracker tracking_profile(location);
    callback.Run(p1);
  }

  const ScopedProfile scoped_profile_;

  DISALLOW_COPY_AND_ASSIGN(ScopedTracker);
};

}  // namespace tracked_objects

#endif  // BASE_PROFILER_SCOPED_TRACKER_H_
