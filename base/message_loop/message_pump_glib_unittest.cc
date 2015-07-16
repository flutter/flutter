// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_pump_glib.h"

#include <glib.h>
#include <math.h>

#include <algorithm>
#include <vector>

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/callback.h"
#include "base/memory/ref_counted.h"
#include "base/message_loop/message_loop.h"
#include "base/run_loop.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

// This class injects dummy "events" into the GLib loop. When "handled" these
// events can run tasks. This is intended to mock gtk events (the corresponding
// GLib source runs at the same priority).
class EventInjector {
 public:
  EventInjector() : processed_events_(0) {
    source_ = static_cast<Source*>(g_source_new(&SourceFuncs, sizeof(Source)));
    source_->injector = this;
    g_source_attach(source_, NULL);
    g_source_set_can_recurse(source_, TRUE);
  }

  ~EventInjector() {
    g_source_destroy(source_);
    g_source_unref(source_);
  }

  int HandlePrepare() {
    // If the queue is empty, block.
    if (events_.empty())
      return -1;
    TimeDelta delta = events_[0].time - Time::NowFromSystemTime();
    return std::max(0, static_cast<int>(ceil(delta.InMillisecondsF())));
  }

  bool HandleCheck() {
    if (events_.empty())
      return false;
    return events_[0].time <= Time::NowFromSystemTime();
  }

  void HandleDispatch() {
    if (events_.empty())
      return;
    Event event = events_[0];
    events_.erase(events_.begin());
    ++processed_events_;
    if (!event.callback.is_null())
      event.callback.Run();
    else if (!event.task.is_null())
      event.task.Run();
  }

  // Adds an event to the queue. When "handled", executes |callback|.
  // delay_ms is relative to the last event if any, or to Now() otherwise.
  void AddEvent(int delay_ms, const Closure& callback) {
    AddEventHelper(delay_ms, callback, Closure());
  }

  void AddDummyEvent(int delay_ms) {
    AddEventHelper(delay_ms, Closure(), Closure());
  }

  void AddEventAsTask(int delay_ms, const Closure& task) {
    AddEventHelper(delay_ms, Closure(), task);
  }

  void Reset() {
    processed_events_ = 0;
    events_.clear();
  }

  int processed_events() const { return processed_events_; }

 private:
  struct Event {
    Time time;
    Closure callback;
    Closure task;
  };

  struct Source : public GSource {
    EventInjector* injector;
  };

  void AddEventHelper(
      int delay_ms, const Closure& callback, const Closure& task) {
    Time last_time;
    if (!events_.empty())
      last_time = (events_.end()-1)->time;
    else
      last_time = Time::NowFromSystemTime();

    Time future = last_time + TimeDelta::FromMilliseconds(delay_ms);
    EventInjector::Event event = {future, callback, task};
    events_.push_back(event);
  }

  static gboolean Prepare(GSource* source, gint* timeout_ms) {
    *timeout_ms = static_cast<Source*>(source)->injector->HandlePrepare();
    return FALSE;
  }

  static gboolean Check(GSource* source) {
    return static_cast<Source*>(source)->injector->HandleCheck();
  }

  static gboolean Dispatch(GSource* source,
                           GSourceFunc unused_func,
                           gpointer unused_data) {
    static_cast<Source*>(source)->injector->HandleDispatch();
    return TRUE;
  }

  Source* source_;
  std::vector<Event> events_;
  int processed_events_;
  static GSourceFuncs SourceFuncs;
  DISALLOW_COPY_AND_ASSIGN(EventInjector);
};

GSourceFuncs EventInjector::SourceFuncs = {
  EventInjector::Prepare,
  EventInjector::Check,
  EventInjector::Dispatch,
  NULL
};

void IncrementInt(int *value) {
  ++*value;
}

// Checks how many events have been processed by the injector.
void ExpectProcessedEvents(EventInjector* injector, int count) {
  EXPECT_EQ(injector->processed_events(), count);
}

// Posts a task on the current message loop.
void PostMessageLoopTask(const tracked_objects::Location& from_here,
                         const Closure& task) {
  MessageLoop::current()->PostTask(from_here, task);
}

// Test fixture.
class MessagePumpGLibTest : public testing::Test {
 public:
  MessagePumpGLibTest() : loop_(NULL), injector_(NULL) { }

