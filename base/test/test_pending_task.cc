// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "base/test/test_pending_task.h"

namespace base {

TestPendingTask::TestPendingTask() : nestability(NESTABLE) {}

TestPendingTask::TestPendingTask(
    const tracked_objects::Location& location,
    const Closure& task,
    TimeTicks post_time,
    TimeDelta delay,
    TestNestability nestability)
    : location(location),
      task(task),
      post_time(post_time),
      delay(delay),
      nestability(nestability) {}

TimeTicks TestPendingTask::GetTimeToRun() const {
  return post_time + delay;
}

bool TestPendingTask::ShouldRunBefore(const TestPendingTask& other) const {
  if (nestability != other.nestability)
    return (nestability == NESTABLE);
  return GetTimeToRun() < other.GetTimeToRun();
}

TestPendingTask::~TestPendingTask() {}

void TestPendingTask::AsValueInto(base::trace_event::TracedValue* state) const {
  state->SetInteger("run_at", GetTimeToRun().ToInternalValue());
  state->SetString("posting_function", location.ToString());
  state->SetInteger("post_time", post_time.ToInternalValue());
  state->SetInteger("delay", delay.ToInternalValue());
  switch (nestability) {
    case NESTABLE:
      state->SetString("nestability", "NESTABLE");
      break;
    case NON_NESTABLE:
      state->SetString("nestability", "NON_NESTABLE");
      break;
  }
  state->SetInteger("delay", delay.ToInternalValue());
}

scoped_refptr<base::trace_event::ConvertableToTraceFormat>
TestPendingTask::AsValue() const {
  scoped_refptr<base::trace_event::TracedValue> state =
      new base::trace_event::TracedValue();
  AsValueInto(state.get());
  return state;
}

std::string TestPendingTask::ToString() const {
  std::string output("TestPendingTask(");
  AsValue()->AppendAsTraceFormat(&output);
  output += ")";
  return output;
}

std::ostream& operator<<(std::ostream& os, const TestPendingTask& task) {
  PrintTo(task, &os);
  return os;
}

void PrintTo(const TestPendingTask& task, std::ostream* os) {
  *os << task.ToString();
}

}  // namespace base
