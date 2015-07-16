// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/worker_pool_posix.h"

#include <set>

#include "base/bind.h"
#include "base/callback.h"
#include "base/synchronization/condition_variable.h"
#include "base/synchronization/lock.h"
#include "base/threading/platform_thread.h"
#include "base/synchronization/waitable_event.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

// Peer class to provide passthrough access to PosixDynamicThreadPool internals.
class PosixDynamicThreadPool::PosixDynamicThreadPoolPeer {
 public:
  explicit PosixDynamicThreadPoolPeer(PosixDynamicThreadPool* pool)
      : pool_(pool) {}

  Lock* lock() { return &pool_->lock_; }
  ConditionVariable* pending_tasks_available_cv() {
    return &pool_->pending_tasks_available_cv_;
  }
  const std::queue<PendingTask>& pending_tasks() const {
    return pool_->pending_tasks_;
  }
  int num_idle_threads() const { return pool_->num_idle_threads_; }
  ConditionVariable* num_idle_threads_cv() {
    return pool_->num_idle_threads_cv_.get();
  }
  void set_num_idle_threads_cv(ConditionVariable* cv) {
    pool_->num_idle_threads_cv_.reset(cv);
  }

 private:
  PosixDynamicThreadPool* pool_;

  DISALLOW_COPY_AND_ASSIGN(PosixDynamicThreadPoolPeer);
};

namespace {

// IncrementingTask's main purpose is to increment a counter.  It also updates a
// set of unique thread ids, and signals a ConditionVariable on completion.
// Note that since it does not block, there is no way to control the number of
// threads used if more than one IncrementingTask is consecutively posted to the
// thread pool, since the first one might finish executing before the subsequent
// PostTask() calls get invoked.
void IncrementingTask(Lock* counter_lock,
                      int* counter,
                      Lock* unique_threads_lock,
                      std::set<PlatformThreadId>* unique_threads) {
  {
    base::AutoLock locked(*unique_threads_lock);
    unique_threads->insert(PlatformThread::CurrentId());
  }
  base::AutoLock locked(*counter_lock);
  (*counter)++;
}

// BlockingIncrementingTask is a simple wrapper around IncrementingTask that
// allows for waiting at the start of Run() for a WaitableEvent to be signalled.
struct BlockingIncrementingTaskArgs {
  Lock* counter_lock;
  int* counter;
  Lock* unique_threads_lock;
  std::set<PlatformThreadId>* unique_threads;
  Lock* num_waiting_to_start_lock;
  int* num_waiting_to_start;
  ConditionVariable* num_waiting_to_start_cv;
  base::WaitableEvent* start;
};

void BlockingIncrementingTask(const BlockingIncrementingTaskArgs& args) {
  {
    base::AutoLock num_waiting_to_start_locked(*args.num_waiting_to_start_lock);
    (*args.num_waiting_to_start)++;
  }
  args.num_waiting_to_start_cv->Signal();
  args.start->Wait();
  IncrementingTask(args.counter_lock, args.counter, args.unique_threads_lock,
                   args.unique_threads);
}

class PosixDynamicThreadPoolTest : public testing::Test {
 protected:
  PosixDynamicThreadPoolTest()
      : pool_(new base::PosixDynamicThreadPool("dynamic_pool", 60*60)),
        peer_(pool_.get()),
        counter_(0),
        num_waiting_to_start_(0),
        num_waiting_to_start_cv_(&num_waiting_to_start_lock_),
        start_(true, false) {}

  void SetUp() override {
    peer_.set_num_idle_threads_cv(new ConditionVariable(peer_.lock()));
  }

  void TearDown() override {
    // Wake up the idle threads so they can terminate.
    if (pool_.get()) pool_->Terminate();
  }

  void WaitForTasksToStart(int num_tasks) {
    base::AutoLock num_waiting_to_start_locked(num_waiting_to_start_lock_);
    while (num_waiting_to_start_ < num_tasks) {
      num_waiting_to_start_cv_.Wait();
    }
  }

  void WaitForIdleThreads(int num_idle_threads) {
    base::AutoLock pool_locked(*peer_.lock());
    while (peer_.num_idle_threads() < num_idle_threads) {
      peer_.num_idle_threads_cv()->Wait();
    }
  }

  base::Closure CreateNewIncrementingTaskCallback() {
    return base::Bind(&IncrementingTask, &counter_lock_, &counter_,
                      &unique_threads_lock_, &unique_threads_);
  }

  base::Closure CreateNewBlockingIncrementingTaskCallback() {
    BlockingIncrementingTaskArgs args = {
        &counter_lock_, &counter_, &unique_threads_lock_, &unique_threads_,
        &num_waiting_to_start_lock_, &num_waiting_to_start_,
        &num_waiting_to_start_cv_, &start_
    };
    return base::Bind(&BlockingIncrementingTask, args);
  }

