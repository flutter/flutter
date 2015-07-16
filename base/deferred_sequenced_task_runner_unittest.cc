// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/deferred_sequenced_task_runner.h"

#include "base/basictypes.h"
#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/location.h"
#include "base/memory/ref_counted.h"
#include "base/single_thread_task_runner.h"
#include "base/threading/non_thread_safe.h"
#include "base/threading/thread.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

class DeferredSequencedTaskRunnerTest : public testing::Test,
                                        public base::NonThreadSafe {
 public:
  class ExecuteTaskOnDestructor :
      public base::RefCounted<ExecuteTaskOnDestructor> {
   public:
    ExecuteTaskOnDestructor(
        DeferredSequencedTaskRunnerTest* executor,
        int task_id)
        : executor_(executor),
          task_id_(task_id) {
    }
  private:
    friend class base::RefCounted<ExecuteTaskOnDestructor>;
    virtual ~ExecuteTaskOnDestructor() {
      executor_->ExecuteTask(task_id_);
    }
    DeferredSequencedTaskRunnerTest* executor_;
    int task_id_;
  };

  void ExecuteTask(int task_id) {
    base::AutoLock lock(lock_);
    executed_task_ids_.push_back(task_id);
  }

  void PostExecuteTask(int task_id) {
    runner_->PostTask(FROM_HERE,
                      base::Bind(&DeferredSequencedTaskRunnerTest::ExecuteTask,
                                 base::Unretained(this),
                                 task_id));
  }

  void StartRunner() {
    runner_->Start();
  }

  void DoNothing(ExecuteTaskOnDestructor* object) {
  }

 protected:
  DeferredSequencedTaskRunnerTest()
      : loop_(),
        runner_(new base::DeferredSequencedTaskRunner(loop_.task_runner())) {}

  base::MessageLoop loop_;
  scoped_refptr<base::DeferredSequencedTaskRunner> runner_;
  mutable base::Lock lock_;
  std::vector<int> executed_task_ids_;
};

TEST_F(DeferredSequencedTaskRunnerTest, Stopped) {
  PostExecuteTask(1);
  loop_.RunUntilIdle();
  EXPECT_THAT(executed_task_ids_, testing::ElementsAre());
}

TEST_F(DeferredSequencedTaskRunnerTest, Start) {
  StartRunner();
  PostExecuteTask(1);
  loop_.RunUntilIdle();
  EXPECT_THAT(executed_task_ids_, testing::ElementsAre(1));
}

TEST_F(DeferredSequencedTaskRunnerTest, StartWithMultipleElements) {
  StartRunner();
  for (int i = 1; i < 5; ++i)
    PostExecuteTask(i);

  loop_.RunUntilIdle();
  EXPECT_THAT(executed_task_ids_, testing::ElementsAre(1, 2, 3, 4));
}

TEST_F(DeferredSequencedTaskRunnerTest, DeferredStart) {
  PostExecuteTask(1);
  loop_.RunUntilIdle();
  EXPECT_THAT(executed_task_ids_, testing::ElementsAre());

  StartRunner();
  loop_.RunUntilIdle();
  EXPECT_THAT(executed_task_ids_, testing::ElementsAre(1));

  PostExecuteTask(2);
  loop_.RunUntilIdle();
  EXPECT_THAT(executed_task_ids_, testing::ElementsAre(1, 2));
}

TEST_F(DeferredSequencedTaskRunnerTest, DeferredStartWithMultipleElements) {
  for (int i = 1; i < 5; ++i)
    PostExecuteTask(i);
  loop_.RunUntilIdle();
  EXPECT_THAT(executed_task_ids_, testing::ElementsAre());

  StartRunner();
  for (int i = 5; i < 9; ++i)
    PostExecuteTask(i);
  loop_.RunUntilIdle();
  EXPECT_THAT(executed_task_ids_, testing::ElementsAre(1, 2, 3, 4, 5, 6, 7, 8));
}

TEST_F(DeferredSequencedTaskRunnerTest, DeferredStartWithMultipleThreads) {
  {
    base::Thread thread1("DeferredSequencedTaskRunnerTestThread1");
    base::Thread thread2("DeferredSequencedTaskRunnerTestThread2");
    thread1.Start();
    thread2.Start();
    for (int i = 0; i < 5; ++i) {
      thread1.task_runner()->PostTask(
          FROM_HERE,
          base::Bind(&DeferredSequencedTaskRunnerTest::PostExecuteTask,
                     base::Unretained(this), 2 * i));
      thread2.task_runner()->PostTask(
          FROM_HERE,
          base::Bind(&DeferredSequencedTaskRunnerTest::PostExecuteTask,
                     base::Unretained(this), 2 * i + 1));
      if (i == 2) {
        thread1.task_runner()->PostTask(
            FROM_HERE, base::Bind(&DeferredSequencedTaskRunnerTest::StartRunner,
                                  base::Unretained(this)));
      }
    }
  }

  loop_.RunUntilIdle();
  EXPECT_THAT(executed_task_ids_,
      testing::WhenSorted(testing::ElementsAre(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)));
}

TEST_F(DeferredSequencedTaskRunnerTest, ObjectDestructionOrder) {
  {
    base::Thread thread("DeferredSequencedTaskRunnerTestThread");
    thread.Start();
    runner_ = new base::DeferredSequencedTaskRunner(thread.task_runner());
    for (int i = 0; i < 5; ++i) {
      {
        // Use a block to ensure that no reference to |short_lived_object|
        // is kept on the main thread after it is posted to |runner_|.
        scoped_refptr<ExecuteTaskOnDestructor> short_lived_object =
            new ExecuteTaskOnDestructor(this, 2 * i);
        runner_->PostTask(
            FROM_HERE,
            base::Bind(&DeferredSequencedTaskRunnerTest::DoNothing,
                       base::Unretained(this),
                       short_lived_object));
      }
      // |short_lived_object| with id |2 * i| should be destroyed before the
      // task |2 * i + 1| is executed.
      PostExecuteTask(2 * i + 1);
    }
    StartRunner();
  }

  // All |short_lived_object| with id |2 * i| are destroyed before the task
  // |2 * i + 1| is executed.
  EXPECT_THAT(executed_task_ids_,
              testing::ElementsAre(0, 1, 2, 3, 4, 5, 6, 7, 8, 9));
}

}  // namespace
