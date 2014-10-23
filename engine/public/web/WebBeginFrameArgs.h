// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WebBeginFrameArgs_h
#define WebBeginFrameArgs_h

namespace blink {

struct WebBeginFrameArgs {
    WebBeginFrameArgs(double lastFrameTimeMonotonic, double deadline, double interval)
        : lastFrameTimeMonotonic(lastFrameTimeMonotonic)
        , deadline(deadline)
        , interval(interval)
    { }

    // TODO: Remove this constructor once Chromium has been updated.
    WebBeginFrameArgs(double lastFrameTimeMonotonic)
        : lastFrameTimeMonotonic(lastFrameTimeMonotonic)
        , deadline(0)
        , interval(0)
    { }

    // FIXME: Upgrade the time in CLOCK_MONOTONIC values to use a TimeTick like
    // class rather than a bare double.

    // FIXME: Extend this class to include the fields from Chrome
    // BeginFrameArgs structure.

    // Time in CLOCK_MONOTONIC that is the most recent vsync time.
    double lastFrameTimeMonotonic;

    // Time in CLOCK_MONOTONIC by which the renderer should finish producing the current frame. 0 means a deadline wasn't set.
    double deadline;

    // Expected delta between two successive frame times. 0 if a regular interval isn't available.
    double interval;
};

} // namespace blink

#endif