  // Overridden from testing::Test:
  void SetUp() override {
    loop_ = new MessageLoop(MessageLoop::TYPE_UI);
    injector_ = new EventInjector();
  }
  void TearDown() override {
    delete injector_;
    injector_ = NULL;
    delete loop_;
    loop_ = NULL;
  }

  MessageLoop* loop() const { return loop_; }
  EventInjector* injector() const { return injector_; }

 private:
  MessageLoop* loop_;
  EventInjector* injector_;
  DISALLOW_COPY_AND_ASSIGN(MessagePumpGLibTest);
};

}  // namespace

TEST_F(MessagePumpGLibTest, TestQuit) {
  // Checks that Quit works and that the basic infrastructure is working.

  // Quit from a task
  RunLoop().RunUntilIdle();
  EXPECT_EQ(0, injector()->processed_events());

  injector()->Reset();
  // Quit from an event
  injector()->AddEvent(0, MessageLoop::QuitWhenIdleClosure());
  loop()->Run();
  EXPECT_EQ(1, injector()->processed_events());
}

TEST_F(MessagePumpGLibTest, TestEventTaskInterleave) {
  // Checks that tasks posted by events are executed before the next event if
  // the posted task queue is empty.
  // MessageLoop doesn't make strong guarantees that it is the case, but the
  // current implementation ensures it and the tests below rely on it.
  // If changes cause this test to fail, it is reasonable to change it, but
  // TestWorkWhileWaitingForEvents and TestEventsWhileWaitingForWork have to be
  // changed accordingly, otherwise they can become flaky.
  injector()->AddEventAsTask(0, Bind(&DoNothing));
  Closure check_task =
      Bind(&ExpectProcessedEvents, Unretained(injector()), 2);
  Closure posted_task =
      Bind(&PostMessageLoopTask, FROM_HERE, check_task);
  injector()->AddEventAsTask(0, posted_task);
  injector()->AddEventAsTask(0, Bind(&DoNothing));
  injector()->AddEvent(0, MessageLoop::QuitWhenIdleClosure());
  loop()->Run();
  EXPECT_EQ(4, injector()->processed_events());

  injector()->Reset();
  injector()->AddEventAsTask(0, Bind(&DoNothing));
  check_task =
      Bind(&ExpectProcessedEvents, Unretained(injector()), 2);
  posted_task = Bind(&PostMessageLoopTask, FROM_HERE, check_task);
  injector()->AddEventAsTask(0, posted_task);
  injector()->AddEventAsTask(10, Bind(&DoNothing));
  injector()->AddEvent(0, MessageLoop::QuitWhenIdleClosure());
  loop()->Run();
  EXPECT_EQ(4, injector()->processed_events());
}

TEST_F(MessagePumpGLibTest, TestWorkWhileWaitingForEvents) {
  int task_count = 0;
  // Tests that we process tasks while waiting for new events.
  // The event queue is empty at first.
  for (int i = 0; i < 10; ++i) {
    loop()->PostTask(FROM_HERE, Bind(&IncrementInt, &task_count));
  }
  // After all the previous tasks have executed, enqueue an event that will
  // quit.
  loop()->PostTask(
      FROM_HERE,
      Bind(&EventInjector::AddEvent, Unretained(injector()), 0,
                 MessageLoop::QuitWhenIdleClosure()));
  loop()->Run();
  ASSERT_EQ(10, task_count);
  EXPECT_EQ(1, injector()->processed_events());

  // Tests that we process delayed tasks while waiting for new events.
  injector()->Reset();
  task_count = 0;
  for (int i = 0; i < 10; ++i) {
    loop()->PostDelayedTask(
        FROM_HERE,
        Bind(&IncrementInt, &task_count),
        TimeDelta::FromMilliseconds(10*i));
  }
  // After all the previous tasks have executed, enqueue an event that will
  // quit.
  // This relies on the fact that delayed tasks are executed in delay order.
  // That is verified in message_loop_unittest.cc.
  loop()->PostDelayedTask(
      FROM_HERE,
      Bind(&EventInjector::AddEvent, Unretained(injector()), 10,
                 MessageLoop::QuitWhenIdleClosure()),
      TimeDelta::FromMilliseconds(150));
  loop()->Run();
  ASSERT_EQ(10, task_count);
  EXPECT_EQ(1, injector()->processed_events());
}

