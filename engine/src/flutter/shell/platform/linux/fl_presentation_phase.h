// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_PRESENTATION_PHASE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_PRESENTATION_PHASE_H_

#include <glib.h>

#include <array>
#include <cstdint>

// Adjusts the phase of the frame grid from Wayland presentation feedback.
//
// The engine starts frames on a monotonic grid of display refresh periods. That
// grid has an arbitrary phase relative to the compositor's vertical blanking
// interval, so a commit can arrive just after the compositor's deadline for a
// refresh and then waits almost a whole refresh before it is shown.
// Presentation feedback reports the time each committed surface actually
// reached the screen, which gives the commit-to-presentation latency.
//
// Starting a frame later also commits it later, which reduces the
// commit-to-presentation latency until the commit passes the compositor's
// deadline. At that point the frame is presented on the following refresh and
// the latency jumps up by a refresh period. The best phase is therefore as
// late as possible without missing the deadline. This class walks the grid
// later while the latency improves, halves the step as it approaches the
// target, and returns to the best phase it measured when a step crosses the
// deadline. Once settled it keeps that phase until the latency at that phase
// regresses, which means the compositor or the workload changed enough to run
// the search again.
//
// The offset is a delay: it moves the frame start (and therefore the commit)
// later than the natural grid. It is limited to less than one refresh period,
// because a larger delay wraps around to the same phase and would make the
// grid stall.
//
// This class can be used from tests with a synthetic clock. It must be used
// from a single thread in production; the engine calls it on the GTK thread.
class FlPresentationPhase {
 public:
  explicit FlPresentationPhase(gint64 interval_us);
  ~FlPresentationPhase();

  // Sets the display refresh interval. Returns true if the interval changed,
  // in which case the learned phase is discarded.
  bool SetInterval(gint64 interval_us);

  // Adds a commit-to-repaint latency sample in microseconds. Returns true if
  // the phase offset changed.
  bool AddSample(gint64 latency_us, gint64 now_us);

  // Discards learned state and returns the grid to its natural phase.
  void Reset();

  // How far later than the natural grid the next frame should start. This is
  // applied to the vsync delivery time, so it moves the commit, not only the
  // timestamps reported to the engine.
  gint64 offset_us() const { return offset_us_; }

 private:
  // Number of samples used to evaluate one step.
  static constexpr int kSampleWindow = 8;
  // A step must reduce the latency by more than this to count as an
  // improvement.
  static constexpr gint64 kImprovementDeadbandUs = 150;
  // The phase is kept this far below one refresh period so it never wraps.
  static constexpr gint64 kProbeResolutionUs = 250;
  // Maximum number of bisection probes after a step overshoots the deadline.
  static constexpr int kMaxBisectProbes = 6;

  gint64 TargetLatencyUs() const;
  gint64 MaxStepUs() const;
  gint64 RegressionThresholdUs() const;
  gint64 ClampOffset(gint64 offset_us) const;
  bool SetOffset(gint64 offset_us);
  bool Settle(gint64 now_us);
  void ClearSamples();
  gint64 MedianSample() const;

  gint64 interval_us_ = 0;
  gint64 offset_us_ = 0;
  gint64 best_latency_us_ = 0;
  gint64 best_offset_us_ = 0;
  gint64 last_sample_us_ = 0;

  // Earliest probe known to be past the compositor deadline. Zero while the
  // search is still walking later.
  gint64 upper_offset_us_ = 0;
  int bisect_probes_ = 0;

  std::array<gint64, kSampleWindow> samples_ = {};
  int sample_count_ = 0;

  int skip_samples_ = 0;
  bool frozen_ = false;
};

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_PRESENTATION_PHASE_H_
