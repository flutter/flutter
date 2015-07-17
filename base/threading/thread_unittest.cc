// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/thread.h"

#include <vector>

#include "base/bind.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "base/third_party/dynamic_annotations/dynamic_annotations.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

using base::Thread;

typedef PlatformTest ThreadTest;

namespace {

void ToggleValue(bool* value) {
  ANNOTATE_BENIGN_RACE(value, "Test-only data race on boolean "
                       "in base/thread_unittest");
  *value = !*value;
}

class SleepInsideInitThread : public Thread {
 public:
  SleepInsideInitThread() : Thread("none") {
    init_called_ = false;
    ANNOTATE_BENIGN_RACE(
        this, "Benign test-only data race on vptr - http://crbug.com/98219");
  }
  ~SleepInsideInitThread() override { Stop(); }

  void Init() override {
    base::PlatformThread::Sleep(base::TimeDelta::FromMilliseconds(500));
    init_called_ = true;
  }
  bool InitCalled() { return init_called_; }
 private:
  bool init_called_;
};

enum ThreadEvent {
  // Thread::Init() was called.
  THREAD_EVENT_INIT = 0,

  // The MessageLoop for the thread was deleted.
  THREAD_EVENT_MESSAGE_LOOP_DESTROYED,

  // Thread::CleanUp() was called.
  THREAD_EVENT_CLEANUP,

  // Keep at end of list.
  THREAD_NUM_EVENTS
};

typedef std::vector<ThreadEvent> EventList;

class CaptureToEventList : public Thread {
 public:
  // This Thread pushes events into the vector |event_list| to show
  // the order they occured in. |event_list| must remain valid for the
  // lifetime of this thread.
  explicit CaptureToEventList(EventList* event_list)
      : Thread("none"),
        event_list_(event_list) {
  }

  ~CaptureToEventList() override { Stop(); }

  void Init() override { event_list_->push_back(THREAD_EVENT_INIT); }

  void CleanUp() override { event_list_->push_back(THREAD_EVENT_CLEANUP); }

 private:
  EventList* event_list_;
};

// Observer that writes a value into |event_list| when a message loop has been
// destroyed.
class CapturingDestructionObserver
    : public base::MessageLoop::DestructionObserver {
 public:
  // |event_list| must remain valid throughout the observer's lifetime.
  explicit CapturingDestructionObserver(EventList* event_list)
      : event_list_(event_list) {
  }

  // DestructionObserver implementation:
  void WillDestroyCurrentMessageLoop() override {
    event_list_->push_back(THREAD_EVENT_MESSAGE_LOOP_DESTROYED);
    event_list_ = NULL;
  }

 private:
  EventList* event_list_;
};

// Task that adds a destruction observer to the current message loop.
void RegisterDestructionObserver(
    base::MessageLoop::DestructionObserver* observer) {
  base::MessageLoop::current()->AddDestructionObserver(observer);
}

}  // namespace

TEST_F(ThreadTest, Restart) {
  Thread a("Restart");
  a.Stop();
  EXPECT_FALSE(a.message_loop());
  EXPECT_FALSE(a.IsRunning());
  EXPECT_TRUE(a.Start());
  EXPECT_TRUE(a.message_loop());
  EXPECT_TRUE(a.IsRunning());
  a.Stop();
  EXPECT_FALSE(a.message_loop());
  EXPECT_FALSE(a.IsRunning());
  EXPECT_TRUE(a.Start());
  EXPECT_TRUE(a.message_loop());
  EXPECT_TRUE(a.IsRunning());
  a.Stop();
  EXPECT_FALSE(a.message_loop());
  EXPECT_FALSE(a.IsRunning());
  a.Stop();
  EXPECT_FALSE(a.message_loop());
  EXPECT_FALSE(a.IsRunning());
}