TEST_F(MessagePumpGLibTest, TestEventsWhileWaitingForWork) {
  // Tests that we process events while waiting for work.
  // The event queue is empty at first.
  for (int i = 0; i < 10; ++i) {
    injector()->AddDummyEvent(0);
  }
  // After all the events have been processed, post a task that will check that
  // the events have been processed (note: the task executes after the event
  // that posted it has been handled, so we expect 11 at that point).
  Closure check_task =
      Bind(&ExpectProcessedEvents, Unretained(injector()), 11);
  Closure posted_task =
      Bind(&PostMessageLoopTask, FROM_HERE, check_task);
  injector()->AddEventAsTask(10, posted_task);

  // And then quit (relies on the condition tested by TestEventTaskInterleave).
  injector()->AddEvent(10, MessageLoop::QuitWhenIdleClosure());
  loop()->Run();

  EXPECT_EQ(12, injector()->processed_events());
}

namespace {

// This class is a helper for the concurrent events / posted tasks test below.
// It will quit the main loop once enough tasks and events have been processed,
// while making sure there is always work to do and events in the queue.
class ConcurrentHelper : public RefCounted<ConcurrentHelper>  {
 public:
  explicit ConcurrentHelper(EventInjector* injector)
      : injector_(injector),
        event_count_(kStartingEventCount),
        task_count_(kStartingTaskCount) {
  }

  void FromTask() {
    if (task_count_ > 0) {
      --task_count_;
    }
    if (task_count_ == 0 && event_count_ == 0) {
        MessageLoop::current()->QuitWhenIdle();
    } else {
      MessageLoop::current()->PostTask(
          FROM_HERE, Bind(&ConcurrentHelper::FromTask, this));
    }
  }

  void FromEvent() {
    if (event_count_ > 0) {
      --event_count_;
    }
    if (task_count_ == 0 && event_count_ == 0) {
        MessageLoop::current()->QuitWhenIdle();
    } else {
      injector_->AddEventAsTask(
          0, Bind(&ConcurrentHelper::FromEvent, this));
    }
  }

  int event_count() const { return event_count_; }
  int task_count() const { return task_count_; }

 private:
  friend class RefCounted<ConcurrentHelper>;

  ~ConcurrentHelper() {}

  static const int kStartingEventCount = 20;
  static const int kStartingTaskCount = 20;

  EventInjector* injector_;
  int event_count_;
  int task_count_;
};

}  // namespace

TEST_F(MessagePumpGLibTest, TestConcurrentEventPostedTask) {
  // Tests that posted tasks don't starve events, nor the opposite.
  // We use the helper class above. We keep both event and posted task queues
  // full, the helper verifies that both tasks and events get processed.
  // If that is not the case, either event_count_ or task_count_ will not get
  // to 0, and MessageLoop::QuitWhenIdle() will never be called.
  scoped_refptr<ConcurrentHelper> helper = new ConcurrentHelper(injector());

  // Add 2 events to the queue to make sure it is always full (when we remove
  // the event before processing it).
  injector()->AddEventAsTask(
      0, Bind(&ConcurrentHelper::FromEvent, helper.get()));
  injector()->AddEventAsTask(
      0, Bind(&ConcurrentHelper::FromEvent, helper.get()));

  // Similarly post 2 tasks.
  loop()->PostTask(
      FROM_HERE, Bind(&ConcurrentHelper::FromTask, helper.get()));
  loop()->PostTask(
      FROM_HERE, Bind(&ConcurrentHelper::FromTask, helper.get()));

  loop()->Run();
  EXPECT_EQ(0, helper->event_count());
  EXPECT_EQ(0, helper->task_count());
}

namespace {

void AddEventsAndDrainGLib(EventInjector* injector) {
  // Add a couple of dummy events
  injector->AddDummyEvent(0);
  injector->AddDummyEvent(0);
  // Then add an event that will quit the main loop.
  injector->AddEvent(0, MessageLoop::QuitWhenIdleClosure());

  // Post a couple of dummy tasks
  MessageLoop::current()->PostTask(FROM_HERE, Bind(&DoNothing));
  MessageLoop::current()->PostTask(FROM_HERE, Bind(&DoNothing));

  // Drain the events
  while (g_main_context_pending(NULL)) {
    g_main_context_iteration(NULL, FALSE);
  }
}

}  // namespace

