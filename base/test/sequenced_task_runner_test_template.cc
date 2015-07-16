// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/sequenced_task_runner_test_template.h"

#include <ostream>

#include "base/location.h"

namespace base {

namespace internal {

TaskEvent::TaskEvent(int i, Type type)
  : i(i), type(type) {
}

SequencedTaskTracker::SequencedTaskTracker()
    : next_post_i_(0),
      task_end_count_(0),
      task_end_cv_(&lock_) {
}

void SequencedTaskTracker::PostWrappedNonNestableTask(
    const scoped_refptr<SequencedTaskRunner>& task_runner,
    const Closure& task) {
  AutoLock event_lock(lock_);
  const int post_i = next_post_i_++;
  Closure wrapped_task = Bind(&SequencedTaskTracker::RunTask, this,
                              task, post_i);
  task_runner->PostNonNestableTask(FROM_HERE, wrapped_task);
  TaskPosted(post_i);
}

void SequencedTaskTracker::PostWrappedNestableTask(
    const scoped_refptr<SequencedTaskRunner>& task_runner,
    const Closure& task) {
  AutoLock event_lock(lock_);
  const int post_i = next_post_i_++;
  Closure wrapped_task = Bind(&SequencedTaskTracker::RunTask, this,
                              task, post_i);
  task_runner->PostTask(FROM_HERE, wrapped_task);
  TaskPosted(post_i);
}

void SequencedTaskTracker::PostWrappedDelayedNonNestableTask(
    const scoped_refptr<SequencedTaskRunner>& task_runner,
    const Closure& task,
    TimeDelta delay) {
  AutoLock event_lock(lock_);
  const int post_i = next_post_i_++;
  Closure wrapped_task = Bind(&SequencedTaskTracker::RunTask, this,
                              task, post_i);
  task_runner->PostNonNestableDelayedTask(FROM_HERE, wrapped_task, delay);
  TaskPosted(post_i);
}

void SequencedTaskTracker::PostNonNestableTasks(
    const scoped_refptr<SequencedTaskRunner>& task_runner,
    int task_count) {
  for (int i = 0; i < task_count; ++i) {
    PostWrappedNonNestableTask(task_runner, Closure());
  }
}

void SequencedTaskTracker::RunTask(const Closure& task, int task_i) {
  TaskStarted(task_i);
  if (!task.is_null())
    task.Run();
  TaskEnded(task_i);
}

void SequencedTaskTracker::TaskPosted(int i) {
  // Caller must own |lock_|.
  events_.push_back(TaskEvent(i, TaskEvent::POST));
}

void SequencedTaskTracker::TaskStarted(int i) {
  AutoLock lock(lock_);
  events_.push_back(TaskEvent(i, TaskEvent::START));
}

void SequencedTaskTracker::TaskEnded(int i) {
  AutoLock lock(lock_);
  events_.push_back(TaskEvent(i, TaskEvent::END));
  ++task_end_count_;
  task_end_cv_.Signal();
}

const std::vector<TaskEvent>&
SequencedTaskTracker::GetTaskEvents() const {
  return events_;
}

void SequencedTaskTracker::WaitForCompletedTasks(int count) {
  AutoLock lock(lock_);
  while (task_end_count_ < count)
    task_end_cv_.Wait();
}

SequencedTaskTracker::~SequencedTaskTracker() {
}

void PrintTo(const TaskEvent& event, std::ostream* os) {
  *os << "(i=" << event.i << ", type=";
  switch (event.type) {
    case TaskEvent::POST: *os << "POST"; break;
    case TaskEvent::START: *os << "START"; break;
    case TaskEvent::END: *os << "END"; break;
  }
  *os << ")";
}

namespace {

// Returns the task ordinals for the task event type |type| in the order that
// they were recorded.
std::vector<int> GetEventTypeOrder(const std::vector<TaskEvent>& events,
                                   TaskEvent::Type type) {
  std::vector<int> tasks;
  std::vector<TaskEvent>::const_iterator event;
  for (event = events.begin(); event != events.end(); ++event) {
    if (event->type == type)
      tasks.push_back(event->i);
  }
  return tasks;
}

// Returns all task events for task |task_i|.
std::vector<TaskEvent::Type> GetEventsForTask(
    const std::vector<TaskEvent>& events,
    int task_i) {
  std::vector<TaskEvent::Type> task_event_orders;
  std::vector<TaskEvent>::const_iterator event;
  for (event = events.begin(); event != events.end(); ++event) {
    if (event->i == task_i)
      task_event_orders.push_back(event->type);
  }
  return task_event_orders;
}

// Checks that the task events for each task in |events| occur in the order
// {POST, START, END}, and that there is only one instance of each event type
// per task.
::testing::AssertionResult CheckEventOrdersForEachTask(
    const std::vector<TaskEvent>& events,
    int task_count) {
  std::vector<TaskEvent::Type> expected_order;
  expected_order.push_back(TaskEvent::POST);
  expected_order.push_back(TaskEvent::START);
  expected_order.push_back(TaskEvent::END);

  // This is O(n^2), but it runs fast enough currently so is not worth
  // optimizing.
  for (int i = 0; i < task_count; ++i) {
    const std::vector<TaskEvent::Type> task_events =
        GetEventsForTask(events, i);
    if (task_events != expected_order) {
      return ::testing::AssertionFailure()
          << "Events for task " << i << " are out of order; expected: "
          << ::testing::PrintToString(expected_order) << "; actual: "
          << ::testing::PrintToString(task_events);
    }
  }
  return ::testing::AssertionSuccess();
}

// Checks that no two tasks were running at the same time. I.e. the only
// events allowed between the START and END of a task are the POSTs of other
// tasks.
::testing::AssertionResult CheckNoTaskRunsOverlap(
    const std::vector<TaskEvent>& events) {
  // If > -1, we're currently inside a START, END pair.
  int current_task_i = -1;

  std::vector<TaskEvent>::const_iterator event;
  for (event = events.begin(); event != events.end(); ++event) {
    bool spurious_event_found = false;

    if (current_task_i == -1) {  // Not inside a START, END pair.
      switch (event->type) {
        case TaskEvent::POST:
          break;
        case TaskEvent::START:
          current_task_i = event->i;
          break;
        case TaskEvent::END:
          spurious_event_found = true;
          break;
      }

    } else {  // Inside a START, END pair.
      bool interleaved_task_detected = false;

      switch (event->type) {
        case TaskEvent::POST:
          if (event->i == current_task_i)
            spurious_event_found = true;
          break;
        case TaskEvent::START:
          interleaved_task_detected = true;
          break;
        case TaskEvent::END:
          if (event->i != current_task_i)
            interleaved_task_detected = true;
          else
            current_task_i = -1;
          break;
      }

      if (interleaved_task_detected) {
        return ::testing::AssertionFailure()
            << "Found event " << ::testing::PrintToString(*event)
            << " between START and END events for task " << current_task_i
            << "; event dump: " << ::testing::PrintToString(events);
      }
    }

    if (spurious_event_found) {
      const int event_i = event - events.begin();
      return ::testing::AssertionFailure()
          << "Spurious event " << ::testing::PrintToString(*event)
          << " at position " << event_i << "; event dump: "
          << ::testing::PrintToString(events);
    }
  }

  return ::testing::AssertionSuccess();
}

}  // namespace

::testing::AssertionResult CheckNonNestableInvariants(
    const std::vector<TaskEvent>& events,
    int task_count) {
  const std::vector<int> post_order =
      GetEventTypeOrder(events, TaskEvent::POST);
  const std::vector<int> start_order =
      GetEventTypeOrder(events, TaskEvent::START);
  const std::vector<int> end_order =
      GetEventTypeOrder(events, TaskEvent::END);

  if (start_order != post_order) {
    return ::testing::AssertionFailure()
        << "Expected START order (which equals actual POST order): \n"
        << ::testing::PrintToString(post_order)
        << "\n Actual START order:\n"
        << ::testing::PrintToString(start_order);
  }

  if (end_order != post_order) {
    return ::testing::AssertionFailure()
        << "Expected END order (which equals actual POST order): \n"
        << ::testing::PrintToString(post_order)
        << "\n Actual END order:\n"
        << ::testing::PrintToString(end_order);
  }

  const ::testing::AssertionResult result =
      CheckEventOrdersForEachTask(events, task_count);
  if (!result)
    return result;

  return CheckNoTaskRunsOverlap(events);
}

}  // namespace internal

}  // namespace base
