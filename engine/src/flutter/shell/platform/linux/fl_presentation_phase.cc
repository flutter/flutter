// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_presentation_phase.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>

FlPresentationPhase::FlPresentationPhase(gint64 interval_us)
    : interval_us_(interval_us > 0 ? interval_us : 16667) {}

FlPresentationPhase::~FlPresentationPhase() = default;

bool FlPresentationPhase::SetInterval(gint64 interval_us) {
  if (interval_us <= 0) {
    interval_us = 16667;
  }
  if (interval_us == interval_us_) {
    return false;
  }
  g_debug("FlPresentationPhase: interval %" G_GINT64_FORMAT
          " -> %" G_GINT64_FORMAT,
          interval_us_, interval_us);
  interval_us_ = interval_us;
  Reset();
  return true;
}

void FlPresentationPhase::Reset() {
  g_debug("FlPresentationPhase: reset, interval %" G_GINT64_FORMAT "us",
          interval_us_);
  ClearSamples();
  offset_us_ = 0;
  best_latency_us_ = 0;
  best_offset_us_ = 0;
  last_sample_us_ = 0;
  upper_offset_us_ = 0;
  bisect_probes_ = 0;
  skip_samples_ = 0;
  frozen_ = false;
}

void FlPresentationPhase::ClearSamples() {
  sample_count_ = 0;
}

gint64 FlPresentationPhase::ClampOffset(gint64 offset_us) const {
  // The offset delays the grid by less than one refresh period. A delay of a
  // whole period is the same phase again and would make the grid stall.
  return CLAMP(offset_us, static_cast<gint64>(0),
               MAX(interval_us_ - kProbeResolutionUs, static_cast<gint64>(0)));
}

gint64 FlPresentationPhase::TargetLatencyUs() const {
  // The commit should be close to the compositor's deadline so it is shown on
  // the nearest refresh, but not so close that scheduling jitter makes it miss.
  // This is a heuristic; the improvement test below decides whether moving
  // towards it actually helps on this compositor.
  return CLAMP(interval_us_ / 8, static_cast<gint64>(750), interval_us_ / 4);
}

gint64 FlPresentationPhase::MaxStepUs() const {
  return CLAMP(interval_us_ / 8, static_cast<gint64>(250),
               static_cast<gint64>(2000));
}

gint64 FlPresentationPhase::RegressionThresholdUs() const {
  // While frozen the phase is kept unless the latency is much worse than the
  // phase that was measured. A small drift is noise.
  return interval_us_ / 4;
}

gint64 FlPresentationPhase::MedianSample() const {
  if (sample_count_ == 0) {
    return 0;
  }
  std::array<gint64, kSampleWindow> sorted = samples_;
  std::sort(sorted.begin(), sorted.begin() + sample_count_);
  return sorted[sample_count_ / 2];
}

bool FlPresentationPhase::Settle(gint64 now_us) {
  g_debug("FlPresentationPhase: settled at offset %" G_GINT64_FORMAT
          "us, latency %" G_GINT64_FORMAT "us, target %" G_GINT64_FORMAT
          "us, interval %" G_GINT64_FORMAT "us",
          best_offset_us_, best_latency_us_, TargetLatencyUs(), interval_us_);
  frozen_ = true;
  upper_offset_us_ = 0;
  bisect_probes_ = 0;
  ClearSamples();
  // Keep a little distance from the last good probe so scheduling jitter does
  // not make a frame miss the deadline.
  return SetOffset(
      MAX(best_offset_us_ - kProbeResolutionUs, static_cast<gint64>(0)));
}

