// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vsync_timing.h"

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
#include "flutter/fml/trace_event.h"

#if FLUTTER_LINUX_GTK4
#include <dlfcn.h>
#include <gtk/gtk.h>
#endif
#endif

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

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
bool FlFrameTimingHistory::Update(gint64 frame,
                                  gint64 history_start,
                                  int result,
                                  gboolean complete,
                                  gint64 presentation_us) {
  samples_.erase(samples_.begin(), samples_.lower_bound(history_start));
  const auto found = samples_.find(frame);
  if (found != samples_.end() && found->second.result == result &&
      found->second.complete == complete &&
      found->second.presentation_us == presentation_us) {
    return false;
  }
  samples_[frame] = {result, complete, presentation_us};
  return true;
}

void fl_vsync_timing_trace_history(GdkFrameClock* clock) {
  static const bool enabled =
      g_strcmp0(g_getenv("FLUTTER_LINUX_FRAME_TIMINGS"), "1") == 0;
  if (!enabled) {
    return;
  }
  // Resolve this optional 4.24 API here so the standalone pacer and GTK3 builds
  // do not acquire a dependency on the GTK4 accessibility/rendering bindings.
#if FLUTTER_LINUX_GTK4
#if GTK_CHECK_VERSION(4, 24, 0)
  using GetResult = GdkFrameResult (*)(GdkFrameTimings*);
#else
  // GdkFrameResult's ABI is an enum with values 0 through 6.
  enum FrameResult {
    kPreparing,
    kSkipped,
    kEmpty,
    kSubmitted,
    kOutstanding,
    kDiscarded,
    kPresented
  };
  using GetResult = FrameResult (*)(GdkFrameTimings*);
#endif
  static const auto get_result = reinterpret_cast<GetResult>(
      dlsym(RTLD_DEFAULT, "gdk_frame_timings_get_result"));
#endif
  struct History {
    FlFrameTimingHistory samples;
    guint64 id;
  };
  static guint64 next_id = 0;
  static const GQuark key = g_quark_from_static_string("flutter-frame-timings");
  auto* history =
      static_cast<History*>(g_object_get_qdata(G_OBJECT(clock), key));
  if (history == nullptr) {
    history = new History{{}, ++next_id};
    g_object_set_qdata_full(G_OBJECT(clock), key, history, [](gpointer data) {
      delete static_cast<History*>(data);
    });
  }
  const gint64 start = gdk_frame_clock_get_history_start(clock);
  const gint64 end = gdk_frame_clock_get_frame_counter(clock);
  for (gint64 frame = start; frame <= end; ++frame) {
    GdkFrameTimings* timings = gdk_frame_clock_get_timings(clock, frame);
    if (timings == nullptr) {
      continue;
    }
    int result = -1;  // Unknown on GTK3 and GTK4 before 4.24.
#if FLUTTER_LINUX_GTK4
    if (get_result != nullptr) {
      result = static_cast<int>(get_result(timings));
    }
#endif
    const gboolean complete = gdk_frame_timings_get_complete(timings);
    const gint64 presentation =
        gdk_frame_timings_get_presentation_time(timings);
    if (!history->samples.Update(frame, start, result, complete,
                                 presentation)) {
      continue;
    }
    g_autofree gchar* sample = g_strdup_printf(
        "{\"clock\":%" G_GUINT64_FORMAT ",\"frame\":%" G_GINT64_FORMAT
        ",\"result\":%d,\"complete\":%s,\"frame_time_us\":%" G_GINT64_FORMAT
        ",\"predicted_us\":%" G_GINT64_FORMAT
        ",\"presentation_us\":%" G_GINT64_FORMAT
        ",\"refresh_interval_us\":%" G_GINT64_FORMAT "}",
        history->id, frame, result, complete ? "true" : "false",
        gdk_frame_timings_get_frame_time(timings),
        gdk_frame_timings_get_predicted_presentation_time(timings),
        presentation, gdk_frame_timings_get_refresh_interval(timings));
    TRACE_EVENT_INSTANT1("flutter", "LinuxFrameTiming", "sample", sample);
  }
}

#endif  // Debug or profile builds.
