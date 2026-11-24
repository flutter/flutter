// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_presentation_phase.h"

#include <functional>

#include "gtest/gtest.h"

namespace {

constexpr gint64 kInterval60 = 16667;
constexpr gint64 kInterval144 = 6944;
constexpr gint64 kInterval240 = 4167;

// A compositor that presents a commit on the first blank at least [lead_us]
// after it. At offset zero the commit is [natural_latency_us] before the blank
// that presents it, so starting the frame later reduces the latency until the
// commit passes the blank's deadline, after which it is presented one refresh
// later.
gint64 VblankLatency(gint64 offset_us,
                     gint64 natural_latency_us,
                     gint64 lead_us,
                     gint64 interval_us) {
  gint64 latency_us = natural_latency_us - offset_us - lead_us;
  latency_us %= interval_us;
  if (latency_us < 0) {
    latency_us += interval_us;
  }
  return latency_us + lead_us;
}

void RunSamples(FlPresentationPhase* phase,
                std::function<gint64(gint64)> latency_for_offset,
                gint64 interval_us,
                int frames,
                gint64* now_us) {
  for (int i = 0; i < frames; i++) {
    phase->AddSample(latency_for_offset(phase->offset_us()), *now_us);
    *now_us += interval_us;
  }
}

// Runs the controller and counts frames whose presentation was a refresh
// later than the window's typical latency.
int CountLateFrames(FlPresentationPhase* phase,
                    std::function<gint64(gint64)> latency_for_offset,
                    gint64 interval_us,
                    int frames,
                    gint64* now_us) {
  int late = 0;
  gint64 previous = 0;
  for (int i = 0; i < frames; i++) {
    gint64 latency = latency_for_offset(phase->offset_us());
    if (previous != 0 && latency > previous + interval_us / 2) {
      late++;
    }
    previous = latency;
    phase->AddSample(latency, *now_us);
    *now_us += interval_us;
  }
  return late;
}

TEST(FlPresentationPhaseTest, LateCommitMovesLaterAndSettles) {
  FlPresentationPhase phase(kInterval60);
  gint64 now_us = 1000000;

  // The natural grid commits 14.7ms before the blank it is shown on, so the
  // frame waits almost a full refresh. Starting it later brings the commit
  // closer to the compositor deadline without missing it.
  auto latency = [](gint64 offset) {
    return VblankLatency(offset, 14667, 500, kInterval60);
  };

  RunSamples(&phase, latency, kInterval60, 400, &now_us);

  EXPECT_GT(phase.offset_us(), kInterval60 / 2);
  EXPECT_LT(phase.offset_us(), kInterval60);
  const gint64 settled_latency = latency(phase.offset_us());
  EXPECT_LE(settled_latency, kInterval60 / 8 + 1000);
  EXPECT_GE(settled_latency, 0);

  // The settled phase must be stable, not oscillate between probes.
  const gint64 converged_offset = phase.offset_us();
  RunSamples(&phase, latency, kInterval60, 300, &now_us);
  EXPECT_EQ(phase.offset_us(), converged_offset);
  EXPECT_EQ(CountLateFrames(&phase, latency, kInterval60, 300, &now_us), 0);
}

TEST(FlPresentationPhaseTest, CommitAfterDeadlineWalksALargeStepLater) {
  FlPresentationPhase phase(kInterval60);
  gint64 now_us = 1000000;

  // The natural commit lands after the deadline, so every frame is presented a
  // refresh late. The useful phase is almost a full period later.
  auto latency = [](gint64 offset) {
    return VblankLatency(offset, 500, 1000, kInterval60);
  };

  RunSamples(&phase, latency, kInterval60, 600, &now_us);

  EXPECT_GT(phase.offset_us(), kInterval60 * 3 / 4);
  EXPECT_LT(phase.offset_us(), kInterval60);
  const gint64 settled_latency = latency(phase.offset_us());
  EXPECT_LE(settled_latency, kInterval60 / 8 + 1000);
  EXPECT_EQ(CountLateFrames(&phase, latency, kInterval60, 300, &now_us), 0);
}

TEST(FlPresentationPhaseTest, StartupStallsDoNotFreezeTheSearch) {
  FlPresentationPhase phase(kInterval60);
  gint64 now_us = 1000000;
  int samples = 0;

  // The first frames of an app are slow (shader compilation, first paint).
  // Those frames must not look like a phase that crossed the deadline, or the
  // controller would stay at the unshifted grid for the rest of the run.
  auto latency = [&samples](gint64 offset) {
    gint64 value = VblankLatency(offset, 14667, 500, kInterval60);
    if (samples++ < 3) {
      value += kInterval60;
    }
    return value;
  };

  RunSamples(&phase, latency, kInterval60, 400, &now_us);

  EXPECT_GT(phase.offset_us(), 0);
  EXPECT_LE(latency(phase.offset_us()), kInterval60 / 8 + 1000);
}

TEST(FlPresentationPhaseTest, AlreadyEarlyGridIsLeftAlone) {
  FlPresentationPhase phase(kInterval60);
  gint64 now_us = 1000000;

  // The natural phase already commits well inside the useful window. There is
  // nothing to improve, so the controller must settle immediately.
  auto latency = [](gint64 offset) {
    return VblankLatency(offset, 700, 500, kInterval60);
  };
  RunSamples(&phase, latency, kInterval60, 300, &now_us);

  EXPECT_EQ(phase.offset_us(), 0);
}

TEST(FlPresentationPhaseTest, QueueingCompositorKeepsNaturalPhase) {
  FlPresentationPhase phase(kInterval144);
  gint64 now_us = 1000000;

  // The compositor holds frames for a fixed time regardless of when they are
  // committed. There is no phase that can reduce the latency, so the
  // controller must settle near the natural phase instead of walking a whole
  // period.
  auto latency = [](gint64 offset) {
    (void)offset;
    return kInterval144;
  };
  RunSamples(&phase, latency, kInterval144, 600, &now_us);

  EXPECT_LT(phase.offset_us(), kInterval144 / 8);
}

TEST(FlPresentationPhaseTest, StepAcrossDeadlineBisectsInsteadOfGivingUp) {
  FlPresentationPhase phase(kInterval60);
  gint64 now_us = 1000000;

  // The compositor needs a lot of lead time, so the target latency is not
  // reachable. The first step already crosses the deadline; the controller
  // must bisect and settle just before it instead of reverting to the
  // unshifted grid.
  auto latency = [](gint64 offset) {
    return VblankLatency(offset, 6000, 5500, kInterval60);
  };
  RunSamples(&phase, latency, kInterval60, 400, &now_us);

  EXPECT_GT(phase.offset_us(), 0);
  EXPECT_LT(phase.offset_us(), 500);
  EXPECT_LT(latency(phase.offset_us()), 6000);
  EXPECT_GE(latency(phase.offset_us()), 5500);
}

TEST(FlPresentationPhaseTest, FrozenControllerRelearnsAfterWorkloadChange) {
  FlPresentationPhase phase(kInterval144);
  gint64 now_us = 1000000;

  auto first = [](gint64 offset) {
    return VblankLatency(offset, 6000, 500, kInterval144);
  };
  RunSamples(&phase, first, kInterval144, 400, &now_us);
  ASSERT_GT(phase.offset_us(), 0);
  const gint64 first_offset = phase.offset_us();

  // The compositor changes its phase: the frozen offset now commits just after
  // the deadline, which is a full refresh worse. The controller must notice
  // and lock to the new phase.
  now_us += 2 * 1000000;
  auto second = [](gint64 offset) {
    return VblankLatency(offset, 6000 + kInterval144 / 2, 500, kInterval144);
  };
  RunSamples(&phase, second, kInterval144, 600, &now_us);

  EXPECT_NE(phase.offset_us(), first_offset);
  EXPECT_LE(second(phase.offset_us()), kInterval144 / 8 + 1000);
  EXPECT_EQ(CountLateFrames(&phase, second, kInterval144, 300, &now_us), 0);
}

TEST(FlPresentationPhaseTest, SingleLateFrameDoesNotReopenASettledSearch) {
  FlPresentationPhase phase(kInterval60);
  gint64 now_us = 1000000;

  RunSamples(
      &phase,
      [](gint64 offset) {
        return VblankLatency(offset, 14667, 500, kInterval60);
      },
      kInterval60, 400, &now_us);
  const gint64 settled_offset = phase.offset_us();
  ASSERT_GT(settled_offset, 0);

  // One frame is shown a refresh late while the phase is settled. A single
  // stall is not a compositor phase change and must not restart the search.
  int sample = 0;
  auto latency = [&sample](gint64 offset) {
    gint64 value = VblankLatency(offset, 14667, 500, kInterval60);
    if (sample++ == 3) {
      value += kInterval60;
    }
    return value;
  };
  RunSamples(&phase, latency, kInterval60, 30, &now_us);

  EXPECT_EQ(phase.offset_us(), settled_offset);
}

TEST(FlPresentationPhaseTest, HighRefreshRateDoesNotOvershoot) {
  FlPresentationPhase phase(kInterval240);
  gint64 now_us = 1000000;

  auto latency = [](gint64 offset) {
    return VblankLatency(offset, 3500, 400, kInterval240);
  };
  RunSamples(&phase, latency, kInterval240, 600, &now_us);

  EXPECT_GT(phase.offset_us(), 0);
  EXPECT_LT(phase.offset_us(), kInterval240);
  const gint64 settled_latency = latency(phase.offset_us());
  EXPECT_GT(settled_latency, 0);
  EXPECT_LE(settled_latency, kInterval240 / 8 + 1000);
  EXPECT_EQ(CountLateFrames(&phase, latency, kInterval240, 300, &now_us), 0);
}

TEST(FlPresentationPhaseTest, InvalidLatencyIsIgnored) {
  FlPresentationPhase phase(kInterval60);
  gint64 now_us = 1000000;

  for (int i = 0; i < 100; i++) {
    phase.AddSample(0, now_us);
    phase.AddSample(-1000, now_us);
    phase.AddSample(kInterval60 * 5, now_us);
    now_us += kInterval60;
  }
  EXPECT_EQ(phase.offset_us(), 0);
}

TEST(FlPresentationPhaseTest, IntervalChangeResetsLearnedPhase) {
  FlPresentationPhase phase(kInterval60);
  gint64 now_us = 1000000;

  RunSamples(
      &phase,
      [](gint64 offset) {
        return VblankLatency(offset, 14000, 500, kInterval60);
      },
      kInterval60, 400, &now_us);
  ASSERT_GT(phase.offset_us(), 0);

  EXPECT_TRUE(phase.SetInterval(kInterval144));
  EXPECT_EQ(phase.offset_us(), 0);
  EXPECT_FALSE(phase.SetInterval(kInterval144));
}

TEST(FlPresentationPhaseTest, StaleSamplesDoNotResetTheOffset) {
  FlPresentationPhase phase(kInterval60);
  gint64 now_us = 1000000;

  RunSamples(
      &phase,
      [](gint64 offset) {
        return VblankLatency(offset, 14000, 500, kInterval60);
      },
      kInterval60, 400, &now_us);
  const gint64 offset = phase.offset_us();
  ASSERT_GT(offset, 0);

  // A long gap (window hidden) discards samples, but the learned phase is
  // still the best known one.
  now_us += kInterval60 * 100;
  phase.AddSample(kInterval60, now_us);
  EXPECT_EQ(phase.offset_us(), offset);
}

TEST(FlPresentationPhaseTest, TwoHundredFortyHzConverges) {
  FlPresentationPhase phase(kInterval240);
  gint64 now_us = 1000000;

  RunSamples(
      &phase,
      [](gint64 offset) {
        return VblankLatency(offset, 3800, 300, kInterval240);
      },
      kInterval240, 600, &now_us);

  EXPECT_GT(phase.offset_us(), 0);
  EXPECT_LT(phase.offset_us(), kInterval240);
  const gint64 latency =
      VblankLatency(phase.offset_us(), 3800, 300, kInterval240);
  EXPECT_LE(latency, kInterval240 / 8 + 1000);
}

}  // namespace