bool FlPresentationPhase::AddSample(gint64 latency_us, gint64 now_us) {
  if (interval_us_ <= 0) {
    return false;
  }

  // A commit can legitimately be presented several refreshes later on a busy
  // or triple-buffered compositor, but a value outside this range is more
  // likely a clock mismatch or a stale sample.
  if (latency_us <= 0 || latency_us > interval_us_ * 4) {
    return false;
  }

  if (last_sample_us_ != 0 && now_us - last_sample_us_ > interval_us_ * 4) {
    // The window was hidden or the compositor stopped sending feedback. The
    // learned offset may still be useful, but old samples are not.
    ClearSamples();
  }
  last_sample_us_ = now_us;

  if (skip_samples_ > 0) {
    skip_samples_--;
    return false;
  }

  samples_[sample_count_++] = latency_us;
  if (sample_count_ < kSampleWindow) {
    return false;
  }

  const gint64 median_us = MedianSample();
  // A probe that crosses the compositor deadline presents most of its frames
  // a refresh late. Require more than one such sample so a single stalled
  // frame (shader compilation, a garbage collection) does not abort a search
  // or freeze the controller at a bad phase.
  int late_count = 0;
  for (int i = 0; i < sample_count_; i++) {
    if (samples_[i] > median_us + interval_us_ / 2) {
      late_count++;
    }
  }
  const bool missed = late_count >= 2;
  ClearSamples();

  if (median_us <= 0 || median_us > interval_us_ * 3) {
    return false;
  }

  const gint64 target_us = TargetLatencyUs();
  // A probe that crosses the deadline is never an improvement, even if its
  // median happens to look good. The first window has no baseline yet, so a
  // startup stall in it only sets the baseline.
  const bool improved =
      best_latency_us_ == 0 ||
      (!missed && median_us + kImprovementDeadbandUs < best_latency_us_);

  if (frozen_) {
    // The phase was settled. Only run the search again if the latency at that
    // phase has really changed, which means the compositor or the workload no
    // longer matches what was measured. Re-probing on a timer would drop
    // frames on a healthy compositor for no reason.
    if (median_us <= best_latency_us_ + RegressionThresholdUs()) {
      return false;
    }
    g_debug("FlPresentationPhase: frozen phase regressed to %" G_GINT64_FORMAT
            "us (best %" G_GINT64_FORMAT "us), searching again",
            median_us, best_latency_us_);
    frozen_ = false;
    best_latency_us_ = 0;
    upper_offset_us_ = 0;
    bisect_probes_ = 0;
    if (offset_us_ != 0) {
      // Start the search from the natural grid. The useful phase is always
      // less than one period after it, so the walk does not need to wrap.
      // This window was measured at the old phase and is discarded.
      return SetOffset(0);
    }
  }

  if (best_latency_us_ == 0 || improved) {
    best_latency_us_ = median_us;
    best_offset_us_ = offset_us_;

    if (median_us <= target_us) {
      // The commit is in the useful part of the refresh period. Hold this
      // phase instead of probing further and risking a missed refresh.
      return Settle(now_us);
    }

    // A probe past the deadline means the useful phase is between the best
    // offset and this one. Bisect instead of throwing away the improvement
    // that was already measured.
    if (upper_offset_us_ > best_offset_us_) {
      const gint64 midpoint = (best_offset_us_ + upper_offset_us_) / 2;
      if (bisect_probes_ >= kMaxBisectProbes ||
          midpoint - best_offset_us_ <= kProbeResolutionUs) {
        return Settle(now_us);
      }
      bisect_probes_++;
      return SetOffset(midpoint);
    }

    // Move the commit later. The error halves each window, so the last steps
    // are fine enough to stop close to the target without overshooting.
    const gint64 error_us = median_us - target_us;
    const gint64 step_us =
        CLAMP(error_us / 2, static_cast<gint64>(1), MaxStepUs());
    const gint64 next_offset = ClampOffset(offset_us_ + step_us);
    if (next_offset == offset_us_) {
      // Already at the latest representable phase. The compositor always
      // queues the frame for at least a period, so there is nothing more to
      // gain.
      return Settle(now_us);
    }
    g_debug("FlPresentationPhase: latency %" G_GINT64_FORMAT
            "us, target %" G_GINT64_FORMAT "us, offset %" G_GINT64_FORMAT
            " -> %" G_GINT64_FORMAT "us",
            median_us, target_us, offset_us_, next_offset);
    return SetOffset(next_offset);
  }

  // The step made the latency worse, so the commit crossed the compositor
  // deadline between the best offset and this one. Bisect to find the latest
  // offset that still presents on the nearest refresh.
  if (offset_us_ > best_offset_us_) {
    upper_offset_us_ = offset_us_;
    const gint64 midpoint = (best_offset_us_ + upper_offset_us_) / 2;
    if (bisect_probes_ < kMaxBisectProbes &&
        midpoint - best_offset_us_ > kProbeResolutionUs) {
      bisect_probes_++;
      return SetOffset(midpoint);
    }
  }

  g_debug("FlPresentationPhase: latency %" G_GINT64_FORMAT
          "us is worse than best %" G_GINT64_FORMAT
          "us, settling at offset %" G_GINT64_FORMAT "us",
          median_us, best_latency_us_, best_offset_us_);
  return Settle(now_us);
}

bool FlPresentationPhase::SetOffset(gint64 offset_us) {
  offset_us = ClampOffset(offset_us);
  if (offset_us == offset_us_) {
    return false;
  }
  offset_us_ = offset_us;
  // Frames already in the pipeline were started with the previous phase.
  // Ignore the next few samples so a step is judged on frames it affected.
  skip_samples_ = 3;
  g_debug("FlPresentationPhase: offset %" G_GINT64_FORMAT
          "us, interval %" G_GINT64_FORMAT "us",
          offset_us_, interval_us_);
  return true;
}
