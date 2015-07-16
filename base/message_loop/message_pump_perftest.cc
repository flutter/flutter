// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/format_macros.h"
#include "base/memory/scoped_vector.h"
#include "base/strings/stringprintf.h"
#include "base/synchronization/condition_variable.h"
#include "base/synchronization/lock.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread.h"
#include "base/time/time.h"
#include "build/build_config.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/perf/perf_test.h"

#if defined(OS_ANDROID)
#include "base/android/java_handler_thread.h"
#endif

namespace base {

class ScheduleWorkTest : public testing::Test {
 public:
  ScheduleWorkTest() : counter_(0) {}

  void Increment(uint64_t amount) { counter_ += amount; }

  void Schedule(int index) {
    base::TimeTicks start = base::TimeTicks::Now();
    base::ThreadTicks thread_start;
    if (ThreadTicks::IsSupported())
      thread_start = base::ThreadTicks::Now();
    base::TimeDelta minimum = base::TimeDelta::Max();
    base::TimeDelta maximum = base::TimeDelta();
    base::TimeTicks now, lastnow = start;
    uint64_t schedule_calls = 0u;
    do {
      for (size_t i = 0; i < kBatchSize; ++i) {
        target_message_loop()->ScheduleWork();
        schedule_calls++;
      }
      now = base::TimeTicks::Now();
      base::TimeDelta laptime = now - lastnow;
      lastnow = now;
      minimum = std::min(minimum, laptime);
      maximum = std::max(maximum, laptime);
    } while (now - start < base::TimeDelta::FromSeconds(kTargetTimeSec));

    scheduling_times_[index] = now - start;
    if (ThreadTicks::IsSupported())
      scheduling_thread_times_[index] =
          base::ThreadTicks::Now() - thread_start;
    min_batch_times_[index] = minimum;
    max_batch_times_[index] = maximum;
    target_message_loop()->PostTask(FROM_HERE,
                                    base::Bind(&ScheduleWorkTest::Increment,
                                               base::Unretained(this),
                                               schedule_calls));
  }

  void ScheduleWork(MessageLoop::Type target_type, int num_scheduling_threads) {
#if defined(OS_ANDROID)
    if (target_type == MessageLoop::TYPE_JAVA) {
      java_thread_.reset(new android::JavaHandlerThread("target"));
      java_thread_->Start();
    } else
#endif
    {
      target_.reset(new Thread("target"));
      target_->StartWithOptions(Thread::Options(target_type, 0u));
    }

    ScopedVector<Thread> scheduling_threads;
    scheduling_times_.reset(new base::TimeDelta[num_scheduling_threads]);
    scheduling_thread_times_.reset(new base::TimeDelta[num_scheduling_threads]);
    min_batch_times_.reset(new base::TimeDelta[num_scheduling_threads]);
    max_batch_times_.reset(new base::TimeDelta[num_scheduling_threads]);

    for (int i = 0; i < num_scheduling_threads; ++i) {
      scheduling_threads.push_back(new Thread("posting thread"));
      scheduling_threads[i]->Start();
    }

    for (int i = 0; i < num_scheduling_threads; ++i) {
      scheduling_threads[i]->message_loop()->PostTask(
          FROM_HERE,
          base::Bind(&ScheduleWorkTest::Schedule, base::Unretained(this), i));
    }

    for (int i = 0; i < num_scheduling_threads; ++i) {
      scheduling_threads[i]->Stop();
    }
#if defined(OS_ANDROID)
    if (target_type == MessageLoop::TYPE_JAVA) {
      java_thread_->Stop();
      java_thread_.reset();
    } else
#endif
    {
      target_->Stop();
      target_.reset();
    }
    base::TimeDelta total_time;
    base::TimeDelta total_thread_time;
    base::TimeDelta min_batch_time = base::TimeDelta::Max();
    base::TimeDelta max_batch_time = base::TimeDelta();
    for (int i = 0; i < num_scheduling_threads; ++i) {
      total_time += scheduling_times_[i];
      total_thread_time += scheduling_thread_times_[i];
      min_batch_time = std::min(min_batch_time, min_batch_times_[i]);
      max_batch_time = std::max(max_batch_time, max_batch_times_[i]);
    }
    std::string trace = StringPrintf(
        "%d_threads_scheduling_to_%s_pump",
        num_scheduling_threads,
        target_type == MessageLoop::TYPE_IO
            ? "io"
            : (target_type == MessageLoop::TYPE_UI ? "ui" : "default"));
    perf_test::PrintResult(
        "task",
        "",
        trace,
        total_time.InMicroseconds() / static_cast<double>(counter_),
        "us/task",
        true);
    perf_test::PrintResult(
        "task",
        "_min_batch_time",
        trace,
        min_batch_time.InMicroseconds() / static_cast<double>(kBatchSize),
        "us/task",
        false);
    perf_test::PrintResult(
        "task",
        "_max_batch_time",
        trace,
        max_batch_time.InMicroseconds() / static_cast<double>(kBatchSize),
        "us/task",
        false);
    if (ThreadTicks::IsSupported()) {
      perf_test::PrintResult(
          "task",
          "_thread_time",
          trace,
          total_thread_time.InMicroseconds() / static_cast<double>(counter_),
          "us/task",
          true);
    }
  }

