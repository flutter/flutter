// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_TEST_PENDING_TASK_H_
#define BASE_TEST_TEST_PENDING_TASK_H_

#include <string>

#include "base/callback.h"
#include "base/location.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event_argument.h"

namespace base {

// TestPendingTask is a helper class for test TaskRunner
// implementations.  See test_simple_task_runner.h for example usage.

struct TestPendingTask {
  enum TestNestability { NESTABLE, NON_NESTABLE };

  TestPendingTask();
  TestPendingTask(const tracked_objects::Location& location,
                  const Closure& task,
                  TimeTicks post_time,
                  TimeDelta delay,
                  TestNestability nestability);
  ~TestPendingTask();

  // Returns post_time + delay.
  TimeTicks GetTimeToRun() const;

  // Returns true if this task is nestable and |other| isn't, or if
  // this task's time to run is strictly earlier than |other|'s time
  // to run.
  //
  // Note that two tasks may both have the same nestability and delay.
  // In that case, the caller must use some other criterion (probably
  // the position in some queue) to break the tie.  Conveniently, the
  // following STL functions already do so:
  //
  //   - std::min_element
  //   - std::stable_sort
  //
  // but the following STL functions don't:
  //
  //   - std::max_element
  //   - std::sort.
  bool ShouldRunBefore(const TestPendingTask& other) const;

  tracked_objects::Location location;
  Closure task;
  TimeTicks post_time;
  TimeDelta delay;
  TestNestability nestability;

  // Functions for using test pending task with tracing, useful in unit
  // testing.
  void AsValueInto(base::trace_event::TracedValue* state) const;
  scoped_refptr<base::trace_event::ConvertableToTraceFormat> AsValue() const;
  std::string ToString() const;
};

// gtest helpers which allow pretty printing of the tasks, very useful in unit
// testing.
std::ostream& operator<<(std::ostream& os, const TestPendingTask& task);
void PrintTo(const TestPendingTask& task, std::ostream* os);

}  // namespace base

#endif  // BASE_TEST_TEST_PENDING_TASK_H_
