// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/libdispatch_task_runner.h"

#include "base/bind.h"
#include "base/mac/bind_objc_block.h"
#include "base/message_loop/message_loop.h"
#include "base/strings/stringprintf.h"
#include "testing/gtest/include/gtest/gtest.h"

class LibDispatchTaskRunnerTest : public testing::Test {
 public:
  void SetUp() override {
    task_runner_ = new base::mac::LibDispatchTaskRunner(
        "org.chromium.LibDispatchTaskRunnerTest");
  }

  // DispatchLastTask is used to run the main test thread's MessageLoop until
  // all non-delayed tasks are run on the LibDispatchTaskRunner.
  void DispatchLastTask() {
    dispatch_async(task_runner_->GetDispatchQueue(), ^{
        message_loop_.PostTask(FROM_HERE,
                               base::MessageLoop::QuitWhenIdleClosure());
    });
    message_loop_.Run();
    task_runner_->Shutdown();
  }

  // VerifyTaskOrder takes the expectations from TaskOrderMarkers and compares
  // them against the recorded values.
  void VerifyTaskOrder(const char* const expectations[],
                       size_t num_expectations) {
    size_t actual_size = task_order_.size();

    for (size_t i = 0; i < num_expectations; ++i) {
      if (i >= actual_size) {
        EXPECT_LE(i, actual_size) << "Expected " << expectations[i];
        continue;
      }

      EXPECT_EQ(expectations[i], task_order_[i]);
    }

    if (actual_size > num_expectations) {
      EXPECT_LE(actual_size, num_expectations) << "Extra tasks were run:";
      for (size_t i = num_expectations; i < actual_size; ++i) {
        EXPECT_EQ("<none>", task_order_[i]) << " (i=" << i << ")";
      }
    }
  }

  // The message loop for the test main thread.
  base::MessageLoop message_loop_;

  // The task runner under test.
  scoped_refptr<base::mac::LibDispatchTaskRunner> task_runner_;

  // Vector that records data from TaskOrderMarker.
  std::vector<std::string> task_order_;
};

// Scoper that records the beginning and end of a running task.
class TaskOrderMarker {
 public:
  TaskOrderMarker(LibDispatchTaskRunnerTest* test, const std::string& name)
      : test_(test),
        name_(name) {
    test->task_order_.push_back(std::string("BEGIN ") + name);
  }
  ~TaskOrderMarker() {
    test_->task_order_.push_back(std::string("END ") + name_);
  }

 private:
  LibDispatchTaskRunnerTest* test_;
  std::string name_;
};

void RecordTaskOrder(LibDispatchTaskRunnerTest* test, const std::string& name) {
  TaskOrderMarker marker(test, name);
}

// Returns a closure that records the task order.
base::Closure BoundRecordTaskOrder(LibDispatchTaskRunnerTest* test,
                                   const std::string& name) {
  return base::Bind(&RecordTaskOrder, base::Unretained(test), name);
}

TEST_F(LibDispatchTaskRunnerTest, PostTask) {
  task_runner_->PostTask(FROM_HERE, BoundRecordTaskOrder(this, "Basic Task"));
  DispatchLastTask();
  const char* const expectations[] = {
    "BEGIN Basic Task",
    "END Basic Task"
  };
  VerifyTaskOrder(expectations, arraysize(expectations));
}

TEST_F(LibDispatchTaskRunnerTest, PostTaskWithinTask) {
  task_runner_->PostTask(FROM_HERE, base::BindBlock(^{
      TaskOrderMarker marker(this, "Outer");
      task_runner_->PostTask(FROM_HERE, BoundRecordTaskOrder(this, "Inner"));
  }));
  DispatchLastTask();

  const char* const expectations[] = {
    "BEGIN Outer",
    "END Outer",
    "BEGIN Inner",
    "END Inner"
  };
  VerifyTaskOrder(expectations, arraysize(expectations));
}

