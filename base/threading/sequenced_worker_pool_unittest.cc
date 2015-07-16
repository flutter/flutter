// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/sequenced_worker_pool.h"

#include <algorithm>

#include "base/bind.h"
#include "base/compiler_specific.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/synchronization/condition_variable.h"
#include "base/synchronization/lock.h"
#include "base/test/sequenced_task_runner_test_template.h"
#include "base/test/sequenced_worker_pool_owner.h"
#include "base/test/task_runner_test_template.h"
#include "base/test/test_timeouts.h"
#include "base/threading/platform_thread.h"
#include "base/time/time.h"
#include "base/tracked_objects.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

// IMPORTANT NOTE:
//
// Many of these tests have failure modes where they'll hang forever. These
// tests should not be flaky, and hanging indicates a type of failure. Do not
// mark as flaky if they're hanging, it's likely an actual bug.

namespace {

const size_t kNumWorkerThreads = 3;

// Allows a number of threads to all be blocked on the same event, and
// provides a way to unblock a certain number of them.
class ThreadBlocker {
 public:
  ThreadBlocker() : lock_(), cond_var_(&lock_), unblock_counter_(0) {}

  void Block() {
    {
      base::AutoLock lock(lock_);
      while (unblock_counter_ == 0)
        cond_var_.Wait();
      unblock_counter_--;
    }
    cond_var_.Signal();
  }

  void Unblock(size_t count) {
    {
      base::AutoLock lock(lock_);
      DCHECK_EQ(unblock_counter_, 0u);
      unblock_counter_ = count;
    }
    cond_var_.Signal();
  }

 private:
  base::Lock lock_;
  base::ConditionVariable cond_var_;

  size_t unblock_counter_;
};

class DestructionDeadlockChecker
    : public base::RefCountedThreadSafe<DestructionDeadlockChecker> {
 public:
  DestructionDeadlockChecker(const scoped_refptr<SequencedWorkerPool>& pool)
      : pool_(pool) {}

 protected:
  virtual ~DestructionDeadlockChecker() {
    // This method should not deadlock.
    pool_->RunsTasksOnCurrentThread();
  }

 private:
  scoped_refptr<SequencedWorkerPool> pool_;
  friend class base::RefCountedThreadSafe<DestructionDeadlockChecker>;
};

class TestTracker : public base::RefCountedThreadSafe<TestTracker> {
 public:
  TestTracker()
      : lock_(),
        cond_var_(&lock_),
        started_events_(0) {
  }

  // Each of these tasks appends the argument to the complete sequence vector
  // so calling code can see what order they finished in.
  void FastTask(int id) {
    SignalWorkerDone(id);
  }

  void SlowTask(int id) {
    base::PlatformThread::Sleep(base::TimeDelta::FromSeconds(1));
    SignalWorkerDone(id);
  }

  void BlockTask(int id, ThreadBlocker* blocker) {
    // Note that this task has started and signal anybody waiting for that
    // to happen.
    {
      base::AutoLock lock(lock_);
      started_events_++;
    }
    cond_var_.Signal();

    blocker->Block();
    SignalWorkerDone(id);
  }

  void PostAdditionalTasks(
        int id, SequencedWorkerPool* pool,
        bool expected_return_value) {
    Closure fast_task = base::Bind(&TestTracker::FastTask, this, 100);
    EXPECT_EQ(expected_return_value,
              pool->PostWorkerTaskWithShutdownBehavior(
                  FROM_HERE, fast_task,
                  SequencedWorkerPool::CONTINUE_ON_SHUTDOWN));
    EXPECT_EQ(expected_return_value,
              pool->PostWorkerTaskWithShutdownBehavior(
                  FROM_HERE, fast_task,
                  SequencedWorkerPool::SKIP_ON_SHUTDOWN));
    pool->PostWorkerTaskWithShutdownBehavior(
        FROM_HERE, fast_task,
        SequencedWorkerPool::BLOCK_SHUTDOWN);
    SignalWorkerDone(id);
  }

  // This task posts itself back onto the SequencedWorkerPool before it
  // finishes running. Each instance of the task maintains a strong reference
  // to a DestructionDeadlockChecker. The DestructionDeadlockChecker is only
  // destroyed when the task is destroyed without being run, which only happens
  // during destruction of the SequencedWorkerPool.
  void PostRepostingTask(
      const scoped_refptr<SequencedWorkerPool>& pool,
      const scoped_refptr<DestructionDeadlockChecker>& checker) {
    Closure reposting_task =
        base::Bind(&TestTracker::PostRepostingTask, this, pool, checker);
    pool->PostWorkerTaskWithShutdownBehavior(
        FROM_HERE, reposting_task, SequencedWorkerPool::SKIP_ON_SHUTDOWN);
  }

  // This task reposts itself back onto the SequencedWorkerPool before it
  // finishes running.
  void PostRepostingBlockingTask(
      const scoped_refptr<SequencedWorkerPool>& pool,
      const SequencedWorkerPool::SequenceToken& token) {
    Closure reposting_task =
        base::Bind(&TestTracker::PostRepostingBlockingTask, this, pool, token);
    pool->PostSequencedWorkerTaskWithShutdownBehavior(token,
        FROM_HERE, reposting_task, SequencedWorkerPool::BLOCK_SHUTDOWN);
  }

