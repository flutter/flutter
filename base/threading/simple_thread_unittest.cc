// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/atomic_sequence_num.h"
#include "base/strings/string_number_conversions.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/simple_thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

class SetIntRunner : public DelegateSimpleThread::Delegate {
 public:
  SetIntRunner(int* ptr, int val) : ptr_(ptr), val_(val) { }
  ~SetIntRunner() override {}

  void Run() override { *ptr_ = val_; }

 private:
  int* ptr_;
  int val_;
};

class WaitEventRunner : public DelegateSimpleThread::Delegate {
 public:
  explicit WaitEventRunner(WaitableEvent* event) : event_(event) { }
  ~WaitEventRunner() override {}

  void Run() override {
    EXPECT_FALSE(event_->IsSignaled());
    event_->Signal();
    EXPECT_TRUE(event_->IsSignaled());
  }
 private:
  WaitableEvent* event_;
};

class SeqRunner : public DelegateSimpleThread::Delegate {
 public:
  explicit SeqRunner(AtomicSequenceNumber* seq) : seq_(seq) { }
  void Run() override { seq_->GetNext(); }

 private:
  AtomicSequenceNumber* seq_;
};

// We count up on a sequence number, firing on the event when we've hit our
// expected amount, otherwise we wait on the event.  This will ensure that we
// have all threads outstanding until we hit our expected thread pool size.
class VerifyPoolRunner : public DelegateSimpleThread::Delegate {
 public:
  VerifyPoolRunner(AtomicSequenceNumber* seq,
                   int total, WaitableEvent* event)
      : seq_(seq), total_(total), event_(event) { }

  void Run() override {
    if (seq_->GetNext() == total_) {
      event_->Signal();
    } else {
      event_->Wait();
    }
  }

 private:
  AtomicSequenceNumber* seq_;
  int total_;
  WaitableEvent* event_;
};

}  // namespace

TEST(SimpleThreadTest, CreateAndJoin) {
  int stack_int = 0;

  SetIntRunner runner(&stack_int, 7);
  EXPECT_EQ(0, stack_int);

  DelegateSimpleThread thread(&runner, "int_setter");
  EXPECT_FALSE(thread.HasBeenStarted());
  EXPECT_FALSE(thread.HasBeenJoined());
  EXPECT_EQ(0, stack_int);

  thread.Start();
  EXPECT_TRUE(thread.HasBeenStarted());
  EXPECT_FALSE(thread.HasBeenJoined());

  thread.Join();
  EXPECT_TRUE(thread.HasBeenStarted());
  EXPECT_TRUE(thread.HasBeenJoined());
  EXPECT_EQ(7, stack_int);
}

TEST(SimpleThreadTest, WaitForEvent) {
  // Create a thread, and wait for it to signal us.
  WaitableEvent event(true, false);

  WaitEventRunner runner(&event);
  DelegateSimpleThread thread(&runner, "event_waiter");

  EXPECT_FALSE(event.IsSignaled());
  thread.Start();
  event.Wait();
  EXPECT_TRUE(event.IsSignaled());
  thread.Join();
}

TEST(SimpleThreadTest, NamedWithOptions) {
  WaitableEvent event(true, false);

  WaitEventRunner runner(&event);
  SimpleThread::Options options;
  DelegateSimpleThread thread(&runner, "event_waiter", options);
  EXPECT_EQ(thread.name_prefix(), "event_waiter");
  EXPECT_FALSE(event.IsSignaled());

  thread.Start();
  EXPECT_EQ(thread.name_prefix(), "event_waiter");
  EXPECT_EQ(thread.name(),
            std::string("event_waiter/") + IntToString(thread.tid()));
  event.Wait();

  EXPECT_TRUE(event.IsSignaled());
  thread.Join();

  // We keep the name and tid, even after the thread is gone.
  EXPECT_EQ(thread.name_prefix(), "event_waiter");
  EXPECT_EQ(thread.name(),
            std::string("event_waiter/") + IntToString(thread.tid()));
}

TEST(SimpleThreadTest, ThreadPool) {
  AtomicSequenceNumber seq;
  SeqRunner runner(&seq);
  DelegateSimpleThreadPool pool("seq_runner", 10);

  // Add work before we're running.
  pool.AddWork(&runner, 300);

  EXPECT_EQ(seq.GetNext(), 0);
  pool.Start();

  // Add work while we're running.
  pool.AddWork(&runner, 300);

  pool.JoinAll();

  EXPECT_EQ(seq.GetNext(), 601);

  // We can reuse our pool.  Verify that all 10 threads can actually run in
  // parallel, so this test will only pass if there are actually 10 threads.
  AtomicSequenceNumber seq2;
  WaitableEvent event(true, false);
  // Changing 9 to 10, for example, would cause us JoinAll() to never return.
  VerifyPoolRunner verifier(&seq2, 9, &event);
  pool.Start();

  pool.AddWork(&verifier, 10);

  pool.JoinAll();
  EXPECT_EQ(seq2.GetNext(), 10);
}

}  // namespace base
