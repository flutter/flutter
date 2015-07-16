// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_synthetic_delay.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace trace_event {
namespace {

const int kTargetDurationMs = 100;
// Allow some leeway in timings to make it possible to run these tests with a
// wall clock time source too.
const int kShortDurationMs = 10;

}  // namespace

class TraceEventSyntheticDelayTest : public testing::Test,
                                     public TraceEventSyntheticDelayClock {
 public:
  TraceEventSyntheticDelayTest() {}
  ~TraceEventSyntheticDelayTest() override { ResetTraceEventSyntheticDelays(); }

  // TraceEventSyntheticDelayClock implementation.
  base::TimeTicks Now() override {
    AdvanceTime(base::TimeDelta::FromMilliseconds(kShortDurationMs / 10));
    return now_;
  }

  TraceEventSyntheticDelay* ConfigureDelay(const char* name) {
    TraceEventSyntheticDelay* delay = TraceEventSyntheticDelay::Lookup(name);
    delay->SetClock(this);
    delay->SetTargetDuration(
        base::TimeDelta::FromMilliseconds(kTargetDurationMs));
    return delay;
  }

  void AdvanceTime(base::TimeDelta delta) { now_ += delta; }

  int64 TestFunction() {
    base::TimeTicks start = Now();
    { TRACE_EVENT_SYNTHETIC_DELAY("test.Delay"); }
    return (Now() - start).InMilliseconds();
  }

  int64 AsyncTestFunctionBegin() {
    base::TimeTicks start = Now();
    { TRACE_EVENT_SYNTHETIC_DELAY_BEGIN("test.AsyncDelay"); }
    return (Now() - start).InMilliseconds();
  }

  int64 AsyncTestFunctionEnd() {
    base::TimeTicks start = Now();
    { TRACE_EVENT_SYNTHETIC_DELAY_END("test.AsyncDelay"); }
    return (Now() - start).InMilliseconds();
  }

 private:
  base::TimeTicks now_;

  DISALLOW_COPY_AND_ASSIGN(TraceEventSyntheticDelayTest);
};

TEST_F(TraceEventSyntheticDelayTest, StaticDelay) {
  TraceEventSyntheticDelay* delay = ConfigureDelay("test.Delay");
  delay->SetMode(TraceEventSyntheticDelay::STATIC);
  EXPECT_GE(TestFunction(), kTargetDurationMs);
}

TEST_F(TraceEventSyntheticDelayTest, OneShotDelay) {
  TraceEventSyntheticDelay* delay = ConfigureDelay("test.Delay");
  delay->SetMode(TraceEventSyntheticDelay::ONE_SHOT);
  EXPECT_GE(TestFunction(), kTargetDurationMs);
  EXPECT_LT(TestFunction(), kShortDurationMs);

  delay->SetTargetDuration(
      base::TimeDelta::FromMilliseconds(kTargetDurationMs));
  EXPECT_GE(TestFunction(), kTargetDurationMs);
}

TEST_F(TraceEventSyntheticDelayTest, AlternatingDelay) {
  TraceEventSyntheticDelay* delay = ConfigureDelay("test.Delay");
  delay->SetMode(TraceEventSyntheticDelay::ALTERNATING);
  EXPECT_GE(TestFunction(), kTargetDurationMs);
  EXPECT_LT(TestFunction(), kShortDurationMs);
  EXPECT_GE(TestFunction(), kTargetDurationMs);
  EXPECT_LT(TestFunction(), kShortDurationMs);
}

TEST_F(TraceEventSyntheticDelayTest, AsyncDelay) {
  ConfigureDelay("test.AsyncDelay");
  EXPECT_LT(AsyncTestFunctionBegin(), kShortDurationMs);
  EXPECT_GE(AsyncTestFunctionEnd(), kTargetDurationMs / 2);
}

TEST_F(TraceEventSyntheticDelayTest, AsyncDelayExceeded) {
  ConfigureDelay("test.AsyncDelay");
  EXPECT_LT(AsyncTestFunctionBegin(), kShortDurationMs);
  AdvanceTime(base::TimeDelta::FromMilliseconds(kTargetDurationMs));
  EXPECT_LT(AsyncTestFunctionEnd(), kShortDurationMs);
}

TEST_F(TraceEventSyntheticDelayTest, AsyncDelayNoActivation) {
  ConfigureDelay("test.AsyncDelay");
  EXPECT_LT(AsyncTestFunctionEnd(), kShortDurationMs);
}

TEST_F(TraceEventSyntheticDelayTest, AsyncDelayNested) {
  ConfigureDelay("test.AsyncDelay");
  EXPECT_LT(AsyncTestFunctionBegin(), kShortDurationMs);
  EXPECT_LT(AsyncTestFunctionBegin(), kShortDurationMs);
  EXPECT_LT(AsyncTestFunctionEnd(), kShortDurationMs);
  EXPECT_GE(AsyncTestFunctionEnd(), kTargetDurationMs / 2);
}

TEST_F(TraceEventSyntheticDelayTest, AsyncDelayUnbalanced) {
  ConfigureDelay("test.AsyncDelay");
  EXPECT_LT(AsyncTestFunctionBegin(), kShortDurationMs);
  EXPECT_GE(AsyncTestFunctionEnd(), kTargetDurationMs / 2);
  EXPECT_LT(AsyncTestFunctionEnd(), kShortDurationMs);

  EXPECT_LT(AsyncTestFunctionBegin(), kShortDurationMs);
  EXPECT_GE(AsyncTestFunctionEnd(), kTargetDurationMs / 2);
}

TEST_F(TraceEventSyntheticDelayTest, ResetDelays) {
  ConfigureDelay("test.Delay");
  ResetTraceEventSyntheticDelays();
  EXPECT_LT(TestFunction(), kShortDurationMs);
}

TEST_F(TraceEventSyntheticDelayTest, BeginParallel) {
  TraceEventSyntheticDelay* delay = ConfigureDelay("test.AsyncDelay");
  base::TimeTicks end_times[2];
  base::TimeTicks start_time = Now();

  delay->BeginParallel(&end_times[0]);
  EXPECT_FALSE(end_times[0].is_null());

  delay->BeginParallel(&end_times[1]);
  EXPECT_FALSE(end_times[1].is_null());

  delay->EndParallel(end_times[0]);
  EXPECT_GE((Now() - start_time).InMilliseconds(), kTargetDurationMs);

  start_time = Now();
  delay->EndParallel(end_times[1]);
  EXPECT_LT((Now() - start_time).InMilliseconds(), kShortDurationMs);
}

}  // namespace trace_event
}  // namespace base