  void PostBlockingTaskThenUnblockThreads(
      const scoped_refptr<SequencedWorkerPool>& pool,
      ThreadBlocker* blocker,
      size_t threads_to_wake) {
    Closure arbitrary_task = base::Bind(&TestTracker::FastTask, this, 0);
    pool->PostWorkerTaskWithShutdownBehavior(
        FROM_HERE, arbitrary_task, SequencedWorkerPool::BLOCK_SHUTDOWN);
    blocker->Unblock(threads_to_wake);
  }

  // Waits until the given number of tasks have started executing.
  void WaitUntilTasksBlocked(size_t count) {
    {
      base::AutoLock lock(lock_);
      while (started_events_ < count)
        cond_var_.Wait();
    }
    cond_var_.Signal();
  }

  // Blocks the current thread until at least the given number of tasks are in
  // the completed vector, and then returns a copy.
  std::vector<int> WaitUntilTasksComplete(size_t num_tasks) {
    std::vector<int> ret;
    {
      base::AutoLock lock(lock_);
      while (complete_sequence_.size() < num_tasks)
        cond_var_.Wait();
      ret = complete_sequence_;
    }
    cond_var_.Signal();
    return ret;
  }

  size_t GetTasksCompletedCount() {
    base::AutoLock lock(lock_);
    return complete_sequence_.size();
  }

  void ClearCompleteSequence() {
    base::AutoLock lock(lock_);
    complete_sequence_.clear();
    started_events_ = 0;
  }

 private:
  friend class base::RefCountedThreadSafe<TestTracker>;
  ~TestTracker() {}

  void SignalWorkerDone(int id) {
    {
      base::AutoLock lock(lock_);
      complete_sequence_.push_back(id);
    }
    cond_var_.Signal();
  }

  // Protects the complete_sequence.
  base::Lock lock_;

  base::ConditionVariable cond_var_;

  // Protected by lock_.
  std::vector<int> complete_sequence_;

  // Counter of the number of "block" workers that have started.
  size_t started_events_;
};

class SequencedWorkerPoolTest : public testing::Test {
 public:
  SequencedWorkerPoolTest()
      : tracker_(new TestTracker) {
    ResetPool();
  }

  void TearDown() override { pool()->Shutdown(); }

  const scoped_refptr<SequencedWorkerPool>& pool() {
    return pool_owner_->pool();
  }
  TestTracker* tracker() { return tracker_.get(); }

  // Destroys the SequencedWorkerPool instance, blocking until it is fully shut
  // down, and creates a new instance.
  void ResetPool() {
    pool_owner_.reset(new SequencedWorkerPoolOwner(kNumWorkerThreads, "test"));
  }

  void SetWillWaitForShutdownCallback(const Closure& callback) {
    pool_owner_->SetWillWaitForShutdownCallback(callback);
  }

  // Ensures that the given number of worker threads is created by adding
  // tasks and waiting until they complete. Worker thread creation is
  // serialized, can happen on background threads asynchronously, and doesn't
  // happen any more at shutdown. This means that if a test posts a bunch of
  // tasks and calls shutdown, fewer workers will be created than the test may
  // expect.
  //
  // This function ensures that this condition can't happen so tests can make
  // assumptions about the number of workers active. See the comment in
  // PrepareToStartAdditionalThreadIfNecessary in the .cc file for more
  // details.
  //
  // It will post tasks to the queue with id -1. It also assumes this is the
  // first thing called in a test since it will clear the complete_sequence_.
  void EnsureAllWorkersCreated() {
    // Create a bunch of threads, all waiting. This will cause that may
    // workers to be created.
    ThreadBlocker blocker;
    for (size_t i = 0; i < kNumWorkerThreads; i++) {
      pool()->PostWorkerTask(FROM_HERE,
                             base::Bind(&TestTracker::BlockTask,
                                        tracker(), -1, &blocker));
    }
    tracker()->WaitUntilTasksBlocked(kNumWorkerThreads);

    // Now wake them up and wait until they're done.
    blocker.Unblock(kNumWorkerThreads);
    tracker()->WaitUntilTasksComplete(kNumWorkerThreads);

    // Clean up the task IDs we added.
    tracker()->ClearCompleteSequence();
  }

  int has_work_call_count() const {
    return pool_owner_->has_work_call_count();
  }

 private:
  MessageLoop message_loop_;
  scoped_ptr<SequencedWorkerPoolOwner> pool_owner_;
  const scoped_refptr<TestTracker> tracker_;
};

// Checks that the given number of entries are in the tasks to complete of
// the given tracker, and then signals the given event the given number of
// times. This is used to wake up blocked background threads before blocking
// on shutdown.
void EnsureTasksToCompleteCountAndUnblock(scoped_refptr<TestTracker> tracker,
                                          size_t expected_tasks_to_complete,
                                          ThreadBlocker* blocker,
                                          size_t threads_to_awake) {
  EXPECT_EQ(
      expected_tasks_to_complete,
      tracker->WaitUntilTasksComplete(expected_tasks_to_complete).size());

  blocker->Unblock(threads_to_awake);
}

class DeletionHelper : public base::RefCountedThreadSafe<DeletionHelper> {
 public:
  explicit DeletionHelper(
      const scoped_refptr<base::RefCountedData<bool> >& deleted_flag)
      : deleted_flag_(deleted_flag) {
  }

 private:
  friend class base::RefCountedThreadSafe<DeletionHelper>;
  virtual ~DeletionHelper() { deleted_flag_->data = true; }