TEST_F(ThreadTest, StartWithOptions_StackSize) {
  Thread a("StartWithStackSize");
  // Ensure that the thread can work with only 12 kb and still process a
  // message.
  Thread::Options options;
#if defined(ADDRESS_SANITIZER) && defined(OS_MACOSX)
  // ASan bloats the stack variables and overflows the 12 kb stack on OSX.
  options.stack_size = 24*1024;
#else
  options.stack_size = 12*1024;
#endif
  EXPECT_TRUE(a.StartWithOptions(options));
  EXPECT_TRUE(a.message_loop());
  EXPECT_TRUE(a.IsRunning());

  bool was_invoked = false;
  a.task_runner()->PostTask(FROM_HERE, base::Bind(&ToggleValue, &was_invoked));

  // wait for the task to run (we could use a kernel event here
  // instead to avoid busy waiting, but this is sufficient for
  // testing purposes).
  for (int i = 100; i >= 0 && !was_invoked; --i) {
    base::PlatformThread::Sleep(base::TimeDelta::FromMilliseconds(10));
  }
  EXPECT_TRUE(was_invoked);
}

TEST_F(ThreadTest, TwoTasks) {
  bool was_invoked = false;
  {
    Thread a("TwoTasks");
    EXPECT_TRUE(a.Start());
    EXPECT_TRUE(a.message_loop());

    // Test that all events are dispatched before the Thread object is
    // destroyed.  We do this by dispatching a sleep event before the
    // event that will toggle our sentinel value.
    a.task_runner()->PostTask(
        FROM_HERE, base::Bind(static_cast<void (*)(base::TimeDelta)>(
                                  &base::PlatformThread::Sleep),
                              base::TimeDelta::FromMilliseconds(20)));
    a.task_runner()->PostTask(FROM_HERE,
                              base::Bind(&ToggleValue, &was_invoked));
  }
  EXPECT_TRUE(was_invoked);
}

TEST_F(ThreadTest, StopSoon) {
  Thread a("StopSoon");
  EXPECT_TRUE(a.Start());
  EXPECT_TRUE(a.message_loop());
  EXPECT_TRUE(a.IsRunning());
  a.StopSoon();
  a.StopSoon();
  a.Stop();
  EXPECT_FALSE(a.message_loop());
  EXPECT_FALSE(a.IsRunning());
}

TEST_F(ThreadTest, ThreadName) {
  Thread a("ThreadName");
  EXPECT_TRUE(a.Start());
  EXPECT_EQ("ThreadName", a.thread_name());
}

// Make sure Init() is called after Start() and before
// WaitUntilThreadInitialized() returns.
TEST_F(ThreadTest, SleepInsideInit) {
  SleepInsideInitThread t;
  EXPECT_FALSE(t.InitCalled());
  t.StartAndWaitForTesting();
  EXPECT_TRUE(t.InitCalled());
}

// Make sure that the destruction sequence is:
//
//  (1) Thread::CleanUp()
//  (2) MessageLoop::~MessageLoop()
//      MessageLoop::DestructionObservers called.
TEST_F(ThreadTest, CleanUp) {
  EventList captured_events;
  CapturingDestructionObserver loop_destruction_observer(&captured_events);

  {
    // Start a thread which writes its event into |captured_events|.
    CaptureToEventList t(&captured_events);
    EXPECT_TRUE(t.Start());
    EXPECT_TRUE(t.message_loop());
    EXPECT_TRUE(t.IsRunning());

    // Register an observer that writes into |captured_events| once the
    // thread's message loop is destroyed.
    t.task_runner()->PostTask(
        FROM_HERE, base::Bind(&RegisterDestructionObserver,
                              base::Unretained(&loop_destruction_observer)));

    // Upon leaving this scope, the thread is deleted.
  }

  // Check the order of events during shutdown.
  ASSERT_EQ(static_cast<size_t>(THREAD_NUM_EVENTS), captured_events.size());
  EXPECT_EQ(THREAD_EVENT_INIT, captured_events[0]);
  EXPECT_EQ(THREAD_EVENT_CLEANUP, captured_events[1]);
  EXPECT_EQ(THREAD_EVENT_MESSAGE_LOOP_DESTROYED, captured_events[2]);
}

TEST_F(ThreadTest, ThreadNotStarted) {
  Thread a("Inert");
  EXPECT_EQ(nullptr, a.task_runner());
}