  scoped_refptr<base::PosixDynamicThreadPool> pool_;
  base::PosixDynamicThreadPool::PosixDynamicThreadPoolPeer peer_;
  Lock counter_lock_;
  int counter_;
  Lock unique_threads_lock_;
  std::set<PlatformThreadId> unique_threads_;
  Lock num_waiting_to_start_lock_;
  int num_waiting_to_start_;
  ConditionVariable num_waiting_to_start_cv_;
  base::WaitableEvent start_;
};

}  // namespace

TEST_F(PosixDynamicThreadPoolTest, Basic) {
  EXPECT_EQ(0, peer_.num_idle_threads());
  EXPECT_EQ(0U, unique_threads_.size());
  EXPECT_EQ(0U, peer_.pending_tasks().size());

  // Add one task and wait for it to be completed.
  pool_->PostTask(FROM_HERE, CreateNewIncrementingTaskCallback());

  WaitForIdleThreads(1);

  EXPECT_EQ(1U, unique_threads_.size()) <<
      "There should be only one thread allocated for one task.";
  EXPECT_EQ(1, counter_);
}

TEST_F(PosixDynamicThreadPoolTest, ReuseIdle) {
  // Add one task and wait for it to be completed.
  pool_->PostTask(FROM_HERE, CreateNewIncrementingTaskCallback());

  WaitForIdleThreads(1);

  // Add another 2 tasks.  One should reuse the existing worker thread.
  pool_->PostTask(FROM_HERE, CreateNewBlockingIncrementingTaskCallback());
  pool_->PostTask(FROM_HERE, CreateNewBlockingIncrementingTaskCallback());

  WaitForTasksToStart(2);
  start_.Signal();
  WaitForIdleThreads(2);

  EXPECT_EQ(2U, unique_threads_.size());
  EXPECT_EQ(2, peer_.num_idle_threads());
  EXPECT_EQ(3, counter_);
}

TEST_F(PosixDynamicThreadPoolTest, TwoActiveTasks) {
  // Add two blocking tasks.
  pool_->PostTask(FROM_HERE, CreateNewBlockingIncrementingTaskCallback());
  pool_->PostTask(FROM_HERE, CreateNewBlockingIncrementingTaskCallback());

  EXPECT_EQ(0, counter_) << "Blocking tasks should not have started yet.";

  WaitForTasksToStart(2);
  start_.Signal();
  WaitForIdleThreads(2);

  EXPECT_EQ(2U, unique_threads_.size());
  EXPECT_EQ(2, peer_.num_idle_threads()) << "Existing threads are now idle.";
  EXPECT_EQ(2, counter_);
}

TEST_F(PosixDynamicThreadPoolTest, Complex) {
  // Add two non blocking tasks and wait for them to finish.
  pool_->PostTask(FROM_HERE, CreateNewIncrementingTaskCallback());

  WaitForIdleThreads(1);

  // Add two blocking tasks, start them simultaneously, and wait for them to
  // finish.
  pool_->PostTask(FROM_HERE, CreateNewBlockingIncrementingTaskCallback());
  pool_->PostTask(FROM_HERE, CreateNewBlockingIncrementingTaskCallback());

  WaitForTasksToStart(2);
  start_.Signal();
  WaitForIdleThreads(2);

  EXPECT_EQ(3, counter_);
  EXPECT_EQ(2, peer_.num_idle_threads());
  EXPECT_EQ(2U, unique_threads_.size());

  // Wake up all idle threads so they can exit.
  {
    base::AutoLock locked(*peer_.lock());
    while (peer_.num_idle_threads() > 0) {
      peer_.pending_tasks_available_cv()->Signal();
      peer_.num_idle_threads_cv()->Wait();
    }
  }

  // Add another non blocking task.  There are no threads to reuse.
  pool_->PostTask(FROM_HERE, CreateNewIncrementingTaskCallback());
  WaitForIdleThreads(1);

  // The POSIX implementation of PlatformThread::CurrentId() uses pthread_self()
  // which is not guaranteed to be unique after a thread joins. The OS X
  // implemntation of pthread_self() returns the address of the pthread_t, which
  // is merely a malloc()ed pointer stored in the first TLS slot. When a thread
  // joins and that structure is freed, the block of memory can be put on the
  // OS free list, meaning the same address could be reused in a subsequent
  // allocation. This in fact happens when allocating in a loop as this test
  // does.
  //
  // Because there are two concurrent threads, there's at least the guarantee
  // of having two unique thread IDs in the set. But after those two threads are
  // joined, the next-created thread can get a re-used ID if the allocation of
  // the pthread_t structure is taken from the free list. Therefore, there can
  // be either 2 or 3 unique thread IDs in the set at this stage in the test.
  EXPECT_TRUE(unique_threads_.size() >= 2 && unique_threads_.size() <= 3)
      << "unique_threads_.size() = " << unique_threads_.size();
  EXPECT_EQ(1, peer_.num_idle_threads());
  EXPECT_EQ(4, counter_);
}

}  // namespace base