  const scoped_refptr<base::RefCountedData<bool> > deleted_flag_;
  DISALLOW_COPY_AND_ASSIGN(DeletionHelper);
};

void HoldPoolReference(const scoped_refptr<base::SequencedWorkerPool>& pool,
                       const scoped_refptr<DeletionHelper>& helper) {
  ADD_FAILURE() << "Should never run";
}

// Tests that delayed tasks are deleted upon shutdown of the pool.
TEST_F(SequencedWorkerPoolTest, DelayedTaskDuringShutdown) {
  // Post something to verify the pool is started up.
  EXPECT_TRUE(pool()->PostTask(
      FROM_HERE, base::Bind(&TestTracker::FastTask, tracker(), 1)));

  scoped_refptr<base::RefCountedData<bool> > deleted_flag(
      new base::RefCountedData<bool>(false));

  base::Time posted_at(base::Time::Now());
  // Post something that shouldn't run.
  EXPECT_TRUE(pool()->PostDelayedTask(
      FROM_HERE,
      base::Bind(&HoldPoolReference,
                 pool(),
                 make_scoped_refptr(new DeletionHelper(deleted_flag))),
      TestTimeouts::action_timeout()));

  std::vector<int> completion_sequence = tracker()->WaitUntilTasksComplete(1);
  ASSERT_EQ(1u, completion_sequence.size());
  ASSERT_EQ(1, completion_sequence[0]);

  pool()->Shutdown();
  // Shutdown is asynchronous, so use ResetPool() to block until the pool is
  // fully destroyed (and thus shut down).
  ResetPool();

  // Verify that we didn't block until the task was due.
  ASSERT_LT(base::Time::Now() - posted_at, TestTimeouts::action_timeout());

  // Verify that the deferred task has not only not run, but has also been
  // destroyed.
  ASSERT_TRUE(deleted_flag->data);
}

// Tests that same-named tokens have the same ID.
TEST_F(SequencedWorkerPoolTest, NamedTokens) {
  const std::string name1("hello");
  SequencedWorkerPool::SequenceToken token1 =
      pool()->GetNamedSequenceToken(name1);

  SequencedWorkerPool::SequenceToken token2 = pool()->GetSequenceToken();

  const std::string name3("goodbye");
  SequencedWorkerPool::SequenceToken token3 =
      pool()->GetNamedSequenceToken(name3);

  // All 3 tokens should be different.
  EXPECT_FALSE(token1.Equals(token2));
  EXPECT_FALSE(token1.Equals(token3));
  EXPECT_FALSE(token2.Equals(token3));

  // Requesting the same name again should give the same value.
  SequencedWorkerPool::SequenceToken token1again =
      pool()->GetNamedSequenceToken(name1);
  EXPECT_TRUE(token1.Equals(token1again));

  SequencedWorkerPool::SequenceToken token3again =
      pool()->GetNamedSequenceToken(name3);
  EXPECT_TRUE(token3.Equals(token3again));
}

// Tests that posting a bunch of tasks (many more than the number of worker
// threads) runs them all.
TEST_F(SequencedWorkerPoolTest, LotsOfTasks) {
  pool()->PostWorkerTask(FROM_HERE,
                         base::Bind(&TestTracker::SlowTask, tracker(), 0));

  const size_t kNumTasks = 20;
  for (size_t i = 1; i < kNumTasks; i++) {
    pool()->PostWorkerTask(FROM_HERE,
                           base::Bind(&TestTracker::FastTask, tracker(), i));
  }

  std::vector<int> result = tracker()->WaitUntilTasksComplete(kNumTasks);
  EXPECT_EQ(kNumTasks, result.size());
}

// Tests that posting a bunch of tasks (many more than the number of
// worker threads) to two pools simultaneously runs them all twice.
// This test is meant to shake out any concurrency issues between
// pools (like histograms).
TEST_F(SequencedWorkerPoolTest, LotsOfTasksTwoPools) {
  SequencedWorkerPoolOwner pool1(kNumWorkerThreads, "test1");
  SequencedWorkerPoolOwner pool2(kNumWorkerThreads, "test2");

  base::Closure slow_task = base::Bind(&TestTracker::SlowTask, tracker(), 0);
  pool1.pool()->PostWorkerTask(FROM_HERE, slow_task);
  pool2.pool()->PostWorkerTask(FROM_HERE, slow_task);

  const size_t kNumTasks = 20;
  for (size_t i = 1; i < kNumTasks; i++) {
    base::Closure fast_task =
        base::Bind(&TestTracker::FastTask, tracker(), i);
    pool1.pool()->PostWorkerTask(FROM_HERE, fast_task);
    pool2.pool()->PostWorkerTask(FROM_HERE, fast_task);
  }

  std::vector<int> result =
      tracker()->WaitUntilTasksComplete(2*kNumTasks);
  EXPECT_EQ(2 * kNumTasks, result.size());

  pool2.pool()->Shutdown();
  pool1.pool()->Shutdown();
}

// Test that tasks with the same sequence token are executed in order but don't
// affect other tasks.
TEST_F(SequencedWorkerPoolTest, Sequence) {
  // Fill all the worker threads except one.
  const size_t kNumBackgroundTasks = kNumWorkerThreads - 1;
  ThreadBlocker background_blocker;
  for (size_t i = 0; i < kNumBackgroundTasks; i++) {
    pool()->PostWorkerTask(FROM_HERE,
                           base::Bind(&TestTracker::BlockTask,
                                      tracker(), i, &background_blocker));
  }
  tracker()->WaitUntilTasksBlocked(kNumBackgroundTasks);

  // Create two tasks with the same sequence token, one that will block on the
  // event, and one which will just complete quickly when it's run. Since there
  // is one worker thread free, the first task will start and then block, and
  // the second task should be waiting.
  ThreadBlocker blocker;
  SequencedWorkerPool::SequenceToken token1 = pool()->GetSequenceToken();
  pool()->PostSequencedWorkerTask(
      token1, FROM_HERE,
      base::Bind(&TestTracker::BlockTask, tracker(), 100, &blocker));
  pool()->PostSequencedWorkerTask(
      token1, FROM_HERE,
      base::Bind(&TestTracker::FastTask, tracker(), 101));
  EXPECT_EQ(0u, tracker()->WaitUntilTasksComplete(0).size());

  // Create another two tasks as above with a different token. These will be
  // blocked since there are no slots to run.
  SequencedWorkerPool::SequenceToken token2 = pool()->GetSequenceToken();
  pool()->PostSequencedWorkerTask(
      token2, FROM_HERE,
      base::Bind(&TestTracker::FastTask, tracker(), 200));
  pool()->PostSequencedWorkerTask(
      token2, FROM_HERE,
      base::Bind(&TestTracker::FastTask, tracker(), 201));
  EXPECT_EQ(0u, tracker()->WaitUntilTasksComplete(0).size());

  // Let one background task complete. This should then let both tasks of
  // token2 run to completion in order. The second task of token1 should still
  // be blocked.
  background_blocker.Unblock(1);
  std::vector<int> result = tracker()->WaitUntilTasksComplete(3);
  ASSERT_EQ(3u, result.size());
  EXPECT_EQ(200, result[1]);
  EXPECT_EQ(201, result[2]);

  // Finish the rest of the background tasks. This should leave some workers
  // free with the second token1 task still blocked on the first.
  background_blocker.Unblock(kNumBackgroundTasks - 1);
  EXPECT_EQ(kNumBackgroundTasks + 2,
            tracker()->WaitUntilTasksComplete(kNumBackgroundTasks + 2).size());

  // Allow the first task of token1 to complete. This should run the second.
  blocker.Unblock(1);
  result = tracker()->WaitUntilTasksComplete(kNumBackgroundTasks + 4);
  ASSERT_EQ(kNumBackgroundTasks + 4, result.size());
  EXPECT_EQ(100, result[result.size() - 2]);
  EXPECT_EQ(101, result[result.size() - 1]);
}

// Tests that any tasks posted after Shutdown are ignored.
// Disabled for flakiness.  See http://crbug.com/166451.
TEST_F(SequencedWorkerPoolTest, DISABLED_IgnoresAfterShutdown) {
  // Start tasks to take all the threads and block them.
  EnsureAllWorkersCreated();
  ThreadBlocker blocker;
  for (size_t i = 0; i < kNumWorkerThreads; i++) {
    pool()->PostWorkerTask(FROM_HERE,
                           base::Bind(&TestTracker::BlockTask,
                                      tracker(), i, &blocker));
  }
  tracker()->WaitUntilTasksBlocked(kNumWorkerThreads);

  SetWillWaitForShutdownCallback(
      base::Bind(&EnsureTasksToCompleteCountAndUnblock,
                 scoped_refptr<TestTracker>(tracker()), 0,
                 &blocker, kNumWorkerThreads));

  // Shutdown the worker pool. This should discard all non-blocking tasks.
  const int kMaxNewBlockingTasksAfterShutdown = 100;
  pool()->Shutdown(kMaxNewBlockingTasksAfterShutdown);

  int old_has_work_call_count = has_work_call_count();

  std::vector<int> result =
      tracker()->WaitUntilTasksComplete(kNumWorkerThreads);

  // The kNumWorkerThread items should have completed, in no particular order.
  ASSERT_EQ(kNumWorkerThreads, result.size());
  for (size_t i = 0; i < kNumWorkerThreads; i++) {
    EXPECT_TRUE(std::find(result.begin(), result.end(), static_cast<int>(i)) !=
                result.end());
  }

  // No further tasks, regardless of shutdown mode, should be allowed.
  EXPECT_FALSE(pool()->PostWorkerTaskWithShutdownBehavior(
      FROM_HERE,
      base::Bind(&TestTracker::FastTask, tracker(), 100),
      SequencedWorkerPool::CONTINUE_ON_SHUTDOWN));
  EXPECT_FALSE(pool()->PostWorkerTaskWithShutdownBehavior(
      FROM_HERE,
      base::Bind(&TestTracker::FastTask, tracker(), 101),
      SequencedWorkerPool::SKIP_ON_SHUTDOWN));
  EXPECT_FALSE(pool()->PostWorkerTaskWithShutdownBehavior(
      FROM_HERE,
      base::Bind(&TestTracker::FastTask, tracker(), 102),
      SequencedWorkerPool::BLOCK_SHUTDOWN));

  ASSERT_EQ(old_has_work_call_count, has_work_call_count());
}

TEST_F(SequencedWorkerPoolTest, AllowsAfterShutdown) {
  // Test that <n> new blocking tasks are allowed provided they're posted
  // by a running tasks.
  EnsureAllWorkersCreated();
  ThreadBlocker blocker;

  // Start tasks to take all the threads and block them.
  const int kNumBlockTasks = static_cast<int>(kNumWorkerThreads);
  for (int i = 0; i < kNumBlockTasks; ++i) {
    EXPECT_TRUE(pool()->PostWorkerTask(
        FROM_HERE,
        base::Bind(&TestTracker::BlockTask, tracker(), i, &blocker)));
  }
  tracker()->WaitUntilTasksBlocked(kNumWorkerThreads);

  // Queue up shutdown blocking tasks behind those which will attempt to post
  // additional tasks when run, PostAdditionalTasks attemtps to post 3
  // new FastTasks, one for each shutdown_behavior.
  const int kNumQueuedTasks = static_cast<int>(kNumWorkerThreads);
  for (int i = 0; i < kNumQueuedTasks; ++i) {
    EXPECT_TRUE(pool()->PostWorkerTaskWithShutdownBehavior(
        FROM_HERE,
        base::Bind(&TestTracker::PostAdditionalTasks, tracker(), i, pool(),
                   false),
        SequencedWorkerPool::BLOCK_SHUTDOWN));
  }

  // Setup to open the floodgates from within Shutdown().
  SetWillWaitForShutdownCallback(
      base::Bind(&EnsureTasksToCompleteCountAndUnblock,
                 scoped_refptr<TestTracker>(tracker()),
                 0, &blocker, kNumBlockTasks));

  // Allow half of the additional blocking tasks thru.
  const int kNumNewBlockingTasksToAllow = kNumWorkerThreads / 2;
  pool()->Shutdown(kNumNewBlockingTasksToAllow);

  // Ensure that the correct number of tasks actually got run.
  tracker()->WaitUntilTasksComplete(static_cast<size_t>(
      kNumBlockTasks + kNumQueuedTasks + kNumNewBlockingTasksToAllow));

  // Clean up the task IDs we added and go home.
  tracker()->ClearCompleteSequence();
}

// Tests that blocking tasks can still be posted during shutdown, as long as
// the task is not being posted within the context of a running task.
TEST_F(SequencedWorkerPoolTest,
       AllowsBlockingTasksDuringShutdownOutsideOfRunningTask) {
  EnsureAllWorkersCreated();
  ThreadBlocker blocker;

  // Start tasks to take all the threads and block them.
  const int kNumBlockTasks = static_cast<int>(kNumWorkerThreads);
  for (int i = 0; i < kNumBlockTasks; ++i) {
    EXPECT_TRUE(pool()->PostWorkerTask(
        FROM_HERE,
        base::Bind(&TestTracker::BlockTask, tracker(), i, &blocker)));
  }
  tracker()->WaitUntilTasksBlocked(kNumWorkerThreads);

  // Setup to open the floodgates from within Shutdown().
  SetWillWaitForShutdownCallback(
      base::Bind(&TestTracker::PostBlockingTaskThenUnblockThreads,
                 scoped_refptr<TestTracker>(tracker()), pool(), &blocker,
                 kNumWorkerThreads));
  pool()->Shutdown(kNumWorkerThreads + 1);

  // Ensure that the correct number of tasks actually got run.
  tracker()->WaitUntilTasksComplete(static_cast<size_t>(kNumWorkerThreads + 1));
  tracker()->ClearCompleteSequence();
}

// Tests that unrun tasks are discarded properly according to their shutdown
// mode.
TEST_F(SequencedWorkerPoolTest, DiscardOnShutdown) {
  // Start tasks to take all the threads and block them.
  EnsureAllWorkersCreated();
  ThreadBlocker blocker;
  for (size_t i = 0; i < kNumWorkerThreads; i++) {
    pool()->PostWorkerTask(FROM_HERE,
                           base::Bind(&TestTracker::BlockTask,
                                      tracker(), i, &blocker));
  }
  tracker()->WaitUntilTasksBlocked(kNumWorkerThreads);

  // Create some tasks with different shutdown modes.
  pool()->PostWorkerTaskWithShutdownBehavior(
      FROM_HERE,
      base::Bind(&TestTracker::FastTask, tracker(), 100),
      SequencedWorkerPool::CONTINUE_ON_SHUTDOWN);
  pool()->PostWorkerTaskWithShutdownBehavior(
      FROM_HERE,
      base::Bind(&TestTracker::FastTask, tracker(), 101),
      SequencedWorkerPool::SKIP_ON_SHUTDOWN);
  pool()->PostWorkerTaskWithShutdownBehavior(
      FROM_HERE,
      base::Bind(&TestTracker::FastTask, tracker(), 102),
      SequencedWorkerPool::BLOCK_SHUTDOWN);

  // Shutdown the worker pool. This should discard all non-blocking tasks.
  SetWillWaitForShutdownCallback(
      base::Bind(&EnsureTasksToCompleteCountAndUnblock,
                 scoped_refptr<TestTracker>(tracker()), 0,
                 &blocker, kNumWorkerThreads));
  pool()->Shutdown();

  std::vector<int> result =
      tracker()->WaitUntilTasksComplete(kNumWorkerThreads + 1);

  // The kNumWorkerThread items should have completed, plus the BLOCK_SHUTDOWN
  // one, in no particular order.
  ASSERT_EQ(kNumWorkerThreads + 1, result.size());
  for (size_t i = 0; i < kNumWorkerThreads; i++) {
    EXPECT_TRUE(std::find(result.begin(), result.end(), static_cast<int>(i)) !=
                result.end());
  }
  EXPECT_TRUE(std::find(result.begin(), result.end(), 102) != result.end());
}

// Tests that CONTINUE_ON_SHUTDOWN tasks don't block shutdown.
TEST_F(SequencedWorkerPoolTest, ContinueOnShutdown) {
  scoped_refptr<TaskRunner> runner(pool()->GetTaskRunnerWithShutdownBehavior(
      SequencedWorkerPool::CONTINUE_ON_SHUTDOWN));
  scoped_refptr<SequencedTaskRunner> sequenced_runner(
      pool()->GetSequencedTaskRunnerWithShutdownBehavior(
          pool()->GetSequenceToken(),
          SequencedWorkerPool::CONTINUE_ON_SHUTDOWN));
  EnsureAllWorkersCreated();
  ThreadBlocker blocker;
  pool()->PostWorkerTaskWithShutdownBehavior(
      FROM_HERE,
      base::Bind(&TestTracker::BlockTask,
                 tracker(), 0, &blocker),
      SequencedWorkerPool::CONTINUE_ON_SHUTDOWN);
  runner->PostTask(
      FROM_HERE,
      base::Bind(&TestTracker::BlockTask,
                 tracker(), 1, &blocker));
  sequenced_runner->PostTask(
      FROM_HERE,
      base::Bind(&TestTracker::BlockTask,
                 tracker(), 2, &blocker));

  tracker()->WaitUntilTasksBlocked(3);

  // This should not block. If this test hangs, it means it failed.
  pool()->Shutdown();

  // The task should not have completed yet.
  EXPECT_EQ(0u, tracker()->WaitUntilTasksComplete(0).size());

  // Posting more tasks should fail.
  EXPECT_FALSE(pool()->PostWorkerTaskWithShutdownBehavior(
      FROM_HERE, base::Bind(&TestTracker::FastTask, tracker(), 0),
      SequencedWorkerPool::CONTINUE_ON_SHUTDOWN));
  EXPECT_FALSE(runner->PostTask(
      FROM_HERE, base::Bind(&TestTracker::FastTask, tracker(), 0)));
  EXPECT_FALSE(sequenced_runner->PostTask(
      FROM_HERE, base::Bind(&TestTracker::FastTask, tracker(), 0)));

  // Continue the background thread and make sure the tasks can complete.
  blocker.Unblock(3);
  std::vector<int> result = tracker()->WaitUntilTasksComplete(3);
  EXPECT_EQ(3u, result.size());
}

// Tests that SKIP_ON_SHUTDOWN tasks that have been started block Shutdown
// until they stop, but tasks not yet started do not.
TEST_F(SequencedWorkerPoolTest, SkipOnShutdown) {
  // Start tasks to take all the threads and block them.
  EnsureAllWorkersCreated();
  ThreadBlocker blocker;

  // Now block all the threads with SKIP_ON_SHUTDOWN. Shutdown() should not
  // return until these tasks have completed.
  for (size_t i = 0; i < kNumWorkerThreads; i++) {
    pool()->PostWorkerTaskWithShutdownBehavior(
        FROM_HERE,
        base::Bind(&TestTracker::BlockTask, tracker(), i, &blocker),
        SequencedWorkerPool::SKIP_ON_SHUTDOWN);
  }
  tracker()->WaitUntilTasksBlocked(kNumWorkerThreads);

  // Now post an additional task as SKIP_ON_SHUTDOWN, which should not be
  // executed once Shutdown() has been called.
  pool()->PostWorkerTaskWithShutdownBehavior(
      FROM_HERE,
      base::Bind(&TestTracker::BlockTask,
                 tracker(), 0, &blocker),
      SequencedWorkerPool::SKIP_ON_SHUTDOWN);

  // This callback will only be invoked if SKIP_ON_SHUTDOWN tasks that have
  // been started block shutdown.
  SetWillWaitForShutdownCallback(
      base::Bind(&EnsureTasksToCompleteCountAndUnblock,
                 scoped_refptr<TestTracker>(tracker()), 0,
                 &blocker, kNumWorkerThreads));

  // No tasks should have completed yet.
  EXPECT_EQ(0u, tracker()->WaitUntilTasksComplete(0).size());

  // This should not block. If this test hangs, it means it failed.
  pool()->Shutdown();

  // Shutdown should not return until all of the tasks have completed.
  std::vector<int> result =
      tracker()->WaitUntilTasksComplete(kNumWorkerThreads);

  // Only tasks marked SKIP_ON_SHUTDOWN that were already started should be
  // allowed to complete. No additional non-blocking tasks should have been
  // started.
  ASSERT_EQ(kNumWorkerThreads, result.size());
  for (size_t i = 0; i < kNumWorkerThreads; i++) {
    EXPECT_TRUE(std::find(result.begin(), result.end(), static_cast<int>(i)) !=
                result.end());
  }
}

// Ensure all worker threads are created, and then trigger a spurious
// work signal. This shouldn't cause any other work signals to be
// triggered. This is a regression test for http://crbug.com/117469.
TEST_F(SequencedWorkerPoolTest, SpuriousWorkSignal) {
  EnsureAllWorkersCreated();
  int old_has_work_call_count = has_work_call_count();
  pool()->SignalHasWorkForTesting();
  // This is inherently racy, but can only produce false positives.
  base::PlatformThread::Sleep(base::TimeDelta::FromMilliseconds(100));
  EXPECT_EQ(old_has_work_call_count + 1, has_work_call_count());
}

void IsRunningOnCurrentThreadTask(
    SequencedWorkerPool::SequenceToken test_positive_token,
    SequencedWorkerPool::SequenceToken test_negative_token,
    SequencedWorkerPool* pool,
    SequencedWorkerPool* unused_pool) {
  EXPECT_TRUE(pool->RunsTasksOnCurrentThread());
  EXPECT_TRUE(pool->IsRunningSequenceOnCurrentThread(test_positive_token));
  EXPECT_FALSE(pool->IsRunningSequenceOnCurrentThread(test_negative_token));
  EXPECT_FALSE(unused_pool->RunsTasksOnCurrentThread());
  EXPECT_FALSE(
      unused_pool->IsRunningSequenceOnCurrentThread(test_positive_token));
  EXPECT_FALSE(
      unused_pool->IsRunningSequenceOnCurrentThread(test_negative_token));
}

// Verify correctness of the IsRunningSequenceOnCurrentThread method.
TEST_F(SequencedWorkerPoolTest, IsRunningOnCurrentThread) {
  SequencedWorkerPool::SequenceToken token1 = pool()->GetSequenceToken();
  SequencedWorkerPool::SequenceToken token2 = pool()->GetSequenceToken();
  SequencedWorkerPool::SequenceToken unsequenced_token;

  scoped_refptr<SequencedWorkerPool> unused_pool =
      new SequencedWorkerPool(2, "unused_pool");

  EXPECT_FALSE(pool()->RunsTasksOnCurrentThread());
  EXPECT_FALSE(pool()->IsRunningSequenceOnCurrentThread(token1));
  EXPECT_FALSE(pool()->IsRunningSequenceOnCurrentThread(token2));
  EXPECT_FALSE(pool()->IsRunningSequenceOnCurrentThread(unsequenced_token));
  EXPECT_FALSE(unused_pool->RunsTasksOnCurrentThread());
  EXPECT_FALSE(unused_pool->IsRunningSequenceOnCurrentThread(token1));
  EXPECT_FALSE(unused_pool->IsRunningSequenceOnCurrentThread(token2));
  EXPECT_FALSE(
      unused_pool->IsRunningSequenceOnCurrentThread(unsequenced_token));

  pool()->PostSequencedWorkerTask(
      token1, FROM_HERE,
      base::Bind(&IsRunningOnCurrentThreadTask,
                 token1, token2, pool(), unused_pool));
  pool()->PostSequencedWorkerTask(
      token2, FROM_HERE,
      base::Bind(&IsRunningOnCurrentThreadTask,
                 token2, unsequenced_token, pool(), unused_pool));
  pool()->PostWorkerTask(
      FROM_HERE,
      base::Bind(&IsRunningOnCurrentThreadTask,
                 unsequenced_token, token1, pool(), unused_pool));
  pool()->Shutdown();
  unused_pool->Shutdown();
}

// Checks that tasks are destroyed in the right context during shutdown. If a
// task is destroyed while SequencedWorkerPool's global lock is held,
// SequencedWorkerPool might deadlock.
TEST_F(SequencedWorkerPoolTest, AvoidsDeadlockOnShutdown) {
  for (int i = 0; i < 4; ++i) {
    scoped_refptr<DestructionDeadlockChecker> checker(
        new DestructionDeadlockChecker(pool()));
    tracker()->PostRepostingTask(pool(), checker);
  }

  // Shutting down the pool should destroy the DestructionDeadlockCheckers,
  // which in turn should not deadlock in their destructors.
  pool()->Shutdown();
}

// Similar to the test AvoidsDeadlockOnShutdown, but there are now also
// sequenced, blocking tasks in the queue during shutdown.
TEST_F(SequencedWorkerPoolTest,
       AvoidsDeadlockOnShutdownWithSequencedBlockingTasks) {
  const std::string sequence_token_name("name");
  for (int i = 0; i < 4; ++i) {
    scoped_refptr<DestructionDeadlockChecker> checker(
        new DestructionDeadlockChecker(pool()));
    tracker()->PostRepostingTask(pool(), checker);

    SequencedWorkerPool::SequenceToken token1 =
        pool()->GetNamedSequenceToken(sequence_token_name);
    tracker()->PostRepostingBlockingTask(pool(), token1);
  }

  // Shutting down the pool should destroy the DestructionDeadlockCheckers,
  // which in turn should not deadlock in their destructors.
  pool()->Shutdown();
}

// Verify that FlushForTesting works as intended.
TEST_F(SequencedWorkerPoolTest, FlushForTesting) {
  // Should be fine to call on a new instance.
  pool()->FlushForTesting();

  // Queue up a bunch of work, including  a long delayed task and
  // a task that produces additional tasks as an artifact.
  pool()->PostDelayedWorkerTask(
      FROM_HERE,
      base::Bind(&TestTracker::FastTask, tracker(), 0),
      TimeDelta::FromMinutes(5));
  pool()->PostWorkerTask(FROM_HERE,
                         base::Bind(&TestTracker::SlowTask, tracker(), 0));
  const size_t kNumFastTasks = 20;
  for (size_t i = 0; i < kNumFastTasks; i++) {
    pool()->PostWorkerTask(FROM_HERE,
                           base::Bind(&TestTracker::FastTask, tracker(), 0));
  }
  pool()->PostWorkerTask(
      FROM_HERE,
      base::Bind(&TestTracker::PostAdditionalTasks, tracker(), 0, pool(),
                 true));

  // We expect all except the delayed task to have been run. We verify all
  // closures have been deleted by looking at the refcount of the
  // tracker.
  EXPECT_FALSE(tracker()->HasOneRef());
  pool()->FlushForTesting();
  EXPECT_TRUE(tracker()->HasOneRef());
  EXPECT_EQ(1 + kNumFastTasks + 1 + 3, tracker()->GetTasksCompletedCount());

  // Should be fine to call on an idle instance with all threads created, and
  // spamming the method shouldn't deadlock or confuse the class.
  pool()->FlushForTesting();
  pool()->FlushForTesting();

  // Should be fine to call after shutdown too.
  pool()->Shutdown();
  pool()->FlushForTesting();
}

TEST(SequencedWorkerPoolRefPtrTest, ShutsDownCleanWithContinueOnShutdown) {
  MessageLoop loop;
  scoped_refptr<SequencedWorkerPool> pool(new SequencedWorkerPool(3, "Pool"));
  scoped_refptr<SequencedTaskRunner> task_runner =
      pool->GetSequencedTaskRunnerWithShutdownBehavior(
          pool->GetSequenceToken(),
          base::SequencedWorkerPool::CONTINUE_ON_SHUTDOWN);

  // Upon test exit, should shut down without hanging.
  pool->Shutdown();
}

class SequencedWorkerPoolTaskRunnerTestDelegate {
 public:
  SequencedWorkerPoolTaskRunnerTestDelegate() {}