TEST_F(LibDispatchTaskRunnerTest, NoMessageLoop) {
  task_runner_->PostTask(FROM_HERE, base::BindBlock(^{
      TaskOrderMarker marker(this,
          base::StringPrintf("MessageLoop = %p", base::MessageLoop::current()));
  }));
  DispatchLastTask();

  const char* const expectations[] = {
    "BEGIN MessageLoop = 0x0",
    "END MessageLoop = 0x0"
  };
  VerifyTaskOrder(expectations, arraysize(expectations));
}

TEST_F(LibDispatchTaskRunnerTest, DispatchAndPostTasks) {
  dispatch_async(task_runner_->GetDispatchQueue(), ^{
      TaskOrderMarker marker(this, "First Block");
  });
  task_runner_->PostTask(FROM_HERE, BoundRecordTaskOrder(this, "First Task"));
  dispatch_async(task_runner_->GetDispatchQueue(), ^{
      TaskOrderMarker marker(this, "Second Block");
  });
  task_runner_->PostTask(FROM_HERE, BoundRecordTaskOrder(this, "Second Task"));
  DispatchLastTask();

  const char* const expectations[] = {
    "BEGIN First Block",
    "END First Block",
    "BEGIN First Task",
    "END First Task",
    "BEGIN Second Block",
    "END Second Block",
    "BEGIN Second Task",
    "END Second Task",
  };
  VerifyTaskOrder(expectations, arraysize(expectations));
}

TEST_F(LibDispatchTaskRunnerTest, NonNestable) {
  task_runner_->PostTask(FROM_HERE, base::BindBlock(^{
      TaskOrderMarker marker(this, "First");
      task_runner_->PostNonNestableTask(FROM_HERE, base::BindBlock(^{
          TaskOrderMarker marker(this, "Second NonNestable");
          message_loop_.PostTask(FROM_HERE,
                                 base::MessageLoop::QuitWhenIdleClosure());
      }));
  }));
  message_loop_.Run();
  task_runner_->Shutdown();

  const char* const expectations[] = {
    "BEGIN First",
    "END First",
    "BEGIN Second NonNestable",
    "END Second NonNestable"
  };
  VerifyTaskOrder(expectations, arraysize(expectations));
}

TEST_F(LibDispatchTaskRunnerTest, PostDelayed) {
  base::TimeTicks post_time;
  __block base::TimeTicks run_time;
  const base::TimeDelta delta = base::TimeDelta::FromMilliseconds(50);

  task_runner_->PostTask(FROM_HERE, BoundRecordTaskOrder(this, "First"));
  post_time = base::TimeTicks::Now();
  task_runner_->PostDelayedTask(FROM_HERE, base::BindBlock(^{
      TaskOrderMarker marker(this, "Timed");
      run_time = base::TimeTicks::Now();
      message_loop_.PostTask(FROM_HERE,
                             base::MessageLoop::QuitWhenIdleClosure());
  }), delta);
  task_runner_->PostTask(FROM_HERE, BoundRecordTaskOrder(this, "Second"));
  message_loop_.Run();
  task_runner_->Shutdown();

  const char* const expectations[] = {
    "BEGIN First",
    "END First",
    "BEGIN Second",
    "END Second",
    "BEGIN Timed",
    "END Timed",
  };
  VerifyTaskOrder(expectations, arraysize(expectations));

  EXPECT_GE(run_time, post_time + delta);
}

TEST_F(LibDispatchTaskRunnerTest, PostAfterShutdown) {
  EXPECT_TRUE(task_runner_->PostTask(FROM_HERE,
      BoundRecordTaskOrder(this, "First")));
  EXPECT_TRUE(task_runner_->PostTask(FROM_HERE,
      BoundRecordTaskOrder(this, "Second")));
  task_runner_->Shutdown();
  EXPECT_FALSE(task_runner_->PostTask(FROM_HERE, base::BindBlock(^{
      TaskOrderMarker marker(this, "Not Run");
      ADD_FAILURE() << "Should not run a task after Shutdown";
  })));

  const char* const expectations[] = {
    "BEGIN First",
    "END First",
    "BEGIN Second",
    "END Second"
  };
  VerifyTaskOrder(expectations, arraysize(expectations));
}
