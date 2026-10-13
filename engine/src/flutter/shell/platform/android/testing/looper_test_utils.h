// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_TESTING_LOOPER_TEST_UTILS_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_TESTING_LOOPER_TEST_UTILS_H_

#include <android/looper.h>

#include <functional>

#include "flutter/fml/message_loop.h"
#include "flutter/fml/message_loop_task_queues.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

// Upper bound for one ALooper_pollOnce call while pumping, in milliseconds.
// Short, so the pump notices completion within a fraction of a frame.
inline constexpr int kLooperPollIntervalMs = 5;

// Dispatches the ALooper of the current thread, which runs both fml tasks and
// Choreographer frame callbacks, until |done| returns true or |timeout|
// passes. With merged threads the UI task runner is the test thread, so
// waiting on a latch instead would stall the vsync it waits for.
//
// A single zero-timeout ALooper_pollOnce right after a task is posted to the
// current thread is not enough: fml's Android message loop wakes through a
// timerfd, and the poll can return before that timer is readable, leaving the
// task queued. Pump with a deadline instead.
inline bool PumpLooperUntil(const std::function<bool()>& done,
                            fml::TimeDelta timeout) {
  const fml::TimePoint deadline = fml::TimePoint::Now() + timeout;
  while (!done()) {
    if (fml::TimePoint::Now() >= deadline) {
      return false;
    }
    if (ALooper_pollOnce(kLooperPollIntervalMs, nullptr, nullptr, nullptr) ==
        ALOOPER_POLL_ERROR) {
      ADD_FAILURE() << "ALooper_pollOnce failed on the test thread.";
      return false;
    }
  }
  return true;
}

// Dispatches the ALooper of the current thread for |duration|.
inline void PumpLooperFor(fml::TimeDelta duration) {
  PumpLooperUntil([] { return false; }, duration);
}

// Runs the current thread's fml tasks until every task that was due when this
// was called has run, or |timeout| passes. It posts a marker task and pumps
// until the marker runs; fml runs tasks in target-time order and in posting
// order for equal times, so earlier immediate tasks run first.
inline bool DrainCurrentThreadTasks(fml::TimeDelta timeout) {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  bool marker_ran = false;
  fml::MessageLoopTaskQueues::GetInstance()->RegisterTask(
      fml::MessageLoop::GetCurrentTaskQueueId(),
      [&marker_ran]() { marker_ran = true; }, fml::TimePoint::Now());
  return PumpLooperUntil([&marker_ran]() { return marker_ran; }, timeout);
}

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_TESTING_LOOPER_TEST_UTILS_H_