  ~SequencedWorkerPoolTaskRunnerTestDelegate() {}

  void StartTaskRunner() {
    pool_owner_.reset(
        new SequencedWorkerPoolOwner(10, "SequencedWorkerPoolTaskRunnerTest"));
  }

  scoped_refptr<SequencedWorkerPool> GetTaskRunner() {
    return pool_owner_->pool();
  }

  void StopTaskRunner() {
    // Make sure all tasks are run before shutting down. Delayed tasks are
    // not run, they're simply deleted.
    pool_owner_->pool()->FlushForTesting();
    pool_owner_->pool()->Shutdown();
    // Don't reset |pool_owner_| here, as the test may still hold a
    // reference to the pool.
  }

 private:
  MessageLoop message_loop_;
  scoped_ptr<SequencedWorkerPoolOwner> pool_owner_;
};

INSTANTIATE_TYPED_TEST_CASE_P(
    SequencedWorkerPool, TaskRunnerTest,
    SequencedWorkerPoolTaskRunnerTestDelegate);

class SequencedWorkerPoolTaskRunnerWithShutdownBehaviorTestDelegate {
 public:
  SequencedWorkerPoolTaskRunnerWithShutdownBehaviorTestDelegate() {}

  ~SequencedWorkerPoolTaskRunnerWithShutdownBehaviorTestDelegate() {
  }

