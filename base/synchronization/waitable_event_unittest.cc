// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/synchronization/waitable_event.h"

#include "base/compiler_specific.h"
#include "base/threading/platform_thread.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

TEST(WaitableEventTest, ManualBasics) {
  WaitableEvent event(true, false);

  EXPECT_FALSE(event.IsSignaled());

  event.Signal();
  EXPECT_TRUE(event.IsSignaled());
  EXPECT_TRUE(event.IsSignaled());

  event.Reset();
  EXPECT_FALSE(event.IsSignaled());
  EXPECT_FALSE(event.TimedWait(TimeDelta::FromMilliseconds(10)));

  event.Signal();
  event.Wait();
  EXPECT_TRUE(event.TimedWait(TimeDelta::FromMilliseconds(10)));
}

TEST(WaitableEventTest, AutoBasics) {
  WaitableEvent event(false, false);

  EXPECT_FALSE(event.IsSignaled());

  event.Signal();
  EXPECT_TRUE(event.IsSignaled());
  EXPECT_FALSE(event.IsSignaled());

  event.Reset();
  EXPECT_FALSE(event.IsSignaled());
  EXPECT_FALSE(event.TimedWait(TimeDelta::FromMilliseconds(10)));

  event.Signal();
  event.Wait();
  EXPECT_FALSE(event.TimedWait(TimeDelta::FromMilliseconds(10)));

  event.Signal();
  EXPECT_TRUE(event.TimedWait(TimeDelta::FromMilliseconds(10)));
}

TEST(WaitableEventTest, WaitManyShortcut) {
  WaitableEvent* ev[5];
  for (unsigned i = 0; i < 5; ++i)
    ev[i] = new WaitableEvent(false, false);

  ev[3]->Signal();
  EXPECT_EQ(WaitableEvent::WaitMany(ev, 5), 3u);

  ev[3]->Signal();
  EXPECT_EQ(WaitableEvent::WaitMany(ev, 5), 3u);

  ev[4]->Signal();
  EXPECT_EQ(WaitableEvent::WaitMany(ev, 5), 4u);

  ev[0]->Signal();
  EXPECT_EQ(WaitableEvent::WaitMany(ev, 5), 0u);

  for (unsigned i = 0; i < 5; ++i)
    delete ev[i];
}

class WaitableEventSignaler : public PlatformThread::Delegate {
 public:
  WaitableEventSignaler(TimeDelta delay, WaitableEvent* event)
      : delay_(delay),
        event_(event) {
  }

  void ThreadMain() override {
    PlatformThread::Sleep(delay_);
    event_->Signal();
  }

 private:
  const TimeDelta delay_;
  WaitableEvent* event_;
};

// Tests that a WaitableEvent can be safely deleted when |Wait| is done without
// additional synchronization.
TEST(WaitableEventTest, WaitAndDelete) {
  WaitableEvent* ev = new WaitableEvent(false, false);

  WaitableEventSignaler signaler(TimeDelta::FromMilliseconds(10), ev);
  PlatformThreadHandle thread;
  PlatformThread::Create(0, &signaler, &thread);

  ev->Wait();
  delete ev;

  PlatformThread::Join(thread);
}

// Tests that a WaitableEvent can be safely deleted when |WaitMany| is done
// without additional synchronization.
TEST(WaitableEventTest, WaitMany) {
  WaitableEvent* ev[5];
  for (unsigned i = 0; i < 5; ++i)
    ev[i] = new WaitableEvent(false, false);

  WaitableEventSignaler signaler(TimeDelta::FromMilliseconds(10), ev[2]);
  PlatformThreadHandle thread;
  PlatformThread::Create(0, &signaler, &thread);

  size_t index = WaitableEvent::WaitMany(ev, 5);

  for (unsigned i = 0; i < 5; ++i)
    delete ev[i];

  PlatformThread::Join(thread);
  EXPECT_EQ(2u, index);
}

// Tests that using TimeDelta::Max() on TimedWait() is not the same as passing
// a timeout of 0. (crbug.com/465948)
#if defined(OS_POSIX)
// crbug.com/465948 not fixed yet.
#define MAYBE_TimedWait DISABLED_TimedWait
#else
#define MAYBE_TimedWait TimedWait
#endif
TEST(WaitableEventTest, MAYBE_TimedWait) {
  WaitableEvent* ev = new WaitableEvent(false, false);

  TimeDelta thread_delay = TimeDelta::FromMilliseconds(10);
  WaitableEventSignaler signaler(thread_delay, ev);
  PlatformThreadHandle thread;
  TimeTicks start = TimeTicks::Now();
  PlatformThread::Create(0, &signaler, &thread);

  ev->TimedWait(TimeDelta::Max());
  EXPECT_GE(TimeTicks::Now() - start, thread_delay);
  delete ev;

  PlatformThread::Join(thread);
}

}  // namespace base