TEST_F(MessagePumpGLibTest, TestDrainingGLib) {
  // Tests that draining events using GLib works.
  loop()->PostTask(
      FROM_HERE,
      Bind(&AddEventsAndDrainGLib, Unretained(injector())));
  loop()->Run();

  EXPECT_EQ(3, injector()->processed_events());
}

namespace {

// Helper class that lets us run the GLib message loop.
class GLibLoopRunner : public RefCounted<GLibLoopRunner> {
 public:
  GLibLoopRunner() : quit_(false) { }

  void RunGLib() {
    while (!quit_) {
      g_main_context_iteration(NULL, TRUE);
    }
  }

  void RunLoop() {
    while (!quit_) {
      g_main_context_iteration(NULL, TRUE);
    }
  }

  void Quit() {
    quit_ = true;
  }

  void Reset() {
    quit_ = false;
  }

 private:
  friend class RefCounted<GLibLoopRunner>;

  ~GLibLoopRunner() {}

  bool quit_;
};

void TestGLibLoopInternal(EventInjector* injector) {
  // Allow tasks to be processed from 'native' event loops.
  MessageLoop::current()->SetNestableTasksAllowed(true);
  scoped_refptr<GLibLoopRunner> runner = new GLibLoopRunner();

  int task_count = 0;
  // Add a couple of dummy events
  injector->AddDummyEvent(0);
  injector->AddDummyEvent(0);
  // Post a couple of dummy tasks
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&IncrementInt, &task_count));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&IncrementInt, &task_count));
  // Delayed events
  injector->AddDummyEvent(10);
  injector->AddDummyEvent(10);
  // Delayed work
  MessageLoop::current()->PostDelayedTask(
      FROM_HERE,
      Bind(&IncrementInt, &task_count),
      TimeDelta::FromMilliseconds(30));
  MessageLoop::current()->PostDelayedTask(
      FROM_HERE,
      Bind(&GLibLoopRunner::Quit, runner.get()),
      TimeDelta::FromMilliseconds(40));

  // Run a nested, straight GLib message loop.
  runner->RunGLib();

  ASSERT_EQ(3, task_count);
  EXPECT_EQ(4, injector->processed_events());
  MessageLoop::current()->QuitWhenIdle();
}

void TestGtkLoopInternal(EventInjector* injector) {
  // Allow tasks to be processed from 'native' event loops.
  MessageLoop::current()->SetNestableTasksAllowed(true);
  scoped_refptr<GLibLoopRunner> runner = new GLibLoopRunner();

  int task_count = 0;
  // Add a couple of dummy events
  injector->AddDummyEvent(0);
  injector->AddDummyEvent(0);
  // Post a couple of dummy tasks
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&IncrementInt, &task_count));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&IncrementInt, &task_count));
  // Delayed events
  injector->AddDummyEvent(10);
  injector->AddDummyEvent(10);
  // Delayed work
  MessageLoop::current()->PostDelayedTask(
      FROM_HERE,
      Bind(&IncrementInt, &task_count),
      TimeDelta::FromMilliseconds(30));
  MessageLoop::current()->PostDelayedTask(
      FROM_HERE,
      Bind(&GLibLoopRunner::Quit, runner.get()),
      TimeDelta::FromMilliseconds(40));

  // Run a nested, straight Gtk message loop.
  runner->RunLoop();

  ASSERT_EQ(3, task_count);
  EXPECT_EQ(4, injector->processed_events());
  MessageLoop::current()->QuitWhenIdle();
}

}  // namespace

TEST_F(MessagePumpGLibTest, TestGLibLoop) {
  // Tests that events and posted tasks are correctly executed if the message
  // loop is not run by MessageLoop::Run() but by a straight GLib loop.
  // Note that in this case we don't make strong guarantees about niceness
  // between events and posted tasks.
  loop()->PostTask(
      FROM_HERE,
      Bind(&TestGLibLoopInternal, Unretained(injector())));
  loop()->Run();
}

TEST_F(MessagePumpGLibTest, TestGtkLoop) {
  // Tests that events and posted tasks are correctly executed if the message
  // loop is not run by MessageLoop::Run() but by a straight Gtk loop.
  // Note that in this case we don't make strong guarantees about niceness
  // between events and posted tasks.
  loop()->PostTask(
      FROM_HERE,
      Bind(&TestGtkLoopInternal, Unretained(injector())));
  loop()->Run();
}

}  // namespace base