  void StartTaskRunner() {
    pool_owner_.reset(
        new SequencedWorkerPoolOwner(10, "SequencedWorkerPoolTaskRunnerTest"));
    task_runner_ = pool_owner_->pool()->GetTaskRunnerWithShutdownBehavior(
        SequencedWorkerPool::BLOCK_SHUTDOWN);
  }

  scoped_refptr<TaskRunner> GetTaskRunner() {
    return task_runner_;
  }

  void StopTaskRunner() {
    // Make sure all tasks are run before shutting down. Delayed tasks are
    // not run, they're simply deleted.
    pool_owner_->pool()->FlushForTesting();
    pool_owner_->pool()->Shutdown();
    // Don't reset |pool_owner_| here, as the test may still hold a
    // reference to the pool.
  }

 private:
  MessageLoop message_loop_;
  scoped_ptr<SequencedWorkerPoolOwner> pool_owner_;
  scoped_refptr<TaskRunner> task_runner_;
};

INSTANTIATE_TYPED_TEST_CASE_P(
    SequencedWorkerPoolTaskRunner, TaskRunnerTest,
    SequencedWorkerPoolTaskRunnerWithShutdownBehaviorTestDelegate);

class SequencedWorkerPoolSequencedTaskRunnerTestDelegate {
 public:
  SequencedWorkerPoolSequencedTaskRunnerTestDelegate() {}