  MessageLoop* target_message_loop() {
#if defined(OS_ANDROID)
    if (java_thread_)
      return java_thread_->message_loop();
#endif
    return target_->message_loop();
  }

 private:
  scoped_ptr<Thread> target_;
#if defined(OS_ANDROID)
  scoped_ptr<android::JavaHandlerThread> java_thread_;
#endif
  scoped_ptr<base::TimeDelta[]> scheduling_times_;
  scoped_ptr<base::TimeDelta[]> scheduling_thread_times_;
  scoped_ptr<base::TimeDelta[]> min_batch_times_;
  scoped_ptr<base::TimeDelta[]> max_batch_times_;
  uint64_t counter_;

  static const size_t kTargetTimeSec = 5;
  static const size_t kBatchSize = 1000;
};

TEST_F(ScheduleWorkTest, ThreadTimeToIOFromOneThread) {
  ScheduleWork(MessageLoop::TYPE_IO, 1);
}

TEST_F(ScheduleWorkTest, ThreadTimeToIOFromTwoThreads) {
  ScheduleWork(MessageLoop::TYPE_IO, 2);
}

TEST_F(ScheduleWorkTest, ThreadTimeToIOFromFourThreads) {
  ScheduleWork(MessageLoop::TYPE_IO, 4);
}

TEST_F(ScheduleWorkTest, ThreadTimeToUIFromOneThread) {
  ScheduleWork(MessageLoop::TYPE_UI, 1);
}

TEST_F(ScheduleWorkTest, ThreadTimeToUIFromTwoThreads) {
  ScheduleWork(MessageLoop::TYPE_UI, 2);
}

TEST_F(ScheduleWorkTest, ThreadTimeToUIFromFourThreads) {
  ScheduleWork(MessageLoop::TYPE_UI, 4);
}

TEST_F(ScheduleWorkTest, ThreadTimeToDefaultFromOneThread) {
  ScheduleWork(MessageLoop::TYPE_DEFAULT, 1);
}

TEST_F(ScheduleWorkTest, ThreadTimeToDefaultFromTwoThreads) {
  ScheduleWork(MessageLoop::TYPE_DEFAULT, 2);
}

TEST_F(ScheduleWorkTest, ThreadTimeToDefaultFromFourThreads) {
  ScheduleWork(MessageLoop::TYPE_DEFAULT, 4);
}

#if defined(OS_ANDROID)
TEST_F(ScheduleWorkTest, ThreadTimeToJavaFromOneThread) {
  ScheduleWork(MessageLoop::TYPE_JAVA, 1);
}

TEST_F(ScheduleWorkTest, ThreadTimeToJavaFromTwoThreads) {
  ScheduleWork(MessageLoop::TYPE_JAVA, 2);
}

TEST_F(ScheduleWorkTest, ThreadTimeToJavaFromFourThreads) {
  ScheduleWork(MessageLoop::TYPE_JAVA, 4);
}
#endif

class FakeMessagePump : public MessagePump {
 public:
  FakeMessagePump() {}
  ~FakeMessagePump() override {}

  void Run(Delegate* delegate) override {}

  void Quit() override {}
  void ScheduleWork() override {}
  void ScheduleDelayedWork(const TimeTicks& delayed_work_time) override {}
};

class PostTaskTest : public testing::Test {
 public:
  void Run(int batch_size, int tasks_per_reload) {
    base::TimeTicks start = base::TimeTicks::Now();
    base::TimeTicks now;
    MessageLoop loop(scoped_ptr<MessagePump>(new FakeMessagePump));
    scoped_refptr<internal::IncomingTaskQueue> queue(
        new internal::IncomingTaskQueue(&loop));
    uint32_t num_posted = 0;
    do {
      for (int i = 0; i < batch_size; ++i) {
        for (int j = 0; j < tasks_per_reload; ++j) {
          queue->AddToIncomingQueue(
              FROM_HERE, base::Bind(&DoNothing), base::TimeDelta(), false);
          num_posted++;
        }
        TaskQueue loop_local_queue;
        queue->ReloadWorkQueue(&loop_local_queue);
        while (!loop_local_queue.empty()) {
          PendingTask t = loop_local_queue.front();
          loop_local_queue.pop();
          loop.RunTask(t);
        }
      }

      now = base::TimeTicks::Now();
    } while (now - start < base::TimeDelta::FromSeconds(5));
    std::string trace = StringPrintf("%d_tasks_per_reload", tasks_per_reload);
    perf_test::PrintResult(
        "task",
        "",
        trace,
        (now - start).InMicroseconds() / static_cast<double>(num_posted),
        "us/task",
        true);
  }
};

TEST_F(PostTaskTest, OneTaskPerReload) {
  Run(10000, 1);
}

TEST_F(PostTaskTest, TenTasksPerReload) {
  Run(10000, 10);
}

TEST_F(PostTaskTest, OneHundredTasksPerReload) {
  Run(1000, 100);
}

}  // namespace base
