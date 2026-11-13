// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VSYNC_TIMING_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VSYNC_TIMING_H_

#include <gdk/gdk.h>
#include <stdint.h>

struct FlVsyncTiming {
  uint64_t frame_start_ns;
  uint64_t frame_target_ns;
  gint64 refresh_interval_us;
};

// Convert GDK's monotonic microseconds to embedder nanoseconds. Missing or
// stale predictions must still produce a target strictly after frame start.
FlVsyncTiming fl_vsync_timing_from_refresh_info(gint64 frame_time_us,
                                                gint64 refresh_interval_us,
                                                gint64 presentation_time_us);

// Read completed clock history; the current frame's timing can be incomplete
// during UPDATE and report no refresh interval even on a high-refresh display.
FlVsyncTiming fl_vsync_timing_for_clock(GdkFrameClock* clock);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VSYNC_TIMING_H_
