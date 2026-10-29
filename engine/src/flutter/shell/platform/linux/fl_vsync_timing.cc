// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vsync_timing.h"

FlVsyncTiming fl_vsync_timing_from_refresh_info(gint64 frame_time_us,
                                                gint64 refresh_interval_us,
                                                gint64 presentation_time_us) {
  if (refresh_interval_us <= 0) {
    refresh_interval_us = 16667;
  }
  if (presentation_time_us <= frame_time_us) {
    presentation_time_us = frame_time_us + refresh_interval_us;
  }
  return {static_cast<uint64_t>(frame_time_us) * 1000,
          static_cast<uint64_t>(presentation_time_us) * 1000,
          refresh_interval_us};
}

FlVsyncTiming fl_vsync_timing_for_clock(GdkFrameClock* clock) {
  const gint64 frame_time = gdk_frame_clock_get_frame_time(clock);
  gint64 interval = 0;
  gint64 presentation = 0;
  gdk_frame_clock_get_refresh_info(clock, frame_time, &interval, &presentation);
  return fl_vsync_timing_from_refresh_info(frame_time, interval, presentation);
}