  ~SequencedWorkerPoolSequencedTaskRunnerTestDelegate() {
  }

  void StartTaskRunner() {
    pool_owner_.reset(new SequencedWorkerPoolOwner(
        10, "SequencedWorkerPoolSequencedTaskRunnerTest"));
    task_runner_ = pool_owner_->pool()->GetSequencedTaskRunner(
        pool_owner_->pool()->GetSequenceToken());
  }

  scoped_refptr<SequencedTaskRunner> GetTaskRunner() {
    return task_runner_;
  }

  void StopTaskRunner() {
    // Make sure all tasks are run before shutting down. Delayed tasks are
    // not run, they're simply deleted.
    pool_owner_->pool()->FlushForTesting();
    pool_owner_->pool()->Shutdown();
    // Don't reset |pool_owner_| here, as the test may still hold a
    // reference to the pool.
  }

 private:
  MessageLoop message_loop_;
  scoped_ptr<SequencedWorkerPoolOwner> pool_owner_;
  scoped_refptr<SequencedTaskRunner> task_runner_;
};

INSTANTIATE_TYPED_TEST_CASE_P(
    SequencedWorkerPoolSequencedTaskRunner, TaskRunnerTest,
    SequencedWorkerPoolSequencedTaskRunnerTestDelegate);

INSTANTIATE_TYPED_TEST_CASE_P(
    SequencedWorkerPoolSequencedTaskRunner, SequencedTaskRunnerTest,
    SequencedWorkerPoolSequencedTaskRunnerTestDelegate);

}  // namespace

}  // namespace base
